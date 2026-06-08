# ClassData.gd

extends Resource
class_name ClassData

enum Class_Names {
	UNKNOWN = -1,
	KNIGHT,
	BARBARIAN,
	CLERIC,
	BARD,
	SORCERER,
	ROGUE,
	RANGER,
	DRUID,
	MONK
}

const BASE_ARMOR_CLASS := 10
const DEFAULT_STARTING_MIGHT := 10
const DEFAULT_STARTING_DEXTERITY := 10
const DEFAULT_STARTING_ENDURANCE := 10
const DEFAULT_STARTING_WISDOM := 10
const BASE_XP_TO_NEXT_LEVEL := 100
const BOW_MASTERY_CRITICAL_CHANCE_BONUS := 10
const BLADE_MASTERY_ATTACK_SPEED_BONUS := 2
const AXE_MASTERY_MIGHT_BONUS := 20
const STAFF_MASTERY_MAGIC_AMP_BONUS := 10
const PRIMARY_STAT_FIELDS := {
	"Might": "base_might",
	"Endurance": "base_endurance",
	"Wisdom": "base_wisdom",
	"Dexterity": "base_dexterity",
}
const CLASS_TEMPLATE_PATHS := {
	Class_Names.KNIGHT: "res://data/classes/knight.tres",
	Class_Names.CLERIC: "res://data/classes/cleric.tres",
	Class_Names.SORCERER: "res://data/classes/sorcerer.tres",
	Class_Names.ROGUE: "res://data/classes/rogue.tres",
	Class_Names.MONK: "res://data/classes/monk.tres",
}
const CLASS_STAT_MAP = {
	Class_Names.KNIGHT: {
		"base_might": 12, "base_end": 12, "base_wis": 6, "base_dex": 8,
		"hp_base": 15, "hp_per_level": 8, "hp_might_scale": 1.3, "hp_end_scale": 1.8,
		"mp_base": 3, "mp_per_level": 1, "mp_wis_scale": 0.8,
		"ac_bonus": -2, "ac_dex_scale": 0.5,
		"accuracy_base": 2, "accuracy_might_scale": 1.0, "accuracy_dex_scale": 0.5,
		"crit_base": 2, "crit_dex_scale": 0.5,
		"initiative_base": 0, "initiative_dex_scale": 0.5,
		"attack_speed_base": 0, "attack_speed_dex_scale": 0.35,
		"bonus_damage_base": 1, "damage_might_scale": 1.0,
		"magic_amp": 0, "magic_amp_wis_scale": 0,
		"movement": 4, "allowed_armor_types": [ArmorData.Armor_Type.LIGHT, ArmorData.Armor_Type.MEDIUM, ArmorData.Armor_Type.HEAVY],
		"skill_bonuses": {"leadership": 1}
	},
	Class_Names.BARBARIAN: {
		"base_might": 14, "base_end": 12, "base_wis": 4, "base_dex": 8,
		"hp_base": 18, "hp_per_level": 10, "hp_might_scale": 1.7, "hp_end_scale": 1.9,
		"mp_base": 0, "mp_per_level": 0, "mp_wis_scale": 0.0,
		"ac_bonus": 0, "ac_dex_scale": 0.35,
		"accuracy_base": 1, "accuracy_might_scale": 1.15, "accuracy_dex_scale": 0.35,
		"crit_base": 1, "crit_dex_scale": 0.35,
		"initiative_base": -1, "initiative_dex_scale": 0.35,
		"attack_speed_base": 0, "attack_speed_dex_scale": 0.25,
		"bonus_damage_base": 3, "damage_might_scale": 1.35,
		"magic_amp": 0, "magic_amp_wis_scale": 0,
		"movement": 4, "allowed_armor_types": [ArmorData.Armor_Type.LIGHT, ArmorData.Armor_Type.MEDIUM],
		"skill_bonuses": {"athletics": 2}
	},
	Class_Names.CLERIC: {
		"base_might": 9, "base_end": 10, "base_wis": 12, "base_dex": 8,
		"hp_base": 12, "hp_per_level": 6, "hp_might_scale": 0.8, "hp_end_scale": 1.4,
		"mp_base": 10, "mp_per_level": 5, "mp_wis_scale": 1.6,
		"ac_bonus": -1, "ac_dex_scale": 0.5,
		"accuracy_base": 0, "accuracy_might_scale": 0.65, "accuracy_dex_scale": 0.4, "accuracy_wis_scale": 0.5,
		"crit_base": 1, "crit_dex_scale": 0.3, "crit_wis_scale": 0.2,
		"initiative_base": 0, "initiative_dex_scale": 0.45,
		"attack_speed_base": 0, "attack_speed_dex_scale": 0.25,
		"bonus_damage_base": 0, "damage_might_scale": 0.55, "damage_wis_scale": 0.3,
		"magic_amp": 0, "magic_amp_wis_scale": 0.2,
		"movement": 4, "allowed_armor_types": [ArmorData.Armor_Type.LIGHT, ArmorData.Armor_Type.MEDIUM],
		"skill_bonuses": {"medicine": 2, "lore": 1}
	},
	Class_Names.BARD: {
		"base_might": 7, "base_end": 8, "base_wis": 11, "base_dex": 10,
		"hp_base": 10, "hp_per_level": 5, "hp_might_scale": 0.6, "hp_end_scale": 1.0,
		"mp_base": 9, "mp_per_level": 4, "mp_wis_scale": 1.5,
		"ac_bonus": 0, "ac_dex_scale": 0.75,
		"accuracy_base": 0, "accuracy_might_scale": 0.35, "accuracy_dex_scale": 0.55, "accuracy_wis_scale": 0.4,
		"crit_base": 2, "crit_dex_scale": 0.45,
		"initiative_base": 1, "initiative_dex_scale": 0.55, "initiative_wis_scale": 0.25,
		"attack_speed_base": 1, "attack_speed_dex_scale": 0.35,
		"bonus_damage_base": 0, "damage_might_scale": 0.35,
		"magic_amp": 0, "magic_amp_wis_scale": 0.1,
		"movement": 5, "allowed_armor_types": [ArmorData.Armor_Type.LIGHT],
		"skill_bonuses": {"lore": 2, "perception": 1, "leadership": 1}
	},
	Class_Names.SORCERER: {
		"base_might": 5, "base_end": 6, "base_wis": 14, "base_dex": 9,
		"hp_base": 8, "hp_per_level": 4, "hp_might_scale": 0.35, "hp_end_scale": 0.95,
		"mp_base": 16, "mp_per_level": 7, "mp_wis_scale": 2.2,
		"ac_bonus": 1, "ac_dex_scale": 0.6,
		"accuracy_base": -1, "accuracy_might_scale": 0.2, "accuracy_dex_scale": 0.4, "accuracy_wis_scale": 0.65,
		"crit_base": 1, "crit_dex_scale": 0.25, "crit_wis_scale": 0.3,
		"initiative_base": 0, "initiative_dex_scale": 0.5, "initiative_wis_scale": 0.2,
		"attack_speed_base": 0, "attack_speed_dex_scale": 0.2,
		"bonus_damage_base": 0, "damage_wis_scale": 0.4,
		"magic_amp": 0, "magic_amp_wis_scale": 0.4,
		"movement": 4, "allowed_armor_types": [ArmorData.Armor_Type.LIGHT],
		"skill_bonuses": {"lore": 2, "perception": 1}
	},
	Class_Names.ROGUE: {
		"base_might": 8, "base_end": 8, "base_wis": 6, "base_dex": 13,
		"hp_base": 10, "hp_per_level": 5, "hp_might_scale": 0.6, "hp_end_scale": 1.0,
		"mp_base": 0, "mp_per_level": 0, "mp_wis_scale": 0.0,
		"ac_bonus": 1, "ac_dex_scale": 1.6,
		"accuracy_base": 1, "accuracy_might_scale": 0.35, "accuracy_dex_scale": 1.0,
		"crit_base": 5, "crit_dex_scale": 1.2,
		"initiative_base": 3, "initiative_dex_scale": 1.1,
		"attack_speed_base": 3, "attack_speed_dex_scale": 0.9,
		"bonus_damage_base": 0, "damage_might_scale": 0.25, "damage_dex_scale": 0.45,
		"magic_amp": 0, "magic_amp_wis_scale": 0,
		"movement": 5, "allowed_armor_types": [ArmorData.Armor_Type.LIGHT],
		"skill_bonuses": {"lockpicking": 2, "thievery": 1, "reflex": 1}
	},
	Class_Names.RANGER: {
		"base_might": 9, "base_end": 9, "base_wis": 8, "base_dex": 12,
		"hp_base": 11, "hp_per_level": 6, "hp_might_scale": 0.75, "hp_end_scale": 1.2,
		"mp_base": 4, "mp_per_level": 2, "mp_wis_scale": 0.7,
		"ac_bonus": 0, "ac_dex_scale": 1.1,
		"accuracy_base": 1, "accuracy_might_scale": 0.35, "accuracy_dex_scale": 0.95,
		"crit_base": 4, "crit_dex_scale": 0.95,
		"initiative_base": 2, "initiative_dex_scale": 0.9,
		"attack_speed_base": 1, "attack_speed_dex_scale": 0.55,
		"bonus_damage_base": 0, "damage_might_scale": 0.45, "damage_dex_scale": 0.35,
		"magic_amp": 0, "magic_amp_wis_scale": 0.15,
		"movement": 6, "allowed_armor_types": [ArmorData.Armor_Type.LIGHT, ArmorData.Armor_Type.MEDIUM],
		"skill_bonuses": {"perception": 2, "survival": 2}
	},
	Class_Names.DRUID: {
		"base_might": 7, "base_end": 8, "base_wis": 14, "base_dex": 8,
		"hp_base": 11, "hp_per_level": 5, "hp_might_scale": 0.5, "hp_end_scale": 1.1,
		"mp_base": 18, "mp_per_level": 7, "mp_wis_scale": 2.4,
		"ac_bonus": 0, "ac_dex_scale": 0.55,
		"accuracy_base": -1, "accuracy_might_scale": 0.25, "accuracy_dex_scale": 0.35, "accuracy_wis_scale": 0.65,
		"crit_base": 1, "crit_dex_scale": 0.25, "crit_wis_scale": 0.25,
		"initiative_base": 0, "initiative_dex_scale": 0.45, "initiative_wis_scale": 0.25,
		"attack_speed_base": 0, "attack_speed_dex_scale": 0.2,
		"bonus_damage_base": 0, "damage_wis_scale": 0.45,
		"magic_amp": 0, "magic_amp_wis_scale": 0.3,
		"movement": 5, "allowed_armor_types": [ArmorData.Armor_Type.LIGHT, ArmorData.Armor_Type.MEDIUM],
		"skill_bonuses": {"medicine": 1, "lore": 2, "survival": 1}
	},
	Class_Names.MONK: {
		"base_might": 9, "base_end": 10, "base_wis": 11, "base_dex": 12,
		"hp_base": 12, "hp_per_level": 6, "hp_might_scale": 0.7, "hp_end_scale": 1.3,
		"mp_base": 5, "mp_per_level": 3, "mp_wis_scale": 1.0,
		"ac_bonus": 0, "ac_dex_scale": 1.3, "ac_wis_scale": 0.6,
		"accuracy_base": 1, "accuracy_might_scale": 0.35, "accuracy_dex_scale": 0.8, "accuracy_wis_scale": 0.35,
		"crit_base": 3, "crit_dex_scale": 0.7, "crit_wis_scale": 0.2,
		"initiative_base": 2, "initiative_dex_scale": 0.8, "initiative_wis_scale": 0.2,
		"attack_speed_base": 2, "attack_speed_dex_scale": 0.7,
		"bonus_damage_base": 1, "damage_might_scale": 0.35, "damage_dex_scale": 0.25, "damage_wis_scale": 0.2,
		"magic_amp": 0, "magic_amp_wis_scale": 0.2,
		"movement": 5, "allowed_armor_types": [ArmorData.Armor_Type.LIGHT],
		"skill_bonuses": {"medicine": 1, "discipline": 2}
	},
}

