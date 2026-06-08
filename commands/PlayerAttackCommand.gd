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

	if not World.has_line_of_sight(player_node.grid_position, target_enemy.grid_position):
		GameEvents.message_logged.emit("[color=gray]%s is behind cover. Turn wasted.[/color]" % target_enemy.enemy_data.enemy_name)
		emit_signal("finished")
		return

	# Calculate 8-directional distance for range check
	var grid_diff = (player_node.grid_position - target_enemy.grid_position).abs()
	var dist: float = max(grid_diff.x, grid_diff.y)  # Chebyshev distance for 8-directional
	var attack_slot := _get_attack_slot(dist)

	var attacks = 1
	var total_speed = attacker.get_total_attack_speed(attack_slot)
	var attack_speed_roll := 0
	var attack_speed_threshold = max(0, total_speed * 10)
	if total_speed > 0:
		attack_speed_roll = randi_range(1, 100)
		if attack_speed_roll <= attack_speed_threshold:
			attacks = 2
	var sequence_context := {
		"attack_slot": ItemData.Equip_Slot.keys()[attack_slot],
		"total_attack_speed": total_speed,
		"extra_attack_threshold": attack_speed_threshold,
		"extra_attack_roll": attack_speed_roll,
		"attacks_granted": attacks
	}

	for i in range(attacks):
		if target_enemy == null or not is_instance_valid(target_enemy) or target_enemy.enemy_data.hp <= 0:
			break

		if dist <= MELEE_RANGE:
			await _do_melee(attacker, target_enemy, sequence_context, i + 1)
		else:
			await _do_ranged_or_skip(attacker, target_enemy, dist, sequence_context, i + 1)
		
	actor.cooldown = 2
	emit_signal("finished")

func _get_attack_slot(dist: float) -> ItemData.Equip_Slot:
	if dist <= MELEE_RANGE:
		return ItemData.Equip_Slot.WEAPON
	return ItemData.Equip_Slot.RANGE

func _do_melee(attacker: ClassData, target: Enemy, sequence_context: Dictionary, attack_index: int) -> void:
	var slot := ItemData.Equip_Slot.WEAPON
	var log_entry := _create_attack_log(attacker, target, slot, "melee", sequence_context, attack_index)
	var accuracy_detail := _roll_accuracy_detail(attacker.get_attack_accuracy(slot), target.enemy_data.armor_class)
	var outcome: String = accuracy_detail["outcome"]
	log_entry["math_breakdown"]["rolls"]["accuracy"] = accuracy_detail

	if outcome == "crit_miss":
		GameEvents.message_logged.emit("[color=orange]%s critically misses![/color]" % attacker.member_name)
		var save_result := PartyState.make_save_throw(attacker, CombatLogic.CRITICAL_MISS_SAVE_DC)
		log_entry["math_breakdown"]["rolls"]["critical_miss_save"] = _sanitize_save_result(save_result)
		log_entry["outcome"] = "crit_miss"
		CombatLogger.log_attack(log_entry)
		CombatLogic.handle_party_critical_miss_save_result(attacker, save_result)
		return

	if outcome == "miss":
		var msg := "[color=white]%s[/color] swings at [color=red]%s[/color] — [color=gray]miss![/color]" % [
			attacker.member_name, target.enemy_data.enemy_name
		]
		GameEvents.message_logged.emit(msg)
		log_entry["outcome"] = "miss"
		CombatLogger.log_attack(log_entry)
		return

	var critical_detail := _apply_attack_critical_chance_detail(attacker, slot, outcome)
	outcome = critical_detail["output_outcome"]
	log_entry["math_breakdown"]["rolls"]["critical_chance"] = critical_detail

	var damage_detail := _roll_damage_detail(
		attacker.get_dice_rolls(slot),
		attacker.get_dice_sides(slot),
		attacker.get_attack_bonus_damage(slot)
	)
	var raw: int = damage_detail["total"]
	log_entry["math_breakdown"]["rolls"]["damage_primary"] = damage_detail
	if _should_roll_polearm_mastery_damage(attacker, slot):
		var second_damage_detail := _roll_damage_detail(
			attacker.get_dice_rolls(slot),
			attacker.get_dice_sides(slot),
			attacker.get_attack_bonus_damage(slot)
		)
		log_entry["math_breakdown"]["rolls"]["damage_polearm_mastery_reroll"] = second_damage_detail
		log_entry["math_breakdown"]["skill_contributions"]["polearm_mastery"] = {
			"active": true,
			"primary_total": raw,
			"reroll_total": second_damage_detail["total"],
			"kept": max(raw, int(second_damage_detail["total"]))
		}
		raw = max(raw, int(second_damage_detail["total"]))
	var pre_crit_raw := raw
	if outcome == "crit":
		raw *= 2
	var might_damage_bonus := CombatLogic.might_bonus(attacker.get_attack_might(slot))
	raw += might_damage_bonus

	# Physical resist on enemy side
	var resist := target.enemy_data.get_resistance("physical")
	var final_damage := CombatLogic.apply_resistance(raw, resist)
	log_entry["math_breakdown"]["damage"] = {
		"pre_crit_raw": pre_crit_raw,
		"crit_multiplier": 2 if outcome == "crit" else 1,
		"might_damage_bonus": might_damage_bonus,
		"raw_after_crit_and_might": raw,
		"target_physical_resistance_percent": resist,
		"final_damage": final_damage
	}
	log_entry["math_breakdown"]["formulas"] = {
		"accuracy": "d20 + attack_accuracy >= 15 - target_ac",
		"damage": "apply_resistance(((kept_weapon_roll + attack_bonus_damage) * crit_multiplier) + might_bonus, physical_resist)"
	}

	var crit_tag := " [color=yellow]CRITICAL![/color]" if outcome == "crit" else ""
	var msg := "[color=white]%s[/color] strikes [color=red]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		attacker.member_name, target.enemy_data.enemy_name, final_damage, crit_tag
	]
	GameEvents.message_logged.emit(msg)
	target.enemy_data.hp -= final_damage
	GameEvents.enemy_took_damage.emit(target, final_damage)
	log_entry["outcome"] = outcome
	log_entry["target_hp_after"] = target.enemy_data.hp
	log_entry["math_breakdown"]["rolls"]["cudgel_mastery_stun"] = _try_apply_cudgel_mastery_stun(attacker, target)
	CombatLogger.log_attack(log_entry)
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
		


