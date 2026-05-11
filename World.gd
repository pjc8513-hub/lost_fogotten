extends Node

signal selected_enemy_changed(enemy)

var selected_enemy: Enemy = null
var selected_dungeon: Dungeon = null
var current_dungeon_data: DungeonData = null
var player_ref
var map_data: Dictionary = {}   # Vector2i -> int (0 floor, 1 wall)
var enemies: Array = []         # Placeholder for future enemy nodes

# --- Treasure Chests ---
var treasure_chests: Array[TreasureChest] = []
var selected_chest: TreasureChest = null
var doors: Array[DungeonDoor] = []
var doors_by_position: Dictionary = {}
var doors_by_id: Dictionary = {}
var doors_by_switch_id: Dictionary = {}

func set_map_data(data: Dictionary) -> void:
	map_data = data

func reset_world_state() -> void:
	enemies.clear()
	treasure_chests.clear()
	doors.clear()
	doors_by_position.clear()
	doors_by_id.clear()
	doors_by_switch_id.clear()
	selected_enemy = null
	selected_chest = null
	selected_dungeon = null
	

func is_walkable(pos: Vector2i) -> bool:
	# First check if the tile exists in the map
	if not map_data.has(pos):
		return false

	# Check if the tile is a floor (0)
	if map_data[pos] != 0:
		return false

	var door := get_door_at(pos)
	if door != null and not door.is_open:
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
	if selected_enemy == enemy:
		set_selected_enemy(null)
	enemies.erase(enemy)
	CombatState.disengage_enemy(enemy)
	enemy.queue_free()

func process_step_events() -> void:
	# Placeholder for traps, pressure plates, etc.
	pass

func world_to_grid(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x), roundi(pos.z))

func register_player(p):
	player_ref = p

func register_door(door: DungeonDoor) -> void:
	if door == null or not is_instance_valid(door):
		return

	if not doors.has(door):
		doors.append(door)

	doors_by_position[door.grid_position] = door
	print("World.register_door:", door.grid_position, " locked=", door.is_locked, " id=", door.door_data.DoorID if door.door_data != null else "")

	if door.door_data != null:
		if not door.door_data.DoorID.is_empty():
			doors_by_id[door.door_data.DoorID] = door

		if not door.door_data.switchID.is_empty():
			if not doors_by_switch_id.has(door.door_data.switchID):
				doors_by_switch_id[door.door_data.switchID] = []
			var switch_doors: Array = doors_by_switch_id[door.door_data.switchID]
			if not switch_doors.has(door):
				switch_doors.append(door)

func unregister_door(door: DungeonDoor) -> void:
	if door == null:
		return

	doors.erase(door)

	if doors_by_position.get(door.grid_position) == door:
		doors_by_position.erase(door.grid_position)

	if door.door_data != null:
		if not door.door_data.DoorID.is_empty() and doors_by_id.get(door.door_data.DoorID) == door:
			doors_by_id.erase(door.door_data.DoorID)

		if not door.door_data.switchID.is_empty() and doors_by_switch_id.has(door.door_data.switchID):
			var switch_doors: Array = doors_by_switch_id[door.door_data.switchID]
			switch_doors.erase(door)
			if switch_doors.is_empty():
				doors_by_switch_id.erase(door.door_data.switchID)

func get_door_at(pos: Vector2i) -> DungeonDoor:
	var door = doors_by_position.get(pos, null)
	if door != null and is_instance_valid(door):
		return door

	if door != null:
		doors_by_position.erase(pos)
	return null

func get_door_by_id(door_id: String) -> DungeonDoor:
	var door = doors_by_id.get(door_id, null)
	if door != null and is_instance_valid(door):
		return door

	if door != null:
		doors_by_id.erase(door_id)
	return null

func unlock_doors_for_switch(switch_id: String) -> void:
	if switch_id.is_empty() or not doors_by_switch_id.has(switch_id):
		return

	var switch_doors: Array = (doors_by_switch_id.get(switch_id, []) as Array).duplicate()
	for door in switch_doors:
		if door != null and is_instance_valid(door):
			door.unlock_and_open()

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

		# Allow the destination tile to be occupied by an enemy and only care about walls.
		if check == to_pos:
			return map_data.has(check) and map_data[check] == 0

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
	selected_chest = null # deselect chest if enemy selected
	if enemy != null and is_instance_valid(enemy) and enemy.enemy_data.hp > 0:
		CombatState.set_target(enemy)
	else:
		selected_enemy = null
		CombatState.clear_target()
	selected_enemy_changed.emit(selected_enemy)
	if selected_enemy:
		print("Selected enemy:", selected_enemy.enemy_data.enemy_name)

# === TREASURE CHEST MANAGEMENT ===
func register_treasure_chest(chest: TreasureChest):
	if not treasure_chests.has(chest):
		treasure_chests.append(chest)

func get_treasure_chests() -> Array[TreasureChest]:
	return treasure_chests.duplicate()

func remove_treasure_chest(chest: TreasureChest) -> void:
	treasure_chests.erase(chest)
	if selected_chest == chest:
		selected_chest = null
	chest.queue_free()

func set_selected_chest(chest: TreasureChest):
	selected_chest = chest
	selected_enemy = null # deselect enemy if chest selected
	CombatState.clear_target()
	selected_enemy_changed.emit(null)
	if chest:
		print("Selected chest:", chest.treasure_data.chest_name)

func set_selected_dungeon(dungeon: Dungeon):
	selected_dungeon = dungeon
	selected_enemy = null
	CombatState.clear_target()
	selected_enemy_changed.emit(null)
	if dungeon:
		print("Selected dungeon: ", dungeon.dungeon_data.DungeonName)
	
func set_current_dungeon(dungeon_data: DungeonData) -> void:
	current_dungeon_data = dungeon_data

func get_player():
	return player_ref

func are_adjacent(a: Node3D, b: Node3D) -> bool:
	if not a or not b:
		return false
	var pos_a = world_to_grid(a.global_position)
	var pos_b = world_to_grid(b.global_position)
	var diff = (pos_a - pos_b).abs()
	return diff.x <= 1 and diff.y <= 1 and not (diff.x == 0 and diff.y == 0) # 8-directional, exclude same tile
