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
	if event.is_action_pressed("attack"):
		_attempt_attack()


func rotate_left():
	forward_vector = Vector2i(forward_vector.y, -forward_vector.x)
	rotation.y += deg_to_rad(90)

func rotate_right():
	forward_vector = Vector2i(-forward_vector.y, forward_vector.x)
	rotation.y -= deg_to_rad(90)

func _queue_melee_attack(target):
	var cmd = MeleeAttackCommand.new()
	cmd.actor = self
	cmd.target = target
	CommandQueue.add_command(cmd)

func _queue_ranged_attack(target):
	# For now: auto-miss if no ranged weapon
	if not has_ranged_weapon():
		print("You have no ranged weapon. Auto-miss!")
		return

	var cmd = RangedAttackCommand.new()
	cmd.actor = self
	cmd.target = target
	CommandQueue.add_command(cmd)

func has_ranged_weapon() -> bool:
	return false  # until you add inventory

func _attempt_attack():
	var target = World.selected_enemy
	if target == null:
		print("No enemy selected")
		return

	var dist = grid_position.distance_to(target.grid_position)

	if dist == 1:
		_queue_melee_attack(target)
	else:
		_queue_ranged_attack(target)
