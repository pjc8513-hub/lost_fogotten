# SkillData.gd
extends Resource
class_name SkillData

enum SkillType {
	PASSIVE_STAT,       # Modifies derived stats (Stage Presence)
	PASSIVE_GAMEPLAY,   # Hooks into specific game events (Experienced)
	ACTIVE_COMBAT,      # Grants a usable combat ability (Quick Step)
}

enum Element { 
	NONE,
	PHYSICAL,
	FIRE, 
	WATER, 
	ELECTRIC, 
	EARTH, 
	SPIRIT, 
	LIGHT, 
	DARK
	}

@export var skill_id: String = ""           # Unique key, matches learned_skills entries
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var skill_type: SkillType = SkillType.PASSIVE_STAT

@export var available_classes: Array[ClassData.Class_Names] = []
@export var max_rank: int = 4
@export var class_max_rank_overrides: Dictionary = {}

@export var min_level: int = 1

# Stat modifier fields (for PASSIVE_STAT skills)
# These get added in ClassData._calculate_* methods
@export var hp_per_level_bonus: float = 0.0   # e.g. Stage Presence: 3.5 avg
@export var mp_per_level_bonus: float = 0.0
@export var accuracy_bonus: int = 0
@export var initiative_bonus: int = 0
@export var movement_bonus: int = 0           # permanent movement increase
@export var element_mastery: Element
@export var complexity_bonus: int = 0
@export var extra_damage_roll: int = 0
@export var status_immunities: Array[String] = []
# ...extend as needed

# Base values per level (Can multiply these by the current level rank)
@export var hp_per_level_increment: float = 0.0
@export var mp_per_level_increment: float = 0.0
@export var accuracy_increment: int = 0
@export var movement_increment: int = 0


# Learning chance
@export var base_learn_chance: int = 5        # % at min_level
@export var chance_per_level: int = 5         # % added per level above min
@export var wisdom_scale: float = 0.5         # extra % per point of wisdom modifier

func get_max_rank_for_class(class_id: ClassData.Class_Names) -> int:
	var resolved_max = max(0, max_rank)
	var class_key := ClassData.get_class_display_name(class_id)
	var possible_keys: Array = [
		class_id,
		str(class_id),
		class_key,
		class_key.to_lower(),
		class_key.to_upper(),
	]

	for key in possible_keys:
		if class_max_rank_overrides.has(key):
			return clampi(int(class_max_rank_overrides[key]), 0, resolved_max)

	for raw_key in class_max_rank_overrides.keys():
		if String(raw_key).strip_edges().to_lower() == class_key.to_lower():
			return clampi(int(class_max_rank_overrides[raw_key]), 0, resolved_max)

	return resolved_max
