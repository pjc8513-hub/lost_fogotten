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
	set_state(State.ENEMY_TURN)

func _on_enemy_turn():
	var enemies = World.get_enemies()

	if enemies.is_empty():
		set_state(State.TRANSITION)
		return

	_run_enemy_turns(enemies)


func _on_transition():
	await get_tree().create_timer(0.05).timeout
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

	enemy.connect("turn_finished", func():
		_run_enemy_turns(enemies)
	, CONNECT_ONE_SHOT)

	enemy.take_turn()
