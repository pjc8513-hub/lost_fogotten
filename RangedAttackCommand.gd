extends Command
class_name RangedAttackCommand

var target

func execute():
	print(actor.name, "ranged-attacked", target.enemy_data.enemy_name)
	emit_signal("finished")
