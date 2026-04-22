extends PanelContainer
class_name StatEntry

signal stat_clicked(stat_name: String)

@onready var name_label: Label = $HBoxContainer/StatNameLabel
@onready var value_label: Label = $HBoxContainer/StatValueLabel

var stat_name: String = ""
var clickable := true

func _ready() -> void:

	# Force visibility + size for debugging
	visible = true
	custom_minimum_size = Vector2(0, 32)
	size_flags_horizontal = Control.SIZE_FILL



func setup(p_stat_name: String, p_value: int):
	stat_name = p_stat_name
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.text = p_stat_name.capitalize()
	value_label.text = str(p_value)
	value_label.add_theme_color_override("font_color", Color.WHITE)

func _gui_input(event: InputEvent) -> void:
	if not clickable:
		return

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		stat_clicked.emit(stat_name)

func set_value(new_value: int):
	value_label.text = str(new_value)

func set_clickable(can_click: bool):
	clickable = can_click
	modulate.a = 1.0 if can_click else 0.4
