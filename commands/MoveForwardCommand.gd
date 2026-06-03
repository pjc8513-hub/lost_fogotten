extends Command
class_name MoveForwardCommand

func execute():
	#print("MoveForwardCommand: actor at ", actor.grid_position, " facing ", actor.forward_vector)

	var target = actor.grid_position + actor.forward_vector
	#print("MoveForwardCommand: target = ", target)

	var door := World.get_door_at(target)
	if door != null and not door.is_open:
		print("Door!")
		if door.is_locked:
			SfxManager.play_sfx("thud")
			GameEvents.message_logged.emit("[color=gray]The door will not budge.[/color]")
			print("MoveForwardCommand: locked door at ", target)
			emit_signal("finished")
			return

		door.open_door()

	if not World.is_walkable(target):
		SfxManager.play_sfx("thud")
		print("MoveForwardCommand: target NOT walkable")
		emit_signal("finished")
		return

	#print("MoveForwardCommand: moving to ", target)
	World.increment_step_count()
	actor.connect("movement_done", Callable(self, "_on_done"), CONNECT_ONE_SHOT)
	actor.move_to(target)
	

func _on_done():
	#print("MoveForwardCommand: movement_done received")
	emit_signal("finished")