@export var class_names: Class_Names = Class_Names.UNKNOWN
@export var member_name: String = ""
@export var row: int = 0

@export_group("Vitals")
@export var max_hp: int = 0
@export var max_mp: int = 0
@export var status_effects: Array[String] = []
@export var current_hp: int = 0:
	set(value):
		current_hp = clamp(value, 0, get_max_hp())
		# Alert the UI that this specific resource changed
		_emit_stats_changed()
			
@export var current_mp: int = 0:
	set(value):
		current_mp = clamp(value, 0, get_max_mp())
		# Alert the UI that this specific resource changed
		_emit_stats_changed()
			
@export_group("Derived Cache")
@export var armor_class: int = 0
@export var accuracy: int = 0   # cached derived value for UI/debugging
@export var critical_chance: int = 0
@export var attack_speed: int = 0
@export var initiative: int = 0
@export var bonus_damage: int = 0

@export_group("Primary Stats")
@export var level: int = 1
@export var base_might: int = 0
@export var base_endurance: int = 0
@export var base_wisdom: int = 0
@export var base_dexterity: int = 0

@export_group("Legacy Stats")
@export var might: int = 0
@export var endurance: int = 0
@export var wisdom: int = 0
@export var dexterity: int = 0

@export_group("Bonuses")
@export var base_armor_class_bonus: int = 0
@export var base_accuracy_bonus: int = 0
@export var base_critical_chance_bonus: int = 0
@export var base_attack_speed_bonus: int = 0
@export var base_initiative_bonus: int = 0
@export var base_bonus_damage_bonus: int = 0
@export var bonus_might: int = 0
@export var bonus_endurance: int = 0
@export var bonus_wisdom: int = 0
@export var bonus_dexterity: int = 0
@export var bonus_max_hp: int = 0
@export var bonus_max_mp: int = 0

