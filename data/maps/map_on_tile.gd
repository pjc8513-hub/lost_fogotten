
class_name LightRestoreTrigger
extends Node3D

@export var trigger_data: TriggerData
var grid_position: Vector2i

func _ready() -> void:
	World.register_step_trigger(self)

func execute() -> void:
	GameEvents.automap_visibility_changed.emit(true)

func _exit_tree() -> void:
	World.unregister_step_trigger(self)
