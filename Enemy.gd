extends Node3D
class_name Enemy

@onready var sprite: Sprite3D = $Sprite3D

signal turn_finished
signal movement_done
signal selected(enemy)

@export var enemy_data: EnemyData:
	set(value):
		enemy_data = value
		if is_inside_tree() and sprite:
			_apply_enemy_data()

var grid_position: Vector2i
var forward_vector: Vector2i = Vector2i(0, 1) # default facing south
var _pending_commands: int = 0



func _ready():
	print("My viewport: ", get_viewport())
	print("Camera: ", get_viewport().get_camera_3d())
	print("Owner viewport: ", get_tree().root)
	print("Current camera: ", get_viewport().get_camera_3d())
	print("Connected signals for Area3D:", $Area3D.get_signal_connection_list("input_event"))
	
	await get_tree().process_frame  # wait one frame for player to finish _ready
	print("My viewport: ", get_viewport())
	print("Camera: ", get_viewport().get_camera_3d())

	$Area3D.input_ray_pickable = true  # should be true by default, but force it
	print("Area3D pickable: ", $Area3D.input_ray_pickable)
	#print(self, " global_position at ready: ", global_position)
	#enemy.grid_position = spawn_pos
	#enemy.global_position = Vector3(spawn_pos.x, 0, spawn_pos.y)
	#grid_position = World.world_to_grid(global_position)
	add_to_group("enemies")
	
	if enemy_data and sprite:
		_apply_enemy_data()
		
	World.register_enemy(self)


func _apply_enemy_data() -> void:
	if not enemy_data:
		print("ERROR: _apply_enemy_data called without valid enemy_data.")
		return
	if not sprite:
		push_error("Sprite3D node not found for enemy! Cannot apply data.")
		return
	# Assign sprite texture
	# var sprite = $Sprite3D
	#print(enemy_data)
	#print('sprite texture: ', enemy_data.sprite_texture)
	if enemy_data and enemy_data.sprite_texture:
		sprite.texture = enemy_data.sprite_texture
	else:
		print("WARNING: Enemy has no sprite texture assigned")
		
	if enemy_data and enemy_data.custom_scale:
		sprite.scale = enemy_data.custom_scale
		print(enemy_data.enemy_name, " final custom scale applied: ", sprite.scale)
	else:
		print("No custom scale in tres")
	
	if enemy_data and enemy_data.custom_position:
		sprite.position = enemy_data.custom_position
		print(enemy_data.enemy_name, " final custom position applied: ", sprite.position)

func move_to(target: Vector2i):
	grid_position = target
	global_position = Vector3(target.x, global_position.y, target.y)
	emit_signal("movement_done")

func take_turn():
	# Placeholder AI — enemy does nothing for now
	#print(enemy_data.enemy_name, " takes its turn (placeholder)")
	#emit_signal("turn_finished")
	match enemy_data.get_ai_enum():
		EnemyData.AIBehavior.HUNTER:
			_take_turn_hunter()
		EnemyData.AIBehavior.RANDOM:
			_take_turn_random()
		EnemyData.AIBehavior.GUARD:
			_take_turn_guard()
		_:
			_take_turn_random()


func _take_turn_hunter():
	var player = World.get_player()
	if player == null:
		emit_signal("turn_finished")
		return
	
	# Attack if adjacent
	if _is_adjacent_to_player():
		_queue_attack()
		return
	
	# Only chase if player is visible
	if not World.can_see_player(grid_position, enemy_data.vision_range):
		# fallback to random wandering
		_take_turn_random()
		return

	var dx = player.grid_position.x - grid_position.x
	var dy = player.grid_position.y - grid_position.y

	# Determine primary direction
	var primary_dir: Vector2i
	var secondary_dir: Vector2i

	if abs(dx) > abs(dy):
		primary_dir = Vector2i(sign(dx), 0)
		secondary_dir = Vector2i(0, sign(dy))
	else:
		primary_dir = Vector2i(0, sign(dy))
		secondary_dir = Vector2i(sign(dx), 0)

	# Try primary direction
	if _try_move_direction(primary_dir):
		return

	# Try secondary direction
	if _try_move_direction(secondary_dir):
		return

	# If both blocked, fallback to random
	_take_turn_random()

	
