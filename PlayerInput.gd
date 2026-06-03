#PlayerInput.gd

extends Node

const MELEE_RANGE: int = 1

func _unhandled_input(event):
	if TurnStateMachine.state != TurnStateMachine.State.PLAYER_INPUT:
		return

	var player = get_node("/root/Main/SubViewportContainer/SubViewport/Player")   # adjust path if needed

	if event.is_action_pressed("ui_up"):
		_queue_player_move(player)
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_left"):
		_queue_player_turn(player, TurnLeftCommand.new())
		get_viewport().set_input_as_handled()

	if event.is_action_pressed("ui_right"):
		_queue_player_turn(player, TurnRightCommand.new())
		get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("toggle_torch"):
		# Assuming your player reference has access to the torch node
		if player and player.has_node("TorchLight"):
			player.get_node("TorchLight").toggle_torch()
			get_viewport().set_input_as_handled()
		else:
			push_error("Player or torchlight node not found")

	if event.is_action_pressed("restart"):
		SceneManager.change_scene("res://Main.tscn")

	# DEBUG/CHEAT: Toggle god mode for testing
	# Pressing the god_mode button will:
	# - Toggle invulnerability for all party members
	# - Revive any dead party members
	# - Level up all party members by 1
	# This is for testing purposes only and should be removed before release
	if event.is_action_pressed("god_mode"):
		_toggle_god_mode()
		get_viewport().set_input_as_handled()


	if event.is_action_pressed("select_member_1"):
		_try_select_party_member(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_member_2"):
		_try_select_party_member(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_member_3"):
		_try_select_party_member(2)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_member_4"):
		_try_select_party_member(3)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("select_member_5"):
		_try_select_party_member(4)
		get_viewport().set_input_as_handled()



func _queue_player_turn(player, cmd) -> void:
	if CommandQueue.is_busy():
		return

	cmd.actor = player
	CommandQueue.add_command(cmd)

	# Turning in place should not advance or reset combat.
	if CombatState.is_in_combat():
		return

	TurnStateMachine.last_action_was_party_wide = true
	TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)

func _queue_player_move(player) -> void:
	if CommandQueue.is_busy():
		return

	var cmd = MoveForwardCommand.new()
	cmd.actor = player
	CommandQueue.add_command(cmd)

	if CombatState.is_in_combat():
		TurnStateMachine.last_action_was_party_wide = false
	else:
		TurnStateMachine.last_action_was_party_wide = true

	TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)

func _try_select_party_member(index: int) -> void:
	print("input")
	if PartyState.select_member(index):
		return

	if CombatState.is_in_combat():
		var acting_member := CombatState.get_acting_member()
		if acting_member != null:
			GameEvents.message_logged.emit("[color=gray]You cannot change characters during combat. It is %s's turn.[/color]" % acting_member.member_name)
		else:
			GameEvents.message_logged.emit("[color=gray]You cannot change characters during combat.[/color]")

# DEBUG/CHEAT: God mode toggle
# TO REMOVE: Delete this entire function and the god_mode check in _unhandled_input when done testing
func _toggle_god_mode() -> void:
	PartyState.god_mode_active = not PartyState.god_mode_active
	
	if PartyState.god_mode_active:
		# Activating god mode: revive and level up all members
		for member in PartyState.active_party:
			if member == null:
				continue
			
			# Revive dead members
			if member.current_hp <= 0:
				member.current_hp = member.get_max_hp()
				member.current_mp = member.get_max_mp()
			
			# Level up by 1
			member.gain_level()
		
		GameEvents.message_logged.emit("[color=gold]GOD MODE ACTIVATED[/color] - All party members revived and leveled up!")
	else:
		GameEvents.message_logged.emit("[color=gray]God mode deactivated[/color]")
