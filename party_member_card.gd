extends PanelContainer
signal add_to_party_requested(member: ClassData)
signal remove_from_party_requested(member: ClassData)
signal delete_requested(member: ClassData)

@onready var portrait_one: TextureRect = $HBoxContainer/PortraitOne
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var class_label: Label = $HBoxContainer/VBoxContainer/ClassLabel
@onready var level_label: Label = $HBoxContainer/VBoxContainer/LevelLabel
@onready var add_button: Button = $HBoxContainer/VBoxContainer2/AddButton
@onready var remove_button: Button = $HBoxContainer/VBoxContainer2/RemoveButton
@onready var delete_button_button: Button = $HBoxContainer/VBoxContainer2/DeleteButtonButton

var member_data: ClassData

func _ready() -> void:
	add_button.pressed.connect(_on_add_pressed)
	remove_button.pressed.connect(_on_remove_pressed)
	delete_button_button.pressed.connect(_on_delete_pressed)

func setup(member: ClassData) -> void:
	member_data = member
	if member_data == null:
		return

	portrait_one.texture = member_data.sprite_texture
	name_label.text = member_data.member_name
	class_label.text = member_data.get_class_display_name_value()
	level_label.text = "Level %d" % member_data.level

	var in_party := PartyState.is_member_in_party(member_data)
	add_button.disabled = in_party or PartyState.is_party_full()
	remove_button.disabled = not in_party

func _on_add_pressed() -> void:
	if member_data != null:
		add_to_party_requested.emit(member_data)

func _on_remove_pressed() -> void:
	if member_data != null:
		remove_from_party_requested.emit(member_data)

func _on_delete_pressed() -> void:
	if member_data != null:
		delete_requested.emit(member_data)
