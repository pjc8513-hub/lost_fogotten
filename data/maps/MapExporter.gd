@tool
extends Node3D

@export var export_path: String = "res://data/maps/dungeons/WitchTree/WitchTree_5/witchtree_5.json"
@export var run_export: bool = false : set = _on_run_export

func _on_run_export(_val):
	export_to_json()

func export_to_json():
	var tilemap = $TileMapLayer
	var light_layer = $LightLayer      # your second TileMapLayer node

	var map_data = {
		"cells": [],
		"entities": [],
		"lights": []        # new array
	}

	# --- existing geometry + entity pass (unchanged) ---
	var used_cells = tilemap.get_used_cells()
	for coords in used_cells:
		var source_id = tilemap.get_cell_source_id(coords)
		var atlas_coords = tilemap.get_cell_atlas_coords(coords)
		var tile_data = tilemap.get_cell_tile_data(coords)

		map_data["cells"].append({
			"pos": [coords.x, coords.y],
			"source_id": source_id,
			"atlas": [atlas_coords.x, atlas_coords.y]
		})

		if tile_data:
			var type = tile_data.get_custom_data("entity_type")
			if type != "" and type != null:
				map_data["entities"].append({
					"type": type,
					"pos": [coords.x, coords.y],
					"data_resource": tile_data.get_custom_data("data_path"),
					"fencing_resource": tile_data.get_custom_data("fencing_resource"),
					"trigger_resource": tile_data.get_custom_data("trigger_resource"),
					"aggro_group": tile_data.get_custom_data("aggro_id")
				})

	# --- new light layer pass ---
	for coords in light_layer.get_used_cells():
		var tile_data = light_layer.get_cell_tile_data(coords)
		if tile_data == null:
			continue

		var light_type = tile_data.get_custom_data("light_type")   # "brazier" / "black_out" / "light_restore"
		if light_type == null or light_type == "":
			continue

		map_data["lights"].append({
			"light_type": light_type,
			"pos": [coords.x, coords.y],
			"data_resource": tile_data.get_custom_data("data_path")   # points to BrazierData.tres etc.
		})

	var file = FileAccess.open(export_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(map_data, "\t"))
	print("Map exported to: ", export_path)
