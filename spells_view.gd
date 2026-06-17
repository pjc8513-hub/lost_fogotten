extends Control

@onready var spell_list: ItemList = $ScrollContainer/SpellList

var current_character: ClassData = null

func _ready() -> void:
	GameEvents.selected_character_changed.connect(_on_selected_character_changed)
	GameEvents.party_member_stats_changed.connect(_on_party_member_stats_changed)
	PartyState.discovered_spells_changed.connect(update_ui)
	spell_list.item_activated.connect(_on_spell_activated)
	update_ui()

func set_character(character: ClassData) -> void:
	current_character = character
	update_ui()

func update_ui() -> void:
	if not is_inside_tree():
		return

	spell_list.clear()
	if current_character == null:
		return

	for spell in PartyState.get_discovered_spells():
		if not SpellExecutor.meets_mastery_requirement(spell, current_character):
			continue

		var index := spell_list.add_item(spell.get_display_name())
		spell_list.set_item_metadata(index, spell)
		spell_list.set_item_tooltip(index, _build_spell_tooltip(spell))

func _on_spell_activated(index: int) -> void:
	var spell := spell_list.get_item_metadata(index) as SpellData
	var caster := PartyState.get_selected()
	var request := SpellExecutor.build_request(spell, caster)
	if not request.is_valid:
		GameEvents.message_logged.emit("[color=red]%s[/color]" % request.get_primary_error())
		return

	if spell.requires_individual_party_target():
		SpellExecutor.begin_party_targeting(request)
		return

	var command := PlayerCastSpellCommand.new()
	command.actor = caster
	command.cast_request = request
	command.target_enemy = CombatState.targeted_enemy if CombatState.has_valid_target() else null
	CommandQueue.add_command(command)
	TurnStateMachine.last_action_was_party_wide = false
	TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)

func _build_spell_tooltip(spell: SpellData) -> String:
	var lines: Array[String] = []
	if not spell.description.strip_edges().is_empty():
		lines.append(spell.description.strip_edges())
	lines.append("Mana: %d" % spell.mana)

	var damage_text := _get_damage_text(spell)
	if not damage_text.is_empty():
		lines.append("Damage: %s" % damage_text)

	return "\n".join(lines)

func _get_damage_text(spell: SpellData) -> String:
	if spell.targets_party_members() or spell.is_buff:
		return ""

	var dice := spell.get_damage_dice()
	if dice.x > 0 and dice.y > 0:
		var rolls := SpellExecutor.get_spell_dice_rolls(spell, current_character)
		var magic_amp := current_character.get_magic_amp() if current_character != null else 0
		if magic_amp > 0:
			return "%dd%d + %d" % [rolls, dice.y, magic_amp]
		return "%dd%d" % [rolls, dice.y]

	if spell.amount > 0:
		return str(spell.amount)

	return ""

func _on_selected_character_changed(character: ClassData) -> void:
	set_character(character)

func _on_party_member_stats_changed(character: ClassData) -> void:
	if character == current_character:
		update_ui()
