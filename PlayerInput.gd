#PlayerInput.gd

extends Node

const MELEE_RANGE: int = 1

func _unhandled_input(event):
	if TurnStateMachine.state != TurnStateMachine.State.PLAYER_INPUT:
		return

	var player = get_node("/root/Main/SubViewportContainer/SubViewport/Player")   # adjust path if needed

	if event.is_action_pressed("ui_up"):
		#print('w')
		var cmd = MoveForwardCommand.new()
		cmd.actor = player
		CommandQueue.add_command(cmd)
		TurnStateMachine.last_action_was_party_wide = true
		TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_left"):
		var cmd = TurnLeftCommand.new()
		cmd.actor = player
		CommandQueue.add_command(cmd)
		TurnStateMachine.last_action_was_party_wide = true
		TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_right"):
		var cmd = TurnRightCommand.new()
		cmd.actor = player
		CommandQueue.add_command(cmd)
		TurnStateMachine.last_action_was_party_wide = true
		TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)
		get_viewport().set_input_as_handled()


func handle_entity_clicked(entity: Node3D) -> void:
	# Only process clicks during player input phase
	if TurnStateMachine.state != TurnStateMachine.State.PLAYER_INPUT:
		return

	if entity.is_in_group("enemies"):
		_on_enemy_clicked(entity as Enemy)
	elif entity.is_in_group("npcs"):
		_on_npc_clicked(entity)
	# Other entity types: silently ignore

func _on_enemy_clicked(enemy: Enemy) -> void:
	CombatState.set_target(enemy)

	# Queue the attack and hand off to the turn state machine
	var cmd := PlayerAttackCommand.new()
	cmd.actor = CombatState.get_acting_member()  # ClassData of acting party member
	CommandQueue.add_command(cmd)

	TurnStateMachine.last_action_was_party_wide = false
	TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)

func _on_npc_clicked(_npc: Node3D) -> void:
	# Placeholder — proximity check + dialog will go here
	pass
