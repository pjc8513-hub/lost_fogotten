extends Node

const SPELL_RANGE := 6

func build_request(spell: SpellData, caster: ClassData) -> SpellCastRequest:
	var request := SpellCastRequest.new()
	request.spell_data = spell
	request.caster = caster
	if spell == null:
		request.validation_errors.append("That melody does not match a known spell.")
	elif caster == null:
		request.validation_errors.append("No caster selected.")
	elif caster.current_hp <= 0:
		request.validation_errors.append("%s cannot cast while defeated." % caster.member_name)
	elif caster.blocks_spell_casting():
		request.validation_errors.append("%s is prevented from casting." % caster.member_name)
	elif caster.current_mp < spell.mana and not _can_cast_without_mana(spell):
		request.validation_errors.append("%s does not have enough mana." % caster.member_name)
	request.is_valid = request.validation_errors.is_empty()
	return request

func execute_request(request: SpellCastRequest, target_enemy: Enemy = null) -> SpellResult:
	var result := SpellResult.new()
	if request == null or not request.is_valid:
		return result

	var spell := request.spell_data
	var caster := request.caster
	result.spell_data = spell

	if not spell.special_effect.strip_edges().is_empty():
		var mana_already_spent := _execute_special_effect(spell, caster)
		if mana_already_spent < 0:
			return result
		var remaining_mana_cost: int = maxi(0, spell.mana - mana_already_spent)
		caster.current_mp -= remaining_mana_cost
		result.success = true
		result.mana_spent = spell.mana
		return result

	var targets := _resolve_targets(spell, caster, target_enemy)
	if _requires_target(spell) and targets.is_empty():
		GameEvents.message_logged.emit("[color=gray]The spell needs a valid target.[/color]")
		return result

	caster.current_mp -= spell.mana
	result.mana_spent = spell.mana
	GameEvents.message_logged.emit("[color=cyan]%s[/color] casts [color=gold]%s[/color] for [color=skyblue]%d[/color] mana." % [
		caster.member_name,
		spell.get_display_name(),
		spell.mana
	])

	_play_projectile(spell, targets)
	for target in targets:
		_apply_spell_to_target(spell, caster, target)
		result.affected_targets.append(target)

	result.success = true
	return result

func roll_spell_damage(spell: SpellData, caster: ClassData) -> int:
	if spell == null:
		return 0
	var dice := spell.get_damage_dice()
	if dice.x <= 0 or dice.y <= 0:
		return max(0, spell.amount)
	var magic_bonus := caster.get_magic_amp() if caster != null else 0
	return CombatLogic.roll_dice(dice.x, dice.y, magic_bonus)

func apply_damage_to_target(target, raw_damage: int, spell: SpellData) -> void:
	if raw_damage <= 0:
		return
	var element := SpellData.element_name(spell.spellbook).to_lower()
	var resistance := 0
	if target is Enemy:
		resistance = target.enemy_data.get_resistance(element)
	var final_damage := CombatLogic.apply_resistance(raw_damage, resistance)
	if target is Enemy:
		final_damage = CombatLogic.apply_damage_status_bonuses(target, final_damage)
		target.enemy_data.hp -= final_damage
		GameEvents.enemy_took_damage.emit(target, final_damage)
		GameEvents.message_logged.emit("[color=red]%s[/color] takes [color=orange]%d[/color] %s damage." % [
			target.enemy_data.enemy_name, final_damage, element
		])
		if target.enemy_data.hp <= 0:
			GameEvents.message_logged.emit("[color=red]%s dies![/color]" % target.enemy_data.enemy_name)
			LootDistributor.distribute_enemy_loot(target)
			LootDistributor.distribute_xp(target.enemy_data.xp)
			World.remove_enemy(target)
	elif target is ClassData:
		target.take_damage(final_damage)

