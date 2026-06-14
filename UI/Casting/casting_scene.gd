extends Control

const MAX_NOTES := 4
const STAFF_TEXTURES := {
	SpellData.Element.FIRE: preload("res://UI/Casting/Music_Staff_Fire.png"),
	SpellData.Element.EARTH: preload("res://UI/Casting/Music_Staff_Earth.png"),
	SpellData.Element.WATER: preload("res://UI/Casting/Music_Staff_Water.png"),
	SpellData.Element.ELECTRIC: preload("res://UI/Casting/Music_Staff_Electric.png"),
	SpellData.Element.SPIRIT: preload("res://UI/Casting/Music_Staff_Spirit.png"),
	SpellData.Element.PHYSICAL: preload("res://UI/Casting/Music_Staff_Physical.png"),
	SpellData.Element.DARK: preload("res://UI/Casting/Music_Staff_Dark.png"),
	SpellData.Element.LIGHT: preload("res://UI/Casting/Music_Staff_Light.png"),
}
const BLANK_STAFF := preload("res://UI/Casting/Music_Staff_Blank.png")

@onready var phrases: Array[TextureRect] = [
	$HBoxContainer/VBoxContainer/MarginContainer/StaffContainer/Phrase_1,
	$HBoxContainer/VBoxContainer/MarginContainer/StaffContainer/Phrase_2,
	$HBoxContainer/VBoxContainer/MarginContainer/StaffContainer/Phrase_3,
	$HBoxContainer/VBoxContainer/MarginContainer/StaffContainer/Phrase_4,
]
@onready var cast_button: Button = $HBoxContainer/MarginContainer/VBoxContainer2/CastButton
@onready var close_button: Button = $HBoxContainer/MarginContainer/VBoxContainer2/CloseButton

var notes: Array[int] = []
var note_buttons: Dictionary = {}

func _ready() -> void:
	note_buttons = {
		SpellData.Element.FIRE: $HBoxContainer/VBoxContainer/MarginContainer2/NoteButtonContainer/FireNoteButton,
		SpellData.Element.ELECTRIC: $HBoxContainer/VBoxContainer/MarginContainer2/NoteButtonContainer/ElectricNoteButton,
		SpellData.Element.SPIRIT: $HBoxContainer/VBoxContainer/MarginContainer2/NoteButtonContainer/SpiritNoteButton,
		SpellData.Element.DARK: $HBoxContainer/VBoxContainer/MarginContainer2/NoteButtonContainer/DarkNoteButton,
		SpellData.Element.LIGHT: $HBoxContainer/VBoxContainer/MarginContainer2/NoteButtonContainer/LightNoteButton,
		SpellData.Element.WATER: $HBoxContainer/VBoxContainer/MarginContainer2/NoteButtonContainer/WaterNoteButton,
		SpellData.Element.PHYSICAL: $HBoxContainer/VBoxContainer/MarginContainer2/NoteButtonContainer/PhysicalNoteButton,
		SpellData.Element.EARTH: $HBoxContainer/VBoxContainer/MarginContainer2/NoteButtonContainer/EarthNoteButton,
	}
	for element in note_buttons:
		(note_buttons[element] as Button).pressed.connect(_add_note.bind(element))
	cast_button.pressed.connect(_on_cast_pressed)
	close_button.pressed.connect(close)
	visibility_changed.connect(_on_visibility_changed)
	_reset_composition()

func open() -> void:
	SpellExecutor.cancel_party_targeting()
	var caster := PartyState.get_selected()
	if caster == null:
		return
	if caster.blocks_spell_casting():
		GameEvents.message_logged.emit("[color=purple]%s is prevented from casting.[/color]" % caster.member_name)
		return
	var available_spellbooks := caster.get_available_spellbooks()
	if available_spellbooks.is_empty():
		GameEvents.message_logged.emit("[color=gray]%s has not learned any spell mastery skills.[/color]" % caster.member_name)
		return
	_reset_composition()
	_show_available_spellbooks(available_spellbooks)
	show()
	mouse_filter = Control.MOUSE_FILTER_STOP
	move_to_front()

func close() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reset_composition()

func _add_note(element: int) -> void:
	if notes.size() >= MAX_NOTES:
		return
	notes.append(element)
	phrases[notes.size() - 1].texture = STAFF_TEXTURES[element]
	if notes.size() == 1:
		_show_all_note_buttons()
	_update_cast_button()

func _on_cast_pressed() -> void:
	var spell := SpellRegistry.find_by_notes(notes)
	var caster := PartyState.get_selected()
	var request := SpellExecutor.build_request(spell, caster)
	if not request.is_valid:
		GameEvents.message_logged.emit("[color=red]%s[/color]" % request.get_primary_error())
		return

	if spell.requires_individual_party_target():
		if SpellExecutor.begin_party_targeting(request):
			close()
		return

	var command := PlayerCastSpellCommand.new()
	command.actor = caster
	command.cast_request = request
	command.target_enemy = CombatState.targeted_enemy if CombatState.has_valid_target() else null
	CommandQueue.add_command(command)
	TurnStateMachine.last_action_was_party_wide = false
	TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)
	close()

func _reset_composition() -> void:
	notes.clear()
	for phrase in phrases:
		phrase.texture = BLANK_STAFF
	_show_all_note_buttons()
	_update_cast_button()

func _show_available_spellbooks(available_spellbooks: Array[int]) -> void:
	for element in note_buttons:
		(note_buttons[element] as Button).visible = available_spellbooks.has(int(element))

func _show_all_note_buttons() -> void:
	for button in note_buttons.values():
		(button as Button).show()

func _update_cast_button() -> void:
	cast_button.disabled = notes.is_empty()
	var spell := SpellRegistry.find_by_notes(notes)
	cast_button.tooltip_text = "" if spell == null else spell.get_display_name()

func _on_visibility_changed() -> void:
	if not visible:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
