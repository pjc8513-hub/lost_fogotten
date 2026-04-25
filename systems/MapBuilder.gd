# res://systems/MapBuilder.gd
class_name MapBuilder

# Returns a Dictionary with { automap_grid: Dictionary }
static func build(data: Dictionary, geometry_parent: Node, entity_parent: Node, 
				on_enemy_selected: Callable = Callable(), 
				on_chest_selected: Callable = Callable()) -> Dictionary:
	var automap_grid := {}
	
	_build_geometry(data, geometry_parent, automap_grid)
	_spawn_entities(data, entity_parent, automap_grid, on_enemy_selected, on_chest_selected)
	
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

static func _build_geometry(data: Dictionary, parent: Node, automap_grid: Dictionary) -> void:
	var wall_scene: PackedScene = load("res://MossyWall.tscn")
	var floor_scene: PackedScene = load("res://FloorMarsh.tscn")
	var floor_materials = [
		load("res://assets/textures/MossWall_Mat.tres"),
		load("res://assets/textures/MossyWall_Mat2.tres"),
		load("res://assets/textures/MossyPit.tres")
	]
	
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
			var wall = wall_scene.instantiate()
			parent.add_child(wall)
			wall.position = Vector3(pos.x, 0, pos.y)
			wall.position += Vector3(randf_range(-0.05, 0.05), 0, randf_range(-0.05, 0.05))
			var scale_variation = randf_range(0.95, 1.05)
			wall.scale = Vector3(scale_variation, 1, scale_variation)
			wall.rotation_degrees.y = [0, 90, 180, 270].pick_random()
		else:
			automap_grid[pos] = 0
			var floor = floor_scene.instantiate()
			parent.add_child(floor)
			floor.get_node("StaticBody3D/CSGBakedMeshInstance3D").material_override = floor_materials.pick_random()
			floor.position = Vector3(pos.x, 0, pos.y)
			floor.rotation_degrees.y = [0, 90, 180, 270].pick_random()

static func _spawn_entities(data: Dictionary, parent: Node, automap_grid: Dictionary,
							on_enemy_selected: Callable, on_chest_selected: Callable) -> void:
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
				_set_player_start(pos, parent, automap_grid)
			"decoration":
				_spawn_decor(pos, parent)

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

static func _set_player_start(grid_pos: Vector2i, parent: Node, automap_grid: Dictionary) -> void:
	# Player lives in the SubViewport already as a scene child
	# We need to find it relative to parent
	var player = parent.get_node_or_null("Player")
	if player:
		player.position = Vector3(grid_pos.x, 0, grid_pos.y)
		if "grid_position" in player:
			player.grid_position = grid_pos
		automap_grid[grid_pos] = 0

static func _spawn_decor(pos: Vector2i, parent: Node) -> void:
	var decor_scene: PackedScene = load("res://MarshTree.tscn")
	var decor = decor_scene.instantiate()
	parent.add_child(decor)
	decor.position = Vector3(pos.x, 0, pos.y)
