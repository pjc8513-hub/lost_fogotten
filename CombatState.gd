# CombatState.gd
extends Node

# The enemy the player has selected as their current target
var targeted_enemy: Enemy = null

# Which party member is acting this action (default to index 0 for now;
# the party combat order system will set this properly later)
var acting_member_index: int = 0

func get_acting_member() -> ClassData:
	if PartyState.active_party.is_empty():
		return null
	acting_member_index = clamp(acting_member_index, 0, PartyState.active_party.size() - 1)
	return PartyState.active_party[acting_member_index]

func set_target(enemy: Enemy) -> void:
	targeted_enemy = enemy

func clear_target() -> void:
	targeted_enemy = null

func has_valid_target() -> bool:
	return targeted_enemy != null and targeted_enemy.enemy_data.hp > 0