func _do_ranged_or_skip(attacker: ClassData, target: Enemy, dist: float, sequence_context: Dictionary, attack_index: int) -> void:
	if not attacker.has_ranged_weapon():
		var msg := "[color=gray]%s is too far away to attack with no ranged weapon. Turn wasted.[/color]" % attacker.member_name
		GameEvents.message_logged.emit(msg)
		return

	var max_range := attacker.get_ranged_weapon_range()
	if dist > max_range:
		var msg := "[color=gray]%s's ranged weapon cannot reach that far. Turn wasted.[/color]" % attacker.member_name
		GameEvents.message_logged.emit(msg)
		return

	var player_node = World.get_player()
	if player_node == null or not World.has_line_of_sight(player_node.grid_position, target.grid_position):
		GameEvents.message_logged.emit("[color=gray]%s can't get a clear shot at %s. Turn wasted.[/color]" % [
			attacker.member_name,
			target.enemy_data.enemy_name
		])
		return

	# Ranged attack — same pipeline, no resist override needed (will use weapon element later)
	var slot := ItemData.Equip_Slot.RANGE
	var log_entry := _create_attack_log(attacker, target, slot, "ranged", sequence_context, attack_index)
	var accuracy_detail := _roll_accuracy_detail(attacker.get_attack_accuracy(slot), target.enemy_data.armor_class)
	var outcome: String = accuracy_detail["outcome"]
	log_entry["math_breakdown"]["rolls"]["accuracy"] = accuracy_detail

	var p = player_node
	if p != null:
		GameEvents.spell_projectile_cast.emit(p.global_position, target.global_position, "res://ArrowScene.tscn")
		await p.get_tree().create_timer(0.5).timeout

	if outcome == "crit_miss":
		GameEvents.message_logged.emit("[color=orange]%s critically misses![/color]" % attacker.member_name)
		var save_result := PartyState.make_save_throw(attacker, CombatLogic.CRITICAL_MISS_SAVE_DC)
		log_entry["math_breakdown"]["rolls"]["critical_miss_save"] = _sanitize_save_result(save_result)
		log_entry["outcome"] = "crit_miss"
		CombatLogger.log_attack(log_entry)
		CombatLogic.handle_party_critical_miss_save_result(attacker, save_result)
		return

	if outcome == "miss":
		var msg := "[color=white]%s[/color] fires at [color=red]%s[/color] — [color=gray]miss![/color]" % [
			attacker.member_name, target.enemy_data.enemy_name
		]
		GameEvents.message_logged.emit(msg)
		log_entry["outcome"] = "miss"
		CombatLogger.log_attack(log_entry)
		return

	var critical_detail := _apply_attack_critical_chance_detail(attacker, slot, outcome)
	outcome = critical_detail["output_outcome"]
	log_entry["math_breakdown"]["rolls"]["critical_chance"] = critical_detail

	var damage_detail := _roll_damage_detail(
		attacker.get_dice_rolls(slot),
		attacker.get_dice_sides(slot),
		attacker.get_attack_bonus_damage(slot)
	)
	var raw: int = damage_detail["total"]
	log_entry["math_breakdown"]["rolls"]["damage_primary"] = damage_detail
	var pre_crit_raw := raw
	if outcome == "crit":
		raw *= 2
	var might_damage_bonus := CombatLogic.might_bonus(attacker.get_attack_might(slot))
	raw += might_damage_bonus

	var resist := target.enemy_data.get_resistance("physical")
	var final_damage := CombatLogic.apply_resistance(raw, resist)
	log_entry["math_breakdown"]["damage"] = {
		"pre_crit_raw": pre_crit_raw,
		"crit_multiplier": 2 if outcome == "crit" else 1,
		"might_damage_bonus": might_damage_bonus,
		"raw_after_crit_and_might": raw,
		"target_physical_resistance_percent": resist,
		"final_damage": final_damage
	}
	log_entry["math_breakdown"]["formulas"] = {
		"accuracy": "d20 + attack_accuracy >= 15 - target_ac",
		"damage": "apply_resistance(((weapon_roll + attack_bonus_damage) * crit_multiplier) + might_bonus, physical_resist)"
	}

	var crit_tag := " [color=yellow]CRITICAL![/color]" if outcome == "crit" else ""
	var msg := "[color=white]%s[/color] shoots [color=red]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		attacker.member_name, target.enemy_data.enemy_name, final_damage, crit_tag
	]
	GameEvents.message_logged.emit(msg)
	target.enemy_data.hp -= final_damage
	GameEvents.enemy_took_damage.emit(target, final_damage)
	log_entry["outcome"] = outcome
	log_entry["target_hp_after"] = target.enemy_data.hp
	CombatLogger.log_attack(log_entry)
	if target.enemy_data.hp <= 0:
		var death_msg := "[color=red]%s[/color] dies!" % target.enemy_data.enemy_name
		GameEvents.message_logged.emit(death_msg)
		# TODO: Drop loot here
		LootDistributor.distribute_enemy_loot(target)
		# Distribute xp
		LootDistributor.distribute_xp(target.enemy_data.xp)
		World.remove_enemy(target)

