extends Node

const BASE_CHORD_FAIL_CHANCE := 70
const BASE_CHORD_SUCCESS_CHANCE := 30

const ELEMENT_RULES := {
	GuitarData.Element.FIRE: {"name": "Fire", "die": 6, "mana": 3, "splash": true},
	GuitarData.Element.ICE: {"name": "Ice", "die": 4, "mana": 2, "splash": false},
	GuitarData.Element.ELECTRIC: {"name": "Electric", "die": 8, "mana": 4, "splash": false},
	GuitarData.Element.EARTH: {"name": "Earth", "die": 5, "mana": 3, "splash": false},
	GuitarData.Element.DARK: {"name": "Dark", "die": 6, "mana": 3, "splash": false},
	GuitarData.Element.LIGHT: {"name": "Light", "die": 5, "mana": 2, "splash": false},
	GuitarData.Element.PHYSICAL: {"name": "Physical", "die": 5, "mana": 2, "splash": false},
	GuitarData.Element.SPIRIT: {"name": "Spirit", "die": 3, "mana": 3, "splash": false, "healing": true},
}

const DISSONANT_CHORDS := {
	"4:3": true,
	"6:7": true,
	"1:2": true,
	"0:5": true,
}

func build_spell_data(caster: ClassData, guitar: GuitarData, sequence_grid: Array[Array], complexity_limit: int = 0) -> SpellData:
	var spell_data := SpellData.new()
	spell_data.caster = caster
	spell_data.guitar = guitar
	spell_data.guitar_name = guitar.guitar_name if guitar != null else ""
	spell_data.step_count = 0 if sequence_grid.is_empty() else sequence_grid[0].size()
	spell_data.string_count = sequence_grid.size()
	spell_data.complexity_limit = complexity_limit

	if guitar != null:
		for element in guitar.get_active_string_elements():
			spell_data.string_elements.append(element)

	for row in sequence_grid:
		var row_copy: Array = []
		for value in row:
			row_copy.append(bool(value))
			if bool(value):
				spell_data.filled_slots += 1
		spell_data.sequence_grid.append(row_copy)

	return spell_data

func resolve_spell_preview(spell_data: SpellData) -> SpellResult:
	var result := SpellResult.new()
	result.spell_data = spell_data
	result.chord_success_chance = _get_chord_success_chance(spell_data)
	result.chord_fail_chance = 100 - result.chord_success_chance

	if spell_data == null or spell_data.guitar == null:
		return result

	var element_counts := {}
	var chord_counts := {}

	for step_index in spell_data.step_count:
		var active_elements := _get_step_elements(spell_data, step_index)
		var remaining_elements := _remove_dissonant_pairs(active_elements)

		for element in remaining_elements:
			element_counts[element] = int(element_counts.get(element, 0)) + 1

		for chord in ChordRegistry.get_matching_chords(remaining_elements):
			if chord == null:
				continue
			var chord_name := chord.display_name
			if not chord_counts.has(chord_name):
				chord_counts[chord_name] = {
					"count": 0,
					"data": chord,
				}
			chord_counts[chord_name]["count"] = int(chord_counts[chord_name]["count"]) + 1

	for element in ELEMENT_RULES.keys():
		var base_rolls := int(element_counts.get(element, 0))
		var bonus_rolls := 0 if base_rolls <= 0 else _get_element_roll_bonus(spell_data, element)
		var total_rolls = max(0, base_rolls + bonus_rolls)
		if total_rolls <= 0:
			continue

		var rule: Dictionary = ELEMENT_RULES[element]
		result.element_rolls[element] = {
			"name": rule["name"],
			"die": int(rule["die"]),
			"rolls": total_rolls,
			"mana_per_roll": int(rule["mana"]),
			"healing": bool(rule.get("healing", false)),
			"splash": bool(rule.get("splash", false)),
			"base_rolls": base_rolls,
			"bonus_rolls": bonus_rolls,
		}
		result.mana_cost += total_rolls * int(rule["mana"])

		if bool(rule.get("splash", false)) and total_rolls >= 4:
			result.splash_entries.append("%s Splash: 1d6 adjacent enemies" % rule["name"])

	var chord_names := chord_counts.keys()
	chord_names.sort()
	for chord_name in chord_names:
		var chord_entry: Dictionary = chord_counts[chord_name]
		var chord_data := chord_entry.get("data") as ChordData
		var count := int(chord_entry.get("count", 0))
		if count <= 0:
			continue

		result.chord_entries.append({
			"name": chord_name,
			"count": count,
			"data": chord_data,
			"summary": chord_data.get_summary_text() if chord_data != null else "",
		})

		if chord_data != null:
			result.mana_cost += chord_data.extra_mana_cost * count

	return result

