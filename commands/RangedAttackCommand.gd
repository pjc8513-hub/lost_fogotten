# RangedAttackCommand.gd

extends Command
class_name RangedAttackCommand

# Set these before queuing the command
var element: String = "physical"
var is_player_attacker: bool = false


func execute():
	var valid_targets = []
	for member in PartyState.active_party:
		if member.current_hp > 0:
			valid_targets.append(member)
			
	if valid_targets.is_empty():
		print("[RangedAttackCommand] no valid targets")
		var msg := "[color=gray]%s looks for a target, but the party is dead.[/color]" % actor.enemy_data.enemy_name
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return
		
	var target = valid_targets.pick_random()

	var attacks = 1
	if actor.enemy_data.attack_speed > 0:
		if randi_range(1, 100) <= (actor.enemy_data.attack_speed * 10):
			attacks = 2

	for i in range(attacks):
		if target.current_hp <= 0:
			print("[RangedAttackCommand] target died before attack", i)
			break

		await _perform_single_ranged_attack(target)

	actor.enemy_data.cooldown = 8
	emit_signal("finished")

func _perform_single_ranged_attack(target) -> void:
	# 1. Accuracy roll
	var accuracy : int = actor.get_accuracy() if actor.has_method("get_accuracy") else 0
	
	var target_ac = target.get_armor_class() if target.has_method("get_armor_class") else target.armor_class
	var outcome = CombatLogic.accuracy_roll(accuracy, target_ac)
	
	var target_pos = Vector3.ZERO
	if target is Enemy:
		target_pos = target.global_position
	else:
		var p = World.get_player()
		if p != null:
			target_pos = p.global_position
			
	GameEvents.spell_projectile_cast.emit(actor.global_position, target_pos, "res://ArrowScene.tscn")
	await actor.get_tree().create_timer(0.5).timeout
	
	if outcome == "miss":
		var msg = "[color=gray]%s[/color] fires at %s — [color=gray]miss![/color]" % [
			actor.enemy_data.enemy_name, target.member_name
		]
		GameEvents.message_logged.emit(msg)
		return
	
	# 2. Roll dice
	var raw := CombatLogic.roll_dice(actor.enemy_data.dice_rolls, actor.enemy_data.dice_sides, actor.enemy_data.bonus_damage)
	if outcome == "crit":
		raw *= 2
	
	# 3. Might bonus (enemies don't have might; only player actors would)
	if is_player_attacker and actor.has_method("get_might"):
		raw += CombatLogic.might_bonus(actor.get_might())
	
	# 4. Resistance
	var resist : int = target.get_resistance(element) if target.has_method("get_resistance") else 0
	var final_damage := CombatLogic.apply_resistance(raw, resist)
	
	# 5. Status proc
	CombatLogic.proc_status(
		actor.enemy_data.ailment,
		5,
		target
	)
	
	# 6. Emit and apply
	var crit_tag := " [color=yellow]CRITICAL![/color]" if outcome == "crit" else ""
	var msg := "[color=red]%s[/color] fires at [color=white]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		actor.enemy_data.enemy_name, target.member_name, final_damage, crit_tag
	]
	GameEvents.message_logged.emit(msg)
	
	GameEvents.emit_signal("attack_animation_started", actor, target, final_damage)
	if actor and actor.has_signal("attack_animation_completed"):
		await actor.attack_animation_completed
	else:
		print("[RangedAttackCommand] actor missing attack_animation_completed signal")
	GameEvents.emit_signal("damage_animation_started", target, final_damage)
	target.take_damage(final_damage)
	GameEvents.emit_signal("attack_animation_finished", actor, target)
	
	if target.current_hp <= 0:
		var death_msg := "[color=white]%s[/color] dies!" % target.member_name
		GameEvents.message_logged.emit(death_msg)
