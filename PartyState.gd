# PartyState.gd (global)
extends Node

# Type-hinting the array ensures only ClassData resources can be added
var active_party: Array[ClassData] = [
	preload("res://data/classes/knight.tres"),
	preload("res://data/classes/monk.tres"),
	preload("res://data/classes/cleric.tres"),
	preload("res://data/classes/rogue.tres"),
	preload("res://data/classes/sorcerer.tres")
]

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
	# Emit initial selection signal if the party isn't empty
	if not active_party.is_empty():
		GameEvents.selected_character_changed.emit(get_selected())

func get_selected() -> ClassData:
	if active_party.is_empty():
		return null
	return active_party[selected_index]
