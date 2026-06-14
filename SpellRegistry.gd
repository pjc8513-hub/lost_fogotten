extends Node

const SPELL_DIRECTORY := "res://data/spells"

var _spells: Array[SpellData] = []

func _ready() -> void:
	reload()

func reload() -> void:
	_spells.clear()
	_load_directory(SPELL_DIRECTORY)

func get_all_spells() -> Array[SpellData]:
	return _spells.duplicate()

func find_by_notes(notes: Array[int]) -> SpellData:
	for spell in _spells:
		if spell.matches_notes(notes):
			return spell
	return null

func find_by_id(spell_id: String) -> SpellData:
	var normalized := spell_id.strip_edges().to_lower()
	for spell in _spells:
		if spell.spell_id.to_lower() == normalized or spell.get_display_name().to_lower() == normalized:
			return spell
	return null

func _load_directory(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory == null:
		return

	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var entry_path := path.path_join(entry)
		if directory.current_is_dir():
			if entry != "." and entry != "..":
				_load_directory(entry_path)
		elif entry.get_extension().to_lower() in ["tres", "res"]:
			var spell := load(entry_path) as SpellData
			if spell == null:
				push_warning("SpellRegistry: %s is not SpellData." % entry_path)
			elif not spell.is_valid_definition():
				push_warning("SpellRegistry: Invalid spell definition at %s." % entry_path)
			else:
				_spells.append(spell)
		entry = directory.get_next()
	directory.list_dir_end()
