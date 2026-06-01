extends OmniLight3D

var theme_ref: MapTheme
var time: float = 0.0

## Called by main.gd whenever a map loads
func configure_torch(theme: MapTheme) -> void:
	theme_ref = theme
	
	if theme_ref == null:
		return
		
	# Apply static theme settings immediately
	light_color = theme_ref.torch_color
	light_energy = theme_ref.torch_base_energy
	omni_range = theme_ref.torch_omni_range
	
	# If flicker is disabled (like daytime), turn off processing to save performance
	set_process(theme_ref.enable_flicker)

func _process(delta: float) -> void:
	if theme_ref == null:
		return
		
	time += delta * theme_ref.torch_flicker_speed
	var noise = sin(time) * cos(time * 0.7) + sin(time * 1.5)
	
	# Flicker around the base energy and range defined by the theme
	light_energy = theme_ref.torch_base_energy + (noise * theme_ref.torch_flicker_amount)

	omni_range = theme_ref.torch_omni_range + noise * 0.15
