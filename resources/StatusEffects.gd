class_name StatusEffects
extends Node

enum Type {
	NONE,
	STUN,
	CURSE,
	WEAKNESS,
	FEAR,
	PARALYZE,
	STONE_SKIN,
	FROZEN,
	CONFUSION,
	BLIND,
	DISEASE,
	POISON,
	BURN
}

# How each status is cleared. Flags are strings so they're easy to check.
const CLEAR_CONDITIONS: Dictionary = {
	Type.STUN:       ["end_of_combat"],
	Type.CURSE:      ["item", "spell", "temple", "death"],
	Type.WEAKNESS:   ["rest", "item", "temple", "spell"],
	Type.FEAR:       ["rest", "item", "temple", "death", "spell"],
	Type.PARALYZE:   ["spell", "temple", "rest", "item"],
	Type.STONE_SKIN: ["spell", "temple", "item"],
	Type.FROZEN:     ["willpower_roll", "end_of_combat"],
	Type.CONFUSION:  ["rest", "item", "spell", "temple", "death"],
	Type.BLIND:      ["spell", "item", "temple", "death"],
	Type.DISEASE:    ["spell", "item", "temple", "rest", "death"],
	Type.POISON:     ["spell", "item", "temple", "death"],
	Type.BURN:       ["rest", "spell", "item", "temple", "death"],
}

const DEFAULT_SAVE_DC := 10
const DC_PER_SOURCE_LEVEL := 1
const POISON_TICK_DAMAGE := 10
const BURN_BONUS_ROLLS := 2
const BURN_BONUS_DIE_SIZE := 8

# Stat modifiers each status applies (used by ClassData calculations)
const STAT_MODIFIERS: Dictionary = {
	Type.FEAR:    {"armor_class": 5, "accuracy": -3},
	Type.BLIND:   {"accuracy": -5},
	Type.WEAKNESS: {"might": -999},  # treated as "set to 0" in get_might()
}

# Whether a status skips the actor's turn entirely
const SKIPS_TURN: Array = [
	Type.STUN, Type.PARALYZE, Type.STONE_SKIN, Type.FROZEN
]

# Whether a status blocks spell casting
const BLOCKS_SPELLS: Array = [
	Type.CONFUSION
]

# Whether a status blocks HP healing
const BLOCKS_HEALING: Array = [
	Type.DISEASE
]

static func get_display_name(type: Type) -> String:
	return Type.keys()[type].capitalize().replace("_", " ")

static func from_string(s: String) -> Type:
	var upper := s.strip_edges().to_upper().replace(" ", "_")
	match upper:
		"PARALYSIS":
			upper = "PARALYZE"
		"FREEZE":
			upper = "FROZEN"
		"STONESKIN":
			upper = "STONE_SKIN"
	return Type.get(upper, Type.NONE) as Type

static func to_id(type: Type) -> String:
	if type == Type.NONE:
		return ""
	return Type.keys()[type].to_lower()

static func normalize_id(status_name: String) -> String:
	return to_id(from_string(status_name))

static func is_valid(status_name: String) -> bool:
	return from_string(status_name) != Type.NONE

static func has_clear_condition(status_name: String, condition: String) -> bool:
	var status_type := from_string(status_name)
	if status_type == Type.NONE:
		return false
	var conditions: Array = CLEAR_CONDITIONS.get(status_type, [])
	return conditions.has(condition)

static func skips_turn(status_name: String) -> bool:
	return SKIPS_TURN.has(from_string(status_name))

static func blocks_spells(status_name: String) -> bool:
	return BLOCKS_SPELLS.has(from_string(status_name))

static func blocks_healing(status_name: String) -> bool:
	return BLOCKS_HEALING.has(from_string(status_name))

static func stat_modifier(status_name: String, modifier_name: String) -> int:
	var modifiers: Dictionary = STAT_MODIFIERS.get(from_string(status_name), {})
	return int(modifiers.get(modifier_name, 0))

static func calculate_save_dc(base_dc: int, source_level: int = 0) -> int:
	var dc := base_dc if base_dc > 0 else DEFAULT_SAVE_DC
	return dc + max(0, source_level) * DC_PER_SOURCE_LEVEL
