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
	if last_action_was_party_wide:
		set_state(State.WORLD_UPDATE)
	else:
		if CombatState.advance_party_member():
			set_state(State.PLAYER_INPUT)
		else:
			set_state(State.WORLD_UPDATE)

func _on_world_update():
	World.process_step_events()
	_apply_poison_effects()
	set_state(State.ENEMY_TURN)

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
			GameEvents.message_logged.emit("[color=purple]" + enemy.enemy_data.enemy_name + " takes 10 poison damage![/color]")
			if enemy.enemy_data.hp <= 0:
				GameEvents.message_logged.emit("[color=red]" + enemy.enemy_data.enemy_name + " dies from poison![/color]")
				World.remove_enemy(enemy)

func _on_enemy_turn():
	var enemies = World.get_enemies()

	if enemies.is_empty():
		set_state(State.TRANSITION)
		return

	_run_enemy_turns(enemies)


func _on_transition():
	await get_tree().create_timer(0.05).timeout
	if World.get_enemies().is_empty():
		for member in PartyState.active_party:
			if "stun" in member.status_effects:
				member.status_effects.erase("stun")
				GameEvents.message_logged.emit("[color=gray]" + member.member_name + " recovers from stun.[/color]")
		CombatState.reset_party_turn()
		if State.PLAYER_INPUT != state:
			set_state(State.PLAYER_INPUT)
	else:
		CombatState.reset_party_turn()
		set_state(State.PLAYER_INPUT)

func _run_enemy_turns(enemies: Array):
	if enemies.is_empty():
		set_state(State.TRANSITION)
		return

	var enemy = enemies.pop_front()

	if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.enemy_data.hp <= 0:
		_run_enemy_turns(enemies)
		return

	if "stun" in enemy.enemy_data.status_effects:
		GameEvents.message_logged.emit("[color=yellow]" + enemy.enemy_data.enemy_name + " is stunned and skips their turn![/color]")
		enemy.enemy_data.status_effects.erase("stun")
		await get_tree().create_timer(0.5).timeout
		_run_enemy_turns(enemies)
		return

	enemy.connect("turn_finished", func():
		_run_enemy_turns(enemies)
	, CONNECT_ONE_SHOT)

	enemy.take_turn()
