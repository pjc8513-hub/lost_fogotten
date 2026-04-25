# PartySetupScene.gd
extends Node

func _ready() -> void:
	$PanelContainer/VBoxContainer/quick_start.pressed.connect(_on_quick_start_pressed)
func _on_quick_start_pressed():
	PartyState.reset_default_party()  # already exists, sets up default party
	SceneManager.change_scene("res://Main.tscn")