func _create_attack_log(attacker: ClassData, target: Enemy, slot: ItemData.Equip_Slot, attack_kind: String, sequence_context: Dictionary, attack_index: int) -> Dictionary:
	var weapon := attacker.get_equipped_weapon(slot)
	var armor := attacker.get_equipped_armor()
	return {
		"attacker": attacker.member_name,
		"target": target.enemy_data.enemy_name,
		"skill": "Basic %s attack" % attack_kind.capitalize(),
		"attack_kind": attack_kind,
		"attack_index": attack_index,
		"sequence": sequence_context.duplicate(true),
		"attacker_snapshot": CombatLogger.describe_character(attacker, slot),
		"target_snapshot": CombatLogger.describe_enemy(target),
		"math_breakdown": {
			"rolls": {},
			"attacker_stats": {
				"base_might": attacker.base_might,
				"effective_might": attacker.get_might(),
				"attack_might": attacker.get_attack_might(slot),
				"base_dexterity": attacker.base_dexterity,
				"effective_dexterity": attacker.get_dexterity(),
				"base_wisdom": attacker.base_wisdom,
				"effective_wisdom": attacker.get_wisdom(),
				"base_accuracy": attacker.get_accuracy(),
				"attack_accuracy": attacker.get_attack_accuracy(slot),
				"weapon_accuracy_penalty": attacker.get_weapon_accuracy_penalty(slot),
				"base_bonus_damage": attacker.get_bonus_damage(),
				"attack_bonus_damage": attacker.get_attack_bonus_damage(slot),
				"critical_chance": attacker.get_critical_chance(),
				"attack_critical_chance": attacker.get_attack_critical_chance(slot),
				"attack_speed_bonus": attacker.get_attack_speed_bonus(),
				"total_attack_speed": attacker.get_total_attack_speed(slot),
				"magic_amp": attacker.get_magic_amp(),
				"max_mp": attacker.get_max_mp()
			},
			"target_stats": {
				"armor_class": target.enemy_data.armor_class,
				"physical_resistance": target.enemy_data.get_resistance("physical"),
				"hp_before": target.enemy_data.hp
			},
			"gear_contributions": {
				"weapon": CombatLogger.describe_item(weapon),
				"armor": CombatLogger.describe_item(armor),
				"all_equipped": CombatLogger.describe_equipped_gear(attacker)
			},
			"skill_contributions": _get_attack_skill_contributions(attacker, slot),
			"formulas": {}
		}
	}

