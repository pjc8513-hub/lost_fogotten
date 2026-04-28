# PartySetupScene.gd
extends Node

func _ready() -> void:
	$PanelContainer/VBoxContainer/quick_start.pressed.connect(_on_quick_start_pressed)
	$PanelContainer/VBoxContainer/add_distortion.pressed.connect(_on_add_distortion_pressed)
	$PanelContainer/VBoxContainer/add_reverb.pressed.connect(_on_reverb_pressed)
	$PanelContainer/VBoxContainer/add_phaser.pressed.connect(_on_phaser_pressed)
	
func _on_quick_start_pressed():
	PartyState.reset_default_party()  # already exists, sets up default party
	SceneManager.change_scene("res://Main.tscn")

func _on_add_distortion_pressed():
	var distortion = AudioEffectDistortion.new()
	distortion.drive = 1.0
	distortion.mode = AudioEffectDistortion.MODE_OVERDRIVE
	AudioServer.add_bus_effect(1, distortion, 0)

func _on_reverb_pressed():
	var reverb = AudioEffectReverb.new()
	reverb.room_size = 0.8
	reverb.damping = 0.5
	reverb.spread = 1
	reverb.dry = 0.8
	reverb.wet = 0.6
	AudioServer.add_bus_effect(1, reverb, 0)

func _on_phaser_pressed():
	var phaser = AudioEffectPhaser.new()
	phaser.depth = 1.5
	AudioServer.add_bus_effect(1, phaser, 0)
