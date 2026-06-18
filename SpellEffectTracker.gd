extends Node

var _round_effects: Array[Dictionary] = []
var _step_effects: Array[Dictionary] = []

func _ready() -> void:
	World.player_stepped.connect(_on_player_stepped)

func add_damage_over_time(spell: SpellData, caster: ClassData, target) -> void:
	if spell == null or target == null or spell.duration <= 0:
		return
	var effect := {
		"spell": spell,
		"caster": caster,
		"target": target,
		"remaining": spell.duration,
	}
	if spell.duration_mode == SpellData.DurationMode.WORLD_STEPS:
		_step_effects.append(effect)
	else:
		_round_effects.append(effect)

func add_step_buff(spell: SpellData, target) -> void:
	if spell == null or target == null or spell.duration <= 0:
		return
	if spell.stats.is_empty() and spell.spell_id != "magic_shield":
		return
	_step_effects.append({
		"spell": spell,
		"target": target,
		"remaining": spell.duration,
		"is_buff": true,
	})
	GameEvents.active_buffs_changed.emit()

func tick_combat_round() -> void:
	_tick_effects(_round_effects)

func _on_player_stepped(_total_steps: int) -> void:
	_tick_effects(_step_effects)

func _tick_effects(effects: Array[Dictionary]) -> void:
	var changed := false
	for effect in effects.duplicate():
		var target = effect.get("target")
		if not _is_target_alive(target):
			effects.erase(effect)
			changed = true
			continue

		var spell := effect.get("spell") as SpellData
		if not bool(effect.get("is_buff", false)):
			var damage := SpellExecutor.roll_spell_damage(spell, effect.get("caster"))
			SpellExecutor.apply_damage_to_target(target, damage, spell)
		effect["remaining"] = int(effect.get("remaining", 1)) - 1
		if int(effect["remaining"]) <= 0:
			if bool(effect.get("is_buff", false)):
				var stats_to_clear: Array = []
				if spell.spell_id == "magic_shield":
					stats_to_clear = ["resist_fire", "resist_water", "resist_earth", "resist_electric"]
				else:
					stats_to_clear = spell.stats.keys()
				for stat_name in stats_to_clear:
					if target is ClassData:
						target.clear_combat_buff(str(stat_name))
					elif target is Enemy:
						target.enemy_data.clear_combat_buff(str(stat_name))
			effects.erase(effect)
			changed = true
	if changed:
		GameEvents.active_buffs_changed.emit()

func _is_target_alive(target) -> bool:
	if target is ClassData:
		return target.current_hp > 0
	if target is Enemy:
		return is_instance_valid(target) and not target.is_queued_for_deletion() and target.enemy_data.hp > 0
	return false

func get_active_buffs() -> Array[SpellData]:
	var list: Array[SpellData] = []
	var changed := false
	for effect in _step_effects.duplicate():
		if bool(effect.get("is_buff", false)):
			var spell := effect.get("spell") as SpellData
			var target = effect.get("target")
			if spell == null or target == null:
				continue
			
			var still_has_buff := false
			if target is ClassData:
				if spell.spell_id == "magic_shield":
					still_has_buff = target.combat_buffs.has("resist_fire")
				else:
					for stat_name in spell.stats.keys():
						if target.combat_buffs.has(stat_name):
							still_has_buff = true
							break
			elif target is Enemy:
				if spell.spell_id == "magic_shield":
					still_has_buff = target.enemy_data.combat_buffs.has("resist_fire")
				else:
					for stat_name in spell.stats.keys():
						if target.enemy_data.combat_buffs.has(stat_name):
							still_has_buff = true
							break
			
			if not still_has_buff:
				_step_effects.erase(effect)
				changed = true
				continue
				
			if spell.buff_icon != null and not str(spell.buff_icon).is_empty() and not list.has(spell):
				list.append(spell)
	if changed:
		GameEvents.active_buffs_changed.emit()
	return list
