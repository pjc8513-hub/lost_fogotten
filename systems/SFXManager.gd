extends Node

# A dictionary to store preloaded sounds for performance
var sounds = {
	"ui_click": preload("res://assets/audio/sfx/open.wav"),
	"loot_pickup": preload("res://assets/audio/sfx/open.wav"),
	"hit": preload("res://assets/audio/sfx/hit.wav"),
	"fireball": preload("res://assets/audio/sfx/fireball.wav"),
	"heal": preload("res://assets/audio/sfx/heal.wav"),
	"buff": preload("res://assets/audio/sfx/buff.wav"),
	"thud": preload("res://assets/audio/sfx/thud.wav")
}

func play_sfx(sound_name: String) -> void:
	if sound_name.strip_edges().is_empty():
		return
	if sounds.has(sound_name):
		var asp = AudioStreamPlayer.new()
		asp.stream = sounds[sound_name]
		asp.bus = "SFX" # Make sure you have an SFX bus in your Audio Mixer
		add_child(asp)
		asp.play()
		# Clean up the node once the sound finishes
		asp.finished.connect(asp.queue_free)
	else:
		push_warning("SfxManager: Unknown sound effect '%s'." % sound_name)
