# res://commands/PlayerOpenChestCommand.gd
extends Command
class_name PlayerOpenChestCommand

# actor here is ClassData - the party member acting
const MELEE_RANGE: int = 1  # 8-directional: max distance for adjacent tiles

func execute() -> void:
	var acting_member: ClassData = PartyState.get_selected() # ClassData
	var target_chest: TreasureChest = World.selected_chest
	
	# Guard: chest deselected or already opened between click and execution
	if target_chest == null or not is_instance_valid(target_chest) or target_chest.is_opened:
		var msg := "[color=gray]Nothing to open.[/color]"
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return
	
	var player_node = World.get_player()
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
	
	# Skill check - use lockpick/thievery from ClassData
	var skill_bonus = acting_member.get_total_skill_bonus("lockpicking")
	var success = target_chest.attempt_unlock(skill_bonus)
	print(acting_member.member_name, " attempts to open")

	if success:
		GameEvents.open_chest_animation_started.emit(target_chest)
		if target_chest.has_signal("open_animation_completed"):
			await target_chest.open_animation_completed
		target_chest.open_chest()
		GameEvents.open_chest_animation_finished.emit(target_chest)
	
	# attempt_unlock() already handles trap trigger + loot + messages
	# so we don't duplicate that logic here
	
	actor.cooldown = 1 # opening is faster than attacking
	emit_signal("finished")
