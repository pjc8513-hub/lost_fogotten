extends Control

const CELL_SIZE := Vector2(42, 42)
const CELL_GAP := 6
const EMPTY_CELL_COLOR := Color(0.07, 0.07, 0.07, 1.0)
const GRID_BACKGROUND_COLOR := Color(0.02, 0.02, 0.02, 0.82)
const LABEL_TEXT_COLOR := Color(0.82, 0.73, 0.45, 1.0)
const INFO_TEXT_COLOR := Color(0.73, 0.69, 0.55, 1.0)
const WARNING_TEXT_COLOR := Color("e0a95c")
const PREVIEW_TEXT_COLOR := Color("d8d2bc")

const ELEMENT_COLORS := {
	GuitarData.Element.FIRE: Color("d6422b"),
	GuitarData.Element.ICE: Color("4f8cff"),
	GuitarData.Element.EARTH: Color("8b5a2b"),
	GuitarData.Element.ELECTRIC: Color("f0d038"),
	GuitarData.Element.LIGHT: Color("f4f1dc"),
	GuitarData.Element.DARK: Color("5d4a78"),
	GuitarData.Element.SPIRIT: Color("3aa55d"),
	GuitarData.Element.PHYSICAL: Color("d8c49a"),
}

@onready var motif_label: Label = $HBoxContainer/LeftPanel/MotifList/MotifLabel
@onready var complexity_label: Label = $HBoxContainer/LeftPanel/MotifList/ComplexityLabel
@onready var preview_label: Label = $HBoxContainer/LeftPanel/MotifList/PreviewLabel
@onready var string_container: VBoxContainer = $HBoxContainer/CenterPanel/ScrollContainer/StingContainer
@onready var cast_button: Button = $HBoxContainer/RightContainer/ControlsContainer/CastButton
@onready var cancel_button: Button = $HBoxContainer/RightContainer/ControlsContainer/CancelButton

