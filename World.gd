extends Node

var selected_enemy: Enemy = null
var player_ref
var map_data: Dictionary = {}   # Vector2i -> int (0 floor, 1 wall)
var enemies: Array = []         # Placeholder for future enemy nodes

func set_map_data(data: Dictionary) -> void:
	map_data = data
	

func is_walkable(pos: Vector2i) -> bool:
	# First check if the tile exists in the map
	if not map_data.has(pos):
		return false

	# Check if the tile is a floor (0)
	if map_data[pos] != 0:
		return false

	# Check if an enemy occupies the tile
	if is_occupied_by_enemy(pos):
		return false

	return true


func register_enemy(enemy):
	enemies.append(enemy)

func get_enemies() -> Array:
	return enemies.duplicate()

func remove_enemy(enemy) -> void:
	enemies.erase(enemy)
	if CombatState.combatants.has(enemy):
		CombatState.combatants.erase(enemy)
	if CombatState.targeted_enemy == enemy:
		CombatState.clear_target()
	enemy.queue_free()

func process_step_events() -> void:
	# Placeholder for traps, pressure plates, etc.
	pass

func world_to_grid(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x), roundi(pos.z))

func register_player(p):
	player_ref = p

func has_line_of_sight(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	var dx = to_pos.x - from_pos.x
	var dy = to_pos.y - from_pos.y

	var steps = max(abs(dx), abs(dy))
	if steps == 0:
		return true

	var step_x = float(dx) / steps
	var step_y = float(dy) / steps

	var x = float(from_pos.x)
	var y = float(from_pos.y)

	for i in range(steps):
		x += step_x
		y += step_y
		var check = Vector2i(roundi(x), roundi(y))

		# Skip the starting tile
		if check == from_pos:
			continue

		# If we hit a wall, LOS is blocked
		if not is_walkable(check):
			return false

	return true

func can_see_player(enemy_pos: Vector2i, vision_range: int) -> bool:
	var player = get_player()
	if player == null:
		return false

	var dist = enemy_pos.distance_to(player.grid_position)
	if dist > vision_range:
		return false

	return has_line_of_sight(enemy_pos, player.grid_position)

func is_occupied_by_enemy(pos: Vector2i) -> bool:
	for e in enemies:
		if e.grid_position == pos:
			return true
	return false

func set_selected_enemy(enemy):
	selected_enemy = enemy
	print("Selected enemy:", enemy.enemy_data.enemy_name)

func get_player():
	return player_ref
