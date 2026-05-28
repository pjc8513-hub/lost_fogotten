extends Resource
class_name MapTheme

@export_group("World Environment")
## Holds the custom sky, fog, ambient light, and tonemapping for this theme.
@export var environment: Environment

@export_group("Wall Settings")
@export var wall_scene: PackedScene
@export var wall_materials: Array[Material] = []
@export var random_wall_variation: bool = false

@export_group("Floor Settings")
@export var floor_scene: PackedScene
@export var floor_materials: Array[Material] = []
@export var random_floor_variation: bool = false

@export_group("Ceiling Settings")
@export var has_ceiling: bool = false
@export var ceiling_scene: PackedScene
@export var ceiling_materials: Array[Material] = []
@export var random_ceiling_variation: bool = false

@export var music_path: String= ""
