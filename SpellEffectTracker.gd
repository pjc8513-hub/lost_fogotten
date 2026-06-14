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
	if spell == null or target == null or spell.duration <= 0 or spell.stats.is_empty():
		return
	_step_effects.append({
		"spell": spell,
		"target": target,
		"remaining": spell.duration,
		"is_buff": true,
	})

func tick_combat_round() -> void:
	_tick_effects(_round_effects)

func _on_player_stepped(_total_steps: int) -> void:
	_tick_effects(_step_effects)

func _tick_effects(effects: Array[Dictionary]) -> void:
	for effect in effects.duplicate():
		var target = effect.get("target")
		if not _is_target_alive(target):
			effects.erase(effect)
			continue

		var spell := effect.get("spell") as SpellData
		if not bool(effect.get("is_buff", false)):
			var damage := SpellExecutor.roll_spell_damage(spell, effect.get("caster"))
			SpellExecutor.apply_damage_to_target(target, damage, spell)
		effect["remaining"] = int(effect.get("remaining", 1)) - 1
		if int(effect["remaining"]) <= 0:
			if bool(effect.get("is_buff", false)):
				for stat_name in spell.stats.keys():
					if target is ClassData:
						target.clear_combat_buff(str(stat_name))
					elif target is Enemy:
						target.enemy_data.clear_combat_buff(str(stat_name))
			effects.erase(effect)

func _is_target_alive(target) -> bool:
	if target is ClassData:
		return target.current_hp > 0
	if target is Enemy:
		return is_instance_valid(target) and not target.is_queued_for_deletion() and target.enemy_data.hp > 0
	return false
