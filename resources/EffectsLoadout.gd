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
# Use this to store specific knob settings: {"drive": 0.5, "mode": 1}
@export var audio_settings: Dictionary = {
	"mode": 0.0,
	"drive": 0.0,
	"post_gain": 0.0,
	"rate_hz": 0.0,
	"depth": 0.0,
	"feedback": 0.0,
	"room_size": 0.0,
	"damping": 0.0,
	"hipass": 0.0,
	"dry": 0.0,
	"wet": 0.0
}

# Gameplay: Key = stat name, Value = bonus. Use floats: 0.2 = +20%
@export var stat_mods: Dictionary = {
	"phys_damage": 0.0,
	"crit_chance": 0.0,
	"crit_damage": 0.0,
	"fire_damage": 0.0,
	"ice_damage": 0.0,
	"aoe_radius": 0.0,
	"evasion": 0.0,
	"accuracy": 0.0
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
