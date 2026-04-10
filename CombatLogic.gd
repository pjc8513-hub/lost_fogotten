# CombatLogic.gd
extends Node

static func roll_dice(expression: String) -> int:
	# Handles "2d6+3", "1d8", "1d4-1", etc.
	var result := 0
	var expr := expression.to_lower().strip_edges()
	
	var bonus := 0
	var plus_idx := expr.rfind("+")
	var minus_idx := expr.rfind("-", expr.find("d") + 1) # avoid "d" itself
	
	if plus_idx != -1:
		bonus = int(expr.substr(plus_idx + 1))
		expr = expr.substr(0, plus_idx)
	elif minus_idx != -1:
		bonus = -int(expr.substr(minus_idx + 1))
		expr = expr.substr(0, minus_idx)
	
	var parts := expr.split("d")
	if parts.size() == 2:
		var num_dice : int = max(1, int(parts[0])) if parts[0] != "" else 1
		var die_size := int(parts[1])
		for i in range(num_dice):
			result += randi_range(1, die_size)
	
	return max(0, result + bonus)

static func accuracy_roll(attacker_accuracy: int, target_ac: int) -> String:
	# Returns "miss", "hit", or "crit"
	var roll := randi_range(1, 20)
	if roll == 20:
		return "crit"
	if roll + attacker_accuracy >= target_ac:
		return "hit"
	return "miss"

static func might_bonus(might: int) -> int:
	return might / 5  # +1 per 5 points; integer division floors it

static func apply_resistance(damage: int, resist_percent: int) -> int:
	return max(0, int(damage * (1.0 - resist_percent / 100.0)))

static func proc_status(ailment: String, chance_percent: int, target) -> void:
	if ailment == "none" or ailment == "":
		return
	if randi_range(1, 100) <= chance_percent:
		if target.has_method("add_status_effect"):
			target.add_status_effect(ailment)
