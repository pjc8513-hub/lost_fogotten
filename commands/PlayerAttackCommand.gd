# PlayerAttackCommand.gd
extends Command
class_name PlayerAttackCommand

# actor here is a ClassData (the party member acting), not an Enemy node.
# This is the reverse of AttackCommand where actor is an Enemy node.

const MELEE_RANGE: int = 1  # 8-directional: max distance for adjacent tiles

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

	# Calculate 8-directional distance for range check
	var grid_diff = (player_node.grid_position - target_enemy.grid_position).abs()
	var dist: float = max(grid_diff.x, grid_diff.y)  # Chebyshev distance for 8-directional
	var attack_slot := _get_attack_slot(dist)

	var attacks = 1
	var total_speed = attacker.get_total_attack_speed(attack_slot)
	if total_speed > 0:
		if randi_range(1, 100) <= (total_speed * 10):
			attacks = 2

	for i in range(attacks):
		if target_enemy == null or not is_instance_valid(target_enemy) or target_enemy.enemy_data.hp <= 0:
			break

		if dist <= MELEE_RANGE:
			await _do_melee(attacker, target_enemy)
		else:
			await _do_ranged_or_skip(attacker, target_enemy, dist)
		
	actor.cooldown = 2
	emit_signal("finished")

func _get_attack_slot(dist: float) -> ItemData.Equip_Slot:
	if dist <= MELEE_RANGE:
		return ItemData.Equip_Slot.WEAPON
	return ItemData.Equip_Slot.RANGE

func _do_melee(attacker: ClassData, target: Enemy) -> void:
	var outcome := CombatLogic.accuracy_roll(attacker.get_accuracy(), target.enemy_data.armor_class)

	if outcome == "miss":
		var msg := "[color=white]%s[/color] swings at [color=red]%s[/color] — [color=gray]miss![/color]" % [
			attacker.member_name, target.enemy_data.enemy_name
		]
		GameEvents.message_logged.emit(msg)
		return

	var raw := CombatLogic.roll_dice(
		attacker.get_dice_rolls(ItemData.Equip_Slot.WEAPON),
		attacker.get_dice_sides(ItemData.Equip_Slot.WEAPON),
		attacker.get_bonus_damage()
	)
	if outcome == "crit":
		raw *= 2
	raw += CombatLogic.might_bonus(attacker.get_might())

	# Physical resist on enemy side
	var resist := target.enemy_data.get_resistance("physical")
	var final_damage := CombatLogic.apply_resistance(raw, resist)

	var crit_tag := " [color=yellow]CRITICAL![/color]" if outcome == "crit" else ""
	var msg := "[color=white]%s[/color] strikes [color=red]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		attacker.member_name, target.enemy_data.enemy_name, final_damage, crit_tag
	]
	GameEvents.message_logged.emit(msg)
	target.enemy_data.hp -= final_damage
	GameEvents.enemy_took_damage.emit(target, final_damage)
	if target.enemy_data.hp <= 0:
		var death_msg := "[color=red]%s[/color] dies!" % target.enemy_data.enemy_name
		GameEvents.message_logged.emit(death_msg)
		# TODO: Drop loot here
		LootDistributor.distribute_enemy_loot(target)
		#Distribute xp
		LootDistributor.distribute_xp(target.enemy_data.xp)
		World.remove_enemy(target)
	else:
		SfxManager.play_sfx("hit")
		


func _do_ranged_or_skip(attacker: ClassData, target: Enemy, dist: float) -> void:
	if not attacker.has_ranged_weapon():
		var msg := "[color=gray]%s is too far away to attack with no ranged weapon. Turn wasted.[/color]" % attacker.member_name
		GameEvents.message_logged.emit(msg)
		return

	var max_range := attacker.get_ranged_weapon_range()
	if dist > max_range:
		var msg := "[color=gray]%s's ranged weapon cannot reach that far. Turn wasted.[/color]" % attacker.member_name
		GameEvents.message_logged.emit(msg)
		return

	# Ranged attack — same pipeline, no resist override needed (will use weapon element later)
	var outcome := CombatLogic.accuracy_roll(attacker.get_accuracy(), target.enemy_data.armor_class)

	var p = World.get_player()
	if p != null:
		GameEvents.spell_projectile_cast.emit(p.global_position, target.global_position, "res://ArrowScene.tscn")
		await p.get_tree().create_timer(0.5).timeout

	if outcome == "miss":
		var msg := "[color=white]%s[/color] fires at [color=red]%s[/color] — [color=gray]miss![/color]" % [
			attacker.member_name, target.enemy_data.enemy_name
		]
		GameEvents.message_logged.emit(msg)
		return

	var raw := CombatLogic.roll_dice(
		attacker.get_dice_rolls(ItemData.Equip_Slot.RANGE),
		attacker.get_dice_sides(ItemData.Equip_Slot.RANGE),
		attacker.get_bonus_damage()
	)
	if outcome == "crit":
		raw *= 2
	raw += CombatLogic.might_bonus(attacker.get_might())

	var resist := target.enemy_data.get_resistance("physical")
	var final_damage := CombatLogic.apply_resistance(raw, resist)

	var crit_tag := " [color=yellow]CRITICAL![/color]" if outcome == "crit" else ""
	var msg := "[color=white]%s[/color] shoots [color=red]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		attacker.member_name, target.enemy_data.enemy_name, final_damage, crit_tag
	]
	GameEvents.message_logged.emit(msg)
	target.enemy_data.hp -= final_damage
	GameEvents.enemy_took_damage.emit(target, final_damage)
	if target.enemy_data.hp <= 0:
		var death_msg := "[color=red]%s[/color] dies!" % target.enemy_data.enemy_name
		GameEvents.message_logged.emit(death_msg)
		# TODO: Drop loot here
		LootDistributor.distribute_enemy_loot(target)
		# Distribute xp
		LootDistributor.distribute_xp(target.enemy_data.xp)
		World.remove_enemy(target)
