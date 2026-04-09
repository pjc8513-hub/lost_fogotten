# auto_map.gd

extends Control

var map_data := {}
var tile_size := 8
var wall_color := Color(0.9, 0.85, 0.7)
var floor_color := Color(0.2, 0.2, 0.25)
var background_color := Color(0.05, 0.05, 0.1, 0.85)
var player_color := Color(0.2, 0.9, 0.4)   # ✅ Green dot
var player_pos := Vector2.ZERO              # ✅ Tracked here
var padding := 10

func set_map_data(data: Dictionary):
	map_data = data
	queue_redraw()

func on_player_moved(grid_pos: Vector2):   # ✅ Called by signal
	player_pos = grid_pos
	queue_redraw()

func _draw():
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

	for pos in map_data.keys():
		var draw_x = (pos.x - min_x) * tile_size + padding
		var draw_y = (pos.y - min_y) * tile_size + padding
		var rect = Rect2(draw_x, draw_y, tile_size - 1, tile_size - 1)
		draw_rect(rect, wall_color if map_data[pos] == 1 else floor_color)

	# ✅ Draw player dot on top
	var px = (player_pos.x - min_x) * tile_size + padding
	var py = (player_pos.y - min_y) * tile_size + padding
	var player_rect = Rect2(px, py, tile_size - 1, tile_size - 1)
	draw_rect(player_rect, player_color)
