extends OmniLight3D

@export var base_energy: float = 1.0
@export var flicker_amount: float = 0.15
@export var flicker_speed: float = 15.0

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta * flicker_speed
	# Use overlapping sine waves for an organic, unpredictable flicker
	var noise = sin(time) * cos(time * 0.7) + sin(time * 1.5)
	
	light_energy = base_energy + (noise * flicker_amount)
