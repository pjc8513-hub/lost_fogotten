# Main.gd

extends Node3D


#@export var rat_data: EnemyData = preload("res://data/enemies/giant_rat.tres")
#@export var goblin_data: EnemyData = preload("res://data/enemies/goblin.tres")
#@export var cat_data: EnemyData = preload("res://data/enemies/dungeon_cat.tres")

#var map_width = 10
#var map_height = 10
var map_open: bool = false
var automap_grid := {}  # Dictionary of Vector2 -> int
@onready var sub_viewport_container: SubViewportContainer = $SubViewportContainer
@onready var sub_viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var casting_scene: Control = $CastingScene

func _enter_tree():
	print("[FRAME ", Engine.get_process_frames(), "] Main _enter_tree")

func _ready():
	print("[FRAME ", Engine.get_process_frames(), "] Main _ready start")
	print("[FRAME ", Engine.get_process_frames(), "] Main initial focus owner: ", get_viewport().gui_get_focus_owner())
	
	casting_scene.visible = false
	sub_viewport.gui_disable_input = false
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	sub_viewport_container.grab_focus()
	print("[FRAME ", Engine.get_process_frames(), "] Main after immediate grab_focus: ", get_viewport().gui_get_focus_owner())
	
	call_deferred("_finish_initial_scene_setup")
	
	if not GameEvents.chest_opened.is_connected(LootDistributor.distribute_chest_loot):
		GameEvents.chest_opened.connect(LootDistributor.distribute_chest_loot)
	set_process_unhandled_input(true)
	var dungeon_data := World.current_dungeon_data
	var map_path := "res://data/maps/locations/swamp/SwampCentral/Swamp_Central.json"
	var theme_path := "res://data/maps/themes/dirt_theme.tres"
	if dungeon_data != null:
		if not dungeon_data.map_data_path.is_empty():
			map_path = dungeon_data.map_data_path
		if not dungeon_data.ThemePath.is_empty():
			theme_path = dungeon_data.ThemePath
	elif not World.current_map_path.is_empty():
		map_path = World.current_map_path
		if not World.current_map_theme_path.is_empty():
			theme_path = World.current_map_theme_path
	var map_theme = load(theme_path)
	#var map_theme = load("res://data/maps/themes/swamp_theme.tres") #testing
	_play_map_music(map_theme)
	
	# Load the new JSON format we exported from the TileMap
	var data = MapBuilder.load_room_data(map_path)
	#var data = MapBuilder.load_room_data("res://data/maps/BonePit.json") #testing
	if data:
		World.reset_world_state()
		var spawn_id := dungeon_data.spawn_id if dungeon_data != null else World.current_map_spawn_id
		var result = MapBuilder.build(
			data, self, 
			$SubViewportContainer/SubViewport,
			map_theme,
			_on_enemy_selected,
			_on_chest_selected,
			_on_dungeon_selected,
			spawn_id
		)
		var automap_grid = result.automap_grid
		var automap = get_node("automap")
		if automap:
			automap.set_map_data(automap_grid)
		World.set_map_data(automap_grid)
		World.current_map_path = map_path
		World.current_map_theme_path = theme_path
		World.current_map_spawn_id = spawn_id
		PartyState.selected_index = 0
		print("[FRAME ", Engine.get_process_frames(), "] Main map build complete, selected index: ", PartyState.selected_index)
		print("[FRAME ", Engine.get_process_frames(), "] Main selected member: ", PartyState.get_selected())
	print("[FRAME ", Engine.get_process_frames(), "] Main _ready end")
	$Control/MarginContainer/VBoxContainer.refresh_party_ui()
		
