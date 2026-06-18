extends Node

const SPELL_RANGE := 6

var _pending_party_request: SpellCastRequest = null

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
	elif not meets_mastery_requirement(spell, caster):
		request.validation_errors.append(
			"%s needs %s Mastery rank %d to cast %s." % [
				caster.member_name,
				_get_spellbook_mastery_name(spell.spellbook),
				spell.spell_level,
				spell.get_display_name()
			]
		)
	elif caster.current_mp < spell.mana and not _can_cast_without_mana(spell):
		request.validation_errors.append("%s does not have enough mana." % caster.member_name)
	request.is_valid = request.validation_errors.is_empty()
	return request

func has_pending_party_target() -> bool:
	return _pending_party_request != null

func begin_party_targeting(request: SpellCastRequest) -> bool:
	if request == null or not request.is_valid or request.spell_data == null:
		return false
	if not request.spell_data.requires_individual_party_target():
		return false
	_pending_party_request = request
	GameEvents.message_logged.emit("[color=cyan]Choose a party member for %s.[/color]" % request.spell_data.get_display_name())
	return true

func cancel_party_targeting() -> void:
	_pending_party_request = null

func try_target_party_member(target: ClassData) -> bool:
	if _pending_party_request == null:
		return false

	var request := build_request(_pending_party_request.spell_data, _pending_party_request.caster)
	if not request.is_valid:
		_pending_party_request = null
		GameEvents.message_logged.emit("[color=red]%s[/color]" % request.get_primary_error())
		return true
	var error := get_party_target_error(request.spell_data, target)
	if not error.is_empty():
		GameEvents.message_logged.emit("[color=red]%s[/color]" % error)
		return true

	_pending_party_request = null
	var command := PlayerCastSpellCommand.new()
	command.actor = request.caster
	command.cast_request = request
	command.target_party_member = target
	CommandQueue.add_command(command)
	TurnStateMachine.last_action_was_party_wide = false
	TurnStateMachine.set_state(TurnStateMachine.State.PLAYER_ACTION)
	return true

func get_party_target_error(spell: SpellData, target: ClassData) -> String:
	if spell == null or target == null or not PartyState.active_party.has(target):
		return "That is not a valid party target."
	if spell.is_resurrection:
		if target.current_hp > 0:
			return "%s is not defeated." % target.member_name
		return ""
	if target.current_hp <= 0:
		return "%s is defeated and cannot be targeted by this spell." % target.member_name
	return ""

func execute_request(
	request: SpellCastRequest,
	target_enemy: Enemy = null,
	target_party_member: ClassData = null
) -> SpellResult:
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
		_play_cast_presentation(spell)
		var remaining_mana_cost: int = maxi(0, spell.mana - mana_already_spent)
		caster.current_mp -= remaining_mana_cost
		result.success = true
		result.mana_spent = spell.mana
		PartyState.discover_spell(spell)
		return result

	var targets := _resolve_targets(spell, caster, target_enemy, target_party_member)
	if _requires_target(spell) and targets.is_empty():
		GameEvents.message_logged.emit("[color=gray]The spell needs a valid target.[/color]")
		return result

	_play_cast_presentation(spell)
	caster.current_mp -= spell.mana
	result.mana_spent = spell.mana
	GameEvents.message_logged.emit("[color=cyan]%s[/color] casts [color=gold]%s[/color] for [color=skyblue]%d[/color] mana." % [
		caster.member_name,
		spell.get_display_name(),
		spell.mana
	])

	await _play_projectile(spell, targets)
	for target in targets:
		_play_target_presentation(spell, target)
		_apply_spell_to_target(spell, caster, target)
		result.affected_targets.append(target)

	result.success = true
	PartyState.discover_spell(spell)
	return result

func roll_spell_damage(spell: SpellData, caster: ClassData) -> int:
	if spell == null:
		return 0
	var dice := spell.get_damage_dice()
	if dice.x <= 0 or dice.y <= 0:
		return max(0, spell.amount)
	var magic_bonus := caster.get_magic_amp() if caster != null else 0
	return CombatLogic.roll_dice(get_spell_dice_rolls(spell, caster), dice.y, magic_bonus)

