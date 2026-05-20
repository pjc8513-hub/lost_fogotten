extends Area3D
class_name BumpTile

var grid_position: Vector2i
var trigger_data: TriggerData

func _ready() -> void:
	World.register_step_trigger(self)

func _exit_tree() -> void:
	World.unregister_step_trigger(self)

func execute() -> void:
	if trigger_data == null:
		push_warning("BumpTile triggered without TriggerData at %s." % grid_position)
		return

	trigger_data.fire()
