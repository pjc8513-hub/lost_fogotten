# ClassData.gd

extends Resource
class_name ClassData

@export var name: String = ""
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
@export var accuracy: int = 0   # flat bonus to hit rolls
@export var critical_chance: int = 0
@export var attack_speed: int = 0
@export var xp: int = 0
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

func get_bonus_damage() -> int:
	return bonus_damage

func get_total_attack_speed(slot: ItemData.Equip_Slot = ItemData.Equip_Slot.WEAPON) -> int:
	var total_speed = float(attack_speed)
	var weapon = get_equipped_weapon(slot)
	if weapon != null:
		total_speed += weapon.attack_speed
	return int(total_speed)
