# modifier_engine.gd
class_name ModifierEngine

func process(event: CombatEvent, hook: int, modifiers: Array):
	# filter relevant modifiers
	var valid = []
	for mod in modifiers:
		if mod.hook == hook:
			valid.append(mod)

	# sort by priority
	valid.sort_custom(func(a, b): return a.priority < b.priority)

	# apply in order
	for mod in valid:
		apply_modifier(event, mod)

		if event.cancelled:
			return event

	return event

static func apply_modifier(event: CombatEvent, mod: ModifierData):

	match mod.hook:

		Hooks.Type.PRE_DAMAGE:

			if "damage_boost" in mod.tags:
				event.damage *= (1.0 + mod.value)

			if "noise_gate" in mod.tags:
				if event.damage < mod.value:
					event.damage = 0

		Hooks.Type.PRE_ACCURACY:

			if "accuracy_penalty" in mod.tags:
				event.accuracy -= mod.value

		Hooks.Type.POST_DAMAGE:

			if "delay" in mod.tags:
				trigger_delayed_repeat(event, mod)

			if "splash" in mod.tags:
				if event.damage >= mod.secondary_value:
					splash_damage(event, mod.value)

		Hooks.Type.POST_ACTION:

			if "reverb" in mod.tags:
				extend_effects(event, mod)
