# NPCData.gd
extends Resource
class_name NPCData

@export var npc_id: String
@export var npc_name: String
@export var dialogue_start_node: String  # Which dialogue node to start with
@export var scene_path: String  # Path to the NPC scene

# Associations
@export var available_quests: Array[String] = []  # Quest IDs they offer
@export var shop_id: String = ""  # If they run a shop
@export var faction: String = ""  # For faction checks in conditions

# Custom properties for conditions
@export var custom_properties: Dictionary = {}  # e.g., {"has_item_x": true, "visited_before": false}
