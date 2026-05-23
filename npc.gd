# NPC.gd
extends Node3D
class_name NPC

signal selected

var grid_position: Vector2i
var npc_data: NPCData

func _ready():
	World.register_npc(self)

func _on_selected():
	World.set_selected_npc(self)
	selected.emit()