# Inside ClassData.gd

# Change your progression group:
@export_group("Progression")
@export var SkillLevel: int = 1
@export var xp: int = 0
@export var xp_to_next_level = BASE_XP_TO_NEXT_LEVEL
@export var available_points = 0
@export var available_skill_points = 0

# Stored as {"skill_id": level_int} (e.g. {"arms_master": 0, "quick_step": 1, "sword_mastery": 3})
@export var learned_skills: Dictionary = {} 

# -- Might & Magic style Learning Methods --

func teach_skill_by_npc(skill_id: String) -> bool:
	if not learned_skills.has(skill_id):
		learned_skills[skill_id] = 1 # Unlock skill at level 1
		recalculate_derived_stats(false)
		return true
	return false

func upgrade_skill(skill_id: String) -> bool:
	if available_skill_points <= 0 or not learned_skills.has(skill_id):
		return false
		
	var skill_res = SkillRegistry.get_skill(skill_id)
	if skill_res and learned_skills[skill_id] < skill_res.max_rank:
		available_skill_points -= 1
		learned_skills[skill_id] += 1
		recalculate_derived_stats(false)
		return true
	return false

# Override the legacy has_skill check
func has_skill(skill_id: String) -> bool:
	var normalized := skill_id.to_lower()
	return (
		learned_skills.has(skill_id) and learned_skills[skill_id] > 0
	) or (
		learned_skills.has(normalized) and learned_skills[normalized] > 0
	)

func get_skill_rank(skill_id: String) -> int:
	print("get_skill_rank skill rank: ",learned_skills.get(skill_id, 0))
	return learned_skills.get(skill_id, 0)

# Accumulate the scalable bonuses inside your existing mathematical loops:
func _get_skill_stat_bonus(stat: String) -> float:
	var total := 0.0
	for skill_id in learned_skills.keys():
		var rank = learned_skills[skill_id]
		if rank <= 0: continue
		
		var skill := SkillRegistry.get_skill(skill_id)
		if skill != null:
			# If your skill properties match the stat name + "_increment"
			var field_name = stat + "_increment"
			var bonus_value = skill.get(field_name)
			if bonus_value != null:
				total += float(bonus_value) * rank
	return total

@export_group("Presentation")
@export var sprite_texture: Texture2D

@export_group("Resistances")
@export var resist_fire: int = 0
@export var resist_cold: int = 0
@export var resist_dark: int = 0

@export_group("Combat")
@export var movement: int = 5
@export var cooldown: int = 0
var quick_step_used: bool = false
var suppress_stat_signal: bool = false
var combat_buffs: Dictionary = {}
var status_metadata: Dictionary = {}

@export var dice_sides: int = 4
@export var dice_rolls: int = 1

@export var inventory: Array[ItemInstance] = []

func get_primary_stats() -> Dictionary:
	return {
		"Might": get_might(),
		"Endurance": get_endurance(),
		"Wisdom": get_wisdom(),
		"Dexterity": get_dexterity(),
	}

func get_derived_stats() -> Dictionary:
	return {
		"Level": level,
		"Max HP": get_max_hp(),
		"Max MP": get_max_mp(),
		"Damage Mod": get_damage_modifier(),
		"Magic Amp": get_magic_amp(),
		"Armor Class": get_armor_class(),
		"Accuracy": get_accuracy(),
		"Critical Chance": get_critical_chance(),
		"Critical Amp": get_critical_amp(),
		"Counter Chance": get_counter_chance(),
		"Initiative": get_initiative(),
		"Attack Speed": get_attack_speed_bonus(),
		"Movement": get_movement(),
	}

