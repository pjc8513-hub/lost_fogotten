# TitleScene.gd
extends Node

func _ready():
	$MarginContainer/VBoxContainer/new_game.pressed.connect(_on_new_game_pressed)
	
func _on_new_game_pressed():
	print("clicked new game")
	SceneManager.change_scene("res://PartySetupScreen.tscn")
