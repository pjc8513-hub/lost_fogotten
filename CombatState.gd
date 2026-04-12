# CombatState.gd
extends Node

# The enemy the player has selected as their current target
var targeted_enemy: Enemy = null

# Which party member is acting this action (default to index 0 for now;
# the party combat order system will set this properly later)
var acting_member_index: int = 0
var current_actor: Variant = null: get = get_current_actor

var combatants: Array = []
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
			return true
		acting_member_index += 1
	return false

func reset_party_turn():
	acting_member_index = 0
	if PartyState.active_party.size() > 0:
		var member = PartyState.active_party[0]
		if _is_dead(member):
			advance_party_member()

func set_target(enemy: Enemy) -> void:
	targeted_enemy = enemy

func clear_target() -> void:
	targeted_enemy = null

func has_valid_target() -> bool:
	return targeted_enemy != null and targeted_enemy.enemy_data.hp > 0

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

	# Add enemies
	for enemy in World.enemies:
		combatants.append(enemy)

	# Sort by initiative (descending)
	combatants.sort_custom(_sort_by_initiative)
	
func _sort_by_initiative(a, b):
	return b.initiative - a.initiative

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
		if actor.cooldown > 0:
			actor.cooldown -= 1
			continue

		# Found the next actor
		current_actor = actor
		return

func _is_dead(actor):
	if actor is Enemy:
		return actor.enemy_data.current_hp <= 0
	if actor is ClassData:
		return actor.current_hp <= 0
	return false
