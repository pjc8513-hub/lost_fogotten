extends PanelContainer
@onready var portrait_one: TextureRect = $HBoxContainer/PortraitOne
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var class_label: Label = $HBoxContainer/VBoxContainer/ClassLabel
@onready var level_label: Label = $HBoxContainer/VBoxContainer/LevelLabel
@onready var add_button: Button = $HBoxContainer/VBoxContainer2/AddButton
@onready var remove_button: Button = $HBoxContainer/VBoxContainer2/RemoveButton
@onready var delete_button_button: Button = $HBoxContainer/VBoxContainer2/DeleteButtonButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
