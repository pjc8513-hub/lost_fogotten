class_name GuitarData extends ItemData

enum Company {
	Arthur,
	THRONE,
	DE,
	WinterWizard,
	Pan,
	OMalley
}

enum Element { 
	PHYSICAL,
	FIRE, 
	ICE, 
	ELECTRIC, 
	EARTH, 
	SPIRIT, 
	LIGHT, 
	DARK
	}

@export var company: Company
@export var guitar_name: String = "6-String Ironclad"
@export var min_strings: int = 3
@export var max_strings: int = 8
@export var string_elements: Array[Element] # [FIRE, ICE, EARTH, LIGHT, SPIRIT, DARK]
@export var step_count: int = 6 # your columns
@export var tuning_modifiers: Dictionary # optional: {"DARK": -1} pitch shift per string
@export var loot_table: LootManager.Loot_Table
