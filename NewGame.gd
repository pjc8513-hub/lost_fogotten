# TitleScene.gd
extends Node

func _ready():
	$MarginContainer/VBoxContainer/new_game.pressed.connect(_on_new_game_pressed)
	MusicManager.play_music(
		preload("res://assets/audio/music/Title.wav"))
	
func _on_new_game_pressed():
	print("clicked new game")
	SceneManager.change_scene("res://PartySetupScreen.tscn")
