extends Node3D
class_name Enemy

@onready var sprite: Sprite3D = $Sprite3D

signal turn_finished
signal movement_done
signal selected(enemy)
signal attack_animation_completed

@export var enemy_data: EnemyData:
	set(value):
		enemy_data = value
		if enemy_data != null:
			max_hp = enemy_data.hp
		if is_inside_tree() and sprite:
			_apply_enemy_data()

var max_hp: int = 0
var grid_position: Vector2i
var forward_vector: Vector2i = Vector2i(0, 1) # default facing south
var _pending_commands: int = 0
var movement_remaining: int = 0
var damage_flash_tween: Tween = null
var _skill_cooldowns: Dictionary = {}
var _is_selected_enemy: bool = false
var _selection_anim_time: float = 0.0
var _selection_anim_blend: float = 0.0
var _selection_rest_offset: Vector2 = Vector2.ZERO
var _selection_rest_rotation_z: float = 0.0
const EnemySkillCommandScript = preload("res://commands/EnemySkillCommand.gd")
const SELECTION_ANIM_SPEED: float = 4.5
const SELECTION_ANIM_OFFSET_PIXELS: float = 5.0
const SELECTION_ANIM_TILT_DEGREES: float = 3.5
const SELECTION_ANIM_BLEND_SPEED: float = 6.0



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
		
	_capture_selection_rest_pose()
	World.selected_enemy_changed.connect(_on_selected_enemy_changed)
	set_process(false)
	if World.selected_enemy == self:
		_on_selected_enemy_changed(self)
		
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

	_capture_selection_rest_pose()

func _process(delta: float) -> void:
	if sprite == null:
		set_process(false)
		return

	var target_blend := 1.0 if _is_selected_enemy else 0.0
	_selection_anim_blend = move_toward(_selection_anim_blend, target_blend, delta * SELECTION_ANIM_BLEND_SPEED)
	_selection_anim_time += delta * SELECTION_ANIM_SPEED

	var sway := sin(_selection_anim_time)
	var offset_x := sway * SELECTION_ANIM_OFFSET_PIXELS * _selection_anim_blend
	var tilt := deg_to_rad(SELECTION_ANIM_TILT_DEGREES) * sway * _selection_anim_blend
	sprite.offset = _selection_rest_offset + Vector2(offset_x, 0.0)
	sprite.rotation.z = _selection_rest_rotation_z + tilt

	if not _is_selected_enemy and is_zero_approx(_selection_anim_blend):
		sprite.offset = _selection_rest_offset
		sprite.rotation.z = _selection_rest_rotation_z
		set_process(false)

func _capture_selection_rest_pose() -> void:
	if sprite == null:
		return
	_selection_rest_offset = sprite.offset
	_selection_rest_rotation_z = sprite.rotation.z

func _on_selected_enemy_changed(enemy) -> void:
	var was_selected := _is_selected_enemy
	_is_selected_enemy = enemy == self
	if _is_selected_enemy and not was_selected:
		_capture_selection_rest_pose()
	set_process(true)

func _queue_command(cmd) -> void:
	_pending_commands += 1
	cmd.actor = self
	print("[Enemy]", enemy_data.enemy_name, "_queue_command ->", cmd, " pending=", _pending_commands)
	cmd.connect("finished", _on_own_command_finished, CONNECT_ONE_SHOT)
	CommandQueue.add_command(cmd)


func move_to(target: Vector2i):
	grid_position = target
	global_position = Vector3(target.x, global_position.y, target.y)
	GameEvents.emit_signal("movement_animation_started", self, target)
	emit_signal("movement_done")

func take_turn():
	movement_remaining = max(0, enemy_data.movement)
	_tick_skill_cooldowns()
	print("[Enemy]", enemy_data.enemy_name, "take_turn movement=", movement_remaining, " ai=", enemy_data.get_ai_enum())
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


func _take_turn_hunter() -> void:
	var player = World.get_player()
	if player == null:
		emit_signal("turn_finished")
		return

	if _try_skill_with_remaining_movement():
		return

	# Try melee attack if adjacent
	if _try_attack_with_remaining_movement():
		return

	# Try ranged attack if in range
	if _try_ranged_attack_with_remaining_movement():
		return

	if not World.can_see_player(grid_position, enemy_data.vision_range):
		_take_turn_random()
		return

	while movement_remaining > 0:
		# Check for attacks after each movement
		if _try_skill_with_remaining_movement():
			return
		if _try_attack_with_remaining_movement():
			return
		if _try_ranged_attack_with_remaining_movement():
			return

		var dirs = _get_hunter_dirs(player.grid_position)
		if _move_in_direction(dirs[0]):
			continue
		if _move_in_direction(dirs[1]):
			continue
		break

	# Final attempt at attack after movement
	if _try_skill_with_remaining_movement():
		return
	if _try_attack_with_remaining_movement():
		return
	if _try_ranged_attack_with_remaining_movement():
		return

	emit_signal("turn_finished")

	