func _get_attack_skill_contributions(attacker: ClassData, slot: ItemData.Equip_Slot) -> Dictionary:
	var weapon := attacker.get_equipped_weapon(slot)
	var weapon_type := -1
	if weapon != null:
		weapon_type = weapon.weapon_type

	return {
		"blade_skill": {
			"rank": attacker.get_skill_rank_value("blade_skill"),
			"active": weapon_type == WeaponData.Weapon_Type.BLADE,
			"accuracy_penalty_removed": weapon_type == WeaponData.Weapon_Type.BLADE and attacker.has_skill("blade_skill")
		},
		"bow_skill": {
			"rank": attacker.get_skill_rank_value("bow_skill"),
			"active": weapon_type == WeaponData.Weapon_Type.BOW,
			"accuracy_penalty_removed": weapon_type == WeaponData.Weapon_Type.BOW and attacker.has_skill("bow_skill")
		},
		"poleaxe_skill": {
			"rank": attacker.get_skill_rank_value("poleaxe_skill"),
			"active": weapon_type == WeaponData.Weapon_Type.POLEARM or weapon_type == WeaponData.Weapon_Type.AXE,
			"accuracy_penalty_removed": (weapon_type == WeaponData.Weapon_Type.POLEARM or weapon_type == WeaponData.Weapon_Type.AXE) and attacker.has_skill("poleaxe_skill")
		},
		"blade_mastery": {
			"rank": attacker.get_skill_rank_value("blade_mastery"),
			"active": weapon_type == WeaponData.Weapon_Type.BLADE and attacker.has_skill("blade_mastery"),
			"attack_speed_bonus": ClassData.BLADE_MASTERY_ATTACK_SPEED_BONUS if weapon_type == WeaponData.Weapon_Type.BLADE and attacker.has_skill("blade_mastery") else 0
		},
		"bow_mastery": {
			"rank": attacker.get_skill_rank_value("bow_mastery"),
			"active": weapon_type == WeaponData.Weapon_Type.BOW and attacker.has_skill("bow_mastery"),
			"critical_chance_bonus": ClassData.BOW_MASTERY_CRITICAL_CHANCE_BONUS if weapon_type == WeaponData.Weapon_Type.BOW and attacker.has_skill("bow_mastery") else 0
		},
		"axe_mastery": {
			"rank": attacker.get_skill_rank_value("axe_mastery"),
			"active": weapon_type == WeaponData.Weapon_Type.AXE and attacker.has_skill("axe_mastery"),
			"might_bonus": ClassData.AXE_MASTERY_MIGHT_BONUS if weapon_type == WeaponData.Weapon_Type.AXE and attacker.has_skill("axe_mastery") else 0
		},
		"polearm_mastery": {
			"rank": attacker.get_skill_rank_value("polearm_mastery"),
			"active": weapon_type == WeaponData.Weapon_Type.POLEARM and attacker.has_skill("polearm_mastery")
		},
		"cudgel_mastery": {
			"rank": attacker.get_skill_rank_value("cudgel_mastery"),
			"active": weapon_type == WeaponData.Weapon_Type.CUDGEL and attacker.has_skill("cudgel_mastery"),
			"stun_chance_percent": 5 if weapon_type == WeaponData.Weapon_Type.CUDGEL and attacker.has_skill("cudgel_mastery") else 0
		},
		"heavy_armor_skill": {
			"rank": attacker.get_skill_rank_value("heavy_armor_skill"),
			"active": attacker.is_wearing_armor_type(ArmorData.Armor_Type.HEAVY),
			"attack_speed_penalty_after_skill": min(0, ClassData.HEAVY_ARMOR_ATTACK_SPEED_PENALTY + attacker.get_skill_rank_value("heavy_armor_skill")) if attacker.is_wearing_armor_type(ArmorData.Armor_Type.HEAVY) else 0
		},
		"light_armor_skill": {
			"rank": attacker.get_skill_rank_value("light_armor_skill"),
			"active": attacker.is_wearing_armor_type(ArmorData.Armor_Type.LIGHT),
			"mp_bonus": attacker.get_skill_rank_value("light_armor_skill") * ClassData.LIGHT_ARMOR_MP_PER_RANK if attacker.is_wearing_armor_type(ArmorData.Armor_Type.LIGHT) else 0
		},
		"staff_mastery": {
			"rank": attacker.get_skill_rank_value("staff_mastery"),
			"active": weapon_type == WeaponData.Weapon_Type.Staff and attacker.has_skill("staff_mastery"),
			"magic_amp_bonus": ClassData.STAFF_MASTERY_MAGIC_AMP_BONUS if weapon_type == WeaponData.Weapon_Type.Staff and attacker.has_skill("staff_mastery") else 0
		}
	}

