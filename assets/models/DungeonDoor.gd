extends Node3D
class_name DungeonDoor


var grid_position: Vector2i
var is_open: bool = false
var is_locked: bool = false # get this from the tres file(?)
@export var door_data = DoorData

# This function can be called by your Switch/Lever script

func unlock_and_open():
	is_locked = false
	open_door()

func open_door():
	if is_open: return
	is_open = true
	
	var tween = create_tween()
	# "Sinking" into the floor or sliding up? 
	# Let's go with sliding up 2 units.
	tween.tween_property(self, "position:y", 2.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