func _take_turn_guard():
	if _try_skill_with_remaining_movement():
		return
	if _try_attack_with_remaining_movement():
		return
	if _try_ranged_attack_with_remaining_movement():
		return
	print('Guard took turn without acting.')
	emit_signal("turn_finished")
	
func _take_turn_random() -> void:
	while movement_remaining > 0:
		# Try attacks before moving
		if _try_skill_with_remaining_movement():
			return
		if _try_attack_with_remaining_movement():
			return
		if _try_ranged_attack_with_remaining_movement():
			return

		var dirs = [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
		var valid_dirs: Array = dirs.filter(func(d): return World.is_walkable(grid_position + d))

		if valid_dirs.is_empty():
			break

		var chosen: Vector2i = valid_dirs[randi() % valid_dirs.size()]
		if not _move_in_direction(chosen):
			break

	# Final attack attempt after movement
	if _try_skill_with_remaining_movement():
		return
	if _try_attack_with_remaining_movement():
		return
	if _try_ranged_attack_with_remaining_movement():
		return

	emit_signal("turn_finished")
	
func rotate_left():
	forward_vector = Vector2i(forward_vector.y, -forward_vector.x)
	rotation.y += deg_to_rad(90)

func rotate_right():
	forward_vector = Vector2i(-forward_vector.y, forward_vector.x)
	rotation.y -= deg_to_rad(90)

func _queue_turn_toward(target_dir: Vector2i) -> void:
	var left  = Vector2i( forward_vector.y, -forward_vector.x)
	var right = Vector2i(-forward_vector.y,  forward_vector.x)

	if target_dir == forward_vector:
		return  # already facing — caller shouldn't reach here, but safe guard

	if target_dir == left:
		_queue_command(TurnLeftCommand.new())
	elif target_dir == right:
		_queue_command(TurnRightCommand.new())
	else:
		# 180 — two turns, both tracked by _pending_commands
		_queue_command(TurnLeftCommand.new())
		_queue_command(TurnLeftCommand.new())

func _on_own_command_finished() -> void:
	_pending_commands -= 1
	if _pending_commands < 0:
		push_warning("_pending_commands underflow: " + enemy_data.enemy_name)
		_pending_commands = 0
	if _pending_commands == 0:
		_on_turn_complete()

func _queue_move_forward() -> void:
	_queue_command(MoveForwardCommand.new())

func _try_move_direction(dir: Vector2i) -> bool:
	if dir == Vector2i.ZERO:
		return false

	var target = grid_position + dir

	if forward_vector != dir:
		# Rotate toward the desired direction first.
		_queue_turn_toward(dir)
		# After rotating we'd be facing dir — check walkability now.
		# If the tile is blocked we still consumed the turn rotating.
		if World.is_walkable(target):
			_queue_move_forward()
		# Either way we queued something, so the turn is handled.
		return true

	# Already facing dir.
	if World.is_walkable(target):
		_queue_move_forward()
		return true

	return false  # facing the right way but wall — caller tries next option

func _move_in_direction(dir: Vector2i) -> bool:
	if movement_remaining <= 0 or dir == Vector2i.ZERO:
		return false

	var target = grid_position + dir
	if not World.is_walkable(target):
		return false

	_face_direction(dir)
	move_to(target)
	movement_remaining -= 1
	return true

func _face_direction(target_dir: Vector2i) -> void:
	while forward_vector != target_dir:
		var left  = Vector2i(forward_vector.y, -forward_vector.x)
		var right = Vector2i(-forward_vector.y, forward_vector.x)

		if target_dir == left:
			rotate_left()
		elif target_dir == right:
			rotate_right()
		else:
			rotate_left()

func _try_attack_with_remaining_movement() -> bool:
	if movement_remaining <= 0 or not _is_adjacent_to_player():
		print("[Enemy]", enemy_data.enemy_name, "_try_attack_with_remaining_movement -> false movement=", movement_remaining, " adjacent=", _is_adjacent_to_player())
		return false

	movement_remaining -= 1
	print("[Enemy]", enemy_data.enemy_name, "_try_attack_with_remaining_movement -> queue attack, movement now=", movement_remaining)
	_queue_attack()
	return true

func _get_hunter_dirs(player_pos: Vector2i) -> Array[Vector2i]:
	var dx = player_pos.x - grid_position.x
	var dy = player_pos.y - grid_position.y

	var primary_dir := Vector2i.ZERO
	var secondary_dir := Vector2i.ZERO

	if abs(dx) > abs(dy):
		primary_dir = Vector2i(sign(dx), 0)
		secondary_dir = Vector2i(0, sign(dy))
	else:
		primary_dir = Vector2i(0, sign(dy))
		secondary_dir = Vector2i(sign(dx), 0)

	return [primary_dir, secondary_dir]


func _is_adjacent_to_player() -> bool:
	var player = World.get_player()
	if player == null:
		return false

	# 8-directional adjacency
	var diff = (grid_position - player.grid_position).abs()
	return diff.x <= 1 and diff.y <= 1 and not (diff.x == 0 and diff.y == 0) and World.has_line_of_sight(grid_position, player.grid_position)

func _queue_attack() -> void:
	print("[Enemy]", enemy_data.enemy_name, "_queue_attack")
	_queue_command(AttackCommand.new())

func _get_distance_to_player() -> float:
	var player = World.get_player()
	if player == null:
		return 999.0
	
	# Chebyshev distance (max of absolute differences) for 8-directional movement
	var grid_diff = (grid_position - player.grid_position).abs()
	return float(max(grid_diff.x, grid_diff.y))

func _is_within_ranged_distance() -> bool:
	if not enemy_data.is_ranged:
		return false
	
	var distance = _get_distance_to_player()
	var player = World.get_player()
	if player == null:
		return false
	return distance <= enemy_data.ranged_tiles and distance > 1 and World.has_line_of_sight(grid_position, player.grid_position)

func _try_ranged_attack_with_remaining_movement() -> bool:
	if movement_remaining <= 0 or not _is_within_ranged_distance():
		return false

	movement_remaining -= 1
	print("[Enemy]", enemy_data.enemy_name, "_try_ranged_attack_with_remaining_movement -> queue ranged attack, movement now=", movement_remaining)
	_queue_ranged_attack()
	return true

func _queue_ranged_attack() -> void:
	print("[Enemy]", enemy_data.enemy_name, "_queue_ranged_attack")
	_queue_command(RangedAttackCommand.new())

func _try_skill_with_remaining_movement() -> bool:
	var skill: Resource = _choose_available_skill()
	if skill == null:
		return false
	if movement_remaining < max(0, skill.consumes_movement):
		return false

	movement_remaining -= max(0, skill.consumes_movement)
	print("[Enemy]", enemy_data.enemy_name, "_try_skill_with_remaining_movement -> queue skill ", skill.get_log_name(), " movement now=", movement_remaining)
	_queue_skill(skill)
	return true

func _choose_available_skill() -> Resource:
	if enemy_data == null or enemy_data.skills.is_empty():
		return null

	var usable: Array[Resource] = []
	for skill in enemy_data.skills:
		if _can_use_skill(skill):
			usable.append(skill)

	if usable.is_empty():
		return null

	usable.sort_custom(func(a: Resource, b: Resource): return int(a.priority) > int(b.priority))
	var highest_priority: int = int(usable[0].priority)
	var choices: Array[Resource] = usable.filter(func(skill: Resource): return int(skill.priority) == highest_priority)
	return choices.pick_random()

func _can_use_skill(skill: Resource) -> bool:
	if skill == null:
		return false
	var key: String = _get_skill_key(skill)
	if int(_skill_cooldowns.get(key, 0)) > 0:
		return false
	if movement_remaining < max(0, skill.consumes_movement):
		return false
	if skill.use_chance < 100 and randi_range(1, 100) > skill.use_chance:
		return false
	if not _skill_has_valid_target(skill):
		return false
	return true

func _skill_has_valid_target(skill: Resource) -> bool:
	match skill.target_mode:
		0:
			if skill.has_healing() and enemy_data.hp >= max_hp:
				return false
			return enemy_data.hp > 0
		1, 2:
			return _has_living_party_target_in_skill_range(skill)
		3, 4:
			return not CombatState.get_engaged_enemies().is_empty()
	return false

func _has_living_party_target_in_skill_range(skill: Resource) -> bool:
	var player = World.get_player()
	if player == null:
		return false
	for member in PartyState.active_party:
		if member == null or member.current_hp <= 0:
			continue
		if not _is_player_position_in_skill_range(skill, player.grid_position):
			continue
		return true
	return false

func _is_player_position_in_skill_range(skill: Resource, player_pos: Vector2i) -> bool:
	var diff = (grid_position - player_pos).abs()
	var distance: int = max(diff.x, diff.y)
	if distance > max(1, skill.range_tiles):
		return false
	if skill.requires_line_of_sight and not World.has_line_of_sight(grid_position, player_pos):
		return false
	return true

func _queue_skill(skill: Resource) -> void:
	var cmd: Command = EnemySkillCommandScript.new()
	cmd.skill = skill
	_queue_command(cmd)

func set_skill_cooldown(skill: Resource, turns: int) -> void:
	if skill == null or turns <= 0:
		return
	_skill_cooldowns[_get_skill_key(skill)] = turns

func _tick_skill_cooldowns() -> void:
	for key in _skill_cooldowns.keys():
		var remaining: int = int(_skill_cooldowns[key]) - 1
		if remaining <= 0:
			_skill_cooldowns.erase(key)
		else:
			_skill_cooldowns[key] = remaining

func _get_skill_key(skill: Resource) -> String:
	if not skill.skill_id.strip_edges().is_empty():
		return skill.skill_id
	return skill.resource_path
	
func _on_turn_complete() -> void:
	print("[Enemy]", enemy_data.enemy_name, "_on_turn_complete emit turn_finished")
	emit_signal("turn_finished")

func get_accuracy() -> int:
	return enemy_data.get_accuracy() if enemy_data else 0


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		print("Enemy clicked:", enemy_data.enemy_name)
		World.set_selected_enemy(self)
		if World.selected_enemy == self:
			var msg := "[color=gray]Targeted %s.[/color]" % enemy_data.enemy_name
			GameEvents.message_logged.emit(msg)
			emit_signal("selected", self)
		
# Animations
func animate_move_to(target: Vector2i, duration: float = 0.25):
	var target_pos = Vector3(target.x, global_position.y, target.y)
	var start_pos = global_position
	
	# Face movement direction
	if target_pos != start_pos:
		look_at(target_pos, Vector3.UP)
	
	var tween = create_tween()
	tween.set_parallel(true) # Run multiple tweens at once
	
	# 1. Main movement with easing
	tween.tween_property(self, "global_position", target_pos, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT) # Fast start, slow stop feels natural
	
	# 2. Add a subtle vertical bob for footsteps
	var mid_point = start_pos.lerp(target_pos, 0.5)
	mid_point.y += 0.1 # hop height
	tween.tween_property(self, "global_position:y", mid_point.y, duration * 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "global_position:y", target_pos.y, duration * 0.5)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
	
	await tween.finished
	grid_position = target
	GameEvents.emit_signal("movement_animation_finished", self)

func animate_take_damage(damage: int):
	if sprite == null:
		return
	if damage_flash_tween:
		damage_flash_tween.kill()
	sprite.modulate = Color(2.2, 0.5, 0.5, 1.0)
	damage_flash_tween = create_tween()
	damage_flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.18)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

