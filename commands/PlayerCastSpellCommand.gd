extends Command
class_name PlayerCastSpellCommand

var cast_request: SpellCastRequest
var target_enemy: Enemy = null

func execute() -> void:
	var caster: ClassData = actor
	if caster == null:
		emit_signal("finished")
		return

	if cast_request == null or not cast_request.is_valid:
		GameEvents.message_logged.emit("[color=red]The spell fizzles before it can be cast.[/color]")
		emit_signal("finished")
		return

	SpellExecutor.execute_request(cast_request, target_enemy)
	caster.cooldown = 2
	emit_signal("finished")