func _input(event):
	if event.is_action_pressed("map"):  # Set this up in Project > Input Map
		map_open = !map_open
		var automap = get_node("automap")
		if automap:
			automap.visible = map_open
		
	if event.is_action_pressed("compose"):
		var owner_char := PartyState.get_selected()
		if owner_char == null:
			return
		
		# Check if character has a guitar equipped
		if not owner_char.has_guitar_equipped():
			GameEvents.message_logged.emit("[color=red]%s has no guitar equipped.[/color]" % owner_char.member_name)
			return
		
		if casting_scene.visible == false:
			casting_scene.visible = true
			casting_scene.mouse_filter = Control.MOUSE_FILTER_STOP
			# Bring CastingScene to front of viewport
			casting_scene.move_to_front()
			print("castingscene vis: ", casting_scene.visible)
		else:
			casting_scene.visible = false
			casting_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	#if event is InputEventMouse:
		#print(event)
		#get_node("SubViewportContainer/SubViewport").push_input(event)
		
# debug
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		World.set_selected_enemy(null)
		CombatState.clear_target()
		World.set_selected_chest(null)
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

func _play_map_music(map_theme: MapTheme) -> void:
	if map_theme == null or map_theme.music_path.is_empty():
		return
	if not ResourceLoader.exists(map_theme.music_path):
		push_warning("Map music not found: " + map_theme.music_path)
		return

	var stream := load(map_theme.music_path) as AudioStream
	if stream == null:
		push_warning("Failed to load map music: " + map_theme.music_path)
		return

	MusicManager.play_music(stream)


func spawn_light_here(posx, posy):
	var light = OmniLight3D.new()
	add_child(light)
	light.position = Vector3(posx, 0.2, posy)
	light.light_energy = 0.4

	
func _grab_viewport_focus():
	sub_viewport_container.grab_focus()

func _finish_initial_scene_setup() -> void:
	print("[FRAME ", Engine.get_process_frames(), "] Main _finish_initial_scene_setup start")
	await get_tree().process_frame
	print("[FRAME ", Engine.get_process_frames(), "] Main setup after process_frame, focus owner: ", get_viewport().gui_get_focus_owner())
	await RenderingServer.frame_post_draw
	print("[FRAME ", Engine.get_process_frames(), "] Main setup after frame_post_draw, focus owner: ", get_viewport().gui_get_focus_owner())
	get_window().grab_focus()
	sub_viewport_container.grab_focus()
	print("[FRAME ", Engine.get_process_frames(), "] Main after deferred focus grabs, focus owner: ", get_viewport().gui_get_focus_owner())
	sub_viewport_container.queue_redraw()
	var party_list = get_node_or_null("Control/MarginContainer/VBoxContainer")
	if party_list:
		print("[FRAME ", Engine.get_process_frames(), "] Main party list child count: ", party_list.get_child_count())
		party_list.queue_redraw()
		for child in party_list.get_children():
			print("[FRAME ", Engine.get_process_frames(), "] Main forcing redraw on child: ", child.name, " visible=", child.visible)
			child.queue_redraw()
			var portrait_node = child.get_node_or_null("HBoxContainer/PortraitOne")
			if portrait_node:
				print("[FRAME ", Engine.get_process_frames(), "] Main portrait node found for ", child.name, " texture=", portrait_node.texture)
				portrait_node.queue_redraw()
	if PartyState.get_selected() != null:
		print("[FRAME ", Engine.get_process_frames(), "] Main re-emitting selected_character_changed for ", PartyState.get_selected().member_name)
		GameEvents.selected_character_changed.emit(PartyState.get_selected())
	print("[FRAME ", Engine.get_process_frames(), "] Main _finish_initial_scene_setup end")

func _notification(what):
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		print("[FRAME ", Engine.get_process_frames(), "] Main window focus in")
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		print("[FRAME ", Engine.get_process_frames(), "] Main window focus out")

func _on_enemy_selected(enemy):
	World.set_selected_enemy(enemy)

func _on_chest_selected(chest):
	World.set_selected_chest(chest)
	
func _on_dungeon_selected(dungeon):
	World.set_selected_dungeon(dungeon)
