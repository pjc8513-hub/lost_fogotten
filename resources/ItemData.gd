extends Resource
class_name ItemData

enum ItemType {
	EQUIPMENT,
	CONSUMABLE,
	QUEST,
	JUNK
}

enum Equip_Slot {
	WEAPON,
	RANGE,
	ARMOR,
	GUITAR,
	HELMET,
	BOOTS,
	GLOVES,
	ACCESSORY
}

@export var item_id: String
@export var name: String
@export var icon: Texture2D
@export var item_type: ItemType
@export var is_stackable: bool = false
@export var sell_value: int = 0
@export var equip_slot: Equip_Slot

@export_group("Stat Bonuses")
@export var might_bonus: int = 0
@export var endurance_bonus: int = 0
@export var wisdom_bonus: int = 0
@export var dexterity_bonus: int = 0
@export var accuracy_bonus: int = 0
@export var armor_class_bonus: int = 0
@export var critical_chance_bonus: int = 0
@export var initiative_bonus: int = 0
@export var attack_speed_bonus: int = 0
@export var max_hp_bonus: int = 0
@export var max_mp_bonus: int = 0
@export var bonus_damage_bonus: int = 0
@export var magic_amp_bonus: int = 0
@export var critical_amp_bonus: int = 0
@export var counter_chance_bonus: int = 0
@export var lockpicking_bonus: int = 0
@export var perception_bonus: int = 0