func get_spell_dice_rolls(spell: SpellData, caster: ClassData) -> int:
	if spell == null:
		return 0
	var dice := spell.get_damage_dice()
	if dice.x <= 0:
		return 0
	var mastery_rolls := caster.get_spell_element_roll_bonus(spell.spellbook) if caster != null else 0
	return dice.x + mastery_rolls

func meets_mastery_requirement(spell: SpellData, caster: ClassData) -> bool:
	return spell != null and caster != null and caster.get_spell_mastery_rank(spell.spellbook) >= spell.spell_level

func apply_damage_to_target(target, raw_damage: int, spell: SpellData) -> void:
	if raw_damage <= 0:
		return
	if target is Enemy and not _enemy_matches_spell_type(spell, target):
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

func _resolve_targets(
	spell: SpellData,
	caster: ClassData,
	target_enemy: Enemy,
	target_party_member: ClassData
) -> Array:
	if spell.targets_party_members():
		if spell.is_aoe:
			if spell.is_resurrection:
				return PartyState.active_party.filter(func(member): return member != null and member.current_hp <= 0)
			return PartyState.active_party.filter(func(member): return member != null and member.current_hp > 0)
		if not get_party_target_error(spell, target_party_member).is_empty():
			return []
		return [target_party_member]

	var resolved_target := target_enemy
	if resolved_target == null and CombatState.has_valid_target():
		resolved_target = CombatState.targeted_enemy
	if not _is_reachable_enemy(resolved_target):
		return []
	if not spell.is_aoe:
		return [resolved_target] if _enemy_matches_spell_type(spell, resolved_target) else []

	var targets: Array = []
	for enemy in CombatState.get_engaged_enemies():
		if _is_reachable_enemy(enemy) and _enemy_matches_spell_type(spell, enemy):
			targets.append(enemy)
	return targets

func _enemy_matches_spell_type(spell: SpellData, enemy: Enemy) -> bool:
	if spell == null or enemy == null or enemy.enemy_data == null:
		return false
	if int(spell.enemy_types) == int(SpellData.Enemy_types.ANY):
		return true
	return int(enemy.enemy_data.enemy_type) == int(spell.enemy_types)

func _apply_spell_to_target(spell: SpellData, caster: ClassData, target) -> void:
	if spell.is_resurrection:
		if target is ClassData and target.current_hp <= 0:
			var restored_hp := roll_spell_damage(spell, caster)
			if restored_hp <= 0:
				restored_hp = max(1, spell.amount)
			target.current_hp = clampi(restored_hp, 1, target.get_max_hp())
			target.apply_status_effect("weakness")
			GameEvents.message_logged.emit("[color=green]%s returns to life with %d HP and is afflicted with weakness.[/color]" % [
				target.member_name,
				target.current_hp
			])
		return

	if spell.is_heal:
		if target is ClassData and not target.blocks_hp_healing():
			var heal_amount := roll_spell_damage(spell, caster)
			if heal_amount <= 0:
				heal_amount = max(0, spell.amount)
			target.current_hp = min(target.get_max_hp(), target.current_hp + heal_amount)
			GameEvents.message_logged.emit("[color=green]%s recovers %d HP.[/color]" % [target.member_name, heal_amount])

	if not spell.remove_status_effect.strip_edges().is_empty() and target is ClassData:
		var status_id := StatusEffects.normalize_id(spell.remove_status_effect)
		if target.has_status_effect(status_id):
			target.clear_status_effect(status_id)
			GameEvents.message_logged.emit("[color=green]%s is cleansed of %s.[/color]" % [
				target.member_name,
				StatusEffects.get_display_name(StatusEffects.from_string(status_id)).to_lower()
			])
		else:
			GameEvents.message_logged.emit("[color=gray]%s is not afflicted with %s.[/color]" % [
				target.member_name,
				spell.remove_status_effect.to_lower()
			])

	if spell.is_buff:
		if spell.spell_id == "magic_shield":
			var light_mastery_rank := caster.get_skill_rank("LightMastery") if caster != null else 0
			var resist_val := 10 + 5 * light_mastery_rank
			var shield_stats := {
				"resist_fire": resist_val,
				"resist_water": resist_val,
				"resist_earth": resist_val,
				"resist_electric": resist_val
			}
			for stat_name in shield_stats.keys():
				var stat_amount := int(shield_stats[stat_name])
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
		else:
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

	if spell.targets_party_members():
		return

	var damage := roll_spell_damage(spell, caster)
	if damage > 0 and not spell.is_dot:
		apply_damage_to_target(target, damage, spell)
	if spell.is_dot:
		SpellEffectTracker.add_damage_over_time(spell, caster, target)
	_apply_debuff_status_to_enemy(spell, caster, target)


