# TriggerData.gd
extends Resource
class_name TriggerData

@export var trigger_id: String = ""
@export var scene_path: String = ""
@export var is_one_shot: bool = false
@export var effects: Array[TriggerEffect] = []

var _has_fired: bool = false

func fire() -> void:
	if is_one_shot and _has_fired:
		return
	_has_fired = true
	for effect in effects:
		effect.execute()
