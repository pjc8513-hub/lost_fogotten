# ChordData.gd
extends Resource
class_name ChordData

# ID
@export var chord_id: String = ""
@export var display_name: String = ""
@export var animation_path: String = ""
@export var details: String = ""
@export var description: String = ""

# Requirements
@export var required_elements: Array[int] = []  # the two element enums
@export var min_required_count: int = 1
@export var extra_mana_cost: int = 0
@export var extra_complexity_cost: int = 0

# What do
@export var status_effect: String = ""
@export var remove_status_effect: String = ""
@export var mp_recovery: bool = false
@export var is_aoe: bool = false
@export var bonus_heal: int = 0
@export var buff_stat: Dictionary = {}
@export var bonus_rolls: int = 0
@export var bonus_damage: int = 0
@export var bonus_vs_type: String = ""

func get_summary_text() -> String:
	if not details.is_empty():
		return details
	return description
