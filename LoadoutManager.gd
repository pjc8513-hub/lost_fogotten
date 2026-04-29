extends Node

signal loadout_changed

const MUSIC_BUS_NAME := "MusicGameplay"
const CLEAN_BUS_NAME := "MusicClean"
const MAX_POINTS := 11

var total_points: int = MAX_POINTS
var equipped: Dictionary = {} # Slot -> EffectLoadout
var music_bus_idx: int = 0

func _ready() -> void:
	music_bus_idx = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if music_bus_idx == -1:
		AudioServer.add_bus()
		music_bus_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_bus_idx, MUSIC_BUS_NAME)
		AudioServer.set_bus_send(music_bus_idx, "Master")
	
	# Ensure clean bus exists for dialogue/menus
	if AudioServer.get_bus_index(CLEAN_BUS_NAME) == -1:
		var clean_idx := AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(clean_idx, CLEAN_BUS_NAME)

# Call this when player changes pedal loadout
func equip_effect(effect: EffectLoadout) -> bool:
	var current_cost := get_current_cost()
	if equipped.has(effect.slot):
		current_cost -= equipped[effect.slot].cost
	
	if current_cost + effect.cost > total_points:
		print("Not enough Effect Points")
		return false
	
	equipped[effect.slot] = effect
	_rebuild_audio_bus()
	loadout_changed.emit()
	return true

func unequip_slot(slot: EffectLoadout.Slot) -> void:
	if equipped.has(slot):
		equipped.erase(slot)
		_rebuild_audio_bus()
		loadout_changed.emit()

func _rebuild_audio_bus() -> void:
	# Clear all effects from music bus
	for i in range(AudioServer.get_bus_effect_count(music_bus_idx)):
		AudioServer.remove_bus_effect(music_bus_idx, 0)
	
	# Add in fixed order: Preamp -> Mod -> Time -> Dynamics -> EQ
	var order := [
		EffectLoadout.Slot.PREAMP,
		EffectLoadout.Slot.MODULATION,
		EffectLoadout.Slot.TIME,
		EffectLoadout.Slot.DYNAMICS,
		EffectLoadout.Slot.EQ,
	]
	
	for slot in order:
		if equipped.has(slot):
			var fx: EffectLoadout = equipped[slot]
			if fx.audio_effect:
				AudioServer.add_bus_effect(music_bus_idx, fx.audio_effect.duplicate())
	
	# Always cap with limiter so nothing clips
	var limiter := AudioEffectLimiter.new()
	limiter.threshold_db = -2.0
	AudioServer.add_bus_effect(music_bus_idx, limiter)

func get_stat_modifier(stat_name: String) -> float:
	var total := 0.0
	for fx in equipped.values():
		total += fx.stat_mods.get(stat_name, 0.0)
	return total

func get_visual_params() -> Dictionary:
	var result := {
		"fog_density": 0.01, # base level
		"bloom_intensity": 0.0,
		"chromatic_aberration": 0.0,
		"color_temp": 0.0,
	}
	for fx in equipped.values():
		for key in fx.visual_mods:
			result[key] = result.get(key, 0.0) + fx.visual_mods[key]
	
	# Clamp so you don't get Silent Hill + Las Vegas at once
	result["fog_density"] = clampf(result["fog_density"], 0.0, 0.4)
	result["bloom_intensity"] = clampf(result["bloom_intensity"], 0.0, 0.8)
	result["chromatic_aberration"] = clampf(result["chromatic_aberration"], 0.0, 0.5)
	return result

func get_current_cost() -> int:
	var cost := 0
	for fx in equipped.values():
		cost += fx.cost
	return cost

func get_points_remaining() -> int:
	return total_points - get_current_cost()