func initialize_from_class_map(reset_vitals: bool = true) -> void:
	var resolved_class := get_resolved_class_name()
	var class_stats: Dictionary = CLASS_STAT_MAP.get(resolved_class, {})

	if class_stats.is_empty():
		push_warning("No class stat map found for %s on %s" % [str(class_names), member_name])
		return

	_migrate_legacy_fields(class_stats)
	recalculate_derived_stats(reset_vitals)

func create_party_member_instance() -> ClassData:
	var member := duplicate(true) as ClassData
	member.status_effects = []
	member.cooldown = 0
	member.initialize_from_class_map(true)
	return member

static func create_custom_member(class_id: Class_Names, member_name_value: String, base_stats: Dictionary = {}, silent: bool = false) -> ClassData:
	var template_path: String = CLASS_TEMPLATE_PATHS.get(class_id, "")
	var member: ClassData = null

	if template_path != "":
		var template := load(template_path) as ClassData
		if template != null:
			if silent:
				member = template.duplicate(true) as ClassData
				member.status_effects = []
				member.cooldown = 0
			else:
				member = template.create_party_member_instance()

	if member == null:
		member = ClassData.new()

	member.suppress_stat_signal = silent
	member.class_names = class_id
	member.member_name = member_name_value.strip_edges()
	member.level = 1
	member.xp = 0
	member.xp_to_next_level = BASE_XP_TO_NEXT_LEVEL
	member.available_points = 0
	member.available_skill_points = 0
	member.learned_skills = {}
	member.status_effects = []
	member.cooldown = 0

	member.base_might = int(base_stats.get("might", base_stats.get("Might", member.base_might)))
	member.base_endurance = int(base_stats.get("endurance", base_stats.get("Endurance", member.base_endurance)))
	member.base_wisdom = int(base_stats.get("wisdom", base_stats.get("Wisdom", member.base_wisdom)))
	member.base_dexterity = int(base_stats.get("dexterity", base_stats.get("Dexterity", member.base_dexterity)))

	member.initialize_from_class_map(true)
	member.suppress_stat_signal = false
	return member

static func get_class_display_name(class_id: Class_Names) -> String:
	for key in Class_Names.keys():
		if Class_Names[key] == class_id:
			return String(key).capitalize()
	return "Unknown"

func get_resolved_class_name() -> Class_Names:
	if class_names != Class_Names.UNKNOWN:
		return class_names
	return _infer_class_name_from_resource()

func get_class_display_name_value() -> String:
	return get_class_display_name(get_resolved_class_name())

func _infer_class_name_from_resource() -> Class_Names:
	var resource_name := String(resource_path.get_file().get_basename()).to_lower()
	match resource_name:
		"knight":
			return Class_Names.KNIGHT
		"barbarian":
			return Class_Names.BARBARIAN
		"cleric":
			return Class_Names.CLERIC
		"bard":
			return Class_Names.BARD
		"sorcerer", "mage":
			return Class_Names.SORCERER
		"rogue", "thief":
			return Class_Names.ROGUE
		"ranger":
			return Class_Names.RANGER
		"druid":
			return Class_Names.DRUID
		"monk":
			return Class_Names.MONK
		_:
			return Class_Names.UNKNOWN

func recalculate_derived_stats(reset_vitals: bool = false) -> void:
	max_hp = _calculate_max_hp()
	max_mp = _calculate_max_mp()
	armor_class = _calculate_armor_class()
	accuracy = _calculate_accuracy()
	critical_chance = _calculate_critical_chance()
	attack_speed = _calculate_attack_speed_bonus()
	initiative = _calculate_initiative()
	bonus_damage = _calculate_bonus_damage()

	if reset_vitals:
		current_hp = max_hp
		current_mp = max_mp
	else:
		current_hp = clamp(current_hp, 0, max_hp)
		current_mp = clamp(current_mp, 0, max_mp)

	_emit_stats_changed()

func spend_stat_point(stat_name: String) -> bool:
	if available_points <= 0:
		return false

	var field_name: String = PRIMARY_STAT_FIELDS.get(stat_name, "")
	if field_name == "":
		return false

	available_points -= 1
	set(field_name, int(get(field_name)) + 1)
	recalculate_derived_stats(false)
	return true

func gain_level(stat_points: int = -1) -> void:
	if stat_points < 0:
		stat_points = roll_level_up_points()
	level += 1
	available_points += stat_points
	available_skill_points += 1
	xp_to_next_level = int(round(xp_to_next_level * 1.35))
	recalculate_derived_stats(false)
	
	var new_skills := try_learn_skills()
	for skill_id in new_skills:
		var skill := SkillRegistry.get_skill(skill_id)
		GameEvents.message_logged.emit(
			"[color=cyan]%s learned %s![/color]" % [member_name, skill.display_name if skill else skill_id]
		)

func roll_level_up_points() -> int:
	var points := randi_range(1, 3)
	if has_skill("Experienced"):
		points += 1
	return points

func get_might() -> int:
	return base_might + bonus_might + _get_equipped_bonus("might_bonus") + _get_combat_bonus("might")

func get_endurance() -> int:
	return base_endurance + bonus_endurance + _get_equipped_bonus("endurance_bonus") + _get_combat_bonus("endurance")

func get_wisdom() -> int:
	return base_wisdom + bonus_wisdom + _get_equipped_bonus("wisdom_bonus") + _get_combat_bonus("wisdom")

func get_dexterity() -> int:
	return base_dexterity + bonus_dexterity + _get_equipped_bonus("dexterity_bonus") + _get_combat_bonus("dexterity")

func get_max_hp() -> int:
	return _calculate_max_hp()

func get_max_mp() -> int:
	return _calculate_max_mp()

func get_armor_class() -> int:
	return _calculate_armor_class()

func get_movement() -> int:
	return _get_class_int("movement", movement) + int(_get_skill_stat_bonus("movement_bonus")) + _get_combat_bonus("movement")

func get_magic_amp() -> int:
	return _calculate_magic_amp()

func get_critical_amp() -> int:
	return _calculate_critical_amp()

func get_counter_chance() -> int:
	return _calculate_counter_chance()

