extends Node

var _all_chords: Array[ChordData] = []

func _ready() -> void:
	_load_all_chords()

func _load_all_chords() -> void:
	_all_chords.clear()
	_scan_chords_folder("res://data/chords/")

func _scan_chords_folder(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Failed to open chords folder: %s" % path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and not file_name.begins_with("."):
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var full_path := path.path_join(file_name)
				var chord_resource := load(full_path) as ChordData
				if chord_resource != null:
					_all_chords.append(chord_resource)
				else:
					push_warning("Failed to load chord: %s" % full_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("Loaded %d chords from %s" % [_all_chords.size(), path])

func get_all_chords() -> Array[ChordData]:
	return _all_chords.duplicate()

func get_matching_chords(active_elements: Array[int]) -> Array[ChordData]:
	var matches: Array[ChordData] = []
	if active_elements.is_empty():
		return matches

	for chord in _all_chords:
		if chord == null:
			continue
		if _matches_requirements(chord, active_elements):
			matches.append(chord)

	return matches

func _matches_requirements(chord: ChordData, active_elements: Array[int]) -> bool:
	if chord.required_elements.is_empty():
		return false

	var counts := {}
	for element in active_elements:
		counts[element] = int(counts.get(element, 0)) + 1

	for required_element in chord.required_elements:
		if int(counts.get(required_element, 0)) < 1:
			return false

	return active_elements.size() >= max(1, chord.min_required_count)
