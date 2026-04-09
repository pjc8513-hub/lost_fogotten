# AttackCommand.gd

extends Command
class_name AttackCommand

func execute():
	# Rudimentary: Just pick the first party member for now
	var target = PartyState.active_party[0]
	
	# Calculate a very basic damage (Enemy Attack - Armor)
	# For now, let's just do a flat 2 damage to see the bar move
	var damage_amount = 2
	
	var msg = "[color=red]%s[/color] hits [color=white]%s[/color] for %d damage!" % [actor.enemy_data.enemy_name, target.member_name, damage_amount]
	
	# Instead of $, we emit a global signal
	GameEvents.message_logged.emit(msg)
	
	# Apply the damage
	target.take_damage(damage_amount)
	
	emit_signal("finished")
