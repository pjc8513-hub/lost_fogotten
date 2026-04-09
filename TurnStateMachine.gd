extends Node

enum State {
	PLAYER_INPUT,
	PLAYER_ACTION,
	WORLD_UPDATE,
	ENEMY_TURN,
	TRANSITION
}

var state: State = State.PLAYER_INPUT

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
	if CommandQueue.queue.is_empty():
		_player_action_complete()
	else:
		CommandQueue.connect("queue_empty", Callable(self, "_player_action_complete"), CONNECT_ONE_SHOT)


func _player_action_complete():
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
	set_state(State.PLAYER_INPUT)

func _run_enemy_turns(enemies: Array):
	if enemies.is_empty():
		set_state(State.TRANSITION)
		return

	var enemy = enemies.pop_front()

	enemy.connect("turn_finished", func():
		_run_enemy_turns(enemies)
	, CONNECT_ONE_SHOT)

	enemy.take_turn()