func format_preview_lines(result: SpellResult) -> Dictionary:
	var output := {
		"element_lines": [],
		"extra_lines": [],
		"chord_lines": [],
		"mana": 0,
	}

	if result == null:
		return output

	output["mana"] = result.mana_cost

	var element_lines: Array[String] = []
	var extra_lines: Array[String] = []
	var chord_lines: Array[String] = []

	for element in ELEMENT_RULES.keys():
		if not result.element_rolls.has(element):
			continue
		var roll_data: Dictionary = result.element_rolls[element]
		var bonus_text := ""
		var bonus_rolls := int(roll_data.get("bonus_rolls", 0))
		if bonus_rolls > 0:
			bonus_text = " (+%s)" % bonus_rolls
		elif bonus_rolls < 0:
			bonus_text = " (%s)" % bonus_rolls

		if bool(roll_data.get("healing", false)):
			element_lines.append("%s: Heals each party member %sd%s%s" % [
				roll_data["name"],
				roll_data["rolls"],
				roll_data["die"],
				bonus_text,
			])
		else:
			element_lines.append("%s: %sd%s%s" % [
				roll_data["name"],
				roll_data["rolls"],
				roll_data["die"],
				bonus_text,
			])

	for splash_entry in result.splash_entries:
		extra_lines.append(splash_entry)

	for chord_entry in result.chord_entries:
		var count_text := "" if int(chord_entry["count"]) == 1 else " x%s" % chord_entry["count"]
		var summary := String(chord_entry.get("summary", ""))
		var extra_text := "" if summary.is_empty() else " - %s" % summary
		chord_lines.append("%s%s (%s%% fail / %s%% success)%s" % [
			chord_entry["name"],
			count_text,
			result.chord_fail_chance,
			result.chord_success_chance,
			extra_text
		])

	output["element_lines"] = element_lines
	output["extra_lines"] = extra_lines
	output["chord_lines"] = chord_lines
	return output

func _get_step_elements(spell_data: SpellData, step_index: int) -> Array[int]:
	var active_elements: Array[int] = []
	for row_index in spell_data.sequence_grid.size():
		if spell_data.sequence_grid[row_index][step_index]:
			active_elements.append(spell_data.string_elements[row_index])
	return active_elements

func _remove_dissonant_pairs(active_elements: Array[int]) -> Array[int]:
	var remaining_elements := active_elements.duplicate()
	for pair_key in DISSONANT_CHORDS.keys():
		var pair := _parse_pair_key(pair_key)
		if remaining_elements.has(pair[0]) and remaining_elements.has(pair[1]):
			remaining_elements.erase(pair[0])
			remaining_elements.erase(pair[1])
	return remaining_elements

func _parse_pair_key(pair_key: String) -> Array[int]:
	var values := pair_key.split(":")
	return [int(values[0]), int(values[1])]

func _get_chord_success_chance(spell_data: SpellData) -> int:
	var caster := spell_data.caster if spell_data != null else null
	var precision_bonus := 0 if caster == null else caster.get_spell_precision_bonus()
	return clamp(BASE_CHORD_SUCCESS_CHANCE + precision_bonus, 0, 100)

func _get_element_roll_bonus(spell_data: SpellData, element: int) -> int:
	var caster := spell_data.caster if spell_data != null else null
	if caster == null:
		return 0
	return caster.get_spell_element_roll_bonus(element)
