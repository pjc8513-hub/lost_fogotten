# CombatLogic.gd
extends Node

static func roll_dice(num_dice: int, die_size: int, bonus: int = 0) -> int:
	var result := 0
	for i in range(num_dice):
		result += randi_range(1, die_size)
	
	return max(0, result + bonus)

static func accuracy_roll(attacker_accuracy: int, target_ac: int) -> String:
	# Returns "miss", "hit", or "crit"
	var roll := randi_range(1, 20)
	if roll == 20:
		return "crit"
		
	# THAC0 15 system: minimum roll needed is 15 - AC
	var target_roll = 15 - target_ac
	if roll + attacker_accuracy >= target_roll:
		return "hit"
	return "miss"

static func might_bonus(might: int) -> int:
	return might / 5  # +1 per 5 points; integer division floors it

static func apply_resistance(damage: int, resist_percent: int) -> int:
	return max(0, int(damage * (1.0 - resist_percent / 100.0)))

static func proc_status(ailment: String, chance_percent: int, target, duration_rounds: int = -1, persists_after_combat: bool = true) -> void:
	if ailment == "none" or ailment == "":
		return
	if randi_range(1, 100) <= chance_percent:
		var effect_list = null
		var target_name = ""
		if target is ClassData:
			effect_list = target.status_effects
			target_name = target.member_name
		elif target is Node3D and target.has_method("get_accuracy"): # Basic check for Enemy
			effect_list = target.enemy_data.status_effects
			target_name = target.enemy_data.enemy_name
			
		if effect_list != null:
			var was_new: bool = not ailment in effect_list
			if target != null and target.has_method("apply_status_effect"):
				target.apply_status_effect(ailment, duration_rounds, persists_after_combat)
			elif target is Node3D and target.has_method("get_accuracy") and target.enemy_data.has_method("apply_status_effect"):
				target.enemy_data.apply_status_effect(ailment, duration_rounds, persists_after_combat)
			else:
				if was_new:
					effect_list.append(ailment)
			if was_new:
				GameEvents.message_logged.emit("[color=yellow]" + target_name + " is afflicted with " + ailment + "![/color]")
