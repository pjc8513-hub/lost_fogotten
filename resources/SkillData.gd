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
	ICE, 
	ELECTRIC, 
	EARTH, 
	SPIRIT, 
	LIGHT, 
	DARK
	}

@export var skill_id: String = ""           # Unique key, matches learned_skills entries
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var skill_type: SkillType = SkillType.PASSIVE_STAT

@export var available_classes: Array[ClassData.Class_Names] = []
@export var min_level: int = 1

# Stat modifier fields (for PASSIVE_STAT skills)
# These get added in ClassData._calculate_* methods
@export var hp_per_level_bonus: float = 0.0   # e.g. Stage Presence: 3.5 avg
@export var mp_per_level_bonus: float = 0.0
@export var accuracy_bonus: int = 0
@export var initiative_bonus: int = 0
@export var movement_bonus: int = 0           # permanent movement increase
@export var element_mastery: Element
@export var precision: float = 0.0
# ...extend as needed

# Learning chance
@export var base_learn_chance: int = 5        # % at min_level
@export var chance_per_level: int = 5         # % added per level above min
@export var wisdom_scale: float = 0.5         # extra % per point of wisdom modifier
