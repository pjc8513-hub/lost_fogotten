# ClassData.gd

extends Resource
class_name ClassData

@export var name: String = ""
@export var member_name: String = ""
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
@export var initiative: int = 10
@export var cooldown: int = 0
@export var has_ranged_weapon: bool = false

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