func _take_turn_guard():
	print('Guard took turn (placeholder!)')
	emit_signal("turn_finished")
	
func _take_turn_random():
	# Attack if adjacent
	if _is_adjacent_to_player():
		_queue_attack()
		return
		
	var dirs = [
		Vector2i(0, -1),  # north
		Vector2i(1, 0),   # east
		Vector2i(0, 1),   # south
		Vector2i(-1, 0)   # west
	]

	var valid_dirs = []

	for dir in dirs:
		var target = grid_position + dir
		if World.is_walkable(target):
			valid_dirs.append(dir)

	if valid_dirs.is_empty():
		emit_signal("turn_finished")
		return

	var target_dir = valid_dirs[randi() % valid_dirs.size()]
	forward_vector = target_dir  # ← critical fix
	#print('target direction: ', target_dir)
	_queue_move_forward()
	
func rotate_left():
	forward_vector = Vector2i(forward_vector.y, -forward_vector.x)
	rotation.y += deg_to_rad(90)

func rotate_right():
	forward_vector = Vector2i(-forward_vector.y, forward_vector.x)
	rotation.y -= deg_to_rad(90)

func _queue_turn_toward(target_dir: Vector2i):
	# Determine left or right turn
	var left = Vector2i(forward_vector.y, -forward_vector.x)
	var right = Vector2i(-forward_vector.y, forward_vector.x)

	if target_dir == left:
		_pending_commands += 1
		var cmd = TurnLeftCommand.new()
		cmd.actor = self
		cmd.connect("finished", _on_own_command_finished, CONNECT_ONE_SHOT)
		CommandQueue.add_command(cmd)
	elif target_dir == right:
		_pending_commands += 1
		var cmd = TurnRightCommand.new()
		cmd.actor = self
		cmd.connect("finished", _on_own_command_finished, CONNECT_ONE_SHOT)
		CommandQueue.add_command(cmd)
	else:
		_pending_commands += 2
		# 180-degree turn: two left turns
		var cmd1 = TurnLeftCommand.new()
		cmd1.actor = self
		cmd1.connect("finished", _on_own_command_finished, CONNECT_ONE_SHOT)
		CommandQueue.add_command(cmd1)

		var cmd2 = TurnLeftCommand.new()
		cmd2.actor = self
		CommandQueue.connect("queue_empty", Callable(self, "_on_turn_complete"), CONNECT_ONE_SHOT)
		cmd2.connect("finished", _on_own_command_finished, CONNECT_ONE_SHOT)
		CommandQueue.add_command(cmd2)

func _on_own_command_finished():
	_pending_commands -= 1
	if _pending_commands < 0:
		print("WARNING: _pending_commands underflow on ", enemy_data.enemy_name)
		_pending_commands = 0
	if _pending_commands <= 0:
		_pending_commands = 0
		_on_turn_complete()

func _queue_move_forward():
	_pending_commands += 1
	var cmd = MoveForwardCommand.new()
	cmd.actor = self
	cmd.connect("finished", _on_own_command_finished, CONNECT_ONE_SHOT)
	CommandQueue.add_command(cmd)

func _try_move_direction(dir: Vector2i) -> bool:
	if dir == Vector2i(0, 0):
		return false

	# If not facing the direction, rotate first
	if forward_vector != dir:
		_queue_turn_toward(dir)
		return true

	# Try to move forward
	var target = grid_position + dir
	if World.is_walkable(target):
		_queue_move_forward()
		return true

	return false

func _is_adjacent_to_player() -> bool:
	var player = World.get_player()
	if player == null:
		return false

	return grid_position.distance_to(player.grid_position) == 1

func _queue_attack():
	_pending_commands += 1
	var cmd = AttackCommand.new()
	cmd.actor = self
	cmd.connect("finished", _on_own_command_finished, CONNECT_ONE_SHOT)
	CommandQueue.add_command(cmd)
	
func _on_turn_complete():
	#print("_on_turn_complete called on: ", enemy_data.enemy_name)
	#print("Enemy finished turn:", self)
	emit_signal("turn_finished")

func get_accuracy() -> int:
	return enemy_data.get_accuracy() if enemy_data else 0


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Enemy clicked:", enemy_data.enemy_name)
		World.set_selected_enemy(self)
		emit_signal("selected", self)
		
