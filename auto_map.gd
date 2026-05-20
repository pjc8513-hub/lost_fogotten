# auto_map.gd

extends Control
@onready var automap_rect: ColorRect = $PanelContainer/VBoxContainer/automap
@onready var compass: Label = $PanelContainer/VBoxContainer/compass


func _ready():
	if is_instance_valid(automap_rect):
		automap_rect.draw.connect(_on_automap_draw)
		automap_rect.clip_contents = true

var map_data := {}
var tile_size := 8
var wall_color := Color(0.9, 0.85, 0.7)
var floor_color := Color(0.2, 0.2, 0.25)
var background_color := Color(0.05, 0.05, 0.1, 0.85)
var player_color := Color(0.2, 0.9, 0.4)   # ✅ Green dot
var player_pos := Vector2i.ZERO              # ✅ Tracked here
var padding := 10
var vision_radius := 4

func _update_fog_of_war():
	var map_path = World.current_map_path
	if map_path.is_empty():
		return
		
	for x in range(-vision_radius, vision_radius + 1):
		for y in range(-vision_radius, vision_radius + 1):
			var check_pos = player_pos + Vector2i(x, y)
			if Vector2(check_pos).distance_to(Vector2(player_pos)) <= vision_radius:
				if map_data.has(check_pos):
					World.add_discovered_tile(map_path, check_pos)


func set_map_data(data: Dictionary):
	map_data = data
	_update_fog_of_war()
	if is_instance_valid(automap_rect):
		automap_rect.queue_redraw()
	else:
		queue_redraw()

func on_player_moved(grid_pos: Vector2i):   # ✅ Called by signal
	player_pos = grid_pos
	_update_fog_of_war()
	if is_instance_valid(automap_rect):
		automap_rect.queue_redraw()
	else:
		queue_redraw()

func _draw():
	if not is_instance_valid(automap_rect):
		_draw_old_behavior()

func _on_automap_draw():
	if map_data.is_empty():
		return

	var rect_size = automap_rect.size
	var center_x = rect_size.x / 2.0
	var center_y = rect_size.y / 2.0
	
	# Draw background
	automap_rect.draw_rect(Rect2(Vector2.ZERO, rect_size), background_color)

	var discovered = World.get_discovered_tiles(World.current_map_path)

	# Draw tiles relative to player
	for pos in map_data.keys():
		if not discovered.has(pos):
			continue
			
		var dx = pos.x - player_pos.x
		var dy = pos.y - player_pos.y
		
		var draw_x = center_x + dx * tile_size - (tile_size / 2.0)
		var draw_y = center_y + dy * tile_size - (tile_size / 2.0)
		
		var rect = Rect2(draw_x, draw_y, tile_size - 1, tile_size - 1)
		
		# Only draw if roughly within bounds
		if rect.intersects(Rect2(Vector2.ZERO, rect_size)):
			automap_rect.draw_rect(rect, wall_color if map_data[pos] == 1 else floor_color)

	# Draw player dot at the center
	var player_rect = Rect2(center_x - (tile_size / 2.0), center_y - (tile_size / 2.0), tile_size - 1, tile_size - 1)
	automap_rect.draw_rect(player_rect, player_color)

func _draw_old_behavior():
	if map_data.is_empty():
		return

	var min_x = INF;  var min_y = INF
	var max_x = -INF; var max_y = -INF
	for pos in map_data.keys():
		min_x = min(min_x, pos.x);  min_y = min(min_y, pos.y)
		max_x = max(max_x, pos.x);  max_y = max(max_y, pos.y)

	var map_pixel_w = (max_x - min_x + 1) * tile_size + padding * 2
	var map_pixel_h = (max_y - min_y + 1) * tile_size + padding * 2
	draw_rect(Rect2(0, 0, map_pixel_w, map_pixel_h), background_color)

	var discovered = World.get_discovered_tiles(World.current_map_path)

	for pos in map_data.keys():
		if not discovered.has(pos):
			continue
			
		var draw_x = (pos.x - min_x) * tile_size + padding
		var draw_y = (pos.y - min_y) * tile_size + padding
		var rect = Rect2(draw_x, draw_y, tile_size - 1, tile_size - 1)
		draw_rect(rect, wall_color if map_data[pos] == 1 else floor_color)

	# ✅ Draw player dot on top
	var px = (player_pos.x - min_x) * tile_size + padding
	var py = (player_pos.y - min_y) * tile_size + padding
	var player_rect = Rect2(px, py, tile_size - 1, tile_size - 1)
	draw_rect(player_rect, player_color)
