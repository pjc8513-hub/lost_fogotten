# pedalboard.gd
class_name Pedalboard

var pedals: Array[PedalInstance] = []

func get_all_modifiers() -> Array:
	var mods = []
	for pedal in pedals:
		mods.append_array(pedal.data.modifiers)
	return mods
