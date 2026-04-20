# res://commands/PlayerDisarmChestCommand.gd
extends Command
class_name PlayerDisarmChestCommand

const MELEE_RANGE: float = 1.5

func execute() -> void:
	var acting_member: ClassData = actor
	var target_chest: TreasureChest = World.selected_chest
	
	if target_chest == null or not is_instance_valid(target_chest):
		GameEvents.message_logged.emit("[color=gray]No chest selected.[/color]")
		emit_signal("finished")
		return
	
	if target_chest.is_opened or not target_chest.treasure_data.is_trapped or target_chest.is_disarmed:
		GameEvents.message_logged.emit("[color=gray]Nothing to disarm.[/color]")
		emit_signal("finished")
		return
	
	var player_node = World.player
	if player_node == null:
		emit_signal("finished")
		return
	
	var dist: float = player_node.grid_position.distance_to(World.world_to_grid(target_chest.global_position))
	if dist > MELEE_RANGE:
		GameEvents.message_logged.emit("[color=red]Out of reach.[/color]")
		emit_signal("finished")
		return
	
	var skill_bonus = acting_member.get_skill_bonus("disarm_traps")
	target_chest.attempt_disarm(skill_bonus)
	
	actor.cooldown = 1
	emit_signal("finished")
