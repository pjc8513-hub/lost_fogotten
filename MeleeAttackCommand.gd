extends Command
class_name MeleeAttackCommand

var target

func execute():
	print(actor.name, "melee-attacked", target.enemy_data.enemy_name)
	emit_signal("finished")
