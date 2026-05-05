extends Resource
class_name SpellResult

var spell_data: SpellData = null
var element_rolls := {}
var mana_cost: int = 0
var chord_fail_chance: int = 0
var chord_success_chance: int = 0
var splash_entries: Array[String] = []
var chord_entries: Array[Dictionary] = []
var notes: Array[String] = []

func has_output() -> bool:
	return not element_rolls.is_empty() or not chord_entries.is_empty()

