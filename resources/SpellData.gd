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
@export_range(1, 99, 1) var spell_level: int = 1
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
@export var is_resurrection: bool = false
@export var remove_status_effect: String = ""
@export var stats: Dictionary = {}
@export var amount: int = 0
@export_range(0, 999, 1) var duration: int = 0
@export var duration_mode: DurationMode = DurationMode.COMBAT_ROUNDS

@export_group("Presentation")
@export_enum("none", "heal", "cleanse", "block", "debuff") var party_target_animation: String = "none"
@export_enum("none", "heal", "buff", "ui_click", "loot_pickup", "hit", "fireball", "thud") var sound_effect: String = "none"
@export_file("*.tscn") var projectile_scene_path: String = ""
@export_range(0.0, 10.0, 0.05) var projectile_travel_time: float = 0.5
@export_range(0.0, 10.0, 0.05) var impact_delay: float = 0.0
@export var shake_screen: bool = false
@export_range(0.0, 2.0, 0.01) var shake_intensity: float = 0.08
@export_range(0.01, 20.0, 0.01) var shake_decay: float = 5.0

@export_group("Special Case")
@export var special_effect: String = ""

func is_valid_definition() -> bool:
	var base_valid := (
		not spell_id.strip_edges().is_empty()
		and not element_notes.is_empty()
		and element_notes[0] == spellbook
		and mana >= 0
	)
	if not base_valid:
		return false
	return remove_status_effect.strip_edges().is_empty() or StatusEffects.is_valid(remove_status_effect)

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

func targets_party_members() -> bool:
	return is_heal or is_buff or is_resurrection or not remove_status_effect.strip_edges().is_empty()

func requires_individual_party_target() -> bool:
	return targets_party_members() and not is_aoe

func get_party_target_animation() -> String:
	if party_target_animation != "none" and not party_target_animation.strip_edges().is_empty():
		return party_target_animation
	if is_heal or is_resurrection:
		return "heal"
	if not remove_status_effect.strip_edges().is_empty():
		return "cleanse"
	return ""

func get_sound_effect() -> String:
	if sound_effect == "none":
		return ""
	return sound_effect.strip_edges()

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
