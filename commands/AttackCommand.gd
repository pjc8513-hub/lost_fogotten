# AttackCommand.gd

extends Command
class_name AttackCommand

# Set these before queuing the command
var element: String = "physical"
var is_player_attacker: bool = false


func execute():
	var valid_targets = []
	for member in PartyState.active_party:
		if member.current_hp > 0:
			valid_targets.append(member)
			
	if valid_targets.is_empty():
		var msg := "[color=gray]%s looks for a target, but the party is dead.[/color]" % actor.enemy_data.enemy_name
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return
		
	var target = valid_targets.pick_random()

	# 1. Accuracy roll
	
	var accuracy : int = actor.get_accuracy()  if actor.has_method("get_accuracy") else 0
	print ("Accuracy: ", accuracy)
	
	var outcome := CombatLogic.accuracy_roll(accuracy, target.armor_class)
	
	if outcome == "miss":
		var msg := "[color=gray]%s[/color] attacks %s — [color=gray]miss![/color]" % [
			actor.enemy_data.enemy_name, target.member_name
		]
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return
	
	# 2. Roll dice
	var raw := CombatLogic.roll_dice(actor.enemy_data.damage)
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
		actor.enemy_data.critical_chance,  # repurpose or add a status_chance field
		target
	)
	
	# 6. Emit and apply
	var crit_tag := " [color=yellow]CRITICAL![/color]" if outcome == "crit" else ""
	var msg := "[color=red]%s[/color] hits [color=white]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		actor.enemy_data.enemy_name, target.member_name, final_damage, crit_tag
	]
	GameEvents.message_logged.emit(msg)
	target.take_damage(final_damage)
	
	if target.current_hp <= 0:
		var death_msg := "[color=white]%s[/color] dies!" % target.member_name
		GameEvents.message_logged.emit(death_msg)
	
	actor.enemy_data.cooldown = 8
	emit_signal("finished")
