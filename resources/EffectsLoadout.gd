class_name EffectLoadout
extends Resource

enum Slot { PREAMP, MODULATION, TIME, DYNAMICS, EQ }

@export var display_name: String = "Distortion"
@export var slot: Slot = Slot.PREAMP
@export var cost: int = 2 # Effect Points to equip
@export var level: int = 1 # 1-3 for scaling

# Audio: What Godot effect + settings to use
@export var audio_effect: AudioEffect # Set in.tres file
@export var bus_send_amount: float = 0.0 # Only used for Time slot if using sends

# Gameplay: Key = stat name, Value = bonus. Use floats: 0.2 = +20%
@export var stat_mods: Dictionary = {
	"phys_damage": 0.0,
	"crit_chance": 0.0,
	"fire_damage": 0.0,
	"ice_damage": 0.0,
	"aoe_radius": 0.0,
	"evasion": 0.0,
}

# Visuals: Key = env property, Value = amount to add
@export var visual_mods: Dictionary = {
	"fog_density": 0.0,
	"bloom_intensity": 0.0,
	"chromatic_aberration": 0.0,
	"color_temp": 0.0, # -1 cold, +1 warm
}

# Description for UI
@export_multiline var description: String = ""
