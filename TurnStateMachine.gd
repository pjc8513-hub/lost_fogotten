extends Node

enum State {
	PLAYER_INPUT,
	PLAYER_ACTION,
	WORLD_UPDATE,
	ENEMY_TURN,
	TRANSITION
}

var state: State = State.PLAYER_INPUT
var last_action_was_party_wide: bool = false
var combat_just_ended: bool = false

func set_state(new_state: State):
	print("STATE → ", new_state)
	state = new_state

	match state:
		State.PLAYER_INPUT:
			pass  # Player can issue commands
		State.PLAYER_ACTION:
			_on_player_action()
		State.WORLD_UPDATE:
			_on_world_update()
		State.ENEMY_TURN:
			_on_enemy_turn()
		State.TRANSITION:
			_on_transition()

func _on_player_action():
	if not CommandQueue.is_busy():
		_player_action_complete()
	else:
		CommandQueue.connect("queue_empty", Callable(self, "_player_action_complete"), CONNECT_ONE_SHOT)

func _player_action_complete():
	if CombatState.is_in_combat() and not last_action_was_party_wide:
		CombatState.mark_current_member_done()

	if last_action_was_party_wide:
		set_state(State.WORLD_UPDATE)
	else:
		if CombatState.advance_party_member():
			set_state(State.PLAYER_INPUT)
		else:
			set_state(State.WORLD_UPDATE)

func _on_world_update():
	var was_in_combat := CombatState.is_in_combat()
	World.process_step_events()
	CombatState.refresh_combat_state()
	_apply_poison_effects()
	if CombatState.is_in_combat():
		_tick_combat_effect_durations()
	combat_just_ended = was_in_combat and not CombatState.is_in_combat()
	if CombatState.is_in_combat():
		set_state(State.ENEMY_TURN)
	else:
		set_state(State.TRANSITION)

func _apply_poison_effects():
	for member in PartyState.active_party:
		if member.has_status_effect("poison") and member.current_hp > 0:
			member.take_damage(StatusEffects.POISON_TICK_DAMAGE)
			GameEvents.message_logged.emit("[color=purple]%s takes %d poison damage![/color]" % [member.member_name, StatusEffects.POISON_TICK_DAMAGE])
			if member.current_hp <= 0:
				GameEvents.message_logged.emit("[color=red]" + member.member_name + " dies from poison![/color]")
				
	var enemies = World.get_enemies()
	for enemy in enemies:
		if enemy.enemy_data.has_status_effect("poison") and enemy.enemy_data.hp > 0:
			var poison_damage := CombatLogic.apply_damage_status_bonuses(enemy, StatusEffects.POISON_TICK_DAMAGE)
			enemy.enemy_data.hp -= poison_damage
			GameEvents.enemy_took_damage.emit(enemy, poison_damage)
			GameEvents.message_logged.emit("[color=purple]%s takes %d poison damage![/color]" % [enemy.enemy_data.enemy_name, poison_damage])
			if enemy.enemy_data.hp <= 0:
				GameEvents.message_logged.emit("[color=red]" + enemy.enemy_data.enemy_name + " dies from poison![/color]")
				World.remove_enemy(enemy)

func _tick_combat_effect_durations() -> void:
	SpellEffectTracker.tick_combat_round()
	for member in PartyState.active_party:
		if member.has_method("tick_combat_buff_durations"):
			member.tick_combat_buff_durations()
		if member.has_method("tick_status_durations"):
			member.tick_status_durations()

	for enemy in World.get_enemies():
		if enemy.enemy_data.has_method("tick_combat_buff_durations"):
			enemy.enemy_data.tick_combat_buff_durations()
		if enemy.enemy_data.has_method("tick_status_durations"):
			enemy.enemy_data.tick_status_durations()

func _on_enemy_turn():
	var enemies = CombatState.get_engaged_enemies()
	print("[TurnStateMachine] _on_enemy_turn enemies=", enemies.size())

	if enemies.is_empty():
		set_state(State.TRANSITION)
		return

	_run_enemy_turns(enemies)


func _on_transition():
	await get_tree().create_timer(0.05).timeout
	if combat_just_ended:
		_clear_end_of_combat_effects()
		combat_just_ended = false

	CombatState.reset_party_turn()
	if State.PLAYER_INPUT != state:
		set_state(State.PLAYER_INPUT)

func _clear_end_of_combat_effects() -> void:
	for member in PartyState.active_party:
		member.clear_combat_buffs()
		member.clear_statuses_by_condition("end_of_combat")
		if member.has_method("clear_temporary_combat_statuses"):
			member.clear_temporary_combat_statuses()

	for enemy in World.get_enemies():
		if enemy.enemy_data.has_method("clear_statuses_by_condition"):
			enemy.enemy_data.clear_statuses_by_condition("end_of_combat")
		if enemy.enemy_data.has_method("clear_combat_buffs"):
			enemy.enemy_data.clear_combat_buffs()
		if enemy.enemy_data.has_method("clear_temporary_combat_statuses"):
			enemy.enemy_data.clear_temporary_combat_statuses()

	CombatState.clear_party_combat_statuses()

func _run_enemy_turns(enemies: Array):
	if enemies.is_empty():
		print("[TurnStateMachine] enemy list exhausted -> transition")
		set_state(State.TRANSITION)
		return

	var enemy = enemies.pop_front()
	print("[TurnStateMachine] next enemy:", enemy)

	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.enemy_data.hp <= 0:
		print("[TurnStateMachine] skipping invalid/dead enemy:", enemy)
		_run_enemy_turns(enemies)
		return

	if enemy.enemy_data.skips_turn_from_status():
		print("[TurnStateMachine] status-blocked enemy skips turn:", enemy.enemy_data.enemy_name)
		GameEvents.message_logged.emit("[color=yellow]" + enemy.enemy_data.enemy_name + " cannot act and skips their turn![/color]")
		await get_tree().create_timer(0.5).timeout
		_run_enemy_turns(enemies)
		return

	enemy.connect("turn_finished", func():
		print("[TurnStateMachine] received turn_finished from", enemy.enemy_data.enemy_name)
		_run_enemy_turns(enemies)
	, CONNECT_ONE_SHOT)

	print("[TurnStateMachine] calling take_turn on", enemy.enemy_data.enemy_name)
	enemy.take_turn()