func can_equip_item(item: ItemData) -> bool:
	if item == null:
		return false
	if item.item_type != ItemData.ItemType.EQUIPMENT:
		return true
	if item is ArmorData:
		return _get_allowed_armor_types().has((item as ArmorData).armor_type)
	return true

# A rudimentary function to handle taking a hit
func take_damage(amount: int):
	# DEBUG: God mode invulnerability - prevent dropping below 1 HP
	if PartyState.god_mode_active:
		current_hp = max(1, current_hp - amount)
		return false
	
	# Subtraction triggers the 'set(value)' logic above
	current_hp -= amount
	
	# Optional: Return true if they died, useful for combat logic later
	return current_hp <= 0
	
func get_resistance(element: String) -> int:
	match element:
		"fire": return resist_fire
		"cold": return resist_cold
		"dark": return resist_dark
		_: return 0

func get_accuracy() -> int:
	return _calculate_accuracy()

func get_attack_accuracy(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	return _calculate_accuracy_with_might(get_attack_might(slot)) + get_weapon_accuracy_penalty(slot)

func get_attack_might(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	var might_value := get_might()
	var weapon := get_equipped_weapon(slot)
	if weapon != null and weapon.weapon_type == WeaponData.Weapon_Type.AXE and has_skill("axe_mastery"):
		might_value += AXE_MASTERY_MIGHT_BONUS
	return might_value

func get_attack_critical_chance(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	var crit_chance := get_critical_chance()
	var weapon := get_equipped_weapon(slot)
	if weapon != null and weapon.weapon_type == WeaponData.Weapon_Type.BOW and has_skill("bow_mastery"):
		crit_chance += BOW_MASTERY_CRITICAL_CHANCE_BONUS
	return max(0, crit_chance)

func get_attack_bonus_damage(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	return _calculate_bonus_damage_with_might(get_attack_might(slot))

func get_weapon_accuracy_penalty(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	var weapon := get_equipped_weapon(slot)
	if weapon == null:
		return 0

	match weapon.weapon_type:
		WeaponData.Weapon_Type.BLADE:
			return 0 if has_skill("blade_skill") else -1
		WeaponData.Weapon_Type.BOW:
			return 0 if has_skill("bow_skill") else -2
		WeaponData.Weapon_Type.POLEARM, WeaponData.Weapon_Type.AXE:
			return 0 if has_skill("poleaxe_skill") else -1
		_:
			return 0

func get_critical_chance() -> int:
	return _calculate_critical_chance()

func get_initiative() -> int:
	return _calculate_initiative()

func get_available_points() -> int:
	return available_points

func get_available_skill_points() -> int:
	return available_skill_points

func get_equipped_item(slot: ItemData.Equip_Slot) -> ItemInstance:
	for inst in inventory:
		if inst.is_equipped and inst.item_data != null and inst.item_data.equip_slot == slot:
			return inst
	return null

func is_slot_equipped(slot: ItemData.Equip_Slot) -> bool:
	return get_equipped_item(slot) != null

func get_equipped_weapon(slot: ItemData.Equip_Slot) -> WeaponData:
	var weapon = get_equipped_item(slot)
	if weapon != null and weapon.item_data is WeaponData:
		return weapon.item_data
	return null

func has_ranged_weapon() -> bool:
	return get_equipped_weapon(ItemData.Equip_Slot.RANGE) != null

func get_ranged_weapon_range() -> int:
	var weapon = get_equipped_weapon(ItemData.Equip_Slot.RANGE)
	if weapon != null:
		return max(1, weapon.tile_range)
	return 0

func get_dice_rolls(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	var weapon = get_equipped_weapon(slot)
	if weapon != null:
		return weapon.dice_rolls
	return dice_rolls

func get_dice_sides(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	var weapon = get_equipped_weapon(slot)
	if weapon != null:
		return weapon.dice_sides
	return dice_sides
	
func get_total_skill_bonus(skill_id:String) ->int:
	if not has_skill(skill_id):
		return 0
	
	var total_bonus :=0
	total_bonus += get_skill_bonus(skill_id)
	total_bonus += get_skill_rank(skill_id)
	return total_bonus
	
func get_skill_bonus(SkillName: String):
	var skill_name := SkillName.to_lower()
	var class_skill_bonuses: Dictionary = _get_class_dictionary("skill_bonuses")
	var class_bonus := int(class_skill_bonuses.get(skill_name, 0))
	match skill_name:
		"lockpicking", "thievery", "reflex":
			return class_bonus + _stat_modifier(get_dexterity()) + _get_equipped_bonus("lockpicking_bonus")
		"perception", "lore", "medicine":
			return class_bonus + _stat_modifier(get_wisdom()) + _get_equipped_bonus("perception_bonus")
		"survival", "discipline", "athletics", "leadership":
			return class_bonus + max(_stat_modifier(get_wisdom()), _stat_modifier(get_dexterity()))
		_:
			return class_bonus

func get_bonus_damage() -> int:
	return _calculate_bonus_damage()

func get_attack_speed_bonus() -> int:
	return _calculate_attack_speed_bonus()

func get_damage_modifier(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	return get_bonus_damage() + CombatLogic.might_bonus(get_might()) + _get_weapon_bonus(slot, "bonus_damage_bonus")

func get_damage_display(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> String:
	return "%dd%d" % [get_dice_rolls(slot), get_dice_sides(slot)]

func get_total_attack_speed(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	var total_speed = float(get_attack_speed_bonus())
	var weapon = get_equipped_weapon(slot)
	if weapon != null:
		total_speed += weapon.attack_speed
		if weapon.weapon_type == WeaponData.Weapon_Type.BLADE and has_skill("blade_mastery"):
			total_speed += BLADE_MASTERY_ATTACK_SPEED_BONUS
	return int(total_speed)

func _migrate_legacy_fields(class_stats: Dictionary) -> void:
	if level <= 0:
		level = 1

	if base_might <= 0:
		base_might = might if might > 0 else class_stats.get("base_might", DEFAULT_STARTING_MIGHT)
	if base_dexterity <= 0:
		base_dexterity = dexterity if dexterity > 0 else class_stats.get("base_dex", DEFAULT_STARTING_DEXTERITY)
	if base_endurance <= 0:
		base_endurance = endurance if endurance > 0 else class_stats.get("base_end", class_stats.get("base_endurance", DEFAULT_STARTING_ENDURANCE))
	if base_wisdom <= 0:
		base_wisdom = wisdom if wisdom > 0 else class_stats.get("base_wis", class_stats.get("base_wisdom", DEFAULT_STARTING_WISDOM))
	if xp_to_next_level <= 0:
		xp_to_next_level = BASE_XP_TO_NEXT_LEVEL
	movement = _get_class_int("movement", movement)

	if base_accuracy_bonus == 0 and accuracy != 0:
		base_accuracy_bonus = accuracy
	if base_critical_chance_bonus == 0 and critical_chance != 0:
		base_critical_chance_bonus = critical_chance
	if base_attack_speed_bonus == 0 and attack_speed != 0:
		base_attack_speed_bonus = attack_speed
	if base_initiative_bonus == 0 and initiative != 0:
		base_initiative_bonus = initiative
	if base_bonus_damage_bonus == 0 and bonus_damage != 0:
		base_bonus_damage_bonus = bonus_damage
	if armor_class != 0 and armor_class != BASE_ARMOR_CLASS:
		base_armor_class_bonus = armor_class - BASE_ARMOR_CLASS

func _calculate_max_hp() -> int:
	var hp_base := _get_class_float("hp_base", 10.0)
	var hp_from_level = max(0.0, float(level - 1) * _get_class_float("hp_per_level", 5.0))
	var hp_from_might = float(get_might()) * _get_class_float("hp_might_scale", 1.0)
	var hp_from_endurance := float(get_endurance()) * _get_class_float("hp_end_scale", 1.0)
	
	var hp_from_skills := float(level - 1) * _get_skill_stat_bonus("hp_per_level_bonus")
	return max(1, int(round(hp_base + hp_from_level + hp_from_might + hp_from_endurance + bonus_max_hp + _get_equipped_bonus("max_hp_bonus"))))

func _calculate_max_mp() -> int:
	var mp_base := _get_class_float("mp_base", 0.0)
	var mp_from_level = max(0.0, float(level - 1) * _get_class_float("mp_per_level", 0.0))
	var mp_from_wisdom := float(get_wisdom()) * _get_class_float("mp_wis_scale", 1.0)
	return max(0, int(round(mp_base + mp_from_level + mp_from_wisdom + bonus_max_mp + _get_equipped_bonus("max_mp_bonus"))))

func _calculate_armor_class() -> int:
	var dex_bonus := _scaled_modifier(get_dexterity(), _get_class_float("ac_dex_scale", 1.0))
	var wis_bonus := _scaled_modifier(get_wisdom(), _get_class_float("ac_wis_scale", 0.0))
	return BASE_ARMOR_CLASS + _get_class_int("ac_bonus", 0) + base_armor_class_bonus + dex_bonus + wis_bonus + _get_armor_item_bonus() + _get_equipped_bonus("armor_class_bonus") + _get_combat_bonus("armor_class")

func _calculate_accuracy() -> int:
	return _calculate_accuracy_with_might(get_might())

func _calculate_accuracy_with_might(might_value: int) -> int:
	return base_accuracy_bonus + _get_class_int("accuracy_base", 0) + _scaled_modifier(might_value, _get_class_float("accuracy_might_scale", 0.0)) + _scaled_modifier(get_dexterity(), _get_class_float("accuracy_dex_scale", 1.0)) + _scaled_modifier(get_wisdom(), _get_class_float("accuracy_wis_scale", 0.0)) + _get_equipped_bonus("accuracy_bonus") + _get_combat_bonus("accuracy")

func _calculate_critical_chance() -> int:
	return max(0, base_critical_chance_bonus + _get_class_int("crit_base", 0) + _scaled_modifier(get_dexterity(), _get_class_float("crit_dex_scale", 0.5)) + _scaled_modifier(get_wisdom(), _get_class_float("crit_wis_scale", 0.0)) + _get_equipped_bonus("critical_chance_bonus"))

func _calculate_attack_speed_bonus() -> int:
	return base_attack_speed_bonus + _get_class_int("attack_speed_base", 0) + _scaled_modifier(get_dexterity(), _get_class_float("attack_speed_dex_scale", 0.5)) + _get_equipped_bonus("attack_speed_bonus") + _get_combat_bonus("attack_speed")

func _calculate_initiative() -> int:
	return base_initiative_bonus + _get_class_int("initiative_base", 0) + _scaled_modifier(get_dexterity(), _get_class_float("initiative_dex_scale", 1.0)) + _scaled_modifier(get_wisdom(), _get_class_float("initiative_wis_scale", 0.0)) + _get_equipped_bonus("initiative_bonus") + _get_combat_bonus("initiative")

func _calculate_bonus_damage() -> int:
	return _calculate_bonus_damage_with_might(get_might())

func _calculate_bonus_damage_with_might(might_value: int) -> int:
	return base_bonus_damage_bonus + _get_class_int("bonus_damage_base", 0) + _scaled_modifier(might_value, _get_class_float("damage_might_scale", 0.0)) + _scaled_modifier(get_dexterity(), _get_class_float("damage_dex_scale", 0.0)) + _scaled_modifier(get_wisdom(), _get_class_float("damage_wis_scale", 0.0)) + _get_equipped_bonus("bonus_damage_bonus") + _get_combat_bonus("bonus_damage")

func _calculate_magic_amp() -> int:
	var total := _get_class_int("magic_amp", 0) + _scaled_modifier(get_wisdom(), _get_class_float("magic_amp_wis_scale", 0.0)) + _get_equipped_bonus("magic_amp_bonus") + _get_combat_bonus("magic_amp")
	var weapon := get_equipped_weapon(ItemData.Equip_Slot.WEAPON)
	if weapon != null and weapon.weapon_type == WeaponData.Weapon_Type.Staff and has_skill("staff_mastery"):
		total += STAFF_MASTERY_MAGIC_AMP_BONUS
	return total

func _calculate_critical_amp() -> int:
	return _get_class_int("crit_amp", 0) + _scaled_modifier(get_dexterity(), _get_class_float("crit_amp_dex_scale", 0.0)) + _get_equipped_bonus("critical_amp_bonus")

func _calculate_counter_chance() -> int:
	return max(0, _get_class_int("counter_chance", 0) + _scaled_modifier(get_dexterity(), _get_class_float("counter_dex_scale", 0.0)) + _scaled_modifier(get_wisdom(), _get_class_float("counter_wis_scale", 0.0)) + _get_equipped_bonus("counter_chance_bonus"))

func _get_equipped_bonus(stat_name: String) -> int:
	var total := 0
	for inst in inventory:
		if not inst.is_equipped or inst.item_data == null:
			continue
		total += int(inst.item_data.get(stat_name))
	return total

func _get_armor_item_bonus() -> int:
	var total := 0
	for inst in inventory:
		if not inst.is_equipped or not inst.item_data is ArmorData:
			continue
		total += (inst.item_data as ArmorData).armor_class
	return total

func _get_weapon_bonus(slot: ItemData.Equip_Slot, stat_name: String) -> int:
	var weapon := get_equipped_weapon(slot)
	if weapon == null:
		return 0
	return int(weapon.get(stat_name))

func _stat_modifier(value: int) -> int:
	return int(floor((value - 10) / 2.0))

func _scaled_modifier(stat_value: int, scale: float) -> int:
	return int(round(_stat_modifier(stat_value) * scale))

func _get_class_profile() -> Dictionary:
	return CLASS_STAT_MAP.get(get_resolved_class_name(), {})

func _get_class_float(key: String, default_value: float = 0.0) -> float:
	return float(_get_class_profile().get(key, default_value))

func _get_class_int(key: String, default_value: int = 0) -> int:
	return int(_get_class_profile().get(key, default_value))

func _get_class_dictionary(key: String) -> Dictionary:
	var value = _get_class_profile().get(key, {})
	return value if value is Dictionary else {}

func _get_allowed_armor_types() -> Array:
	var allowed = _get_class_profile().get("allowed_armor_types", [])
	return allowed if allowed is Array else []

func _emit_stats_changed() -> void:
	if suppress_stat_signal:
		return
	if GameEvents:
		GameEvents.party_member_stats_changed.emit(self)

# ==SKILLS==

const SKILL_REGISTRY_PATH = "res://data/skills/"  # folder of SkillData .tres files

func try_learn_skills() -> Array[String]:
	# Call this at level-up. Returns list of newly learned skill IDs.
	var newly_learned: Array[String] = []
	
	for skill in _get_all_skills_for_class():
		# Dictionaries use .has() to check if a key exists
		if learned_skills.has(skill.skill_id):
			continue
		if level < skill.min_level:
			continue
		
		var chance := _calculate_learn_chance(skill)
		if randi_range(1, 100) <= chance:
			# FIX: Instead of appending to an array, assign the initial rank level (1) to the key
			learned_skills[skill.skill_id] = 1 
			
			# This remains an array tracking text outputs, so append stays here
			newly_learned.append(skill.skill_id)
			
			# Stat skills take effect immediately
			recalculate_derived_stats(false)  
	
	return newly_learned

func _calculate_learn_chance(skill: SkillData) -> int:
	var levels_above_min = max(0, level - skill.min_level)
	var wis_mod := _stat_modifier(get_wisdom())  # you already have this
	var wis_bonus := int(round(float(wis_mod) * skill.wisdom_scale * 10.0))
	return skill.base_learn_chance + (levels_above_min * skill.chance_per_level) + wis_bonus

func _get_all_skills_for_class() -> Array[SkillData]:
	# Load from a registry — see below
	return SkillRegistry.get_skills_for_class(get_resolved_class_name())

func get_learned_skill_resources() -> Array[SkillData]:
	var skills: Array[SkillData] = []
	for skill_id in learned_skills:
		var skill := SkillRegistry.get_skill(skill_id)
		if skill != null:
			skills.append(skill)
	return skills

func get_spell_precision_bonus() -> int:
	var total := 0.0
	for skill in get_learned_skill_resources():
		total += skill.precision
	return int(round(total))

func get_spell_complexity_bonus() -> int:
	var total := 0
	for skill in get_learned_skill_resources():
		total += skill.complexity_bonus
	return total

func get_spell_element_roll_bonus(element: int) -> int:
	return _get_spell_mastery_bonus(element) + _get_guitar_tuning_bonus(element)

func _get_spell_mastery_bonus(element: int) -> int:
	var total := 0
	for skill in get_learned_skill_resources():
		if _get_mastery_target_element(skill) == element:
			total += max(1, skill.extra_damage_roll if skill.extra_damage_roll > 0 else 1)
	return total

func _get_guitar_tuning_bonus(element: int) -> int:
	var guitar_instance := get_equipped_guitar()
	if guitar_instance == null or not guitar_instance.item_data is GuitarData:
		return 0

	var guitar_data := guitar_instance.item_data as GuitarData
	if guitar_data.tuning_modifiers.is_empty():
		return 0

	var possible_keys := [
		element,
		str(element),
		GuitarData.Element.keys()[element],
		String(GuitarData.Element.keys()[element]).to_lower()
	]

	for key in possible_keys:
		if guitar_data.tuning_modifiers.has(key):
			return int(guitar_data.tuning_modifiers[key])

	return 0

func _get_mastery_target_element(skill: SkillData) -> int:
	if skill == null:
		return -1

	if skill.element_mastery != SkillData.Element.NONE:
		return _convert_skill_element_to_guitar_element(skill.element_mastery)

	var skill_text := "%s %s" % [skill.skill_id, skill.display_name]
	var normalized := skill_text.to_lower()
	if normalized.contains("physical"):
		return GuitarData.Element.PHYSICAL
	if normalized.contains("fire"):
		return GuitarData.Element.FIRE
	if normalized.contains("ice"):
		return GuitarData.Element.ICE
	if normalized.contains("electric"):
		return GuitarData.Element.ELECTRIC
	if normalized.contains("earth"):
		return GuitarData.Element.EARTH
	if normalized.contains("spirit"):
		return GuitarData.Element.SPIRIT
	if normalized.contains("light"):
		return GuitarData.Element.LIGHT
	if normalized.contains("dark"):
		return GuitarData.Element.DARK

	return -1

func _convert_skill_element_to_guitar_element(skill_element: SkillData.Element) -> int:
	match skill_element:
		SkillData.Element.PHYSICAL:
			return GuitarData.Element.PHYSICAL
		SkillData.Element.FIRE:
			return GuitarData.Element.FIRE
		SkillData.Element.ICE:
			return GuitarData.Element.ICE
		SkillData.Element.ELECTRIC:
			return GuitarData.Element.ELECTRIC
		SkillData.Element.EARTH:
			return GuitarData.Element.EARTH
		SkillData.Element.SPIRIT:
			return GuitarData.Element.SPIRIT
		SkillData.Element.LIGHT:
			return GuitarData.Element.LIGHT
		SkillData.Element.DARK:
			return GuitarData.Element.DARK
		_:
			return -1

func apply_combat_buff(stat_name: String, value: int, duration_rounds: int = -1) -> void:
	var normalized := _normalize_combat_buff_key(stat_name)
	if normalized.is_empty() or value == 0:
		return

	var current_entry: Dictionary = _get_combat_buff_entry(normalized)
	var current_value := int(current_entry.get("value", 0))
	var new_entry := {
		"value": value,
		"remaining_rounds": duration_rounds
	}
	if value > 0:
		if value >= current_value:
			combat_buffs[normalized] = new_entry
	elif value < 0:
		if value <= current_value:
			combat_buffs[normalized] = new_entry

	recalculate_derived_stats(false)

func clear_combat_buffs() -> void:
	if combat_buffs.is_empty():
		return
	combat_buffs.clear()
	recalculate_derived_stats(false)

func tick_combat_buff_durations() -> void:
	if combat_buffs.is_empty():
		return

	var changed := false
	for stat_name in combat_buffs.keys():
		var entry := _get_combat_buff_entry(stat_name)
		var remaining := int(entry.get("remaining_rounds", -1))
		if remaining < 0:
			continue

		remaining -= 1
		if remaining <= 0:
			combat_buffs.erase(stat_name)
		else:
			entry["remaining_rounds"] = remaining
			combat_buffs[stat_name] = entry
		changed = true

	if changed:
		recalculate_derived_stats(false)

func _get_combat_bonus(stat_name: String) -> int:
	var normalized := _normalize_combat_buff_key(stat_name)
	if normalized.is_empty():
		return 0
	return int(_get_combat_buff_entry(normalized).get("value", 0))

func _get_combat_buff_entry(stat_name: String) -> Dictionary:
	var raw = combat_buffs.get(stat_name, {})
	if raw is Dictionary:
		return raw
	return {
		"value": int(raw),
		"remaining_rounds": -1
	}

func apply_status_effect(status_name: String, duration_rounds: int = -1, persists_after_combat: bool = true) -> void:
	var normalized := status_name.to_lower().strip_edges()
	if normalized.is_empty() or normalized == "none":
		return
	if not status_effects.has(normalized):
		status_effects.append(normalized)
	status_metadata[normalized] = {
		"remaining_rounds": duration_rounds,
		"persists_after_combat": persists_after_combat
	}

func clear_status_effect(status_name: String) -> void:
	var normalized := status_name.to_lower().strip_edges()
	status_effects.erase(normalized)
	status_metadata.erase(normalized)

func clear_temporary_combat_statuses() -> void:
	for status_name in status_effects.duplicate():
		var metadata: Dictionary = status_metadata.get(status_name, {})
		if not bool(metadata.get("persists_after_combat", true)):
			clear_status_effect(status_name)

func tick_status_durations() -> void:
	for status_name in status_effects.duplicate():
		var metadata: Dictionary = status_metadata.get(status_name, {})
		var remaining := int(metadata.get("remaining_rounds", -1))
		if remaining < 0:
			continue
		remaining -= 1
		if remaining <= 0:
			clear_status_effect(status_name)
		else:
			metadata["remaining_rounds"] = remaining
			status_metadata[status_name] = metadata

func _normalize_combat_buff_key(stat_name: String) -> String:
	var key := stat_name.to_lower().strip_edges()
	match key:
		"might":
			return "might"
		"endurance":
			return "endurance"
		"wisdom":
			return "wisdom"
		"dexterity":
			return "dexterity"
		"accuracy":
			return "accuracy"
		"ac_bonus", "armor_class":
			return "armor_class"
		"initiative":
			return "initiative"
		"attack_speed":
			return "attack_speed"
		"magic_amp":
			return "magic_amp"
		"movement":
			return "movement"
		"bonus_damage":
			return "bonus_damage"
		_:
			return ""

func get_combat_movement() -> int:
	# Includes Quick Step bonus if not yet used this turn
	var base := get_movement()
	if has_skill("quick_step") and not quick_step_used:
		base += 1
	return base

# ===== GUITAR/INSTRUMENT TRACKING =====
func has_guitar_equipped() -> bool:
	"""Check if a guitar is equipped in the GUITAR slot."""
	return is_slot_equipped(ItemData.Equip_Slot.GUITAR)

func get_equipped_guitar() -> ItemInstance:
	"""Get the equipped guitar ItemInstance from the GUITAR slot."""
	return get_equipped_item(ItemData.Equip_Slot.GUITAR)
