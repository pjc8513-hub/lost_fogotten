# PartyState.gd (global)
extends Node

signal roster_changed
signal active_party_changed

const DEFAULT_PARTY_TEMPLATES: Array[ClassData] = [
	preload("res://data/classes/knight.tres"),
	preload("res://data/classes/monk.tres"),
	preload("res://data/classes/cleric.tres"),
	preload("res://data/classes/rogue.tres"),
	preload("res://data/classes/sorcerer.tres")
]
const MAX_ACTIVE_PARTY_SIZE := 5

var roster: Array[ClassData] = []
var active_party: Array[ClassData] = []
var _selected_index: int = 0
var selected_index: int:
	get:
		return _selected_index
	set(value):
		_set_selected_index(value)

var party_gold: int = 0:
	set(value):
		party_gold = max(0, value)
		GameEvents.gold_changed.emit(party_gold)
		
var party_food: int = 5:
	set(value):
		party_food = max(0, value)
		GameEvents.food_changed.emit(party_food)

func _ready():
	roster.clear()
	active_party.clear()

func get_selected() -> ClassData:
	if active_party.is_empty():
		return null
	return active_party[_selected_index]

func select_member(index: int, allow_during_combat: bool = false) -> bool:
	if CombatState.is_in_combat() and not allow_during_combat:
		return false

	_set_selected_index(index)
	return true

func select_member_by_reference(member: ClassData, allow_during_combat: bool = false) -> bool:
	if member == null:
		return false

	var index := active_party.find(member)
	if index == -1:
		return false

	return select_member(index, allow_during_combat)

func reset_default_party() -> void:
	roster.clear()
	active_party.clear()

	for template in DEFAULT_PARTY_TEMPLATES:
		if template == null:
			continue
		var member := template.create_party_member_instance()
		roster.append(member)
		active_party.append(member)

	_emit_party_state_changed()
	
func get_active_party() -> Array[ClassData]:
	return active_party

func get_roster() -> Array[ClassData]:
	return roster

func add_roster_member(member: ClassData, add_to_party: bool = false) -> bool:
	if member == null or roster.has(member):
		return false

	roster.append(member)
	var added_to_party := false
	if add_to_party:
		added_to_party = add_member_to_party(member)

	roster_changed.emit()
	if not added_to_party:
		_normalize_selected_index()
	return true

func add_member_to_party(member: ClassData) -> bool:
	if member == null:
		return false
	if not roster.has(member):
		roster.append(member)
		roster_changed.emit()
	if active_party.has(member) or active_party.size() >= MAX_ACTIVE_PARTY_SIZE:
		return false

	active_party.append(member)
	_emit_party_state_changed()
	return true

func remove_member_from_party(member: ClassData) -> bool:
	if not active_party.has(member):
		return false

	active_party.erase(member)
	_emit_party_state_changed()
	return true

func delete_roster_member(member: ClassData) -> bool:
	if member == null or not roster.has(member):
		return false

	active_party.erase(member)
	roster.erase(member)
	_emit_party_state_changed()
	return true

func is_member_in_party(member: ClassData) -> bool:
	return active_party.has(member)

func is_party_full() -> bool:
	return active_party.size() >= MAX_ACTIVE_PARTY_SIZE

func can_set_out() -> bool:
	return not active_party.is_empty()

func clear_all_party_data() -> void:
	roster.clear()
	active_party.clear()
	_emit_party_state_changed()

func _emit_party_state_changed() -> void:
	roster_changed.emit()
	active_party_changed.emit()
	_normalize_selected_index()

func _normalize_selected_index() -> void:
	if active_party.is_empty():
		_selected_index = 0
		GameEvents.selected_character_changed.emit(null)
		return
	_selected_index = clamp(_selected_index, 0, active_party.size() - 1)
	GameEvents.selected_character_changed.emit(get_selected())

func _set_selected_index(value: int) -> void:
	if active_party.is_empty():
		_selected_index = 0
		GameEvents.selected_character_changed.emit(null)
		return

	_selected_index = clamp(value, 0, active_party.size() - 1)
	GameEvents.selected_character_changed.emit(get_selected())
	
	# Environmental damage
	# Inside PartyState.gd

## Picks one random living party member and applies the damage to them
func damage_random_member(amount: int) -> String:
	var living_members = []
	
	for member in active_party:
		if member.class_data and member.class_data.current_hp > 0:
			living_members.append(member)
			
	if living_members.size() > 0:
		var target = living_members.pick_random()
		target.class_data.take_damage(amount)
		return target.character_name # Returns name so you can print it in a log
		
	return ""
