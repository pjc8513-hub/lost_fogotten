class_name GearAttributeRoller
extends RefCounted

const ATTRIBUTE_CHANCE := 0.35
const SECOND_CATEGORY_CHANCE := 0.10

const WEAPON_TAGS := [
	{"name": "Vorpal", "weight": 5},
	{"name": "Viper", "weight": 15},
	{"name": "Frost", "weight": 15},
	{"name": "Crushing", "weight": 12},
	{"name": "Enhanced", "weight": 25},
	{"name": "Blessed", "weight": 18},
	{"name": "Slaying", "weight": 3},
	{"name": "Holy", "weight": 4},
	{"name": "Hunting", "weight": 8},
]

const ARMOR_CLASS_TAGS := [
	{"name": "Hardened", "weight": 50, "armor_class_bonus": -1},
	{"name": "Magic", "weight": 25, "armor_class_bonus": -2},
	{"name": "Golem", "weight": 13, "armor_class_bonus": -3},
	{"name": "Dwarven", "weight": 8, "armor_class_bonus": -4},
	{"name": "Divine", "weight": 4, "armor_class_bonus": -5},
]

const ARMOR_UTILITY_TAGS := [
	{"name": "Nimble", "weight": 50, "dexterity_save_bonus": 1},
	{"name": "Fortitude", "weight": 50, "willpower_save_bonus": 1},
]

const ARMOR_RESIST_TAGS := [
	{"name": "Fire", "resistance": "fire"},
	{"name": "Electric", "resistance": "electric"},
	{"name": "Water", "resistance": "water"},
	{"name": "Earth", "resistance": "earth"},
	{"name": "Dark", "resistance": "dark"},
	{"name": "Light", "resistance": "light"},
	{"name": "Physical", "resistance": "physical"},
]

const ACCESSORY_IMMUNITY_TAGS := [
	"Burn", "Freeze", "Paralyze", "Confusion", "Blind",
	"Poison", "Disease", "Fear", "Curse",
]

const ACCESSORY_STAT_TAGS := [
	{"name": "Might", "stat": "might_bonus", "min": 1, "max": 5},
	{"name": "Dexterity", "stat": "dexterity_bonus", "min": 1, "max": 5},
	{"name": "Endurance", "stat": "endurance_bonus", "min": 1, "max": 5},
	{"name": "Wisdom", "stat": "wisdom_bonus", "min": 1, "max": 3},
	{"name": "Willpower", "stat": "willpower_bonus", "min": 1, "max": 3},
	{"name": "Arcane", "stat": "magic_amp_bonus", "min": 1, "max": 5},
]

static func roll_for_item(instance: ItemInstance) -> void:
	if instance == null or instance.item_data == null:
		return
	if randf() > ATTRIBUTE_CHANCE:
		return

	var item := instance.item_data
	if item is WeaponData:
		_roll_weapon(instance)
	elif item is ArmorData:
		_roll_armor(instance)
	elif item.equip_slot == ItemData.Equip_Slot.ACCESSORY:
		_roll_accessory(instance)

static func _roll_weapon(instance: ItemInstance) -> void:
	var tag: Dictionary = _weighted_pick(WEAPON_TAGS)
	var tag_name := String(tag.get("name", ""))
	instance.add_tag(tag_name)
	match tag_name:
		"Enhanced":
			instance.add_bonus("bonus_damage_bonus", randi_range(1, 8))
		"Blessed":
			instance.add_bonus("accuracy_bonus", randi_range(1, 3))

static func _roll_armor(instance: ItemInstance) -> void:
	var categories := ["defense", "resistance"]
	var first_category: String = categories.pick_random()
	_roll_armor_category(instance, first_category)
	if randf() <= SECOND_CATEGORY_CHANCE:
		_roll_armor_category(instance, "resistance" if first_category == "defense" else "defense")

static func _roll_armor_category(instance: ItemInstance, category: String) -> void:
	if category == "resistance":
		var resist_tag: Dictionary = ARMOR_RESIST_TAGS.pick_random()
		instance.add_tag(String(resist_tag["name"]))
		instance.add_resistance(String(resist_tag["resistance"]), 1)
		return

	var defense_pool := ARMOR_CLASS_TAGS + ARMOR_UTILITY_TAGS
	var tag: Dictionary = _weighted_pick(defense_pool)
	instance.add_tag(String(tag["name"]))
	for bonus_name in ["armor_class_bonus", "dexterity_save_bonus", "willpower_save_bonus"]:
		var value := int(tag.get(bonus_name, 0))
		if value != 0:
			instance.add_bonus(bonus_name, value)

static func _roll_accessory(instance: ItemInstance) -> void:
	var first_category := "immunity" if randf() < 0.5 else "stat"
	_roll_accessory_category(instance, first_category)
	if randf() <= SECOND_CATEGORY_CHANCE:
		_roll_accessory_category(instance, "stat" if first_category == "immunity" else "immunity")

static func _roll_accessory_category(instance: ItemInstance, category: String) -> void:
	if category == "immunity":
		var immunity: String = ACCESSORY_IMMUNITY_TAGS.pick_random()
		instance.add_tag(immunity)
		instance.status_immunities.append(StatusEffects.normalize_id(immunity))
		return

	var tag: Dictionary = ACCESSORY_STAT_TAGS.pick_random()
	var value := randi_range(int(tag["min"]), int(tag["max"]))
	instance.add_tag("%s +%d" % [tag["name"], value])
	instance.add_bonus(String(tag["stat"]), value)

static func _weighted_pick(entries: Array) -> Dictionary:
	var total_weight := 0
	for entry in entries:
		total_weight += int(entry.get("weight", 1))
	var roll := randi_range(1, total_weight)
	for entry in entries:
		roll -= int(entry.get("weight", 1))
		if roll <= 0:
			return entry
	return entries.back()
