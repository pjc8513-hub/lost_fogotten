extends Command
class_name PlayerCastSpellCommand

var cast_request: SpellCastRequest
var target_enemy: Enemy = null
var target_party_member: ClassData = null

func execute() -> void:
	var caster: ClassData = actor
	if caster == null:
		emit_signal("finished")
		return
	if caster.blocks_spell_casting():
		GameEvents.message_logged.emit("[color=purple]%s is prevented from casting.[/color]" % caster.member_name)
		emit_signal("finished")
		return
	if not CombatLogic.can_complete_cursed_action(caster, "spell"):
		emit_signal("finished")
		return
	if cast_request == null or not cast_request.is_valid:
		GameEvents.message_logged.emit("[color=red]The spell fizzles before it can be cast.[/color]")
		emit_signal("finished")
		return

	var result := await SpellExecutor.execute_request(cast_request, target_enemy, target_party_member)
	if result.success:
		caster.cooldown = 2
	emit_signal("finished")
