# PlayerAttackCommand.gd
extends Command
class_name PlayerAttackCommand

# actor here is a ClassData (the party member acting), not an Enemy node.
# This is the reverse of AttackCommand where actor is an Enemy node.

const MELEE_RANGE: int = 1

func execute() -> void:
	var attacker: ClassData = actor  # ClassData
	var target_enemy: Enemy = CombatState.targeted_enemy

	# Guard: target died between click and execution (another enemy killed them, etc.)
	if target_enemy == null or target_enemy.enemy_data.hp <= 0:
		var msg := "[color=gray]Target is no longer valid.[/color]"
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return

	# Get player's grid position from the player node
	var player_node = World.get_player()
	if player_node == null:
		emit_signal("finished")
		return

	var dist: float = player_node.grid_position.distance_to(target_enemy.grid_position)

	if dist <= MELEE_RANGE:
		_do_melee(attacker, target_enemy)
	else:
		_do_ranged_or_skip(attacker, target_enemy, dist)
		
	actor.cooldown = 2

func _do_melee(attacker: ClassData, target: Enemy) -> void:
	var outcome := CombatLogic.accuracy_roll(attacker.accuracy, target.enemy_data.armor_class)

	if outcome == "miss":
		var msg := "[color=white]%s[/color] swings at [color=red]%s[/color] — [color=gray]miss![/color]" % [
			attacker.member_name, target.enemy_data.enemy_name
		]
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return

	var raw := CombatLogic.roll_dice(attacker.dice_rolls, attacker.dice_sides, attacker.bonus_damage)
	if outcome == "crit":
		raw *= 2
	raw += CombatLogic.might_bonus(attacker.might)

	# Physical resist on enemy side
	var resist := target.enemy_data.get_resistance("physical")
	var final_damage := CombatLogic.apply_resistance(raw, resist)

	var crit_tag := " [color=yellow]CRITICAL![/color]" if outcome == "crit" else ""
	var msg := "[color=white]%s[/color] strikes [color=red]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		attacker.member_name, target.enemy_data.enemy_name, final_damage, crit_tag
	]
	GameEvents.message_logged.emit(msg)
	target.enemy_data.hp -= final_damage
	if target.enemy_data.hp <= 0:
		var death_msg := "[color=red]%s[/color] dies!" % target.enemy_data.enemy_name
		GameEvents.message_logged.emit(death_msg)
		World.remove_enemy(target)
		# TODO: Drop loot here

	emit_signal("finished")

func _do_ranged_or_skip(attacker: ClassData, target: Enemy, dist: float) -> void:
	if not attacker.has_ranged_weapon:
		var msg := "[color=gray]%s is too far away to attack with no ranged weapon. Turn wasted.[/color]" % attacker.member_name
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return

	# Ranged attack — same pipeline, no resist override needed (will use weapon element later)
	var outcome := CombatLogic.accuracy_roll(attacker.accuracy, target.enemy_data.armor_class)

	if outcome == "miss":
		var msg := "[color=white]%s[/color] fires at [color=red]%s[/color] — [color=gray]miss![/color]" % [
			attacker.member_name, target.enemy_data.enemy_name
		]
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return

	var raw := CombatLogic.roll_dice(attacker.dice_rolls, attacker.dice_sides, attacker.bonus_damage)
	if outcome == "crit":
		raw *= 2
	raw += CombatLogic.might_bonus(attacker.might)

	var resist := target.enemy_data.get_resistance("physical")
	var final_damage := CombatLogic.apply_resistance(raw, resist)

	var crit_tag := " [color=yellow]CRITICAL![/color]" if outcome == "crit" else ""
	var msg := "[color=white]%s[/color] shoots [color=red]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		attacker.member_name, target.enemy_data.enemy_name, final_damage, crit_tag
	]
	GameEvents.message_logged.emit(msg)
	target.enemy_data.hp -= final_damage
	if target.enemy_data.hp <= 0:
		var death_msg := "[color=red]%s[/color] dies!" % target.enemy_data.enemy_name
		GameEvents.message_logged.emit(death_msg)
		World.remove_enemy(target)
		# TODO: Drop loot here

	emit_signal("finished")
