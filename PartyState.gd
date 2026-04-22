# PartyState.gd (global)
extends Node

const DEFAULT_PARTY_TEMPLATES: Array[ClassData] = [
	preload("res://data/classes/knight.tres"),
	preload("res://data/classes/monk.tres"),
	preload("res://data/classes/cleric.tres"),
	preload("res://data/classes/rogue.tres"),
	preload("res://data/classes/sorcerer.tres")
]

var active_party: Array[ClassData] = []
var selected_index: int = 0:
	set(value):
		if active_party.is_empty():
			return
		# Clamp based on the active_party size
		selected_index = clamp(value, 0, active_party.size() - 1)
		GameEvents.selected_character_changed.emit(get_selected())

var party_gold: int = 0:
	set(value):
		party_gold = max(0, value)
		GameEvents.gold_changed.emit(party_gold)
		
var party_food: int = 5:
	set(value):
		party_food = max(0, value)
		GameEvents.food_changed.emit(party_food)

func _ready():
	reset_default_party()

func get_selected() -> ClassData:
	if active_party.is_empty():
		return null
	return active_party[selected_index]

func reset_default_party() -> void:
	active_party.clear()

	for template in DEFAULT_PARTY_TEMPLATES:
		if template == null:
			continue
		active_party.append(template.create_party_member_instance())

	selected_index = 0
