# res://resources/effects/ChipDamageEffect.gd
extends TriggerEffect
class_name ChipDamageEffect

@export var damage_amount: int = 3
@export var is_random_target: bool = true

func execute() -> void:
	if is_random_target:
		var victim_name = PartyState.damage_random_member(damage_amount)
		if not victim_name.is_empty():
			var msg := "[color=red]%s took %s damage![/color]" % [victim_name, damage_amount]
			GameEvents.message_logged.emit(msg)
	else:
		PartyState.damage_entire_party(damage_amount)
		var msg := "[color=red]The party took %s damage![/color]" % damage_amount
		GameEvents.message_logged.emit(msg)
