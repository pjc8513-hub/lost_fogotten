extends Node3D
class_name DungeonExit

signal selected(exit: DungeonExit)

@export var dungeon_data: DungeonData
var grid_position: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	World.register_exit(self)


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var msg := "[color=yellow]Inspecting %s[/color]" % dungeon_data.DungeonName
		GameEvents.message_logged.emit(msg)
		print("Selected exit: ", dungeon_data.DungeonName)
		selected.emit(self)
		World.set_selected_exit(self)
