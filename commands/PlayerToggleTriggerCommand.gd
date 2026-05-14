# res://commands/PlayerToggleTriggerCommand.gd
extends Command
class_name PlayerToggleTriggerCommand

# actor here is ClassData - the party member acting
const MELEE_RANGE: int = 1  # 8-directional: max distance for adjacent tiles

func execute() -> void:
	var acting_member: ClassData = actor # ClassData
	var target_trigger: Trigger = World.selected_trigger
	
	# Guard: chest deselected or already opened between click and execution
	if target_trigger == null or not is_instance_valid(target_trigger):
		var msg := "[color=gray]Lever seems broken.[/color]"
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return
	
	var player_node = World.get_player()
	if player_node == null:
		emit_signal("finished")
		return
	
	# Range check - 8-directional adjacency
	var trigger_grid = World.world_to_grid(target_trigger.global_position)
	var grid_diff = (player_node.grid_position - trigger_grid).abs()
	var dist: float = max(grid_diff.x, grid_diff.y)  # Chebyshev distance for 8-directional
	if dist > MELEE_RANGE:
		GameEvents.message_logged.emit("[color=red]Out of reach.[/color]")
		emit_signal("finished")
		return
	
	GameEvents.pull_lever_animation_started.emit(target_trigger)
	if target_trigger.has_signal("pull_lever_completed"):
		await target_trigger.pull_lever_completed
	target_trigger.execute()
	GameEvents.pull_lever_animation_finished.emit(target_trigger)
	
	# attempt_unlock() already handles trap trigger + loot + messages
	# so we don't duplicate that logic here
	
	actor.cooldown = 1 # opening is faster than attacking
	emit_signal("finished")
