extends Node

const DEFAULT_BUFF_COOLDOWN := 2
const DEFAULT_AMPED_RECOVERY := 3
const DEFAULT_SPLASH_DICE := 1
const DEFAULT_SPLASH_DIE_SIZE := 6

func execute_request(request: SpellCastRequest, target_enemy: Enemy = null) -> Dictionary:
	var outcome := {
		"success": false,
		"spent_mana": 0,
		"target_used": target_enemy,
		"messages": [],
	}

	if request == null or not request.is_valid:
		return outcome

	var caster := request.caster
	var result := request.spell_result
	if caster == null or result == null:
		return outcome

	caster.current_mp -= result.mana_cost
	outcome["spent_mana"] = result.mana_cost
	outcome["success"] = true

	var effect_target := target_enemy
	if effect_target == null and CombatState.has_valid_target():
		effect_target = CombatState.targeted_enemy
	outcome["target_used"] = effect_target

	GameEvents.message_logged.emit("[color=cyan]%s[/color] casts [color=gold]%s[/color] for [color=skyblue]%d[/color] mana." % [
		caster.member_name,
		request.spell_data.guitar_name,
		result.mana_cost
	])

	_apply_healing(caster, result, outcome)
	_apply_buffs(caster, result, outcome)
	_apply_mp_recovery(caster, result, outcome)
	_apply_damage(caster, result, effect_target, outcome)
	_apply_chord_statuses(effect_target, result)

	return outcome

func _apply_healing(caster: ClassData, result: SpellResult, outcome: Dictionary) -> void:
	var heal_bonus := 0
	for chord_entry in result.chord_entries:
		var chord_data := chord_entry.get("data") as ChordData
		if chord_data != null:
			heal_bonus += chord_data.bonus_heal * int(chord_entry.get("count", 1))

	for roll_data in result.element_rolls.values():
		if not bool(roll_data.get("healing", false)):
			continue

		for member in PartyState.active_party:
			if member == null or member.current_hp <= 0:
				continue
			var heal_amount := CombatLogic.roll_dice(int(roll_data["rolls"]), int(roll_data["die"]), heal_bonus)
			member.current_hp = min(member.get_max_hp(), member.current_hp + heal_amount)
			GameEvents.message_logged.emit("[color=green]%s[/color] recovers [color=lime]%d[/color] HP." % [
				member.member_name,
				heal_amount
			])

func _apply_buffs(caster: ClassData, result: SpellResult, outcome: Dictionary) -> void:
	if not CombatState.is_in_combat():
		return

	for chord_entry in result.chord_entries:
		var chord_data := chord_entry.get("data") as ChordData
		if chord_data == null or chord_data.buff_stat.is_empty():
			continue

		for member in PartyState.active_party:
			if member == null or member.current_hp <= 0:
				continue
			for stat_name in chord_data.buff_stat.keys():
				member.apply_combat_buff(str(stat_name), int(chord_data.buff_stat[stat_name]))

		GameEvents.message_logged.emit("[color=yellow]%s[/color] empowers the party with [color=orange]%s[/color]." % [
			caster.member_name,
			chord_data.display_name
		])

func _apply_mp_recovery(caster: ClassData, result: SpellResult, outcome: Dictionary) -> void:
	for chord_entry in result.chord_entries:
		var chord_data := chord_entry.get("data") as ChordData
		if chord_data == null or not chord_data.mp_recovery:
			continue

		for member in PartyState.active_party:
			if member == null or member == caster or member.current_hp <= 0:
				continue
			member.current_mp = min(member.get_max_mp(), member.current_mp + DEFAULT_AMPED_RECOVERY)
			GameEvents.message_logged.emit("[color=skyblue]%s[/color] recovers [color=aqua]%d[/color] MP." % [
				member.member_name,
				DEFAULT_AMPED_RECOVERY
			])

