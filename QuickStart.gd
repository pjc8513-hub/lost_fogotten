# PartySetupScene.gd
extends Node

func _ready() -> void:
	$PanelContainer/VBoxContainer/quick_start.pressed.connect(_on_quick_start_pressed)
	$PanelContainer/VBoxContainer/CreateCharacterButton.pressed.connect(_on_CreateCharacterButton_pressed)
	$PanelContainer/VBoxContainer/ManagePartyButton.pressed.connect(_on_manage_party_pressed)
	$PanelContainer/VBoxContainer/BeginButton.pressed.connect(_on_begin_pressed)
	
func _on_quick_start_pressed():
	PartyState.reset_default_party()  # already exists, sets up default party
	SceneManager.change_scene("res://Main.tscn")

func _on_CreateCharacterButton_pressed():
	SceneManager.change_scene("res://CharacterCreation.tscn")

func _on_manage_party_pressed():
	SceneManager.change_scene("res://PartyMemberSelection.tscn")

func _on_begin_pressed():
	if PartyState.can_set_out():
		SceneManager.change_scene("res://Main.tscn")
	else:
		SceneManager.change_scene("res://PartyMemberSelection.tscn")
