# pedal_data.gd
extends Resource
class_name PedalData

@export var name: String
@export var type: String # "distortion", "delay", etc

@export var modifiers: Array[ModifierData]
