extends Node

@onready var player: AudioStreamPlayer = $Music
var current_track: AudioStream

func play_music(stream: AudioStream, fade := 0.0) -> void:
	if current_track == stream:
		return

	current_track = stream
	player.stream = stream
	player.play()

func stop_music() -> void:
	player.stop()
	current_track = null
