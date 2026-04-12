extends Node3D
class_name Player

signal player_moved(grid_pos: Vector2i)
signal movement_done

var grid_position: Vector2i
var forward_vector: Vector2i = Vector2i(0, -1)   # Facing north

func _ready():
	World.register_player(self)
	grid_position = Vector2i(roundi(global_position.x), roundi(global_position.z))

	var automap = get_node("/root/Main/SubViewportContainer/SubViewport/CanvasLayer/AutoMap")
	player_moved.connect(automap.on_player_moved)

	emit_signal("player_moved", grid_position)

func move_to(target: Vector2i):
	#print('moving')
	grid_position = target
	global_position.x = target.x
	global_position.z = target.y

	emit_signal("player_moved", grid_position)
	emit_signal("movement_done")

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
		_queue_player_attack()


func rotate_left():
	forward_vector = Vector2i(forward_vector.y, -forward_vector.x)
	rotation.y += deg_to_rad(90)

func rotate_right():
	forward_vector = Vector2i(-forward_vector.y, forward_vector.x)
	rotation.y -= deg_to_rad(90)


func _queue_player_attack():
	if not CombatState.has_valid_target():
		print("No valid target selected")
		return

	var cmd := PlayerAttackCommand.new()
	cmd.actor = CombatState.get_acting_member()  # ClassData
	CommandQueue.add_command(cmd)

	TurnStateMachine.last_action_was_party_wide = false
	TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)
