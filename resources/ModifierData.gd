# modifier_data.gd
extends Resource
class_name ModifierData

@export var hook: String
@export var priority: int = 0

# generic values so it's data-driven
@export var value: float = 0.0
@export var secondary_value: float = 0.0
@export var tags: Array[String] = []
