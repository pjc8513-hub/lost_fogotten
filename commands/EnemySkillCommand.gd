extends Command
class_name EnemySkillCommand

var skill: Resource

func execute() -> void:
	if actor == null or skill == null or not actor is Enemy:
		emit_signal("finished")
		return

	var targets: Array = _resolve_targets()
	if targets.is_empty():
		GameEvents.message_logged.emit("[color=gray]%s tries to use %s, but has no valid target.[/color]" % [
			actor.enemy_data.enemy_name,
			skill.get_log_name()
		])
		emit_signal("finished")
		return

	_log_cast(targets)
	await _play_projectile(targets[0])
	_trigger_screen_shake()

	for target in targets:
		if not _is_target_alive(target):
			continue
		await _apply_skill_to_target(target)

	if skill.cooldown_turns > 0 and actor.has_method("set_skill_cooldown"):
		actor.set_skill_cooldown(skill, skill.cooldown_turns)

	emit_signal("finished")

func _resolve_targets() -> Array:
	match skill.target_mode:
		0:
			return [actor]
		1:
			var party_targets: Array[ClassData] = _living_party_members()
			if party_targets.is_empty():
				return []
			return [party_targets.pick_random()]
		2:
			return _living_party_members()
		3:
			var allies: Array[Enemy] = _living_engaged_enemies()
			if allies.is_empty():
				return []
			return [allies.pick_random()]
		4:
			return _living_engaged_enemies()
	return []

func _living_party_members() -> Array[ClassData]:
	var members: Array[ClassData] = []
	for member in PartyState.active_party:
		if member != null and member.current_hp > 0:
			members.append(member)
	return members

func _living_engaged_enemies() -> Array[Enemy]:
	var enemies: Array[Enemy] = []
	for enemy in CombatState.get_engaged_enemies():
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.enemy_data.hp > 0:
			enemies.append(enemy)
	return enemies

func _apply_skill_to_target(target) -> void:
	if skill.has_damage():
		await _apply_damage(target)

	if skill.has_healing():
		_apply_healing(target)

	if skill.has_stat_modifiers():
		_apply_stat_modifiers(target)

	if skill.has_status():
		CombatLogic.proc_status(skill.status_effect.strip_edges().to_lower(), skill.status_chance, target, skill.status_duration_rounds, skill.status_persists_after_combat)

func _apply_damage(target) -> void:
	if skill.uses_accuracy_roll:
		var target_ac: int = _get_target_armor_class(target)
		var outcome: String = CombatLogic.accuracy_roll(actor.get_accuracy(), target_ac)
		if outcome == "miss":
			GameEvents.message_logged.emit("[color=gray]%s uses %s on %s - miss![/color]" % [
				actor.enemy_data.enemy_name,
				skill.get_log_name(),
				_get_target_name(target)
			])
			return

		var raw_hit: int = _roll_skill_damage()
		if outcome == "crit" and skill.can_crit:
			raw_hit *= 2
		await _deal_damage(target, raw_hit, outcome == "crit")
		return

	await _deal_damage(target, _roll_skill_damage(), false)

func _roll_skill_damage() -> int:
	return CombatLogic.roll_dice(skill.dice_rolls, skill.dice_sides, skill.bonus_damage + actor.enemy_data.get_magic_bonus())

func _deal_damage(target, raw_damage: int, was_crit: bool) -> void:
	var resist: int = _get_target_resistance(target, skill.element)
	var final_damage: int = CombatLogic.apply_resistance(raw_damage, resist)
	var crit_tag: String = " [color=yellow]CRITICAL![/color]" if was_crit else ""

	GameEvents.message_logged.emit("[color=red]%s[/color]'s %s hits [color=white]%s[/color] for [color=orange]%d[/color] damage!%s" % [
		actor.enemy_data.enemy_name,
		skill.get_log_name(),
		_get_target_name(target),
		final_damage,
		crit_tag
	])

	GameEvents.emit_signal("attack_animation_started", actor, target, final_damage)
	if actor.has_signal("attack_animation_completed"):
		await actor.attack_animation_completed
	GameEvents.emit_signal("damage_animation_started", target, final_damage)

	if target is ClassData:
		target.take_damage(final_damage)
	elif target is Enemy:
		target.enemy_data.hp -= final_damage
		GameEvents.enemy_took_damage.emit(target, final_damage)
		if target.enemy_data.hp <= 0:
			World.remove_enemy(target)

	GameEvents.emit_signal("attack_animation_finished", actor, target)
	if not _is_target_alive(target):
		GameEvents.message_logged.emit("[color=white]%s[/color] dies!" % _get_target_name(target))

