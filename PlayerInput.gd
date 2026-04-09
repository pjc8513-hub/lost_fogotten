#PlayerInput.gd

extends Node

func _unhandled_input(event):
	if TurnStateMachine.state != TurnStateMachine.State.PLAYER_INPUT:
		return

	var player = get_node("/root/Main/SubViewportContainer/SubViewport/Player")   # adjust path if needed

	if event.is_action_pressed("ui_up"):
		#print('w')
		var cmd = MoveForwardCommand.new()
		cmd.actor = player
		CommandQueue.add_command(cmd)
		TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_left"):
		var cmd = TurnLeftCommand.new()
		cmd.actor = player
		CommandQueue.add_command(cmd)
		TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_right"):
		var cmd = TurnRightCommand.new()
		cmd.actor = player
		CommandQueue.add_command(cmd)
		TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)
		get_viewport().set_input_as_handled()
