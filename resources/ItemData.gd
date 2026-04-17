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
	SHIELD,
	HELMET,
	BOOTS,
	GLOVES,
	ACCESSORY
}

@export var name: String
@export var icon: Texture2D
@export var item_type: ItemType
@export var is_stackable: bool = false
@export var sell_value: int = 0
@export var equip_slot: Equip_Slot
