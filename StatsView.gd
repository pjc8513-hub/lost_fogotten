extends VBoxContainer

@export var stat_entry_scene: PackedScene = preload("res://StatEntry.tscn" )
@onready var stats_list: VBoxContainer = $ScrollContainer/StatsList
@onready var points_header: PanelContainer = $PointsHeader
@onready var points_label: Label = $PointsHeader/Label

var available_points: int = 0:
	set(value):
		available_points = value
		_update_header()

var stat_entries: Dictionary = {} # "Might": StatEntry node

func _ready():
	GameEvents.selected_character_changed.connect(
		func(character):
			_refresh_from_character(character)
	)

	GameEvents.party_member_stats_changed.connect(
		func(character):
			if character == PartyState.get_selected():
				_refresh_from_character(character)
	)

	if PartyState.get_selected():
		_refresh_from_character(PartyState.get_selected())


func _refresh_from_character(character):
	if character == null:
		return

	var stats = character.get_stats()
	_build_stat_list(stats)

	available_points = character.get_available_points()

func _on_stats_changed(character):
	if character == PartyState.get_selected():
		_build_stat_list(character.get_stats())
		
func _build_stat_list(stats: Dictionary):
	# Clear old ones if rebuilding
	for child in stats_list.get_children():
		child.queue_free()
	stat_entries.clear()
	
	# Create one row per stat
	for stat_name in stats.keys(): # ["might", "dexterity", "vitality", ...]
		print("Building stat: ", stat_name)
		var entry: StatEntry = stat_entry_scene.instantiate()
		if entry:
			entry.custom_minimum_size = Vector2(0, 32)
			stats_list.add_child(entry)
			entry.setup(stat_name, stats[stat_name])
			entry.stat_clicked.connect(_on_stat_clicked)
			stat_entries[stat_name] = entry
		else:
			print("No stat_entry_scene")
	
	_update_all_entries()

func _on_stat_clicked(stat_name: String):
	if available_points > 0:
		available_points -= 1
		var player_stats = PartyState.get_selected().get_stats()
		player_stats[stat_name] += 1
		stat_entries[stat_name].set_value(player_stats[stat_name])
		_update_all_entries()

func _update_all_entries():
	var can_add = available_points > 0
	for entry in stat_entries.values():
		entry.set_clickable(can_add)

func _update_header():
	points_label.text = "Available stat points: %d" % available_points

	var style := points_header.get_theme_stylebox("panel").duplicate()
	points_header.add_theme_stylebox_override("panel", style)

	if available_points > 0:
		style.bg_color = Color("90EE90")
	else:
		style.bg_color = Color("2D2D2D")