func _apply_healing(target) -> void:
	var amount: int = CombatLogic.roll_dice(skill.heal_rolls, skill.heal_die_sides, skill.bonus_healing + actor.enemy_data.get_magic_bonus())
	if target is ClassData:
		target.current_hp = min(target.get_max_hp(), target.current_hp + amount)
	elif target is Enemy:
		target.enemy_data.hp = min(target.max_hp, target.enemy_data.hp + amount)
		GameEvents.enemy_took_damage.emit(target, 0)

	GameEvents.message_logged.emit("[color=green]%s restores %d HP to %s.[/color]" % [
		skill.get_log_name(),
		amount,
		_get_target_name(target)
	])

func _apply_stat_modifiers(target) -> void:
	for stat_name in skill.stat_modifiers.keys():
		var amount: int = int(skill.stat_modifiers[stat_name])
		if amount == 0:
			continue
		if target is ClassData and target.has_method("apply_combat_buff"):
			target.apply_combat_buff(str(stat_name), amount, skill.stat_modifier_duration_rounds)
		elif target is Enemy:
			target.enemy_data.apply_combat_buff(str(stat_name), amount, skill.stat_modifier_duration_rounds)

		var verb: String = "raises" if amount > 0 else "lowers"
		GameEvents.message_logged.emit("[color=yellow]%s %s %s's %s by %d.[/color]" % [
			skill.get_log_name(),
			verb,
			_get_target_name(target),
			str(stat_name).capitalize(),
			abs(amount)
		])

func _play_projectile(target) -> void:
	if skill.projectile_scene_path.strip_edges().is_empty():
		return

	var target_pos: Vector3 = _get_target_world_position(target)
	if target_pos == Vector3.INF:
		return

	GameEvents.spell_projectile_cast.emit(actor.global_position, target_pos, skill.projectile_scene_path)
	var wait_time: float = max(float(skill.projectile_travel_time), 0.0) + max(float(skill.impact_delay), 0.0)
	if wait_time > 0.0:
		await actor.get_tree().create_timer(wait_time).timeout

func _trigger_screen_shake() -> void:
	if not bool(skill.shake_screen):
		return
	GameEvents.camera_shake_requested.emit(float(skill.shake_intensity), float(skill.shake_decay))

func _log_cast(targets: Array) -> void:
	if not skill.cast_message.strip_edges().is_empty():
		var message: String = skill.cast_message
		message = message.replace("{enemy}", actor.enemy_data.enemy_name)
		message = message.replace("{skill}", skill.get_log_name())
		GameEvents.message_logged.emit(message)
		return

	GameEvents.message_logged.emit("[color=red]%s[/color] uses [color=orange]%s[/color]!" % [
		actor.enemy_data.enemy_name,
		skill.get_log_name()
	])

func _get_target_name(target) -> String:
	if target is ClassData:
		return target.member_name
	if target is Enemy:
		return target.enemy_data.enemy_name
	return "target"

func _get_target_armor_class(target) -> int:
	if target.has_method("get_armor_class"):
		return target.get_armor_class()
	if target is Enemy:
		return target.enemy_data.get_armor_class()
	return int(target.armor_class)

func _get_target_resistance(target, element: String) -> int:
	if target.has_method("get_resistance"):
		return target.get_resistance(element)
	if target is Enemy:
		return target.enemy_data.get_resistance(element)
	return 0

func _get_target_world_position(target) -> Vector3:
	if target is Enemy:
		return target.global_position
	var player: Node3D = World.get_player()
	if player != null:
		return player.global_position
	return Vector3.INF

func _is_target_alive(target) -> bool:
	if target is ClassData:
		return target.current_hp > 0
	if target is Enemy:
		return is_instance_valid(target) and not target.is_queued_for_deletion() and target.enemy_data.hp > 0
	return false
