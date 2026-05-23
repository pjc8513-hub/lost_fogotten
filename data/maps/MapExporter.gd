@tool
extends Node3D

@export var export_path: String = "res://data/maps/dungeons/WitchTree/WitchTree_1/witchtree_1.json"
@export var run_export: bool = false : set = _on_run_export

func _on_run_export(_val):
	export_to_json()

func export_to_json():
	var tilemap = $TileMapLayer # Adjust path to your layer
	var map_data = {
		"cells": [],
		"entities": [],
		"triggers": []
	}
	
	var used_cells = tilemap.get_used_cells()
	
	for coords in used_cells:
		var source_id = tilemap.get_cell_source_id(coords)
		var atlas_coords = tilemap.get_cell_atlas_coords(coords)
		var tile_data = tilemap.get_cell_tile_data(coords)
		
		# 1. ALWAYS export the base tile for collision/visuals
		map_data["cells"].append({
			"pos": [coords.x, coords.y],
			"source_id": source_id,
			"atlas": [atlas_coords.x, atlas_coords.y]
		})
		
		# 2. ALSO export entity data if this tile has it
		if tile_data:
			var type = tile_data.get_custom_data("entity_type")
			if type != "" and type != null:
				var entity_info = {
					"type": type,
					"pos": [coords.x, coords.y],
					"data_resource": tile_data.get_custom_data("data_path"),
					"aggro_group": tile_data.get_custom_data("aggro_id")
				}
				map_data["entities"].append(entity_info)

	# Save the file
	var file = FileAccess.open(export_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(map_data, "\t"))
	print("Map exported successfully to: ", export_path)
