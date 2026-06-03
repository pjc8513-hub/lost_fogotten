extends Node3D

var brazier_data: BrazierData
var grid_position: Vector2i

var _theme_ref: MapTheme
var _light: OmniLight3D
var _time: float = 0.0
var _base_energy: float
var _base_range:  float
var _flicker_speed:  float
var _flicker_amount: float
var _flicker_enabled: bool

func configure(theme: MapTheme) -> void:
	_theme_ref = theme
	_light = $OmniLight3D

	# Brazier-specific values win; fall back to theme
	_light.light_color = brazier_data.light_color if brazier_data.light_color != Color.BLACK \
						else theme.torch_color

	_base_energy     = brazier_data.base_energy  if brazier_data.base_energy  > 0.0 else theme.torch_base_energy
	_base_range      = brazier_data.omni_range   if brazier_data.omni_range   > 0.0 else theme.torch_omni_range
	_flicker_speed   = brazier_data.flicker_speed  if brazier_data.flicker_speed  > 0.0 else theme.torch_flicker_speed
	_flicker_amount  = brazier_data.flicker_amount if brazier_data.flicker_amount > 0.0 else theme.torch_flicker_amount
	_flicker_enabled = brazier_data.enable_flicker

	_light.light_energy = _base_energy
	_light.omni_range   = _base_range
	set_process(_flicker_enabled)

func _process(delta: float) -> void:
	_time += delta * _flicker_speed
	var noise = sin(_time) * cos(_time * 0.7) + sin(_time * 1.5)
	_light.light_energy = _base_energy + (noise * _flicker_amount)
	_light.omni_range   = _base_range  + noise * 0.15
