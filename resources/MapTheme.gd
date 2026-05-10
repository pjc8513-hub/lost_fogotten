extends Resource
class_name MapTheme

@export_group("Wall Settings")
@export var wall_scene: PackedScene
@export var wall_materials: Array[Material] = []

@export_group("Floor Settings")
@export var floor_scene: PackedScene
@export var floor_materials: Array[Material] = []