var sequence_grid: Array[Array] = []
var current_character: ClassData = null
var current_guitar: GuitarData = null
var current_complexity_limit: int = 0

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	GameEvents.selected_character_changed.connect(_on_selected_character_changed)
	GameEvents.inventory_changed.connect(_on_inventory_changed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	cast_button.disabled = true
	_apply_static_styling()
	_refresh_from_selected_character()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_from_selected_character()

func _on_selected_character_changed(character: ClassData) -> void:
	current_character = character
	if visible:
		_refresh_from_selected_character()

func _on_inventory_changed(character: ClassData) -> void:
	if character == PartyState.get_selected():
		current_character = character
		if visible:
			_refresh_from_selected_character()

func _refresh_from_selected_character() -> void:
	current_character = PartyState.get_selected()
	current_guitar = _get_equipped_guitar_data(current_character)
	_rebuild_interface()

func _get_equipped_guitar_data(character: ClassData) -> GuitarData:
	if character == null:
		return null

	var guitar_instance := character.get_equipped_guitar()
	if guitar_instance == null or not guitar_instance.item_data is GuitarData:
		return null

	return guitar_instance.item_data as GuitarData

func _rebuild_interface() -> void:
	for child in string_container.get_children():
		child.queue_free()

	sequence_grid.clear()

	if current_character == null:
		motif_label.text = "No party member selected."
		complexity_label.text = "Complexity: 0/0"
		preview_label.text = "Select a party member to preview a spell."
		cast_button.disabled = true
		return

	if current_guitar == null:
		motif_label.text = "%s needs a guitar equipped." % current_character.member_name
		complexity_label.text = "Complexity: 0/0"
		preview_label.text = "Equip a guitar to start composing."
		cast_button.disabled = true
		return

	var string_elements := current_guitar.get_active_string_elements()
	var string_count := string_elements.size()
	var step_count = max(1, current_guitar.step_count)
	current_complexity_limit = _get_current_complexity_limit()

	motif_label.text = "%s\n%s strings, %s steps" % [
		current_guitar.guitar_name,
		string_count,
		step_count
	]

	_build_step_header(step_count)

	for row_index in string_count:
		var row_state: Array = []
		for _col in step_count:
			row_state.append(false)
		sequence_grid.append(row_state)

		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_BEGIN
		row.add_theme_constant_override("separation", CELL_GAP)

		var string_label := Label.new()
		string_label.custom_minimum_size = Vector2(90, CELL_SIZE.y)
		string_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		string_label.text = _get_element_name(string_elements[row_index])
		string_label.add_theme_color_override("font_color", _get_text_color_for_element(string_elements[row_index]))
		row.add_child(string_label)

		for col_index in step_count:
			var cell := ColorRect.new()
			cell.custom_minimum_size = CELL_SIZE
			cell.mouse_filter = Control.MOUSE_FILTER_STOP
			cell.color = EMPTY_CELL_COLOR
			cell.set_meta("row", row_index)
			cell.set_meta("col", col_index)
			cell.set_meta("element", string_elements[row_index])
			cell.gui_input.connect(_on_cell_gui_input.bind(cell))
			row.add_child(cell)

		string_container.add_child(row)

	_update_complexity_display()
	_update_spell_preview()
	_update_cast_button_state()

func _build_step_header(step_count: int) -> void:
	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", CELL_GAP)

	var corner := Label.new()
	corner.custom_minimum_size = Vector2(90, 24)
	corner.text = "STEPS"
	corner.add_theme_color_override("font_color", LABEL_TEXT_COLOR)
	header_row.add_child(corner)

	for step_index in step_count:
		var step_label := Label.new()
		step_label.custom_minimum_size = Vector2(CELL_SIZE.x, 24)
		step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		step_label.text = str(step_index + 1)
		step_label.add_theme_color_override("font_color", LABEL_TEXT_COLOR)
		header_row.add_child(step_label)

	string_container.add_child(header_row)

func _on_cell_gui_input(event: InputEvent, cell: ColorRect) -> void:
	if not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	var row := int(cell.get_meta("row"))
	var col := int(cell.get_meta("col"))
	var is_active = not sequence_grid[row][col]

	if is_active and _get_filled_slot_count() >= current_complexity_limit:
		return

	sequence_grid[row][col] = is_active

	if is_active:
		cell.color = ELEMENT_COLORS.get(cell.get_meta("element"), Color.WHITE)
	else:
		cell.color = EMPTY_CELL_COLOR

	_update_complexity_display()
	_update_spell_preview()
	_update_cast_button_state()

func _update_cast_button_state() -> void:
	for row in sequence_grid:
		for value in row:
			if value:
				cast_button.disabled = false
				return
	cast_button.disabled = true

func _apply_static_styling() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = GRID_BACKGROUND_COLOR
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.border_color = Color("7b6230")
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.corner_radius_bottom_left = 8

	for panel_path in [
		$HBoxContainer/LeftPanel,
		$HBoxContainer/CenterPanel,
		$HBoxContainer/RightContainer,
	]:
		panel_path.add_theme_stylebox_override("panel", panel_style)

	motif_label.add_theme_color_override("font_color", INFO_TEXT_COLOR)
	complexity_label.add_theme_color_override("font_color", LABEL_TEXT_COLOR)
	preview_label.add_theme_color_override("font_color", PREVIEW_TEXT_COLOR)

func _on_cancel_pressed() -> void:
	visible = false

func _get_current_complexity_limit() -> int:
	if current_guitar == null:
		return 0

	var base_complexity = max(0, current_guitar.complexity)
	var bonus_complexity := _get_complexity_bonus(current_character)
	var max_slots = current_guitar.get_active_string_elements().size() * max(1, current_guitar.step_count)
	return clamp(base_complexity + bonus_complexity, 0, max_slots)

func _get_complexity_bonus(character: ClassData) -> int:
	if character == null:
		return 0

	return character.get_spell_complexity_bonus()

func _get_filled_slot_count() -> int:
	var total := 0
	for row in sequence_grid:
		for value in row:
			if value:
				total += 1
	return total

func _update_complexity_display() -> void:
	var filled_slots := _get_filled_slot_count()
	var remaining_slots = max(0, current_complexity_limit - filled_slots)
	complexity_label.text = "Complexity: %s/%s\nRemaining motifs: %s" % [
		filled_slots,
		current_complexity_limit,
		remaining_slots
	]

	if remaining_slots == 0 and current_complexity_limit > 0:
		complexity_label.add_theme_color_override("font_color", WARNING_TEXT_COLOR)
	else:
		complexity_label.add_theme_color_override("font_color", LABEL_TEXT_COLOR)

func _update_spell_preview() -> void:
	var spell_data := _build_spell_data()
	var result := SpellResolver.resolve_spell_preview(spell_data)
	var preview := SpellResolver.format_preview_lines(result)
	var lines: Array[String] = []

	if preview["element_lines"].is_empty() and preview["chord_lines"].is_empty():
		lines.append("Spell Preview")
		lines.append("Place notes on the grid to see rolls, chords, and mana.")
	else:
		lines.append("Spell Preview")
		lines.append_array(preview["element_lines"])
		if not preview["extra_lines"].is_empty():
			lines.append("")
			lines.append_array(preview["extra_lines"])
		if not preview["chord_lines"].is_empty():
			lines.append("")
			lines.append_array(preview["chord_lines"])
		lines.append("")
		lines.append("Mana: %s" % preview["mana"])

	preview_label.text = "\n".join(lines)

func _build_spell_data() -> SpellData:
	return SpellResolver.build_spell_data(current_character, current_guitar, sequence_grid, current_complexity_limit)

func _get_element_name(element: int) -> String:
	match element:
		GuitarData.Element.FIRE:
			return "Fire"
		GuitarData.Element.ICE:
			return "Ice"
		GuitarData.Element.EARTH:
			return "Earth"
		GuitarData.Element.ELECTRIC:
			return "Electric"
		GuitarData.Element.LIGHT:
			return "Light"
		GuitarData.Element.DARK:
			return "Dark"
		GuitarData.Element.SPIRIT:
			return "Spirit"
		GuitarData.Element.PHYSICAL:
			return "Physical"
		_:
			return "Unknown"

func _get_text_color_for_element(element: int) -> Color:
	if element == GuitarData.Element.DARK:
		return Color("b69ad9")
	return ELEMENT_COLORS.get(element, LABEL_TEXT_COLOR)
