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
	combat_just_ended = was_in_combat and not CombatState.is_in_combat()
	if CombatState.is_in_combat():
		set_state(State.ENEMY_TURN)
	else:
		set_state(State.TRANSITION)

func _apply_poison_effects():
	for member in PartyState.active_party:
		if "poison" in member.status_effects and member.current_hp > 0:
			member.take_damage(10)
			GameEvents.message_logged.emit("[color=purple]" + member.member_name + " takes 10 poison damage![/color]")
			if member.current_hp <= 0:
				GameEvents.message_logged.emit("[color=red]" + member.member_name + " dies from poison![/color]")
				
	var enemies = World.get_enemies()
	for enemy in enemies:
		if "poison" in enemy.enemy_data.status_effects and enemy.enemy_data.hp > 0:
			enemy.enemy_data.hp -= 10
			GameEvents.enemy_took_damage.emit(enemy, 10)
			GameEvents.message_logged.emit("[color=purple]" + enemy.enemy_data.enemy_name + " takes 10 poison damage![/color]")
			if enemy.enemy_data.hp <= 0:
				GameEvents.message_logged.emit("[color=red]" + enemy.enemy_data.enemy_name + " dies from poison![/color]")
				World.remove_enemy(enemy)

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
		if "stun" in member.status_effects:
			member.status_effects.erase("stun")
			GameEvents.message_logged.emit("[color=gray]" + member.member_name + " recovers from stun.[/color]")

	for enemy in World.get_enemies():
		if "stun" in enemy.enemy_data.status_effects:
			enemy.enemy_data.status_effects.erase("stun")
		if enemy.enemy_data.has_method("clear_combat_buffs"):
			enemy.enemy_data.clear_combat_buffs()

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

	if "stun" in enemy.enemy_data.status_effects:
		print("[TurnStateMachine] stunned enemy skips turn:", enemy.enemy_data.enemy_name)
		GameEvents.message_logged.emit("[color=yellow]" + enemy.enemy_data.enemy_name + " is stunned and skips their turn![/color]")
		enemy.enemy_data.status_effects.erase("stun")
		await get_tree().create_timer(0.5).timeout
		_run_enemy_turns(enemies)
		return

	enemy.connect("turn_finished", func():
		print("[TurnStateMachine] received turn_finished from", enemy.enemy_data.enemy_name)
		_run_enemy_turns(enemies)
	, CONNECT_ONE_SHOT)

	print("[TurnStateMachine] calling take_turn on", enemy.enemy_data.enemy_name)
	enemy.take_turn()
