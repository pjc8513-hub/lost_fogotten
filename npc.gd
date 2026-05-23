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

func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		var name_str = npc_data.npc_name
		print("NPC clicked:", name_str)
		selected.emit(self)
		var msg := "[color=yellow]Inspecting %s[/color]" % name_str
		GameEvents.message_logged.emit(msg)
		World.set_selected_npc(self)  # similar to set_selected_enemy
