# TreasureData.gd

extends Resource
class_name TreasureData

enum Chest_Name {
	NOOB,
	INTERESTING,
	EPIC
}

@export var chest_name: Chest_Name
@export_file("*.tscn") var scene_path: String
@export var tier: int = 1
@export var sprite_texture: Texture2D
@export var custom_scale: Vector3 = Vector3(1, 1, 1)
@export var custom_position: Vector3 = Vector3.ZERO

# Gold roll
@export var gold_die: int = 20
@export var gold_multiplier: int = 1 # 1, 5, 10

# Loot table(s)
@export var loot_table: Array[LootManager.Loot_Table] = []

# Trap stats
@export var is_trapped: bool = true
@export var trap_disarm_dc: int = 10 # 10, 15, 20
@export var trap_damage_die: int = 6
@export var trap_damage_num_dice: int = 1

@export var lock_dc: int = 10 
