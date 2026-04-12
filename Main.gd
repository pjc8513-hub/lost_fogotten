# Main.gd

extends Node3D

@export var wall_scene: PackedScene = preload("res://Wall.tscn")
@export var enemy_scene: PackedScene = preload("res://Enemy.tscn")
@export var rat_data: EnemyData = preload("res://data/enemies/giant_rat.tres")
@export var goblin_data: EnemyData = preload("res://data/enemies/goblin.tres")
@export var cat_data: EnemyData = preload("res://data/enemies/dungeon_cat.tres")

var map_width = 10
var map_height = 10
var map_open: bool = false
var automap_grid := {}  # Dictionary of Vector2 -> int

func _ready():
	set_process_unhandled_input(true) # debug
	
	var data = load_room_data("res://data/maps/open1.json")
	if data:
		stamp_room(Vector2(0, 0), data)
		stamp_room(Vector2(8, 0), data)

		# ✅ Send the populated automap_grid to the AutoMap node
		var automap = get_node("SubViewportContainer/SubViewport/CanvasLayer/AutoMap")
		automap.set_map_data(automap_grid)
		World.set_map_data(automap_grid)

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

func stamp_room(start_pos: Vector2, room_data: Dictionary):
	var base = room_data["base_layer"]
	var entities = room_data.get("entity_layer", null)

	for y in range(room_data["height"]):
		for x in range(room_data["width"]):

			var world_x = int(start_pos.x + x)
			var world_y = int(start_pos.y + y)
			var world_pos = Vector2i(world_x, world_y)

			# --- BASE LAYER (floors, walls) ---
			var base_value = base[y][x]
			automap_grid[world_pos] = base_value

			if base_value == 1:
				var wall = wall_scene.instantiate()
				add_child(wall)
				wall.position = Vector3(world_x, 0, world_y)

			# --- ENTITY LAYER (enemies, items, etc.) ---
			if entities:
				var ent_value = entities[y][x]

				if ent_value == 4:
					_spawn_enemy(world_pos)

func _spawn_enemy(world_pos: Vector2i):
	var enemy = enemy_scene.instantiate()
	#add_child(enemy)
	$SubViewportContainer/SubViewport.add_child(enemy)
	
	#enemy.add_to_group("enemies") <- moved to enemy.gd _ready (?)

	enemy.grid_position = world_pos   # ✅ THIS is the missing piece
	enemy.position = Vector3(world_pos.x, 0, world_pos.y)

	enemy.enemy_data = cat_data if randf() < 0.5 else goblin_data
	enemy.connect("selected", Callable(self, "_on_enemy_selected"))
	print("Spawned enemy with data: ", enemy.enemy_data.resource_path)
	print("Enemy ailment: ", enemy.enemy_data.ailment)
func _on_enemy_selected(enemy):
	print("Selected enemy:", enemy.enemy_data.enemy_name)
	# Later: show UI panel, highlight enemy, set attack target, etc.
