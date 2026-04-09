extends Command
class_name MoveForwardCommand

func execute():
	#print("MoveForwardCommand: actor at ", actor.grid_position, " facing ", actor.forward_vector)

	var target = actor.grid_position + actor.forward_vector
	#print("MoveForwardCommand: target = ", target)

	if not World.is_walkable(target):
		print("MoveForwardCommand: target NOT walkable")
		emit_signal("finished")
		return

	#print("MoveForwardCommand: moving to ", target)
	actor.connect("movement_done", Callable(self, "_on_done"), CONNECT_ONE_SHOT)
	actor.move_to(target)
	

func _on_done():
	#print("MoveForwardCommand: movement_done received")
	emit_signal("finished")
