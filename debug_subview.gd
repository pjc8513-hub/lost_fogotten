extends Node

func _ready():
	get_viewport().set_input_as_handled() # reset
	get_viewport().set_process_input(true)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		print("[SubViewport] Viewport _input got click at: ", event.position)
		print("[SubViewport] Physics picking enabled: ", get_viewport().physics_object_picking)
		print("[SubViewport] GUI disable input: ", get_viewport().gui_disable_input)
