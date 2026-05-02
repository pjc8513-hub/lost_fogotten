# res://autoloads/LootManager.gd
extends Node

enum Loot_Table {
	EQUIP_1, EQUIP_2, EQUIP_3,
	ITEM_1, ITEM_2, ITEM_3,
	GUITAR_1, GUITAR_2, GUITAR_3
	# Later: WEAPON_1, ARMOR_1, ACCESSORY_1, etc
}

# Each table maps to actual items. Weight = drop chance if you want.
# For now: just arrays of item_id strings or Resource paths
const LOOT_POOLS = {
	Loot_Table.EQUIP_1: {
		"items": ["RustyDagger", "ShortSword", "SimpleBow", "ClothRobe", "LeatherCap"],
		"rolls": 1, # how many times to roll this table when selected
		"chance": 1.0 # 100% chance to get something if this table is rolled
	},
	Loot_Table.EQUIP_2: {
		"items": ["IronSword", "ChainMail", "SteelHelm"],
		"rolls": 1,
		"chance": 0.75
	},
	Loot_Table.EQUIP_3: {
		"items": ["MithrilBlade", "PlateArmor", "DragonHelm"],
		"rolls": 1,
		"chance": 0.5
	},
	Loot_Table.ITEM_1: {
		"items": ["health_potion_small", "bread", "torch"],
		"rolls": 2, # tier 1 items drop more often
		"chance": 1.0
	},
	Loot_Table.ITEM_2: {
		"items": ["health_potion", "mana_potion", "antidote"],
		"rolls": 2,
		"chance": 0.8
	},
	Loot_Table.ITEM_3: {
		"items": ["elixir", "phoenix_down", "scroll_teleport"],
		"rolls": 1,
		"chance": 0.6
	},
	Loot_Table.GUITAR_1: {
		"items": ["OMALLEY", "PAN"],
		"rolls": 1,
		"chance": 0.8
	},
	Loot_Table.GUITAR_2: {
		"items": ["WinterWizard", "DE"],
		"rolls": 1,
		"chance": 0.8
	},
	Loot_Table.GUITAR_3: {
		"items": ["THRONE", "Arthur"],
		"rolls": 1,
		"chance": 0.8
	}
}

# Main function both chests and enemies call
func roll_loot(tables: Array[Loot_Table], bonus_luck: int = 0) -> Array[String]:
	var results: Array[String] = []
	
	if tables.is_empty():
		return results
	
	for table in tables:
		if not LOOT_POOLS.has(table):
			push_warning("LootManager: No pool defined for %s" % Loot_Table.keys()[table])
			continue
			
		var pool = LOOT_POOLS[table]
		var chance: float = pool.chance + (bonus_luck * 0.05) # +5% per luck
		chance = clampf(chance, 0.0, 1.0)
		
		for i in pool.rolls:
			if randf() <= chance:
				var item = pool.items.pick_random()
				results.append(item)
				
	return results

# Helper if you want to convert item_id -> ItemData resource later
func get_item_data(item_id: String) -> Resource:
	var path = "res://data/weapons/%s.tres" % item_id
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("LootManager: ItemData not found: %s" % path)
	return null

# Debug helper
func table_name(table: Loot_Table) -> String:
	return Loot_Table.keys()[table]