func _apply_debuff_status_to_enemy(spell: SpellData, caster: ClassData, target) -> void:
	if spell == null or not target is Enemy:
		return
	var status_id := StatusEffects.normalize_id(spell.apply_status)
	if status_id.is_empty():
		return

	var save_dc := _get_enemy_debuff_save_dc(spell, caster, status_id)
	if save_dc > 0 and _enemy_resists_debuff(target, status_id, save_dc):
		return

	var duration_rounds := spell.duration + 1 if spell.duration > 0 else -1
	target.enemy_data.apply_status_effect(status_id, duration_rounds, true, save_dc)
	GameEvents.message_logged.emit("[color=yellow]%s is afflicted with %s![/color]" % [
		target.enemy_data.enemy_name,
		StatusEffects.get_display_name(StatusEffects.from_string(status_id)).to_lower()
	])

func _get_enemy_debuff_save_dc(spell: SpellData, caster: ClassData, status_id: String) -> int:
	match status_id:
		"blind", "frozen", "sleep", "stun":
			return 10 + (caster.get_spell_mastery_rank(spell.spellbook) if caster != null else 0)
		_:
			return 0

func _enemy_resists_debuff(target: Enemy, status_id: String, save_dc: int) -> bool:
	var roll := randi_range(1, 20)
	var success := roll >= save_dc
	var status_label := StatusEffects.get_display_name(StatusEffects.from_string(status_id))
	var color := "green" if success else "red"
	var outcome := "resists" if success else "fails to resist"
	GameEvents.message_logged.emit("[color=%s]%s %s %s: d20 %d vs DC %d[/color]" % [
		color,
		target.enemy_data.enemy_name,
		outcome,
		status_label.to_lower(),
		roll,
		save_dc
	])
	return success

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
	return spell.special_effect.strip_edges().is_empty()

func _can_cast_without_mana(spell: SpellData) -> bool:
	var special_id := spell.special_effect.strip_edges().to_lower()
	return special_id in ["torchlight", "torch_light"] and PartyState.is_magic_torch_lit

func _get_spellbook_mastery_name(element: int) -> String:
	return SpellData.element_name(element)

func _is_reachable_enemy(enemy: Enemy) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.enemy_data.hp <= 0:
		return false
	var player: Node3D = World.get_player()
	if player == null:
		return false
	var difference = (player.grid_position - enemy.grid_position).abs()
	return max(difference.x, difference.y) <= SPELL_RANGE and World.has_line_of_sight(player.grid_position, enemy.grid_position)

func _play_cast_presentation(spell: SpellData) -> void:
	var sound_effect := spell.get_sound_effect()
	if not sound_effect.is_empty():
		SfxManager.play_sfx(sound_effect)
	if spell.shake_screen:
		GameEvents.camera_shake_requested.emit(spell.shake_intensity, spell.shake_decay)

func _play_target_presentation(spell: SpellData, target) -> void:
	if not target is ClassData:
		return
	var animation_name := spell.get_party_target_animation()
	if not animation_name.is_empty():
		GameEvents.party_spell_animation_requested.emit(target, animation_name)

func _play_projectile(spell: SpellData, targets: Array) -> void:
	if spell.projectile_scene_path.is_empty() or targets.is_empty() or not targets[0] is Enemy:
		return
	var player: Node3D = World.get_player()
	if player != null:
		GameEvents.spell_projectile_cast.emit(
			player.global_position,
			targets[0].global_position,
			spell.projectile_scene_path,
			spell.projectile_travel_time
		)
		var wait_time: float = maxf(0.0, spell.projectile_travel_time) + maxf(0.0, spell.impact_delay)
		if wait_time > 0.0:
			await get_tree().create_timer(wait_time).timeout
