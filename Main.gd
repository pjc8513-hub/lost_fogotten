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
@onready var world_environment: WorldEnvironment = $SubViewportContainer/SubViewport/WorldEnvironment

#func _enter_tree():
	#print("[FRAME ", Engine.get_process_frames(), "] Main _enter_tree")

func _ready():
	#print("[FRAME ", Engine.get_process_frames(), "] Main _ready start")
	#print("[FRAME ", Engine.get_process_frames(), "] Main initial focus owner: ", get_viewport().gui_get_focus_owner())
	var torch_ui = $SubViewportContainer/SubViewport/TorchBar
	var player_torch = $SubViewportContainer/SubViewport/Player/TorchLight
	if torch_ui and player_torch:
		torch_ui.hook_up_torch(player_torch)
	else:
		push_error("Main.gd: Could not find torch_ui or player_torch in the scene tree!")
		
	casting_scene.visible = false
	sub_viewport.gui_disable_input = false
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_ensure_sub_viewport_world()
	sub_viewport_container.mouse_filter = Control.MOUSE_FILTER_STOP
	sub_viewport_container.grab_focus()
	#print("[FRAME ", Engine.get_process_frames(), "] Main after immediate grab_focus: ", get_viewport().gui_get_focus_owner())
	
	call_deferred("_finish_initial_scene_setup")
	
	if not GameEvents.chest_opened.is_connected(LootDistributor.distribute_chest_loot):
		GameEvents.chest_opened.connect(LootDistributor.distribute_chest_loot)
	set_process_unhandled_input(true)
	var dungeon_data := World.current_dungeon_data
	var map_path := "res://data/maps/dungeons/WitchTree/WitchTree_2/witchtree_2.json"
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
	var map_theme := load(theme_path) as MapTheme
	if map_theme == null:
		push_warning("Failed to load map theme: " + theme_path)
	#var map_theme = load("res://data/maps/themes/swamp_theme.tres") #testing

	# --- NEW: Update the post-processing shader with this theme's properties ---
	if map_theme != null and $SubViewportContainer/SubViewport/ShaderDitheringLayer/ColorRect != null:
		var mat = $SubViewportContainer/SubViewport/ShaderDitheringLayer/ColorRect.material as ShaderMaterial
		if mat:
			if map_theme.palette_texture:
				mat.set_shader_parameter("palette_texture", map_theme.palette_texture)
			mat.set_shader_parameter("pixel_size", map_theme.pixel_size)
			mat.set_shader_parameter("dither_strength", map_theme.dither_strength)
			mat.set_shader_parameter("contrast", map_theme.contrast)
	# ----------------------------------------------------------------------------
	
	_play_map_music(map_theme)	
	apply_world_environment(map_theme)
	call_deferred("_debug_world_environment_state", "after apply deferred")
	
	# Load the new JSON format we exported from the TileMap
	var data = MapBuilder.load_room_data(map_path)
	#var data = MapBuilder.load_room_data("res://data/maps/BonePit.json") #testing
	if data:
		World.reset_world_state()
		var spawn_id := dungeon_data.spawn_id if dungeon_data != null else World.current_map_spawn_id
		var result = MapBuilder.build(
			data,
			sub_viewport,
			sub_viewport,
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
		#print("[FRAME ", Engine.get_process_frames(), "] Main map build complete, selected index: ", PartyState.selected_index)
		#print("[FRAME ", Engine.get_process_frames(), "] Main selected member: ", PartyState.get_selected())
	print("[FRAME ", Engine.get_process_frames(), "] Main _ready end")
	$Control/MarginContainer/VBoxContainer.refresh_party_ui()

func apply_world_environment(theme: MapTheme) -> void:
	_ensure_sub_viewport_world()

	if theme == null:
		push_warning("Cannot apply world environment because the map theme is missing.")
		return
	print("[WorldEnv] Theme: ", theme.resource_path)
	print("[WorldEnv] Theme environment: ", _describe_environment(theme.environment))
	
	# --- NEW: Find your player's OmniLight3D and apply the theme settings ---
	# Adjust this path to wherever your torch light node lives inside the sub_viewport
	var player_torch = sub_viewport.find_child("TorchLight", true, false) as OmniLight3D
	if player_torch and player_torch.has_method("configure_torch"):
		player_torch.configure_torch(theme)
	else:
		push_warning("[WorldEnv] Player TorchLight node not found or missing configuration method.")
	# ------------------------------------------------------------------------
	
	if theme.environment == null:
		push_warning("Map theme has no environment assigned: " + str(theme.resource_path))
		return

	var runtime_environment := theme.environment
	if runtime_environment == null:
		push_warning("Failed to get environment for map theme: " + str(theme.resource_path))
		return

	_apply_environment_to_viewports(runtime_environment)
	_debug_world_environment_state("after apply immediate")

func _apply_environment_to_viewports(environment: Environment) -> void:
	if is_instance_valid(world_environment):
		world_environment.environment = environment
		print("[WorldEnv] Assigned WorldEnvironment node: ", _describe_environment(world_environment.environment))
	else:
		push_warning("[WorldEnv] WorldEnvironment node is not valid.")

	_set_viewport_environment(sub_viewport, environment)
	# Clear any camera environment override so that the WorldEnvironment is used.
	# In Godot 4, setting an environment directly on a Camera3D acts as an override
	# but does not support the full suite of environment features (like background sky, fog, ambient light).
	_clear_camera_environment_override()

func _ensure_sub_viewport_world() -> void:
	if sub_viewport == null:
		return

	if not sub_viewport.own_world_3d:
		sub_viewport.own_world_3d = true
	if sub_viewport.get_world_3d() == null:
		push_warning("[WorldEnv] SubViewport does not have a World3D yet; environment assignment will be deferred.")

func _set_viewport_environment(viewport: Viewport, environment: Environment) -> void:
	if viewport == null:
		push_warning("[WorldEnv] Cannot assign environment because viewport is null.")
		return

	var world := viewport.get_world_3d()
	if world != null:
		world.environment = environment
		print("[WorldEnv] Assigned viewport world '", viewport.name, "': ", _describe_environment(world.environment))
		return

	push_warning("[WorldEnv] Viewport has no World3D yet: " + str(viewport.name))
	(func():
		if is_instance_valid(viewport) and viewport.get_world_3d() != null:
			viewport.get_world_3d().environment = environment
			print("[WorldEnv] Deferred viewport world assignment '", viewport.name, "': ", _describe_environment(viewport.get_world_3d().environment))
		else:
			push_warning("[WorldEnv] Deferred assignment failed because viewport still has no World3D.")
	).call_deferred()

func _clear_camera_environment_override() -> void:
	if not is_instance_valid(sub_viewport):
		return

	var camera := sub_viewport.get_camera_3d()
	if camera == null:
		push_warning("[WorldEnv] Cannot clear camera environment override because SubViewport has no active Camera3D.")
		return

	camera.environment = null
	print("[WorldEnv] Cleared camera environment override so WorldEnvironment takes precedence.")

func _debug_world_environment_state(label: String) -> void:
	print("[WorldEnv] --- ", label, " ---")
	print("[WorldEnv] WorldEnvironment node valid: ", is_instance_valid(world_environment))
	if is_instance_valid(world_environment):
		print("[WorldEnv] WorldEnvironment node env: ", _describe_environment(world_environment.environment))

	_debug_viewport_environment(sub_viewport, "sub_viewport")
	_debug_viewport_environment(get_viewport(), "root_viewport")

	var camera := sub_viewport.get_camera_3d() if is_instance_valid(sub_viewport) else null
	print("[WorldEnv] SubViewport camera: ", camera.get_path() if camera != null else "<none>")
	if camera != null:
		print("[WorldEnv] Camera current: ", camera.current)
		print("[WorldEnv] Camera env override: ", _describe_environment(camera.environment))

func _debug_viewport_environment(viewport: Viewport, label: String) -> void:
	if viewport == null:
		print("[WorldEnv] ", label, ": <null viewport>")
		return

	var world := viewport.get_world_3d()
	print("[WorldEnv] ", label, " path: ", viewport.get_path())
	print("[WorldEnv] ", label, " world exists: ", world != null)
	if world != null:
		print("[WorldEnv] ", label, " world env: ", _describe_environment(world.environment))

func _describe_environment(environment: Environment) -> String:
	if environment == null:
		return "<null>"

	var sky_material := environment.sky.sky_material if environment.sky != null else null
	var panorama_path := ""
	if sky_material != null and "panorama" in sky_material and sky_material.panorama != null:
		panorama_path = sky_material.panorama.resource_path

	return "env=%s path=%s background_mode=%s has_sky=%s sky_material=%s panorama=%s fog=%s fog_sky_affect=%s fog_density=%s ambient=%s" % [
		str(environment),
		str(environment.resource_path),
		str(environment.background_mode),
		str(environment.sky != null),
		str(sky_material),
		panorama_path,
		str(environment.fog_enabled),
		str(environment.fog_sky_affect),
		str(environment.fog_density),
		str(environment.ambient_light_source)
	]

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
			#print("castingscene vis: ", casting_scene.visible)
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
		#print("[Main] Unhandled click at: ", event.position)

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
	#print("[FRAME ", Engine.get_process_frames(), "] Main _finish_initial_scene_setup start")
	await get_tree().process_frame
	#print("[FRAME ", Engine.get_process_frames(), "] Main setup after process_frame, focus owner: ", get_viewport().gui_get_focus_owner())
	await RenderingServer.frame_post_draw
	#print("[FRAME ", Engine.get_process_frames(), "] Main setup after frame_post_draw, focus owner: ", get_viewport().gui_get_focus_owner())
	get_window().grab_focus()
	sub_viewport_container.grab_focus()
	#print("[FRAME ", Engine.get_process_frames(), "] Main after deferred focus grabs, focus owner: ", get_viewport().gui_get_focus_owner())
	sub_viewport_container.queue_redraw()
	var party_list = get_node_or_null("Control/MarginContainer/VBoxContainer")
	if party_list:
		#print("[FRAME ", Engine.get_process_frames(), "] Main party list child count: ", party_list.get_child_count())
		party_list.queue_redraw()
		for child in party_list.get_children():
			#print("[FRAME ", Engine.get_process_frames(), "] Main forcing redraw on child: ", child.name, " visible=", child.visible)
			child.queue_redraw()
			var portrait_node = child.get_node_or_null("HBoxContainer/PortraitOne")
			if portrait_node:
				#print("[FRAME ", Engine.get_process_frames(), "] Main portrait node found for ", child.name, " texture=", portrait_node.texture)
				portrait_node.queue_redraw()
	if PartyState.get_selected() != null:
		#print("[FRAME ", Engine.get_process_frames(), "] Main re-emitting selected_character_changed for ", PartyState.get_selected().member_name)
		GameEvents.selected_character_changed.emit(PartyState.get_selected())
	#print("[FRAME ", Engine.get_process_frames(), "] Main _finish_initial_scene_setup end")

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
