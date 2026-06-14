extends Node

signal selected_enemy_changed(enemy)
signal player_stepped(total_steps: int)

var total_steps_taken: int = 0
var active_world_effects: Dictionary = {}

var selected_enemy: Enemy = null
var selected_dungeon: Dungeon = null
var selected_exit: DungeonExit = null
var current_dungeon_data: DungeonData = null
var selected_trigger: Trigger = null
var player_ref
var map_data: Dictionary = {}   # Vector2i -> int (0 floor, 1 wall)
var enemies: Array = []         # Placeholder for future enemy nodes
var current_map_path: String = ""
var current_map_theme_path: String = ""
var current_map_spawn_id: String = ""
var map_discovered_tiles: Dictionary = {} # String (map_path) -> Dictionary (Vector2i -> bool)

var step_triggers: Array = []
var step_triggers_by_position: Dictionary = {}
var _last_step_event_position: Variant = null

# --- NPCs ---
var npcs: Array[NPC] = []
var selected_npc: NPC = null

# --- Treasure Chests ---
var treasure_chests: Array[TreasureChest] = []
var selected_chest: TreasureChest = null

var dungeons: Array[Dungeon] = []
var exits: Array[DungeonExit] = []
var doors: Array[DungeonDoor] = []
var doors_by_position: Dictionary = {}
var doors_by_id: Dictionary = {}
var doors_by_switch_id: Dictionary = {}

func set_map_data(data: Dictionary) -> void:
	map_data = data

func reset_world_state() -> void:
	enemies.clear()
	treasure_chests.clear()
	dungeons.clear()
	exits.clear()
	doors.clear()
	doors_by_position.clear()
	doors_by_id.clear()
	doors_by_switch_id.clear()
	step_triggers.clear()
	step_triggers_by_position.clear()
	_last_step_event_position = null
	selected_enemy = null
	selected_chest = null
	selected_dungeon = null
	selected_trigger = null
	selected_exit = null
	selected_npc = null
	active_world_effects.clear()

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

	if is_occupied_by_chest(pos):
		return false

	if is_occupied_by_dungeon(pos):
		return false

	if is_occupied_by_exit(pos):
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
	
func register_npc(npc: NPC):
	if not npcs.has(npc):
		npcs.append(npc)
	NPCManager.register_npc(npc)

func set_selected_npc(npc: NPC):
	selected_npc = npc
	selected_enemy = null
	selected_chest = null
	selected_trigger = null
	selected_exit = null
	CombatState.clear_target()
	selected_enemy_changed.emit(null)
	if npc:
		print("Selected NPC: ", npc.npc_data.npc_name)

func process_step_events() -> void:
	var player = get_player()
	if player == null or not is_instance_valid(player):
		return

	var player_position: Vector2i = player.grid_position
	if _last_step_event_position == player_position:
		return

	_last_step_event_position = player_position
	var trigger = get_step_trigger_at(player_position)
	if trigger != null and trigger.has_method("execute"):
		trigger.execute()

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

func register_step_trigger(trigger) -> void:
	if trigger == null or not is_instance_valid(trigger):
		return

	if not step_triggers.has(trigger):
		step_triggers.append(trigger)

	step_triggers_by_position[trigger.grid_position] = trigger

func unregister_step_trigger(trigger) -> void:
	if trigger == null:
		return

	step_triggers.erase(trigger)

	if step_triggers_by_position.get(trigger.grid_position) == trigger:
		step_triggers_by_position.erase(trigger.grid_position)

func get_step_trigger_at(pos: Vector2i):
	var trigger = step_triggers_by_position.get(pos, null)
	if trigger != null and is_instance_valid(trigger):
		return trigger

	if trigger != null:
		step_triggers_by_position.erase(pos)
	return null

func unlock_doors_for_switch(switch_id: String) -> void:
	if switch_id.is_empty() or not doors_by_switch_id.has(switch_id):
		return

	var switch_doors: Array = (doors_by_switch_id.get(switch_id, []) as Array).duplicate()
	for door in switch_doors:
		if door != null and is_instance_valid(door):
			door.unlock_and_open()

func has_line_of_sight(from_pos: Vector2i, to_pos: Vector2i) -> bool:
	if from_pos == to_pos:
		return _is_line_of_sight_tile_clear(from_pos)

	for check in _get_supercover_line(from_pos, to_pos):
		if check == from_pos:
			continue
		if not _is_line_of_sight_tile_clear(check):
			return false

	return true

func can_player_see_enemy(enemy: Enemy) -> bool:
	var player = get_player()
	if player == null or enemy == null or not is_instance_valid(enemy):
		return false
	return has_line_of_sight(player.grid_position, enemy.grid_position)

func _is_line_of_sight_tile_clear(pos: Vector2i) -> bool:
	if not map_data.has(pos):
		return false
	if map_data[pos] != 0:
		return false

	var door := get_door_at(pos)
	return door == null or door.is_open

