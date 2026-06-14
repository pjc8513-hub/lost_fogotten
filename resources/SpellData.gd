extends Resource
class_name SpellData

enum Element {
	FIRE,
	EARTH,
	WATER,
	ELECTRIC,
	SPIRIT,
	PHYSICAL,
	DARK,
	LIGHT
}

enum DurationMode {
	COMBAT_ROUNDS,
	WORLD_STEPS
}

@export_group("Identity")
@export var spell_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Composition")
@export var spellbook: Element = Element.FIRE
@export var element_notes: Array[Element] = []
@export_range(0, 999, 1) var mana: int = 0

@export_group("Effects")
@export_placeholder("3d8") var damage: String = ""
@export var is_aoe: bool = false
@export var is_dot: bool = false
@export var is_heal: bool = false
@export var is_buff: bool = false
@export var stats: Dictionary = {}
@export var amount: int = 0
@export_range(0, 999, 1) var duration: int = 0
@export var duration_mode: DurationMode = DurationMode.COMBAT_ROUNDS

@export_group("Special Case")
@export var special_effect: String = ""
@export_file("*.tscn") var projectile_scene_path: String = ""

func is_valid_definition() -> bool:
	return (
		not spell_id.strip_edges().is_empty()
		and not element_notes.is_empty()
		and element_notes[0] == spellbook
		and mana >= 0
	)

func matches_notes(notes: Array[int]) -> bool:
	if notes.size() != element_notes.size() or notes.is_empty():
		return false
	if notes[0] != spellbook:
		return false
	for index in notes.size():
		if notes[index] != element_notes[index]:
			return false
	return true

func get_display_name() -> String:
	return display_name if not display_name.strip_edges().is_empty() else spell_id.capitalize()

func get_damage_dice() -> Vector2i:
	var expression := damage.strip_edges().to_lower()
	var parts := expression.split("d", false, 1)
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i.ZERO
	return Vector2i(max(0, int(parts[0])), max(0, int(parts[1])))

static func element_name(element: int) -> String:
	if element < 0 or element >= Element.size():
		return "Unknown"
	return Element.keys()[element].capitalize()
