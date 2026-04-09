extends Node3D

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

func rotate_left():
	forward_vector = Vector2i(forward_vector.y, -forward_vector.x)
	rotation.y += deg_to_rad(90)

func rotate_right():
	forward_vector = Vector2i(-forward_vector.y, forward_vector.x)
	rotation.y -= deg_to_rad(90)
