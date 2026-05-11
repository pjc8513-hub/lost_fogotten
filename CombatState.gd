# CombatState.gd
extends Node

const COMBAT_RANGE: int = 6

enum CombatStatus { IDLE, WAITING, ACTING, STUN, DONE }

# The enemy the player has selected as their current target
var targeted_enemy: Enemy = null

# Which party member is acting this action (default to index 0 for now;
# the party combat order system will set this properly later)
var acting_member_index: int = 0
var current_actor: Variant = null: get = get_current_actor

var combatants: Array = []
var engaged_enemies: Array[Enemy] = []
var turn_index: int = 0

func get_acting_member() -> ClassData:
	if PartyState.active_party.is_empty():
		return null
	acting_member_index = clamp(acting_member_index, 0, PartyState.active_party.size() - 1)
	return PartyState.active_party[acting_member_index]

func advance_party_member() -> bool:
	acting_member_index += 1
	var size = PartyState.active_party.size()
	while acting_member_index < size:
		var member = PartyState.active_party[acting_member_index]
		if not _is_dead(member):
			if "stun" in member.status_effects:
				GameEvents.combat_status_changed.emit(member, CombatStatus.STUN)
				GameEvents.message_logged.emit("[color=yellow]" + member.member_name + " is stunned and skips their turn![/color]")
				member.status_effects.erase("stun")
				GameEvents.combat_status_changed.emit(member, CombatStatus.DONE)
				acting_member_index += 1
				continue
			_refresh_party_combat_statuses()
			_sync_selected_to_acting_member()
			return true
		acting_member_index += 1
	_refresh_party_combat_statuses()
	return false

func reset_party_turn():
	acting_member_index = -1
	advance_party_member()

func set_target(enemy: Enemy) -> void:
	#engage_enemy(enemy)
	targeted_enemy = enemy

func clear_target() -> void:
	targeted_enemy = null

func has_valid_target() -> bool:
	return targeted_enemy != null and is_instance_valid(targeted_enemy) and targeted_enemy.enemy_data.hp > 0

func is_in_combat() -> bool:
	return not engaged_enemies.is_empty()

func get_engaged_enemies() -> Array:
	return engaged_enemies.duplicate()

func engage_enemy(enemy: Enemy) -> void:
	var was_in_combat := is_in_combat()
	if not _is_valid_enemy(enemy):
		return
	if not engaged_enemies.has(enemy):
		engaged_enemies.append(enemy)
		rebuild_combatants()
	if not was_in_combat:
		_refresh_party_combat_statuses()
		_sync_selected_to_acting_member()

func disengage_enemy(enemy: Enemy) -> void:
	if engaged_enemies.has(enemy):
		engaged_enemies.erase(enemy)
		rebuild_combatants()
	if targeted_enemy == enemy:
		clear_target()

func refresh_combat_state() -> bool:
	var was_in_combat := is_in_combat()
	var refreshed: Array[Enemy] = []

	for enemy in engaged_enemies:
		if _should_remain_engaged(enemy):
			refreshed.append(enemy)

	for enemy in World.get_enemies():
		if _can_enter_combat(enemy) and not refreshed.has(enemy):
			refreshed.append(enemy)

	engaged_enemies = refreshed

	if World.selected_enemy != null and _is_valid_enemy(World.selected_enemy) and engaged_enemies.has(World.selected_enemy):
		set_target(World.selected_enemy)

	if targeted_enemy != null and (not is_instance_valid(targeted_enemy) or not engaged_enemies.has(targeted_enemy)):
		World.set_selected_enemy(null)

	rebuild_combatants()
	if not was_in_combat and is_in_combat():
		_refresh_party_combat_statuses()
		_sync_selected_to_acting_member()
	return was_in_combat and not is_in_combat()

func mark_current_member_done() -> void:
	if not is_in_combat():
		return

	var member = get_acting_member()
	if member == null or _is_dead(member):
		return

	GameEvents.combat_status_changed.emit(member, CombatStatus.DONE)

