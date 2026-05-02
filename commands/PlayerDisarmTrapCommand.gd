# res://commands/PlayerDisarmChestCommand.gd
extends Command
class_name PlayerDisarmChestCommand

const MELEE_RANGE: int = 1  # 8-directional: max distance for adjacent tiles

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
	
	# Range check - 8-directional adjacency
	var chest_grid = World.world_to_grid(target_chest.global_position)
	var grid_diff = (player_node.grid_position - chest_grid).abs()
	var dist: float = max(grid_diff.x, grid_diff.y)  # Chebyshev distance for 8-directional
	if dist > MELEE_RANGE:
		GameEvents.message_logged.emit("[color=red]Out of reach.[/color]")
		emit_signal("finished")
		return
	
	var skill_bonus = acting_member.get_skill_bonus("disarm_traps")
	target_chest.attempt_disarm(skill_bonus)
	
	actor.cooldown = 1
	emit_signal("finished")
