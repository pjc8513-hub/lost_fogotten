extends Control
@onready var npc_name_label: Label = $Panel/HBoxContainer/DialogueContainer/NPCNameLabel
@onready var dialogue_text: RichTextLabel = $Panel/HBoxContainer/DialogueContainer/DialogueText
@onready var password_input: LineEdit = $Panel/HBoxContainer/DialogueContainer/PasswordInput
@onready var choice_container: VBoxContainer = $Panel/HBoxContainer/ChoiceContainer

var choice_button_scene = preload("res://ui/DialogueChoiceButton.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()
	DialogueManager.register_ui(self)


func clear_choices():
	if choice_container == null:
		return
	for child in choice_container.get_children():
		child.queue_free()
