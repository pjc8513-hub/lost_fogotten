extends Node3D
class_name DungeonDoor


var grid_position: Vector2i
var is_open: bool = false
var is_locked: bool = false # get this from the tres file(?)
@export var door_data: DoorData

func _ready() -> void:
	if door_data != null:
		is_locked = door_data.is_locked
	World.register_door(self)

func _exit_tree() -> void:
	World.unregister_door(self)

func unlock_and_open() -> void:
	is_locked = false
	open_door()

func open_door() -> void:
	if is_open:
		return
	is_open = true
	
	var tween = create_tween()
	# "Sinking" into the floor or sliding up? 
	# Let's go with sliding up 2 units.
	tween.tween_property(self, "position:y", 2.5, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