func _roll_accuracy_detail(attacker_accuracy: int, target_ac: int) -> Dictionary:
	var d20_roll := randi_range(1, 20)
	var target_roll := 15 - target_ac
	var total := d20_roll + attacker_accuracy
	var outcome := "miss"
	if d20_roll == 1:
		outcome = "crit_miss"
	elif d20_roll == 20:
		outcome = "crit"
	elif total >= target_roll:
		outcome = "hit"

	return {
		"d20_roll": d20_roll,
		"attacker_accuracy": attacker_accuracy,
		"target_ac": target_ac,
		"target_roll": target_roll,
		"total": total,
		"outcome": outcome,
		"formula": "d20 + attacker_accuracy >= 15 - target_ac"
	}

func _roll_damage_detail(num_dice: int, die_size: int, bonus: int) -> Dictionary:
	var rolls: Array[int] = []
	var subtotal := 0
	for i in range(num_dice):
		var roll := randi_range(1, die_size)
		rolls.append(roll)
		subtotal += roll

	return {
		"num_dice": num_dice,
		"die_size": die_size,
		"rolls": rolls,
		"subtotal": subtotal,
		"bonus": bonus,
		"total": max(0, subtotal + bonus),
		"formula": "max(0, sum(rolls) + bonus)"
	}

func _apply_attack_critical_chance_detail(attacker: ClassData, slot: ItemData.Equip_Slot, outcome: String) -> Dictionary:
	var detail := {
		"input_outcome": outcome,
		"chance_percent": attacker.get_attack_critical_chance(slot),
		"roll": 0,
		"output_outcome": outcome,
		"formula": "roll <= attack_critical_chance"
	}
	if outcome == "crit" or CombatLogic.is_miss_outcome(outcome):
		return detail

	var roll := randi_range(1, 100)
	detail["roll"] = roll
	if roll <= attacker.get_attack_critical_chance(slot):
		detail["output_outcome"] = "crit"
	return detail

func _sanitize_save_result(save_result: Dictionary) -> Dictionary:
	return {
		"dc": int(save_result.get("dc", 0)),
		"natural_roll": int(save_result.get("natural_roll", 0)),
		"dexterity_bonus": int(save_result.get("dexterity_bonus", 0)),
		"skill_id": String(save_result.get("skill_id", "")),
		"skill_bonus": int(save_result.get("skill_bonus", 0)),
		"total": int(save_result.get("total", 0)),
		"success": bool(save_result.get("success", false))
	}

func _should_roll_polearm_mastery_damage(attacker: ClassData, slot: ItemData.Equip_Slot) -> bool:
	var weapon := attacker.get_equipped_weapon(slot)
	return weapon != null and weapon.weapon_type == WeaponData.Weapon_Type.POLEARM and attacker.has_skill("polearm_mastery")

func _try_apply_cudgel_mastery_stun(attacker: ClassData, target: Enemy) -> Dictionary:
	var detail := {
		"active": false,
		"chance_percent": 0,
		"roll": 0,
		"applied": false,
		"reason": ""
	}
	var weapon := attacker.get_equipped_weapon(ItemData.Equip_Slot.WEAPON)
	if weapon == null or weapon.weapon_type != WeaponData.Weapon_Type.CUDGEL or not attacker.has_skill("cudgel_mastery"):
		detail["reason"] = "not_using_cudgel_or_missing_cudgel_mastery"
		return detail
	if target.enemy_data.hp <= 0:
		detail["reason"] = "target_dead"
		return detail

	detail["active"] = true
	detail["chance_percent"] = 5
	var roll := randi_range(1, 100)
	detail["roll"] = roll
	if roll > 5:
		detail["reason"] = "roll_failed"
		return detail

	target.enemy_data.apply_status_effect("stun", 1, false)
	detail["applied"] = true
	detail["reason"] = "roll_succeeded"
	GameEvents.message_logged.emit("[color=yellow]%s is stunned![/color]" % target.enemy_data.enemy_name)
	return detail
