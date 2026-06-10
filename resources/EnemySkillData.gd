extends Resource
class_name EnemySkillData

enum TargetMode {
	SELF,
	SINGLE_PARTY_MEMBER,
	ALL_PARTY_MEMBERS,
	SINGLE_ENGAGED_ENEMY,
	ALL_ENGAGED_ENEMIES
}

@export var skill_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var target_mode: TargetMode = TargetMode.SINGLE_PARTY_MEMBER
@export var priority: int = 0
@export_range(0, 100, 1) var use_chance: int = 100
@export var cooldown_turns: int = 0
@export var consumes_movement: int = 1
@export var range_tiles: int = 1
@export var requires_line_of_sight: bool = true

@export_group("Damage")
@export var dice_rolls: int = 0
@export var dice_sides: int = 0
@export var bonus_damage: int = 0
@export var element: String = "physical"
@export var uses_accuracy_roll: bool = true
@export var can_crit: bool = true

@export_group("Healing")
@export var heal_rolls: int = 0
@export var heal_die_sides: int = 0
@export var bonus_healing: int = 0

@export_group("Status")
@export var status_effect: String = "none"
@export_range(0, 100, 1) var status_chance: int = 0
@export var status_duration_rounds: int = -1
@export var status_persists_after_combat: bool = true
@export var status_save_dc: int = 0

@export_group("Stat Modifiers")
@export var stat_modifiers: Dictionary = {}
@export var stat_modifier_duration_rounds: int = -1

@export_group("Presentation")
@export var cast_message: String = ""
@export_file("*.tscn") var projectile_scene_path: String = ""
@export var projectile_travel_time: float = 0.5
@export var impact_delay: float = 0.0
@export var shake_screen: bool = false
@export var shake_intensity: float = 0.08
@export var shake_decay: float = 5.0

func has_damage() -> bool:
	return dice_rolls > 0 and dice_sides > 0

func has_healing() -> bool:
	return heal_rolls > 0 and heal_die_sides > 0

func has_status() -> bool:
	return status_chance > 0 and status_effect.strip_edges().to_lower() != "none" and status_effect.strip_edges() != ""

func has_stat_modifiers() -> bool:
	return not stat_modifiers.is_empty()

func get_log_name() -> String:
	if not display_name.strip_edges().is_empty():
		return display_name
	if not skill_id.strip_edges().is_empty():
		return skill_id.capitalize()
	return "skill"
