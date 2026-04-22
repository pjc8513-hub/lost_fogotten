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
const PRIMARY_STAT_FIELDS := {
	"Might": "base_might",
	"Endurance": "base_endurance",
	"Wisdom": "base_wisdom",
	"Dexterity": "base_dexterity",
}
const CLASS_STAT_MAP = {
	Class_Names.KNIGHT:    {"hp_mult": 12, "mp_mult": 0,  "base_end": 12, "base_wis": 5, "ac_bonus": -2},
	Class_Names.BARBARIAN: {"hp_mult": 15, "mp_mult": 0,  "base_end": 15, "base_wis": 4, "ac_bonus": -1},
	Class_Names.CLERIC:      {"hp_mult": 7,  "mp_mult": 7, "base_end": 10, "base_wis": 8, "ac_bonus": -1},
	Class_Names.BARD:      {"hp_mult": 5,  "mp_mult": 9, "base_end": 7, "base_wis": 7, "ac_bonus": 0},
	Class_Names.SORCERER:      {"hp_mult": 4,  "mp_mult": 12, "base_end": 6, "base_wis": 13, "ac_bonus": 0},
	Class_Names.ROGUE:      {"hp_mult": 5,  "mp_mult": 0, "base_end": 6, "base_wis": 5, "ac_bonus": 0},
	Class_Names.RANGER:      {"hp_mult": 5,  "mp_mult": 5, "base_end": 7, "base_wis": 7, "ac_bonus": -1},
	Class_Names.DRUID:      {"hp_mult": 7,  "mp_mult": 9, "base_end": 6, "base_wis": 10, "ac_bonus": 0},
	Class_Names.MONK:      {"hp_mult": 8,  "mp_mult": 4, "base_end": 9, "base_wis": 6, "ac_bonus": -1},
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

@export_group("Progression")
@export var xp: int = 0
@export var xp_to_next_level = 100
@export var available_points = 1

@export_group("Presentation")
@export var sprite_texture: Texture2D

@export_group("Resistances")
@export var resist_fire: int = 0
@export var resist_cold: int = 0
@export var resist_dark: int = 0

@export_group("Combat")
@export var movement: int = 5
@export var cooldown: int = 0

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
		"Armor Class": get_armor_class(),
		"Accuracy": get_accuracy(),
		"Critical Chance": get_critical_chance(),
		"Initiative": get_initiative(),
		"Attack Speed": get_attack_speed_bonus(),
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

func get_resolved_class_name() -> Class_Names:
	if class_names != Class_Names.UNKNOWN:
		return class_names
	return _infer_class_name_from_resource()

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

func gain_level(stat_points: int = 1) -> void:
	level += 1
	available_points += stat_points
	xp_to_next_level = int(round(xp_to_next_level * 1.35))
	recalculate_derived_stats(false)

func get_might() -> int:
	return base_might + bonus_might + _get_equipped_bonus("might_bonus")

func get_endurance() -> int:
	return base_endurance + bonus_endurance + _get_equipped_bonus("endurance_bonus")

func get_wisdom() -> int:
	return base_wisdom + bonus_wisdom + _get_equipped_bonus("wisdom_bonus")

func get_dexterity() -> int:
	return base_dexterity + bonus_dexterity + _get_equipped_bonus("dexterity_bonus")

func get_max_hp() -> int:
	return _calculate_max_hp()

func get_max_mp() -> int:
	return _calculate_max_mp()

func get_armor_class() -> int:
	return _calculate_armor_class()

# A rudimentary function to handle taking a hit
func take_damage(amount: int):
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

func get_critical_chance() -> int:
	return _calculate_critical_chance()

func get_initiative() -> int:
	return _calculate_initiative()

func get_available_points() -> int:
	return available_points

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
	
func get_skill_bonus(SkillName: String):
	var skill_name := SkillName.to_lower()
	match skill_name:
		"lockpicking", "thievery", "sleight_of_hand":
			return _stat_modifier(get_dexterity()) + _get_equipped_bonus("lockpicking_bonus")
		"perception", "lore", "medicine":
			return _stat_modifier(get_wisdom()) + _get_equipped_bonus("perception_bonus")
		_:
			return 0

func get_bonus_damage() -> int:
	return _calculate_bonus_damage()

func get_attack_speed_bonus() -> int:
	return _calculate_attack_speed_bonus()

func get_total_attack_speed(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	var total_speed = float(get_attack_speed_bonus())
	var weapon = get_equipped_weapon(slot)
	if weapon != null:
		total_speed += weapon.attack_speed
	return int(total_speed)

func _migrate_legacy_fields(class_stats: Dictionary) -> void:
	if level <= 0:
		level = 1

	if base_might <= 0:
		base_might = might if might > 0 else DEFAULT_STARTING_MIGHT
	if base_dexterity <= 0:
		base_dexterity = dexterity if dexterity > 0 else DEFAULT_STARTING_DEXTERITY
	if base_endurance <= 0:
		base_endurance = endurance if endurance > 0 else class_stats.get("base_end", DEFAULT_STARTING_ENDURANCE)
	if base_wisdom <= 0:
		base_wisdom = wisdom if wisdom > 0 else class_stats.get("base_wis", DEFAULT_STARTING_WISDOM)

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
	var class_stats = CLASS_STAT_MAP.get(get_resolved_class_name(), {})
	var hp_mult = class_stats.get("hp_mult", 0)
	var hp_growth = max(1, int(hp_mult / 2))
	var hp_from_level = max(0, (level - 1) * hp_growth)
	return max(1, hp_mult + (get_might() + get_endurance()) * 2 + hp_from_level + bonus_max_hp + _get_equipped_bonus("max_hp_bonus"))

func _calculate_max_mp() -> int:
	var class_stats = CLASS_STAT_MAP.get(get_resolved_class_name(), {})
	var mp_mult = class_stats.get("mp_mult", 0)
	var mp_growth = max(1, int(mp_mult / 2))
	var mp_from_level = max(0, (level - 1) * mp_growth)
	return max(0, mp_mult + get_wisdom() * 2 + mp_from_level + bonus_max_mp + _get_equipped_bonus("max_mp_bonus"))

func _calculate_armor_class() -> int:
	var class_stats = CLASS_STAT_MAP.get(get_resolved_class_name(), {})
	var class_bonus = class_stats.get("ac_bonus", 0)
	var dex_bonus := int(floor((get_dexterity() - 10) / 2.0))
	return BASE_ARMOR_CLASS + class_bonus + base_armor_class_bonus + dex_bonus + _get_armor_item_bonus() + _get_equipped_bonus("armor_class_bonus")

func _calculate_accuracy() -> int:
	return base_accuracy_bonus + _stat_modifier(get_dexterity()) + _get_equipped_bonus("accuracy_bonus")

func _calculate_critical_chance() -> int:
	return base_critical_chance_bonus + max(0, int(floor((get_dexterity() - 10) / 4.0))) + _get_equipped_bonus("critical_chance_bonus")

func _calculate_attack_speed_bonus() -> int:
	return base_attack_speed_bonus + max(0, _stat_modifier(get_dexterity())) + _get_equipped_bonus("attack_speed_bonus")

func _calculate_initiative() -> int:
	return base_initiative_bonus + _stat_modifier(get_dexterity()) + _get_equipped_bonus("initiative_bonus")

func _calculate_bonus_damage() -> int:
	return base_bonus_damage_bonus + _get_equipped_bonus("bonus_damage_bonus")

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

func _stat_modifier(value: int) -> int:
	return int(floor((value - 10) / 2.0))

func _emit_stats_changed() -> void:
	if GameEvents:
		GameEvents.party_member_stats_changed.emit(self)
