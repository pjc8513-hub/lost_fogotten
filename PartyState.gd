# PartyState.gd (global)
extends Node

signal roster_changed
signal active_party_changed
signal magic_torch_toggled(is_active: bool)  # Emitted when magic torch turns on/off

const DEFAULT_PARTY_TEMPLATES: Array[ClassData] = [
	preload("res://data/classes/knight.tres"),
	preload("res://data/classes/monk.tres"),
	preload("res://data/classes/cleric.tres"),
	preload("res://data/classes/rogue.tres"),
	preload("res://data/classes/sorcerer.tres")
]
const MAX_ACTIVE_PARTY_SIZE := 5

var roster: Array[ClassData] = []
var active_party: Array[ClassData] = []
var _selected_index: int = 0
var selected_index: int:
	get:
		return _selected_index
	set(value):
		_set_selected_index(value)

var party_gold: int = 0:
	set(value):
		party_gold = max(0, value)
		GameEvents.gold_changed.emit(party_gold)

func add_gold(amount: int) -> void:
	if amount <= 0:
		return

	party_gold += amount

func remove_gold(amount: int) -> bool:
	if amount <= 0:
		return true

	if party_gold < amount:
		return false

	party_gold -= amount
	return true
		
var party_food: int = 5:
	set(value):
		party_food = max(0, value)
		GameEvents.food_changed.emit(party_food)

var party_torches: int = 2:
	set(value):
		party_torches = max(0, value)
		GameEvents.torch_changed.emit(party_torches)
var is_torch_lit: bool = false # Defaults to off when entering the first zone

# Magic Torch (Mana-based) tracking
var is_magic_torch_lit: bool = false
var magic_torch_caster: ClassData = null  # References who cast the magic torch
var magic_torch_step_counter: int = 0  # Counter for 1 mana every 2 steps

# DEBUG/CHEAT: God mode - invulnerability and party buffs for testing
var god_mode_active: bool = false

const SAVE_THROW_DIE_SIDES := 20
const SAVE_THROW_DEXTERITY_DIVISOR := 4.0
const DEFAULT_SAVE_THROW_SKILL := "reflex"

func _ready():
	roster.clear()
	active_party.clear()

func get_selected() -> ClassData:
	if active_party.is_empty():
		return null
	return active_party[_selected_index]

func select_member(index: int, allow_during_combat: bool = false) -> bool:
	if CombatState.is_in_combat() and not allow_during_combat:
		return false

	_set_selected_index(index)
	return true

func select_member_by_reference(member: ClassData, allow_during_combat: bool = false) -> bool:
	if member == null:
		return false

	var index := active_party.find(member)
	if index == -1:
		return false

	return select_member(index, allow_during_combat)

func reset_default_party() -> void:
	roster.clear()
	active_party.clear()

	for template in DEFAULT_PARTY_TEMPLATES:
		if template == null:
			continue
		var member := template.create_party_member_instance()
		roster.append(member)
		active_party.append(member)

	_emit_party_state_changed()
	
func get_active_party() -> Array[ClassData]:
	return active_party

func get_roster() -> Array[ClassData]:
	return roster

func add_roster_member(member: ClassData, add_to_party: bool = false) -> bool:
	if member == null or roster.has(member):
		return false

	roster.append(member)
	var added_to_party := false
	if add_to_party:
		added_to_party = add_member_to_party(member)

	roster_changed.emit()
	if not added_to_party:
		_normalize_selected_index()
	return true

func add_member_to_party(member: ClassData) -> bool:
	if member == null:
		return false
	if not roster.has(member):
		roster.append(member)
		roster_changed.emit()
	if active_party.has(member) or active_party.size() >= MAX_ACTIVE_PARTY_SIZE:
		return false

	active_party.append(member)
	_emit_party_state_changed()
	return true

func remove_member_from_party(member: ClassData) -> bool:
	if not active_party.has(member):
		return false

	active_party.erase(member)
	_emit_party_state_changed()
	return true

func delete_roster_member(member: ClassData) -> bool:
	if member == null or not roster.has(member):
		return false

	active_party.erase(member)
	roster.erase(member)
	_emit_party_state_changed()
	return true

func is_member_in_party(member: ClassData) -> bool:
	return active_party.has(member)

func is_party_full() -> bool:
	return active_party.size() >= MAX_ACTIVE_PARTY_SIZE

func can_set_out() -> bool:
	return not active_party.is_empty()

func clear_all_party_data() -> void:
	roster.clear()
	active_party.clear()
	_emit_party_state_changed()

func _emit_party_state_changed() -> void:
	roster_changed.emit()
	active_party_changed.emit()
	_normalize_selected_index()

func _normalize_selected_index() -> void:
	if active_party.is_empty():
		_selected_index = 0
		GameEvents.selected_character_changed.emit(null)
		return
	_selected_index = clamp(_selected_index, 0, active_party.size() - 1)
	GameEvents.selected_character_changed.emit(get_selected())

func _set_selected_index(value: int) -> void:
	if active_party.is_empty():
		_selected_index = 0
		GameEvents.selected_character_changed.emit(null)
		return

	_selected_index = clamp(value, 0, active_party.size() - 1)
	GameEvents.selected_character_changed.emit(get_selected())
	
	# Environmental damage
	# Inside PartyState.gd

