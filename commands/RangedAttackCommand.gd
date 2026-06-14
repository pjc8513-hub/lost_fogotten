# RangedAttackCommand.gd

extends Command
class_name RangedAttackCommand

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


# Returns the grid position of any actor type (Enemy or ClassData/player).
func _get_actor_grid_pos(a) -> Vector2i:
	if a is Enemy:
		return a.grid_position
	# ClassData actors — get position via the player node.
	var player = World.get_player()
	if player != null:
		return player.grid_position
	return Vector2i(-9999, -9999)


# Returns the grid position of any target type (ClassData or Enemy).
func _get_target_grid_pos(t) -> Vector2i:
	if t is Enemy:
		return t.grid_position
	var player = World.get_player()
	if player != null:
		return player.grid_position
	return Vector2i(-9999, -9999)


func _perform_single_ranged_attack(target) -> void:
	# --- NEW: line-of-sight check ---
	var from_pos := _get_actor_grid_pos(actor)
	var to_pos   := _get_target_grid_pos(target)

	if not World.has_line_of_sight(from_pos, to_pos):
		var attacker_name = actor.enemy_data.enemy_name if actor is Enemy else (actor as ClassData).member_name
		var target_name   = target.member_name if target is ClassData else (target as Enemy).enemy_data.enemy_name
		var blocked_msg := "[color=gray]%s can't get a clear shot at %s — something is in the way.[/color]" % [attacker_name, target_name]
		GameEvents.message_logged.emit(blocked_msg)
		return
	# --------------------------------

	# 1. Fire projectile visual first (only when LOS is confirmed)
	var target_pos := Vector3.ZERO
	if target is Enemy:
		target_pos = target.global_position
	else:
		var p = World.get_player()
		if p != null:
			target_pos = p.global_position
	GameEvents.spell_projectile_cast.emit(actor.global_position, target_pos, "res://ArrowScene.tscn", 0.5)
	await actor.get_tree().create_timer(0.5).timeout

	# 2. Accuracy roll
	var accuracy : int = actor.get_accuracy() if actor.has_method("get_accuracy") else 0
	var target_ac = target.get_armor_class() if target.has_method("get_armor_class") else target.armor_class
	var outcome = CombatLogic.accuracy_roll(accuracy, target_ac)
	
	if CombatLogic.is_miss_outcome(outcome):
		var msg = "[color=gray]%s[/color] fires at %s — [color=gray]miss![/color]" % [
			actor.enemy_data.enemy_name, target.member_name
		]
		GameEvents.message_logged.emit(msg)
		return
	
	# 3. Roll dice
	var damage_bonus = actor.enemy_data.get_bonus_damage() if actor.enemy_data.has_method("get_bonus_damage") else actor.enemy_data.bonus_damage
	var raw := CombatLogic.roll_dice(actor.enemy_data.dice_rolls, actor.enemy_data.dice_sides, damage_bonus)
	if outcome == "crit":
		raw *= 2
	
	if is_player_attacker and actor.has_method("get_might"):
		raw += CombatLogic.might_bonus(actor.get_might())
	
	var resist : int = target.get_resistance(element) if target.has_method("get_resistance") else 0
	var final_damage := CombatLogic.apply_resistance(raw, resist)
	
	CombatLogic.proc_status(actor.enemy_data.ailment, target, -1, true, StatusEffects.DEFAULT_SAVE_DC, actor.enemy_data.tier)
	
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
