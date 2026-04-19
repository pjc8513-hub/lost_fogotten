# Main.gd

extends Node3D

@export var wall_scene: PackedScene = preload("res://MossyWall.tscn")
@export var floor_scene: PackedScene = preload("res://FloorMarsh.tscn")
@export var enemy_scene: PackedScene = preload("res://Enemy.tscn")
#@export var rat_data: EnemyData = preload("res://data/enemies/giant_rat.tres")
#@export var goblin_data: EnemyData = preload("res://data/enemies/goblin.tres")
#@export var cat_data: EnemyData = preload("res://data/enemies/dungeon_cat.tres")

#var map_width = 10
#var map_height = 10
var map_open: bool = false
var automap_grid := {}  # Dictionary of Vector2 -> int

func _ready():
	set_process_unhandled_input(true)
	
	# Load the new JSON format we exported from the TileMap
	var data = load_room_data("res://data/maps/cave_level_1.json")
	if data:
		build_map_from_json(data)

		# Setup UI/World
		var automap = get_node("SubViewportContainer/SubViewport/CanvasLayer/AutoMap")
		automap.set_map_data(automap_grid)
		World.set_map_data(automap_grid)
		PartyState.selected_index = 0

func _input(event):
	if event.is_action_pressed("map"):  # Set this up in Project > Input Map
		map_open = !map_open
		var automap = get_node("SubViewportContainer/SubViewport/CanvasLayer/AutoMap")
		automap.visible = map_open
		
	#if event is InputEventMouse:
		#print(event)
		#get_node("SubViewportContainer/SubViewport").push_input(event)
		
# debug
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[Main] Unhandled click at: ", event.position)		

func load_room_data(file_path: String) -> Dictionary:
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

func build_map_from_json(data: Dictionary):
	# 1. Spawn Walls/Floors from "cells"
	for cell in data.get("cells", []):
		# Handle pos being either Array or String like "[x,y]"
		var pos_data = cell.get("pos", [])
		if pos_data is String:
			pos_data = JSON.parse_string(pos_data)
		
		# Handle atlas being either Array or String like "[x,y]"
		var atlas_data = cell.get("atlas", [])
		if atlas_data is String:
			atlas_data = JSON.parse_string(atlas_data)
		
		# Now validate we actually have arrays with 2 elements
		if not (pos_data is Array and atlas_data is Array and pos_data.size() >= 2 and atlas_data.size() >= 2):
			push_error("Malformed cell in map data: " + str(cell))
			continue
			
		var pos = Vector2i(int(pos_data[0]), int(pos_data[1]))
		var atlas_x = int(atlas_data[0])
		var atlas_y = int(atlas_data[1])
		
		# For a blobber, we usually treat certain atlas coords as walls
		# Assuming your wall tile was Atlas (0,0) in the TileSet
		if atlas_x == 0 and atlas_y == 0:
			automap_grid[pos] = 1 # 1 for Wall in your automap logic
			var wall = wall_scene.instantiate()
			add_child(wall)
			wall.position = Vector3(pos.x, 0, pos.y)
			wall.position += Vector3(
				randf_range(-0.05, 0.05),
				0,
				randf_range(-0.05, 0.05)
			)
			
			var scale_variation = randf_range(0.95, 1.05)
			wall.scale = Vector3(scale_variation, 1, scale_variation)
			
			# Random 0, 90, 180, 270 rotation
			var rotations = [0, 90, 180, 270]
			wall.rotation_degrees.y = rotations.pick_random()
		else:
			automap_grid[pos] = 0 # 0 for Floor/Empty
			var floor = floor_scene.instantiate()
			add_child(floor)
			floor.position = Vector3(pos.x, 0, pos.y)
			floor.rotation_degrees.y = [0, 90, 180, 270].pick_random()
			
	

	# 2. Spawn Entities (Enemies, Chests, etc.)
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
				_spawn_enemy(pos, ent["data_resource"], ent["aggro_group"])
			"chest":
				print("Chest found at ", pos, " with loot: ", ent["data_resource"])
				# _spawn_chest(pos, ent["data_resource"])
			"player":
				print("spawning player at: ", pos)
				_set_player_start(pos)

func _spawn_enemy(grid_pos: Vector2i, data_path: String, aggro_id: int):
	#var enemy = enemy_scene.instantiate()
	var res = load(data_path) as EnemyData
	
	# Load the scene from the path string
	var enemy_scene_resource = load(res.scene_path) 
	var enemy = enemy_scene_resource.instantiate()
	$SubViewportContainer/SubViewport.add_child(enemy)
	
	enemy.grid_position = grid_pos
	enemy.position = Vector3(grid_pos.x, 0, grid_pos.y)

	# Load the .tres file directly from the path provided by the TileMap
	if FileAccess.file_exists(data_path):
		#var res = load(data_path)
		enemy.enemy_data = res.duplicate()
	else:
		print("no enemy at: ", data_path)
	
	# Handle Aggro Groups
	if aggro_id > 0:
		enemy.add_to_group("aggro_" + str(aggro_id))
		print("Enemy added to aggro group: aggro_", aggro_id)
	
	enemy.connect("selected", Callable(self, "_on_enemy_selected"))


func _set_player_start(grid_pos: Vector2i):
	# Find your player node. Adjust the path if yours is different!
	# (e.g., $Player or $SubViewportContainer/.../Player)
	var player = get_node("SubViewportContainer/SubViewport/Player") 
	
	if player:
		# Update the 3D position
		player.position = Vector3(grid_pos.x, 0, grid_pos.y)
		
		# If your player script has a 'grid_position' variable for movement:
		if "grid_position" in player:
			player.grid_position = grid_pos
			
		print("Player started at grid position: ", grid_pos)
		
		# Ensure the automap knows this tile is walkable (0) and not a wall
		automap_grid[grid_pos] = 0

func spawn_light_here(posx, posy):
	var light = OmniLight3D.new()
	add_child(light)
	light.position = Vector3(posx, 0.2, posy)
	light.light_energy = 0.4
