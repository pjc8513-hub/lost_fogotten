extends Control
@onready var party_list_container: VBoxContainer = $VBoxContainer/PartyListContainer
@onready var empty_label: Label = $VBoxContainer/EmptyLabel
@onready var return_button: Button = $VBoxContainer/ReturnButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	return_button.pressed.connect(_on_return_button_pressed)


func _on_return_button_pressed():
	SceneManager.change_scene("res://PartySetupScreen.tscn")
