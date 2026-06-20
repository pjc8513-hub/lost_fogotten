extends Node3D
class_name BlackoutTile

var grid_position: Vector2i

func _ready() -> void:
	World.register_blackout_tile(self)

func set_occupied(occupied: bool) -> void:
	visible = not occupied

func _exit_tree() -> void:
	World.unregister_blackout_tile(self)