func _apply_damage(caster: ClassData, result: SpellResult, target_enemy: Enemy, outcome: Dictionary) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy) or target_enemy.enemy_data.hp <= 0:
		if _has_damage_component(result):
			GameEvents.message_logged.emit("[color=gray]No target selected, so the spell's damage dissipates harmlessly.[/color]")
		return

	var total_damage := 0
	var splash_damage := 0

	for element in result.element_rolls.keys():
		var roll_data: Dictionary = result.element_rolls[element]
		if bool(roll_data.get("healing", false)):
			continue

		var resist_rolls := _get_resist_roll_reduction(target_enemy, element)
		var effective_rolls = max(0, int(roll_data["rolls"]) - resist_rolls)
		if effective_rolls <= 0:
			GameEvents.message_logged.emit("[color=gray]%s shrugs off the %s energy.[/color]" % [
				target_enemy.enemy_data.enemy_name,
				String(roll_data["name"]).to_lower()
			])
			continue

		var element_bonus := caster.get_magic_amp() + _get_chord_bonus_damage_for_target(result, target_enemy)
		var damage = CombatLogic.roll_dice(effective_rolls, int(roll_data["die"]), element_bonus)
		total_damage += damage

		if bool(roll_data.get("splash", false)) and int(roll_data["rolls"]) >= 4:
			splash_damage += CombatLogic.roll_dice(DEFAULT_SPLASH_DICE, DEFAULT_SPLASH_DIE_SIZE)

		GameEvents.message_logged.emit("[color=white]%s[/color] channels [color=orange]%s[/color] for [color=red]%d[/color] damage." % [
			caster.member_name,
			roll_data["name"],
			damage
		])

	if total_damage > 0:
		target_enemy.enemy_data.hp -= total_damage
		GameEvents.message_logged.emit("[color=red]%s[/color] takes [color=orange]%d[/color] total spell damage." % [
			target_enemy.enemy_data.enemy_name,
			total_damage
		])

	if splash_damage > 0:
		for enemy in CombatState.get_engaged_enemies():
			if enemy == null or enemy == target_enemy or not is_instance_valid(enemy) or enemy.enemy_data.hp <= 0:
				continue
			if not World.are_adjacent(enemy, target_enemy):
				continue
			enemy.enemy_data.hp -= splash_damage
			GameEvents.message_logged.emit("[color=orange]%s[/color] is splashed for [color=red]%d[/color] damage." % [
				enemy.enemy_data.enemy_name,
				splash_damage
			])
			_cleanup_enemy_if_dead(enemy)

	_cleanup_enemy_if_dead(target_enemy)

func _apply_chord_statuses(target_enemy: Enemy, result: SpellResult) -> void:
	if target_enemy == null or not is_instance_valid(target_enemy) or target_enemy.enemy_data.hp <= 0:
		return

	for chord_entry in result.chord_entries:
		var chord_data := chord_entry.get("data") as ChordData
		if chord_data == null or chord_data.status_effect.is_empty():
			continue
		if randi_range(1, 100) > result.chord_success_chance:
			GameEvents.message_logged.emit("[color=gray]%s fails to take hold.[/color]" % chord_data.display_name)
			continue
		CombatLogic.proc_status(chord_data.status_effect.to_lower(), 100, target_enemy)

func _get_resist_roll_reduction(target_enemy: Enemy, element: int) -> int:
	match element:
		GuitarData.Element.FIRE:
			return target_enemy.enemy_data.get_resistance("fire")
		GuitarData.Element.ICE:
			return target_enemy.enemy_data.get_resistance("cold")
		GuitarData.Element.ELECTRIC:
			return target_enemy.enemy_data.get_resistance("electric")
		GuitarData.Element.EARTH:
			return 0
		GuitarData.Element.LIGHT:
			return target_enemy.enemy_data.get_resistance("light")
		GuitarData.Element.DARK:
			return target_enemy.enemy_data.get_resistance("dark")
		GuitarData.Element.PHYSICAL:
			return target_enemy.enemy_data.get_resistance("physical")
		_:
			return 0

func _get_chord_bonus_damage_for_target(result: SpellResult, target_enemy: Enemy) -> int:
	var bonus := 0
	for chord_entry in result.chord_entries:
		var chord_data := chord_entry.get("data") as ChordData
		if chord_data == null:
			continue
		bonus += chord_data.bonus_damage * int(chord_entry.get("count", 1))
		if chord_data.bonus_vs_type == "UNDEAD" and _is_undead(target_enemy):
			bonus += chord_data.bonus_rolls
	return bonus

func _is_undead(target_enemy: Enemy) -> bool:
	if target_enemy == null or target_enemy.enemy_data == null:
		return false
	var name_text := target_enemy.enemy_data.enemy_name.to_lower()
	return name_text.contains("undead") or name_text.contains("skeleton") or name_text.contains("zombie") or name_text.contains("ghost")

func _has_damage_component(result: SpellResult) -> bool:
	for roll_data in result.element_rolls.values():
		if not bool(roll_data.get("healing", false)):
			return true
	return false

func _cleanup_enemy_if_dead(enemy: Enemy) -> void:
	if enemy == null or not is_instance_valid(enemy) or enemy.enemy_data.hp > 0:
		return
	GameEvents.message_logged.emit("[color=red]%s[/color] dies!" % enemy.enemy_data.enemy_name)
	LootDistributor.distribute_enemy_loot(enemy)
	LootDistributor.distribute_xp(enemy.enemy_data.xp)
	World.remove_enemy(enemy)
