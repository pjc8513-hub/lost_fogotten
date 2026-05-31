extends Resource
class_name MapTheme

@export_group("Visual Style")
@export var palette_texture: Texture2D
@export var pixel_size: float = 8.0
@export var dither_strength: float = 0.15
@export var contrast: float = 1.4

@export_group("World Environment")
## Holds the custom sky, fog, ambient light, and tonemapping for this theme.
@export var environment: Environment

@export_group("Player Torch Settings")
@export var enable_flicker: bool = true
@export var torch_base_energy: float = 1.0
@export var torch_omni_range: float = 10.0
@export var torch_flicker_amount: float = 0.15
@export var torch_flicker_speed: float = 15.0
@export var torch_color: Color = Color(0.923, 0.822, 0.6, 1.0) # Warm torch light

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
