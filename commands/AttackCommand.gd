# AttackCommand.gd

extends Command
class_name AttackCommand

# Set these before queuing the command
var element: String = "physical"
var is_player_attacker: bool = false


func execute():
	#print("[AttackCommand] execute actor=", actor)
	var valid_targets = []
	for member in PartyState.active_party:
		if member.current_hp > 0:
			valid_targets.append(member)
			
	if valid_targets.is_empty():
		print("[AttackCommand] no valid targets")
		var msg := "[color=gray]%s looks for a target, but the party is dead.[/color]" % actor.enemy_data.enemy_name
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return
		
	var target = valid_targets.pick_random()
	#print("[AttackCommand] chosen target=", target.member_name)

	var attacks = 1
	var attack_speed = actor.enemy_data.get_attack_speed() if actor.enemy_data.has_method("get_attack_speed") else actor.enemy_data.attack_speed
	if attack_speed > 0:
		if randi_range(1, 100) <= (attack_speed * 10):
			attacks = 2
	#print("[AttackCommand] attacks=", attacks)

	for i in range(attacks):
		if target.current_hp <= 0:
			print("[AttackCommand] target died before attack", i)
			break

		#print("[AttackCommand] begin attack index=", i)
		await _perform_single_attack(target)
		#print("[AttackCommand] attack index complete=", i)

	#print("[AttackCommand] all attacks complete -> emit finished")
	actor.enemy_data.cooldown = 8
	emit_signal("finished")

func _perform_single_attack(target) -> void:
	#print("[AttackCommand] _perform_single_attack target=", target.member_name)
	# 1. Accuracy roll
	
	var accuracy : int = actor.get_accuracy()  if actor.has_method("get_accuracy") else 0
	
	var target_ac = target.get_armor_class() if target.has_method("get_armor_class") else target.armor_class
	var outcome = CombatLogic.accuracy_roll(accuracy, target_ac)
	#print("[AttackCommand] outcome=", outcome, " accuracy=", accuracy, " armor=", target.armor_class)
	
	if CombatLogic.is_miss_outcome(outcome):
		var msg = "[color=gray]%s[/color] attacks %s — [color=gray]miss![/color]" % [
			actor.enemy_data.enemy_name, target.member_name
		]
		GameEvents.message_logged.emit(msg)
		#print("[AttackCommand] miss -> return")
		return
	
	# 2. Roll dice
	var damage_bonus = actor.enemy_data.get_bonus_damage() if actor.enemy_data.has_method("get_bonus_damage") else actor.enemy_data.bonus_damage
	var raw := CombatLogic.roll_dice(actor.enemy_data.dice_rolls, actor.enemy_data.dice_sides, damage_bonus)
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
		target,
		-1,
		true,
		StatusEffects.DEFAULT_SAVE_DC,
		actor.enemy_data.tier
	)
	
	# 6. Emit and apply
	var crit_tag := " [color=yellow]CRITICAL![/color]" if outcome == "crit" else ""
	var msg := "[color=red]%s[/color] hits [color=white]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		actor.enemy_data.enemy_name, target.member_name, final_damage, crit_tag
	]
	GameEvents.message_logged.emit(msg)
	
	#print("[AttackCommand] emit attack_animation_started")
	GameEvents.emit_signal("attack_animation_started", actor, target, final_damage)
	if actor and actor.has_signal("attack_animation_completed"):
		#print("[AttackCommand] awaiting attack_animation_completed from actor")
		await actor.attack_animation_completed
		#print("[AttackCommand] resumed after attack_animation_completed")
	else:
		print("[AttackCommand] actor missing attack_animation_completed signal")
	GameEvents.emit_signal("damage_animation_started", target, final_damage)
	SfxManager.play_sfx("hit")
	target.take_damage(final_damage)
	#print("[AttackCommand] damage applied final_damage=", final_damage, " target_hp=", target.current_hp)
	GameEvents.emit_signal("attack_animation_finished", actor, target)
	
	if target.current_hp <= 0:
		var death_msg := "[color=white]%s[/color] dies!" % target.member_name
		GameEvents.message_logged.emit(death_msg)
		#print("[AttackCommand] target died")
