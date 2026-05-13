# resources/effects/DoorTriggerEffect.gd
extends TriggerEffect
class_name DoorTriggerEffect

enum Action { TOGGLE, LOCK, UNLOCK, OPEN, CLOSE }

@export var door_ids: Array[String] = []
@export var action: Action = Action.TOGGLE

func execute() -> void:
	for door_id in door_ids:
		var door = World.get_door_by_id(door_id)
		if door == null:
			continue
		match action:
			Action.TOGGLE:
				if door.is_locked:
					door.unlock_and_open()
				else:
					door.lock_and_close()   # you'll add this method
			Action.LOCK:   door.lock_and_close()
			Action.UNLOCK: door.unlock_and_open()
			Action.OPEN:   door.open()
			Action.CLOSE:  door.close()
