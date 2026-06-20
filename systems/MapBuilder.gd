# res://systems/MapBuilder.gd
class_name MapBuilder

# Returns a Dictionary with { automap_grid: Dictionary }
static func build(data: Dictionary, geometry_parent: Node, entity_parent: Node,
				theme: MapTheme, 
				on_enemy_selected: Callable = Callable(), 
				on_chest_selected: Callable = Callable(),
				on_dungeon_selected: Callable = Callable(),
				spawn_id: String = "") -> Dictionary:
	var automap_grid := {}
	
	_build_geometry(data, geometry_parent, automap_grid, theme)
	_spawn_entities(data, entity_parent, automap_grid, on_enemy_selected, on_chest_selected, on_dungeon_selected, spawn_id)
	_spawn_lights(data, entity_parent, theme)
	return { "automap_grid": automap_grid }

static func load_room_data(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		print("File not found: ", file_path)
		return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		return json.data
	else:
		print("JSON Parse Error: ", json.get_error_message())
		return {}

static func _build_geometry(data: Dictionary, parent: Node, automap_grid: Dictionary, theme: MapTheme) -> void:
	var wall_scene: PackedScene = load("res://data/maps/locations/swamp/MossyWall.tscn")
	var floor_scene: PackedScene = load("res://data/maps/locations/swamp/SwampSouth/FloorMarsh.tscn")
	var floor_materials = [
		load("res://assets/textures/MossWall_Mat.tres"),
		load("res://assets/textures/MossyWall_Mat2.tres"),
		load("res://assets/textures/MossyPit.tres")
	]
	
	var wall_counter := 0 
	var cell_types := {}
	for cell in data.get("cells", []):
		var pos_data = cell.get("pos", [])
		if pos_data is String:
			pos_data = JSON.parse_string(pos_data)
		var atlas_data = cell.get("atlas", [])
		if atlas_data is String:
			atlas_data = JSON.parse_string(atlas_data)
			
		if pos_data is Array and atlas_data is Array and pos_data.size() >= 2 and atlas_data.size() >= 2:
			var pos = Vector2i(int(pos_data[0]), int(pos_data[1]))
			var atlas_x = int(atlas_data[0])
			var atlas_y = int(atlas_data[1])
			if atlas_x == 0 and atlas_y == 0:
				cell_types[pos] = "wall"
			else:
				cell_types[pos] = "floor"
				
	for cell in data.get("cells", []):
		var pos_data = cell.get("pos", [])
		if pos_data is String:
			pos_data = JSON.parse_string(pos_data)
		
		var atlas_data = cell.get("atlas", [])
		if atlas_data is String:
			atlas_data = JSON.parse_string(atlas_data)
		
		if not (pos_data is Array and atlas_data is Array and pos_data.size() >= 2 and atlas_data.size() >= 2):
			push_error("Malformed cell in map data: " + str(cell))
			continue
		
		var pos = Vector2i(int(pos_data[0]), int(pos_data[1]))
		var atlas_x = int(atlas_data[0])
		var atlas_y = int(atlas_data[1])
		
		if atlas_x == 0 and atlas_y == 0:
			automap_grid[pos] = 1
			var wall = theme.wall_scene.instantiate()
			parent.add_child(wall)
			
			wall.position = Vector3(pos.x, 0, pos.y)
			# random wall materials if the array exists
			if theme.wall_materials.size() > 0:
				wall.get_node("Cube").material_override = theme.wall_materials.pick_random()
				wall.position += Vector3(randf_range(-0.05, 0.05), 0, randf_range(-0.05, 0.05))
			
			var east_is_floor = cell_types.get(pos + Vector2i(1, 0), "wall") == "floor"
			var west_is_floor = cell_types.get(pos + Vector2i(0, -1), "wall") == "floor"
			var test_is_floor = cell_types.get(pos + Vector2i(-1, 0), "wall") == "floor"
			if east_is_floor and not west_is_floor:
				wall.rotation_degrees.y = 90
			elif test_is_floor and not west_is_floor:
				wall.rotation_degrees.y = 90

			wall_counter += 1
			if wall_counter % 3 == 0:
				wall.rotation_degrees.y += 180

			#for random variations in cave walls and outdoor
			if theme.random_wall_variation == true:
				var scale_variation = randf_range(0.95, 1.05)
				wall.scale = Vector3(scale_variation, 1, scale_variation)
		else:
			automap_grid[pos] = 0
			var floor = theme.floor_scene.instantiate()
			parent.add_child(floor)
			if theme.floor_materials.size() > 0:
				floor.get_node("StaticBody3D/CSGBakedMeshInstance3D").material_override = theme.floor_materials.pick_random()
			floor.position = Vector3(pos.x, -0.5, pos.y)
			
			if theme.random_floor_variation == true:
				floor.rotation_degrees.y = [0, 90, 180, 270].pick_random()

			if theme.has_ceiling and theme.ceiling_scene:
				var ceiling = theme.ceiling_scene.instantiate()
				parent.add_child(ceiling)
				if theme.ceiling_materials.size() > 0:
					var ceiling_mesh = ceiling.get_node_or_null("StaticBody3D/CSGBakedMeshInstance3D")
					if ceiling_mesh:
						ceiling_mesh.material_override = theme.ceiling_materials.pick_random()
				
				# Place ceiling above the floor (adjust the Y value if your walls are a different height)
				ceiling.position = Vector3(pos.x, 2.0, pos.y)
				
				if theme.random_ceiling_variation:
					ceiling.rotation_degrees.y = [0, 90, 180, 270].pick_random()

static func _spawn_entities(data: Dictionary, parent: Node, automap_grid: Dictionary,
							on_enemy_selected: Callable, on_chest_selected: Callable,
							on_dungeon_selected: Callable,
							spawn_id: String = "") -> void:
	var player_spawn_was_set := false
	var fallback_spawn_position := Vector2i.ZERO
	var fallback_spawn_data_path := ""
	var has_fallback_spawn := false

	for ent in data.get("entities", []):
		var ent_pos_data = ent.get("pos", [])
		if ent_pos_data is String:
			ent_pos_data = JSON.parse_string(ent_pos_data)
		
		if not (ent_pos_data is Array and ent_pos_data.size() >= 2):
			push_error("Malformed entity in map data: " + str(ent))
			continue
		
		var pos = Vector2i(int(ent_pos_data[0]), int(ent_pos_data[1]))
		var type = ent["type"]
		
		match type:
			"enemy":
				_spawn_enemy(pos, ent["data_resource"], ent["aggro_group"], parent, on_enemy_selected)
			"chest":
				_spawn_chest(pos, ent["data_resource"], parent, on_chest_selected)
			# ...
			"player":
				if not has_fallback_spawn:
					fallback_spawn_position = pos
					fallback_spawn_data_path = ent.get("data_resource", "")
					has_fallback_spawn = true
				if spawn_id.is_empty() and player_spawn_was_set:
					automap_grid[pos] = 0
					continue
				if _set_player_start(pos, ent.get("data_resource", ""), parent, automap_grid, spawn_id):
					player_spawn_was_set = true
			"decoration":
				_spawn_decor(pos, parent)
			"fencing":
				# ent["data_resource"] will point to your "swamp_fencing.tres"
				_spawn_fencing(pos, ent["data_resource"], parent)
			"dungeon":
				_spawn_dungeon(pos, ent["data_resource"], parent, on_dungeon_selected)
			"door":
				_spawn_door(pos, ent["data_resource"], parent)
			"trigger":
				_spawn_trigger(pos, ent["data_resource"], parent)
			"briar_trap":
				# Extract both resource paths from the exporter's JSON format
				var fence_path = ent.get("fencing_resource", "")
				var trigger_path = ent.get("trigger_resource", "")
				
				# 1. Spawn the visual wrapper using your existing fencing code
				if not fence_path.is_empty():
					_spawn_fencing(pos, fence_path, parent)
				
				# 2. Spawn the custom mechanical trigger data
				if not trigger_path.is_empty():
					_spawn_briar_trigger(pos, trigger_path, parent)
			"exit":
				_spawn_exit(pos, ent["data_resource"], parent)
			"NPC":
				_spawn_NPC(pos, ent["data_resource"], parent)

	if not player_spawn_was_set and has_fallback_spawn:
		if not spawn_id.is_empty():
			push_warning("Player spawn '%s' was not found. Using the first player spawn in the map." % spawn_id)
		_set_player_start(fallback_spawn_position, fallback_spawn_data_path, parent, automap_grid)

static func _spawn_enemy(grid_pos: Vector2i, data_path: String, aggro_id: int, 
						 parent: Node, on_enemy_selected: Callable) -> void:
	var res = load(data_path) as EnemyData
	var enemy_scene_resource = load(res.scene_path)
	var enemy = enemy_scene_resource.instantiate()
	parent.add_child(enemy)
	
	enemy.grid_position = grid_pos
	enemy.position = Vector3(grid_pos.x, 0, grid_pos.y)
	
	if FileAccess.file_exists(data_path):
		enemy.enemy_data = res.duplicate()
	
	if aggro_id > 0:
		enemy.add_to_group("aggro_" + str(aggro_id))
	
	if not on_enemy_selected.is_null():
		enemy.connect("selected", on_enemy_selected)
	# Note: _on_enemy_selected callback needs to be connected
	# We emit a signal so Main can handle this, or pass a callable
	# See note below about the selected signal

static func _spawn_trigger (grid_pos: Vector2i, data_path: String,
						parent: Node) -> void:
	var res = load(data_path) as TriggerData
	var trigger_scene_resource = load(res.scene_path)
	var trigger = trigger_scene_resource.instantiate()
	trigger.grid_position = grid_pos
	if FileAccess.file_exists(data_path):
		trigger.trigger_data = res.duplicate()
	trigger.position = Vector3(grid_pos.x, 0, grid_pos.y)
	parent.add_child(trigger)
	
static func _spawn_briar_trigger(grid_pos: Vector2i, data_path: String, parent: Node) -> void:
	if not FileAccess.file_exists(data_path):
		push_error("Briar trigger resource data file not found: " + data_path)
		return

	# Load the specialized TriggerData resource (e.g., PoisonBriar, HeavyDamageBriar)
	var res = load(data_path) as TriggerData 
	if res == null:
		push_error("Failed to load TriggerData resource at: " + data_path)
		return

	# Instantiate the hidden step-checker tile
	var bump_tile_scene = load(res.scene_path)
	var bump_tile = bump_tile_scene.instantiate()
	
	bump_tile.grid_position = grid_pos 
	bump_tile.position = Vector3(grid_pos.x, 0, grid_pos.y) 
	
	# Duplicate the resource so runtime modifications don't bleed into your save files
	bump_tile.trigger_data = res.duplicate() 
	
	parent.add_child(bump_tile)

static func _spawn_NPC (grid_pos: Vector2i, data_path: String,
						parent: Node) -> void:
	var res = load(data_path) as NPCData
	var NPC_scene_resource = load(res.scene_path)
	var NPC = NPC_scene_resource.instantiate()
	NPC.grid_position = grid_pos
	if FileAccess.file_exists(data_path):
		NPC.npc_data = res.duplicate()
	NPC.position = Vector3(grid_pos.x, 0, grid_pos.y)
	if res.rotation != null and res.rotation !=0:
		NPC.rotation_degrees.y = res.rotation
	parent.add_child(NPC)

static func _spawn_exit(grid_pos: Vector2i, data_path: String,
						parent: Node) -> void:
	var res = load(data_path) as DungeonData
	var exit_scene_resource = load(res.scene_path)
	var exit = exit_scene_resource.instantiate()
	if "grid_position" in exit:
		exit.grid_position = grid_pos
	if FileAccess.file_exists(data_path):
		if "dungeon_data" in exit:
			exit.dungeon_data = res.duplicate()
	exit.position = Vector3(grid_pos.x, 0, grid_pos.y)
	if res.rotation != null and res.rotation !=0:
		exit.rotation_degrees.y = res.rotation
	parent.add_child(exit)
	

static func _spawn_door(grid_pos: Vector2i, data_path: String,
						parent: Node) -> void:
	var res = load(data_path) as DoorData
	var door_scene_resource = load(res.scene_path)
	var door = door_scene_resource.instantiate()
	door.grid_position = grid_pos
	if FileAccess.file_exists(data_path):
		door.door_data = res.duplicate()
		door.is_locked = door.door_data.is_locked
	door.position = Vector3(grid_pos.x, -0.5, grid_pos.y)
	door.rotation_degrees.y = res.rotation
	parent.add_child(door)

static func _spawn_chest(grid_pos: Vector2i, data_path: String, 
						 parent: Node, on_chest_selected: Callable) -> void:
	var res = load(data_path) as TreasureData
	var chest_scene_resource = load(res.scene_path)
	var chest = chest_scene_resource.instantiate()
	parent.add_child(chest)
	
	chest.grid_position = grid_pos
	chest.position = Vector3(grid_pos.x, -0.5, grid_pos.y)
	
	if FileAccess.file_exists(data_path):
		chest.treasure_data = res.duplicate()
	
	if not on_chest_selected.is_null():
		chest.connect("selected", on_chest_selected)

static func _spawn_fencing(grid_pos: Vector2i, data_path: String, parent: Node) -> void:
	if data_path.is_empty() or not FileAccess.file_exists(data_path):
		push_error("Fencing data file not found: " + data_path)
		return
		
	var res = load(data_path)
	if not res or not ("fence_variants" in res) or res.fence_variants.size() == 0:
		push_error("Fencing data resource is missing 'fence_variants' or it is empty.")
		return

	# Define the 4 sides of the tile: [Offset Direction, Rotation Angle]
	# Assuming 1 unit = 1 tile size based on your wall.position setup
	var sides = [
		{"offset": Vector3(0, 0, -0.49), "rotation": 0},    # North (Pull back slightly from 0.5 to prevent wall clipping)
		{"offset": Vector3(0.49, 0, 0),  "rotation": 90},   # East
		{"offset": Vector3(0, 0, 0.49),  "rotation": 180},  # South
		{"offset": Vector3(-0.49, 0, 0), "rotation": 270}   # West
	]

	for side in sides:
		# Pick a random swamp flower/reed PackedScene from your .tres array
		var flower_scene: PackedScene = res.fence_variants.pick_random()
		if not flower_scene:
			continue
			
		var flower = flower_scene.instantiate()
		parent.add_child(flower)
		
		# Position the flower at the tile center, then push it to the specific edge
		# We add a microscopic random offset so they don't look perfectly robotic
		var organic_fuzz = Vector3(randf_range(-0.04, 0.04), 0, randf_range(-0.04, 0.04))
		flower.position = Vector3(grid_pos.x, 0, grid_pos.y) + side["offset"] + organic_fuzz
		
		# Rotate it to align with the tile edge
		flower.rotation_degrees.y = side["rotation"]

static func _set_player_start(grid_pos: Vector2i, data_path: String, parent: Node, automap_grid: Dictionary, spawn_id: String = "") -> bool:
	var spawn_data: PlayerSpawnData = null
	if not data_path.is_empty() and FileAccess.file_exists(data_path):
		spawn_data = load(data_path) as PlayerSpawnData

	if not _should_use_player_spawn(spawn_data, spawn_id):
		automap_grid[grid_pos] = 0
		return false

	# Player lives in the SubViewport already as a scene child
	# We need to find it relative to parent
	var player = parent.get_node_or_null("Player")
	if player:
		if player.has_method("apply_spawn"):
			player.apply_spawn(grid_pos, spawn_data)
		else:
			player.position = Vector3(grid_pos.x, 0, grid_pos.y)
			if "grid_position" in player:
				player.grid_position = grid_pos
		automap_grid[grid_pos] = 0
		return true

	return false

static func _should_use_player_spawn(spawn_data: PlayerSpawnData, requested_spawn_id: String) -> bool:
	if requested_spawn_id.is_empty():
		return true

	if spawn_data == null:
		return false

	return spawn_data.SpawnID == requested_spawn_id

static func _spawn_decor(pos: Vector2i, parent: Node) -> void:
	var decor_scene: PackedScene = load("res://data/maps/locations/swamp/MarshTree.tscn")
	var decor = decor_scene.instantiate()
	parent.add_child(decor)
	decor.position = Vector3(pos.x, 0, pos.y)

static func _spawn_dungeon(grid_pos: Vector2i, data_path: String, 
						 parent: Node, on_dungeon_selected: Callable) -> void:
	var res = load(data_path) as DungeonData
	
	var dungeon_scene_resource = load(res.scene_path)
	print("dungeon  res: ", res, " dungeon scene: ", dungeon_scene_resource)
	var dungeon = dungeon_scene_resource.instantiate()
	parent.add_child(dungeon)
	
	dungeon.grid_position = grid_pos
	dungeon.position = Vector3(grid_pos.x, -0.5, grid_pos.y)
	
	if FileAccess.file_exists(data_path):
		dungeon.dungeon_data = res.duplicate()
	
	if not on_dungeon_selected.is_null():
		dungeon.connect("selected", on_dungeon_selected)

static func _spawn_lights(data: Dictionary, parent: Node, theme: MapTheme) -> void:
	for entry in data.get("lights", []):
		var pos_data = entry.get("pos", [])
		if pos_data is String:
			pos_data = JSON.parse_string(pos_data)
		if not (pos_data is Array and pos_data.size() >= 2):
			push_error("Malformed light entry: " + str(entry))
			continue

		var pos     = Vector2i(int(pos_data[0]), int(pos_data[1]))
		var ltype   = entry.get("light_type", "")
		var dpath   = entry.get("data_resource", "")

		match ltype:
			"brazier":
				_spawn_brazier(pos, dpath, parent, theme)
			"black_out":
				_spawn_blackout(pos, parent)
			"black_out_trigger":
				_spawn_blackout_trigger(pos, dpath, parent)
			"light_restore":
				_spawn_light_restore_trigger(pos, dpath, parent)
			_:
				push_warning("Unknown light_type: " + ltype)


static func _spawn_brazier(grid_pos: Vector2i, data_path: String,
							parent: Node, theme: MapTheme) -> void:
	if data_path.is_empty() or not FileAccess.file_exists(data_path):
		push_error("BrazierData not found: " + data_path)
		return

	var res = load(data_path) as BrazierData
	if res == null:
		push_error("Failed to cast BrazierData at: " + data_path)
		return

	var brazier = load(res.scene_path).instantiate()
	brazier.grid_position = grid_pos
	brazier.position      = Vector3(grid_pos.x, 0, grid_pos.y)
	brazier.brazier_data  = res.duplicate()
	# Pass theme so the brazier can fall back to theme defaults if its own
	# data fields are left blank (matches your omni_light_3d.gd pattern)
	if brazier.has_method("configure"):
		brazier.configure(theme)
	parent.add_child(brazier)

static func _spawn_blackout(pos: Vector2i, parent: Node) -> void:
	var blackout_scene: PackedScene = load("res://black_out.tscn")
	var blackout = blackout_scene.instantiate()
	blackout.grid_position = pos
	blackout.position = Vector3(pos.x, 0, pos.y)
	parent.add_child(blackout)

static func _spawn_blackout_trigger(grid_pos: Vector2i, data_path: String,
									 parent: Node) -> void:
	if data_path.is_empty() or not FileAccess.file_exists(data_path):
		push_error("BlackoutTriggerData not found: " + data_path)
		return

	var res = load(data_path) as TriggerData
	var trigger = load(res.scene_path).instantiate()
	trigger.grid_position = grid_pos
	trigger.position      = Vector3(grid_pos.x, 0, grid_pos.y)
	trigger.trigger_data  = res.duplicate()
	parent.add_child(trigger)


static func _spawn_light_restore_trigger(grid_pos: Vector2i, data_path: String,
										  parent: Node) -> void:
	# Identical shape to blackout — kept separate so they get distinct
	# TriggerData scene_paths and execute() logic without a shared type
	if data_path.is_empty() or not FileAccess.file_exists(data_path):
		push_error("LightRestoreData not found: " + data_path)
		return

	var res = load(data_path) as TriggerData
	var trigger = load(res.scene_path).instantiate()
	trigger.grid_position = grid_pos
	trigger.position      = Vector3(grid_pos.x, 0, grid_pos.y)
	trigger.trigger_data  = res.duplicate()
	parent.add_child(trigger)
