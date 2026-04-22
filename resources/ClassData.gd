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
@export var max_hp: int = 0
@export var max_mp: int = 0
@export var status_effects: Array[String] = []
@export var current_hp: int = 0:
	set(value):
		current_hp = clamp(value, 0, max_hp)
		# Alert the UI that this specific resource changed
		if GameEvents:
			GameEvents.party_member_stats_changed.emit(self)
			
@export var current_mp: int = 0:
	set(value):
		current_mp = clamp(value, 0, max_mp)
		# Alert the UI that this specific resource changed
		if GameEvents:
			GameEvents.party_member_stats_changed.emit(self)
			
@export var armor_class: int = 0
@export var might: int = 0
@export var endurance: int = 0
@export var wisdom: int = 0
@export var dexterity: int = 0
@export var accuracy: int = 0   # flat bonus to hit rolls
@export var critical_chance: int = 0
@export var attack_speed: int = 0

# level up
@export var xp: int = 0
@export var xp_to_next_level = 100
@export var available_points = 1

@export var sprite_texture: Texture2D
@export var resist_fire: int = 0
@export var resist_cold: int = 0
@export var resist_dark: int = 0
@export var initiative: int = 0
@export var movement: int = 5
@export var cooldown: int = 0

@export var dice_sides: int = 4
@export var dice_rolls: int = 1
@export var bonus_damage: int = 0

@export var inventory: Array[ItemInstance] = []

func get_stats() -> Dictionary:
	return {
		"Might": might,
		"Endurance": endurance,
		"Wisdom": wisdom,
		"Dexterity": dexterity,
		"Armor Class": armor_class,
		"Accuracy": accuracy,
		"Critical Chance": critical_chance,
		"Attack Speed": attack_speed,
	}
	


func initialize_from_class_map(reset_vitals: bool = true) -> void:
	var resolved_class := get_resolved_class_name()
	var class_stats: Dictionary = CLASS_STAT_MAP.get(resolved_class, {})

	if class_stats.is_empty():
		push_warning("No class stat map found for %s on %s" % [str(class_names), member_name])
		return

	if might <= 0:
		might = DEFAULT_STARTING_MIGHT
	if dexterity <= 0:
		dexterity = DEFAULT_STARTING_DEXTERITY

	endurance = class_stats.get("base_end", endurance)
	wisdom = class_stats.get("base_wis", wisdom)
	armor_class = BASE_ARMOR_CLASS + class_stats.get("ac_bonus", 0)

	# Placeholder derived stats until the character creator supplies rolled values.
	max_hp = class_stats.get("hp_mult", 0) + ((might + endurance) * 2)
	max_mp = class_stats.get("mp_mult", 0) + (wisdom * 2)

	if reset_vitals:
		current_hp = max_hp
		current_mp = max_mp
	else:
		current_hp = clamp(current_hp, 0, max_hp)
		current_mp = clamp(current_mp, 0, max_mp)

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
	return accuracy

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
	# placeholder
	pass

func get_bonus_damage() -> int:
	return bonus_damage

func get_total_attack_speed(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	var total_speed = float(attack_speed)
	var weapon = get_equipped_weapon(slot)
	if weapon != null:
		total_speed += weapon.attack_speed
	return int(total_speed)