func make_save_throw(member: ClassData, dc: int, skill_id: String = DEFAULT_SAVE_THROW_SKILL) -> Dictionary:
	if member == null:
		return {}

	var natural_roll := randi_range(1, SAVE_THROW_DIE_SIDES)
	var dexterity_bonus := _get_save_throw_dexterity_bonus(member)
	var skill_bonus := member.get_total_skill_bonus(skill_id) if skill_id != "" else 0
	var total := natural_roll + dexterity_bonus + skill_bonus

	return {
		"member": member,
		"dc": dc,
		"natural_roll": natural_roll,
		"dexterity_bonus": dexterity_bonus,
		"skill_id": skill_id,
		"skill_bonus": skill_bonus,
		"total": total,
		"success": total >= dc,
	}

func damage_entire_party_with_save_throw(amount: int, dc: int, label: String = "Trap", skill_id: String = DEFAULT_SAVE_THROW_SKILL) -> void:
	if god_mode_active:
		return

	for member in active_party:
		if member == null or member.current_hp <= 0:
			continue

		var save_result := make_save_throw(member, dc, skill_id)
		_log_save_throw_result(save_result, label)
		if bool(save_result.get("success", false)):
			continue

		var died = member.take_damage(amount)
		GameEvents.message_logged.emit("[color=red]%s takes %d %s damage![/color]" % [
			member.member_name,
			amount,
			label.to_lower()
		])
		if died:
			GameEvents.message_logged.emit("[color=red]%s dies![/color]" % member.member_name)

func _get_save_throw_dexterity_bonus(member: ClassData) -> int:
	return max(0, int(floor(float(member.get_dexterity() - 10) / SAVE_THROW_DEXTERITY_DIVISOR)))

func _log_save_throw_result(save_result: Dictionary, label: String) -> void:
	var member := save_result.get("member", null) as ClassData
	if member == null:
		return

	var color := "green" if bool(save_result.get("success", false)) else "red"
	var outcome := "succeeds" if bool(save_result.get("success", false)) else "fails"
	var skill_id := String(save_result.get("skill_id", ""))
	var skill_bonus := int(save_result.get("skill_bonus", 0))
	var skill_text := ""
	if skill_id != "" and skill_bonus != 0:
		skill_text = " + %s %d" % [skill_id.capitalize(), skill_bonus]

	GameEvents.message_logged.emit("[color=%s]%s %s save %s: %d + Dex %d%s = %d vs DC %d[/color]" % [
		color,
		member.member_name,
		label,
		outcome,
		int(save_result.get("natural_roll", 0)),
		int(save_result.get("dexterity_bonus", 0)),
		skill_text,
		int(save_result.get("total", 0)),
		int(save_result.get("dc", 0))
	])

## Picks one random living party member and applies the damage to them
func damage_random_member(amount: int) -> String:
	# DEBUG: Skip damage in god mode
	if god_mode_active:
		return ""
	
	var living_members = []
	
	for member in active_party:
		if member and member.current_hp > 0:
			living_members.append(member)
			
	if living_members.size() > 0:
		var target = living_members.pick_random()
		target.take_damage(amount)
		return target.character_name # Returns name so you can print it in a log
		
	return ""

## Damages all living party members by a specified amount
func damage_entire_party(amount: int) -> void:
	# DEBUG: Skip damage in god mode
	if god_mode_active:
		return
	
	# active_party contains ClassData instances directly
	for member in active_party:
		if member and member.current_hp > 0:
			member.take_damage(amount)

## Toggles the magic torch on/off (cast by a party member using mana)
func toggle_magic_torch(caster: ClassData) -> bool:
	if is_magic_torch_lit:
		# Turn off the magic torch
		is_magic_torch_lit = false
		magic_torch_caster = null
		magic_torch_step_counter = 0
		magic_torch_toggled.emit(false)
		return true
	else:
		# Turn on the magic torch (caster must have enough mana for initial cast)
		if caster == null or caster.current_mp < 1:
			return false
		is_magic_torch_lit = true
		magic_torch_caster = caster
		magic_torch_step_counter = 0
		caster.current_mp -= 1  # Initial mana cost to activate
		magic_torch_toggled.emit(true)
		return true

## Consumes mana for the active magic torch (called each step) - 1 mana per 2 steps
func drain_magic_torch_mana() -> bool:
	if not is_magic_torch_lit or magic_torch_caster == null:
		is_magic_torch_lit = false
		magic_torch_caster = null
		magic_torch_step_counter = 0
		return false
	
	magic_torch_step_counter += 1
	
	# Deduct mana every 2 steps
	if magic_torch_step_counter >= 2:
		if magic_torch_caster.current_mp < 1:
			# Not enough mana to sustain the torch
			is_magic_torch_lit = false
			magic_torch_caster = null
			magic_torch_step_counter = 0
			magic_torch_toggled.emit(false)
			GameEvents.message_logged.emit("[color=cyan]The magic torch fades as mana runs dry.[/color]")
			return false
		
		magic_torch_caster.current_mp -= 1
		magic_torch_step_counter = 0
	
	return true
