extends SubViewportContainer

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("[SubViewportContainer] Received click at: ", event.position, " | Filter: ", mouse_filter)
		# Don't call accept_event() here or you'll stop propagation