func clear_party_combat_statuses() -> void:
	for member in PartyState.active_party:
		GameEvents.combat_status_changed.emit(member, CombatStatus.IDLE)

func reset() -> void:
	targeted_enemy = null
	current_actor = null
	combatants.clear()
	engaged_enemies.clear()
	turn_index = 0
	acting_member_index = 0
	clear_party_combat_statuses()

func get_current_actor():
	# During PLAYER_INPUT, the actor should be the selected party member
	if TurnStateMachine.state == TurnStateMachine.State.PLAYER_INPUT:
		return get_acting_member()
	
	# During other states, use the combatants list if combat is active
	if combatants.size() > 0 and turn_index < combatants.size():
		return combatants[turn_index]
	
	return null

func rebuild_combatants():
	combatants.clear()

	# Add party members
	for member in PartyState.active_party:
		combatants.append(member)

	# Add enemies currently engaged with the party
	for enemy in engaged_enemies:
		combatants.append(enemy)

	# Sort by initiative (descending)
	combatants.sort_custom(_sort_by_initiative)
	
func _sort_by_initiative(a, b):
	return _get_initiative(b) - _get_initiative(a)

func next_turn():
	if combatants.is_empty():
		return

	while true:
		turn_index = (turn_index + 1) % combatants.size()
		var actor = combatants[turn_index]

		# Skip dead actors
		if _is_dead(actor):
			continue

		# Cooldown handling
		if _get_cooldown(actor) > 0:
			_set_cooldown(actor, _get_cooldown(actor) - 1)
			continue

		# Found the next actor
		current_actor = actor
		return

func _is_dead(actor):
	if actor is Enemy:
		return actor.enemy_data.hp <= 0
	if actor is ClassData:
		return actor.current_hp <= 0
	return false

func _can_enter_combat(enemy: Enemy) -> bool:
	if not _is_valid_enemy(enemy):
		return false
	var player = World.get_player()
	if player == null:
		return false
	if player.grid_position.distance_to(enemy.grid_position) > COMBAT_RANGE:
		return false
	return World.has_line_of_sight(player.grid_position, enemy.grid_position)

func _should_remain_engaged(enemy: Enemy) -> bool:
	if not _is_valid_enemy(enemy):
		return false
	var player = World.get_player()
	if player == null:
		return false
	return player.grid_position.distance_to(enemy.grid_position) <= COMBAT_RANGE

func _is_valid_enemy(enemy: Enemy) -> bool:
	return enemy != null and is_instance_valid(enemy) and enemy.enemy_data.hp > 0

func _get_initiative(actor) -> int:
	if actor is Enemy:
		return actor.enemy_data.initiative
	if actor is ClassData:
		return actor.get_initiative()
	return 0

func _get_cooldown(actor) -> int:
	if actor is Enemy:
		return actor.enemy_data.cooldown
	if actor is ClassData:
		return actor.cooldown
	return 0

func _set_cooldown(actor, value: int) -> void:
	if actor is Enemy:
		actor.enemy_data.cooldown = value
	elif actor is ClassData:
		actor.cooldown = value

func _refresh_party_combat_statuses() -> void:
	if not is_in_combat():
		clear_party_combat_statuses()
		return

	for index in range(PartyState.active_party.size()):
		var member = PartyState.active_party[index]
		if _is_dead(member):
			GameEvents.combat_status_changed.emit(member, CombatStatus.DONE)
		elif "stun" in member.status_effects:
			GameEvents.combat_status_changed.emit(member, CombatStatus.STUN)
		elif index < acting_member_index:
			GameEvents.combat_status_changed.emit(member, CombatStatus.DONE)
		elif index == acting_member_index:
			GameEvents.combat_status_changed.emit(member, CombatStatus.ACTING)
		else:
			GameEvents.combat_status_changed.emit(member, CombatStatus.WAITING)

func _sync_selected_to_acting_member() -> void:
	if not is_in_combat():
		return

	var acting_member := get_acting_member()
	if acting_member == null:
		return

	PartyState.select_member_by_reference(acting_member, true)
