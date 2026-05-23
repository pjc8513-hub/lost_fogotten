extends Node3D
class_name Player

signal player_moved(grid_pos: Vector2i)
signal player_rotated(forward_vector: Vector2i)
signal movement_done

var grid_position: Vector2i
var forward_vector: Vector2i = Vector2i(0, -1)   # Facing north

func _ready():
	World.register_player(self)
	grid_position = Vector2i(roundi(global_position.x), roundi(global_position.z))

	var automap = get_node("/root/Main/automap")
	if automap:
		player_moved.connect(automap.on_player_moved)
		player_rotated.connect(automap.update_compass)

	emit_signal("player_moved", grid_position)
	emit_signal("player_rotated", forward_vector)
	

func move_to(target: Vector2i):
	#print('moving')
	grid_position = target
	global_position.x = target.x
	global_position.z = target.y

	emit_signal("player_moved", grid_position)
	emit_signal("movement_done")

func apply_spawn(spawn_grid_position: Vector2i, spawn_data: PlayerSpawnData = null) -> void:
	grid_position = spawn_grid_position
	global_position.x = spawn_grid_position.x
	global_position.z = spawn_grid_position.y

	if spawn_data != null:
		_apply_facing_rotation(spawn_data.rotation)

	emit_signal("player_moved", grid_position)

func _apply_facing_rotation(rotation_degrees_y: int) -> void:
	var normalized_rotation := posmod(rotation_degrees_y, 360)
	rotation_degrees.y = normalized_rotation

	match normalized_rotation:
		0:
			forward_vector = Vector2i(0, -1)
		90:
			forward_vector = Vector2i(-1, 0)
		180:
			forward_vector = Vector2i(0, 1)
		270:
			forward_vector = Vector2i(1, 0)
		_:
			forward_vector = Vector2i(
				roundi(-sin(deg_to_rad(normalized_rotation))),
				roundi(-cos(deg_to_rad(normalized_rotation)))
			)
	emit_signal("player_rotated", forward_vector)

func _unhandled_input(event):
	if TurnStateMachine.state != TurnStateMachine.State.PLAYER_INPUT:
		return

	var acting_member = CombatState.current_actor
	if acting_member == null:
		return
	
	# Only handle input if the acting member is actually the player/party
	if not acting_member is ClassData:
		return  # it's an enemy turn, ignore input
		
	if event.is_action_pressed("attack"):
		_queue_context_action()
		get_viewport().set_input_as_handled()
		
func _queue_context_action():
	var actor: ClassData = CombatState.get_acting_member()
	
	# Priority order: Chest > Trigger > Enemy > Dungeon > NPC > nothing
	# Only one thing can be selected at a time thanks to World.set_selected_*()
	print("selected: ", World.selected_exit)
	if World.selected_chest and not World.selected_chest.is_opened:
		_queue_open_chest(actor)
	elif World.selected_trigger:
		_queue_toggle_lever(actor)
	elif World.selected_enemy and is_instance_valid(World.selected_enemy) and World.selected_enemy.enemy_data.hp > 0:
		CombatState.set_target(World.selected_enemy)
		_queue_player_attack(actor)
	elif World.selected_npc:
		_queue_talk_to_npc(actor)
	elif World.selected_dungeon and is_instance_valid(World.selected_dungeon):
		_enter_selected_dungeon()
	elif World.selected_exit and is_instance_valid(World.selected_exit):
		_exit_dungeon()
	else:
		World.set_selected_enemy(null)
		GameEvents.message_logged.emit("[color=gray]Nothing to interact with.[/color]")


func rotate_left():
	forward_vector = Vector2i(forward_vector.y, -forward_vector.x)
	rotation.y += deg_to_rad(90)
	emit_signal("player_rotated", forward_vector)

func rotate_right():
	forward_vector = Vector2i(-forward_vector.y, forward_vector.x)
	rotation.y -= deg_to_rad(90)
	emit_signal("player_rotated", forward_vector)



func _queue_player_attack(actor: ClassData):
	if not CombatState.has_valid_target():
		print("No valid target selected")
		GameEvents.message_logged.emit("[color=gray]No valid target.[/color]")
		return

	var cmd := PlayerAttackCommand.new()
	cmd.actor = actor
	CommandQueue.add_command(cmd)
	_start_player_action()

func _queue_open_chest(actor: ClassData):
	var cmd := PlayerOpenChestCommand.new()
	cmd.actor = actor
	CommandQueue.add_command(cmd)
	_start_player_action()
	
func _queue_toggle_lever(actor: ClassData):
	print("lever toggled")
	var cmd := PlayerToggleTriggerCommand.new()
	cmd.actor = actor
	CommandQueue.add_command(cmd)
	_start_player_action()

func _queue_talk_to_npc(actor: ClassData):
	var cmd := PlayerTalkCommand.new()
	cmd.actor = actor
	cmd.target_npc = World.selected_npc
	CommandQueue.add_command(cmd)
	_start_player_action()
	

func _start_player_action():
	TurnStateMachine.last_action_was_party_wide = false
	TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)

func _enter_selected_dungeon() -> void:
	var dungeon := World.selected_dungeon
	
	if dungeon == null or not is_instance_valid(dungeon) or dungeon.dungeon_data == null:
		GameEvents.message_logged.emit("[color=gray]There is no dungeon entrance here.[/color]")
		return

	if not World.are_adjacent(self, dungeon):
		GameEvents.message_logged.emit("[color=gray]You need to move closer to enter %s.[/color]" % dungeon.dungeon_data.DungeonName)
		return

	if dungeon.dungeon_data.PasswordRequired:
		DialogueManager.show_password_prompt(
			dungeon.dungeon_data.RequiredPassword,
			func(): _perform_enter_dungeon(dungeon),  # success callback
			func(): GameEvents.message_logged.emit("[color=red]Incorrect password.[/color]")  # fail callback
		)
	else:
		var prompt = "Enter %s?" % dungeon.dungeon_data.DungeonName
		DialogueManager.show_confirmation(prompt, func():
			_perform_enter_dungeon(dungeon)
		)

func _perform_enter_dungeon(dungeon: Node) -> void:
	World.set_current_dungeon(dungeon.dungeon_data)
	SceneManager.change_scene("res://Main.tscn")
	
func _exit_dungeon() -> void:
	var exit := World.selected_exit
	
	if exit == null or not is_instance_valid(exit) or exit.dungeon_data == null:
		GameEvents.message_logged.emit("[color=gray]There is no dungeon entrance here.[/color]")
		return

	if not World.are_adjacent(self, exit):
		GameEvents.message_logged.emit("[color=gray]You need to move closer to enter %s.[/color]" % exit.dungeon_data.DungeonName)
		return

	World.set_current_dungeon(exit.dungeon_data)
	SceneManager.change_scene("res://Main.tscn")
