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
	Type.BURN:       [],   # passive rider — no active clearing mechanic
}

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
	return Type.get(upper, Type.NONE) as Type