func _resolve_targets(spell: SpellData, caster: ClassData, target_enemy: Enemy) -> Array:
	if spell.is_heal or spell.is_buff:
		if spell.is_aoe:
			return PartyState.active_party.filter(func(member): return member != null and member.current_hp > 0)
		return [caster]

	var resolved_target := target_enemy
	if resolved_target == null and CombatState.has_valid_target():
		resolved_target = CombatState.targeted_enemy
	if not _is_reachable_enemy(resolved_target):
		return []
	if not spell.is_aoe:
		return [resolved_target]

	var targets: Array = []
	for enemy in CombatState.get_engaged_enemies():
		if _is_reachable_enemy(enemy):
			targets.append(enemy)
	return targets

func _apply_spell_to_target(spell: SpellData, caster: ClassData, target) -> void:
	if spell.is_heal:
		if target is ClassData and not target.blocks_hp_healing():
			var heal_amount := roll_spell_damage(spell, caster)
			if heal_amount <= 0:
				heal_amount = max(0, spell.amount)
			target.current_hp = min(target.get_max_hp(), target.current_hp + heal_amount)
			GameEvents.message_logged.emit("[color=green]%s recovers %d HP.[/color]" % [target.member_name, heal_amount])
		return

	if spell.is_buff:
		for stat_name in spell.stats.keys():
			var stat_amount := int(spell.stats[stat_name])
			if target is ClassData:
				target.apply_combat_buff(
					str(stat_name),
					stat_amount,
					-1 if spell.duration_mode == SpellData.DurationMode.WORLD_STEPS else spell.duration
				)
			elif target is Enemy:
				target.enemy_data.apply_combat_buff(
					str(stat_name),
					stat_amount,
					-1 if spell.duration_mode == SpellData.DurationMode.WORLD_STEPS else spell.duration
				)
		if spell.duration_mode == SpellData.DurationMode.WORLD_STEPS:
			SpellEffectTracker.add_step_buff(spell, target)

	var damage := roll_spell_damage(spell, caster)
	if damage > 0 and not spell.is_dot:
		apply_damage_to_target(target, damage, spell)
	if spell.is_dot:
		SpellEffectTracker.add_damage_over_time(spell, caster, target)

func _execute_special_effect(spell: SpellData, caster: ClassData) -> int:
	match spell.special_effect.strip_edges().to_lower():
		"torchlight", "torch_light":
			var mana_before := caster.current_mp
			var was_lit := PartyState.is_magic_torch_lit
			var success := PartyState.toggle_magic_torch(caster)
			if success:
				var action := "extinguishes" if was_lit else "summons"
				GameEvents.message_logged.emit("[color=cyan]%s[/color] %s a [color=green]magic torch[/color]." % [caster.member_name, action])
				return mana_before - caster.current_mp
			return -1
		"levitate":
			World.set_world_effect("levitate", spell.duration)
			GameEvents.message_logged.emit("[color=cyan]The party begins to levitate.[/color]")
			return 0
		_:
			push_warning("SpellExecutor: Unknown special effect '%s'." % spell.special_effect)
			return -1

func _requires_target(spell: SpellData) -> bool:
	return not spell.is_heal and not spell.is_buff and spell.special_effect.strip_edges().is_empty()

func _can_cast_without_mana(spell: SpellData) -> bool:
	var special_id := spell.special_effect.strip_edges().to_lower()
	return special_id in ["torchlight", "torch_light"] and PartyState.is_magic_torch_lit

func _is_reachable_enemy(enemy: Enemy) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.enemy_data.hp <= 0:
		return false
	var player: Node3D = World.get_player()
	if player == null:
		return false
	var difference = (player.grid_position - enemy.grid_position).abs()
	return max(difference.x, difference.y) <= SPELL_RANGE and World.has_line_of_sight(player.grid_position, enemy.grid_position)

func _play_projectile(spell: SpellData, targets: Array) -> void:
	if spell.projectile_scene_path.is_empty() or targets.is_empty() or not targets[0] is Enemy:
		return
	var player: Node3D = World.get_player()
	if player != null:
		GameEvents.spell_projectile_cast.emit(player.global_position, targets[0].global_position, spell.projectile_scene_path)
