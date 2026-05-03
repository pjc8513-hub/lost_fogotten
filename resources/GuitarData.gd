class_name GuitarData extends ItemData

enum Company {
	Arthur,
	THRONE,
	DE,
	WinterWizard,
	Pan,
	OMalley
}

enum Element { 
	PHYSICAL,
	FIRE, 
	ICE, 
	ELECTRIC, 
	EARTH, 
	SPIRIT, 
	LIGHT, 
	DARK
	}

@export var company: Company
@export var guitar_name: String = "6-String Ironclad"
@export var min_strings: int = 3
@export var max_strings: int = 8
@export var string_elements: Array[Element] # [FIRE, ICE, EARTH, LIGHT, SPIRIT, DARK]
@export var step_count: int = 6 # your columns
@export var complexity: int = 6
@export var tuning_modifiers: Dictionary # optional: {"DARK": -1} pitch shift per string
@export var loot_table: LootManager.Loot_Table

var rolled_string_count: int = 0
var rolled_string_elements: Array[Element] = []

func roll_strings() -> void:
	var available_elements := _get_unique_element_pool()
	if available_elements.is_empty():
		available_elements = _get_all_elements()

	var clamped_max = max(1, min(max_strings, available_elements.size()))
	var clamped_min = clamp(min_strings, 1, clamped_max)
	var string_count = clamped_min if clamped_min >= clamped_max else randi_range(clamped_min, clamped_max)

	available_elements.shuffle()
	rolled_string_count = string_count
	rolled_string_elements.clear()

	for i in string_count:
		rolled_string_elements.append(available_elements[i])

func get_active_string_count() -> int:
	if rolled_string_count > 0:
		return rolled_string_count
	var defined_count := string_elements.size()
	if defined_count > 0:
		return defined_count
	return clamp(min_strings, 1, max(max_strings, 1))

func get_active_string_elements() -> Array[Element]:
	if not rolled_string_elements.is_empty():
		return rolled_string_elements.duplicate()

	var defined_elements := _get_unique_element_pool()
	if not defined_elements.is_empty():
		return defined_elements

	var fallback_elements := _get_all_elements()
	var active_count = min(get_active_string_count(), fallback_elements.size())
	return fallback_elements.slice(0, active_count)

func _get_unique_element_pool() -> Array[Element]:
	var unique_elements: Array[Element] = []
	for element in string_elements:
		if unique_elements.has(element):
			continue
		unique_elements.append(element)
	return unique_elements

func _get_all_elements() -> Array[Element]:
	var all_elements: Array[Element] = []
	for value in Element.values():
		all_elements.append(value)
	return all_elements