func animate_death():
	GameEvents.emit_signal("character_died_animation_started", self)
	var tween = create_tween()
	tween.tween_property($Sprite3D, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()
	
func play_attack_animation():
	#print("[Enemy]", enemy_data.enemy_name, "play_attack_animation")
	var anim_player = get_node_or_null("Sprite3D/AnimationPlayer")
	
	if anim_player and anim_player is AnimationPlayer:
		#print("[Enemy]", enemy_data.enemy_name, "AnimationPlayer found. current=", anim_player.current_animation, " is_playing=", anim_player.is_playing())
		if anim_player.has_animation("attack"):
			print("[Enemy]", enemy_data.enemy_name, "playing attack animation")
			anim_player.play("attack")
		else:
			print("[Enemy] Warning: Animation 'attack' not found on ", name)
			call_deferred("_emit_attack_animation_completed")
	else:
		print("[Enemy] No AnimationPlayer found on ", name)
		call_deferred("_emit_attack_animation_completed")
		

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	#print("[Enemy]", enemy_data.enemy_name, "_on_animation_player_animation_finished:", anim_name)
	if anim_name == &"attack":
		#print("[Enemy]", enemy_data.enemy_name, "emit attack_animation_completed")
		attack_animation_completed.emit()

func _emit_attack_animation_completed() -> void:
	print("[Enemy]", enemy_data.enemy_name, "deferred emit attack_animation_completed")
	attack_animation_completed.emit()