func _get_supercover_line(from_pos: Vector2i, to_pos: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	points.append(from_pos)
	var current := from_pos
	var dx := to_pos.x - from_pos.x
	var dy := to_pos.y - from_pos.y
	var nx = abs(dx)
	var ny = abs(dy)
	var step_x := _sign_step(dx)
	var step_y := _sign_step(dy)
	var ix := 0
	var iy := 0

	while ix < nx or iy < ny:
		var decision = (1 + 2 * ix) * ny - (1 + 2 * iy) * nx
		if decision == 0:
			points.append(Vector2i(current.x + step_x, current.y))
			points.append(Vector2i(current.x, current.y + step_y))
			current = Vector2i(current.x + step_x, current.y + step_y)
			ix += 1
			iy += 1
		elif decision < 0:
			current = Vector2i(current.x + step_x, current.y)
			ix += 1
		else:
			current = Vector2i(current.x, current.y + step_y)
			iy += 1
		points.append(current)

	return points

func _sign_step(value: int) -> int:
	if value > 0:
		return 1
	if value < 0:
		return -1
	return 0

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
	selected_chest = null # deselect chest if enemy selected
	selected_trigger = null
	selected_dungeon = null
	selected_npc = null
	if enemy != null and is_instance_valid(enemy) and enemy.enemy_data.hp > 0:
		if can_player_see_enemy(enemy):
			selected_enemy = enemy
			CombatState.set_target(enemy)
		else:
			selected_enemy = null
			CombatState.clear_target()
			GameEvents.message_logged.emit("[color=gray]You can't get a clear view of %s.[/color]" % enemy.enemy_data.enemy_name)
	else:
		selected_enemy = null
		CombatState.clear_target()
	selected_enemy_changed.emit(selected_enemy)
	if selected_enemy:
		print("Selected enemy:", selected_enemy.enemy_data.enemy_name)

func is_occupied_by_chest(pos: Vector2i) -> bool:
	for c in treasure_chests:
		if c.grid_position == pos:
			return true
	return false

func is_occupied_by_dungeon(pos: Vector2i) -> bool:
	for d in dungeons:
		if d.grid_position == pos:
			return true
	return false

func is_occupied_by_exit(pos: Vector2i) -> bool:
	for e in exits:
		if e.grid_position == pos:
			return true
	return false

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
	selected_trigger = null
	selected_exit = null
	selected_npc = null
	CombatState.clear_target()
	selected_enemy_changed.emit(null)
	if chest:
		print("Selected chest: ", chest.treasure_data.chest_name)

func set_selected_trigger(trigger: Trigger):
	selected_trigger = trigger
	selected_enemy = null # deselect enemy if chest selected
	selected_chest = null
	selected_exit = null
	selected_npc = null
	CombatState.clear_target()
	selected_enemy_changed.emit(null)
	if trigger:
		print("Selected trigger: ", trigger.trigger_data.trigger_id)

func set_selected_exit(exit: DungeonExit):
	selected_exit = exit
	selected_trigger = null
	selected_chest = null
	selected_npc = null
	selected_enemy = null # deselect enemy if chest selected
	CombatState.clear_target()
	selected_enemy_changed.emit(null)
	if exit:
		print("Set selected dungeon: ", exit.dungeon_data.DungeonName)

func register_dungeon(dungeon: Dungeon):
	if not dungeons.has(dungeon):
		dungeons.append(dungeon)

func get_dungeons() -> Array[Dungeon]:
	return dungeons.duplicate()

func remove_dungeon(dungeon: Dungeon) -> void:
	dungeons.erase(dungeon)
	if selected_dungeon == dungeon:
		set_selected_dungeon(null)
	dungeon.queue_free()

func register_exit(exit: DungeonExit):
	if not exits.has(exit):
		exits.append(exit)

func get_exits() -> Array[DungeonExit]:
	return exits.duplicate()

func remove_exit(exit: DungeonExit) -> void:
	exits.erase(exit)
	exit.queue_free()

func set_selected_dungeon(dungeon: Dungeon):
	selected_dungeon = dungeon
	selected_enemy = null
	selected_trigger = null
	selected_npc = null
	CombatState.clear_target()
	selected_enemy_changed.emit(null)
	if dungeon:
		print("Selected dungeon: ", dungeon.dungeon_data.DungeonName)
	
func set_current_dungeon(dungeon_data: DungeonData) -> void:
	current_dungeon_data = dungeon_data

func set_current_map(map_path: String, spawn_id: String = "", theme_path: String = "") -> void:
	current_dungeon_data = null
	current_map_path = map_path
	current_map_spawn_id = spawn_id
	current_map_theme_path = theme_path

func get_discovered_tiles(map_path: String) -> Dictionary:
	if not map_discovered_tiles.has(map_path):
		map_discovered_tiles[map_path] = {}
	return map_discovered_tiles[map_path]

func add_discovered_tile(map_path: String, pos: Vector2i) -> void:
	if not map_discovered_tiles.has(map_path):
		map_discovered_tiles[map_path] = {}
	map_discovered_tiles[map_path][pos] = true

func get_player():
	return player_ref

func are_adjacent(a: Node3D, b: Node3D) -> bool:
	if not a or not b:
		return false
	var pos_a = world_to_grid(a.global_position)
	var pos_b = world_to_grid(b.global_position)
	var diff = (pos_a - pos_b).abs()
	return diff.x <= 1 and diff.y <= 1 and not (diff.x == 0 and diff.y == 0) # 8-directional, exclude same tile

func increment_step_count() -> void:
	total_steps_taken += 1
	_tick_world_effects()
	player_stepped.emit(total_steps_taken)

func set_world_effect(effect_id: String, duration_steps: int) -> void:
	var normalized := effect_id.strip_edges().to_lower()
	if normalized.is_empty():
		return
	active_world_effects[normalized] = max(0, duration_steps)

func has_world_effect(effect_id: String) -> bool:
	return active_world_effects.has(effect_id.strip_edges().to_lower())

func _tick_world_effects() -> void:
	for effect_id in active_world_effects.keys():
		var remaining := int(active_world_effects[effect_id])
		if remaining <= 0:
			continue
		remaining -= 1
		if remaining <= 0:
			active_world_effects.erase(effect_id)
			GameEvents.message_logged.emit("[color=gray]%s fades.[/color]" % String(effect_id).capitalize())
		else:
			active_world_effects[effect_id] = remaining
