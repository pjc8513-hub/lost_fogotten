# res://commands/PlayerTalkCommand.gd
extends Command
class_name PlayerTalkCommand

# actor here is ClassData - the party member acting
const MELEE_RANGE: int = 1  # 8-directional: max distance for adjacent tiles

var target_npc: NPC

func execute() -> void:
	var acting_member: ClassData = actor  # ClassData
	
	# Guard: NPC deselected or invalid between click and execution
	if target_npc == null or not is_instance_valid(target_npc) or target_npc.npc_data == null:
		var msg := "[color=gray]No one to talk to.[/color]"
		GameEvents.message_logged.emit(msg)
		emit_signal("finished")
		return
	
	var player_node = World.get_player()
	if player_node == null:
		emit_signal("finished")
		return
	
	# Range check - 8-directional adjacency
	var npc_grid = World.world_to_grid(target_npc.global_position)
	var grid_diff = (player_node.grid_position - npc_grid).abs()
	var dist: float = max(grid_diff.x, grid_diff.y)  # Chebyshev distance for 8-directional
	if dist > MELEE_RANGE:
		GameEvents.message_logged.emit("[color=red]Too far away to talk.[/color]")
		emit_signal("finished")
		return
	
	# Start dialogue with the NPC
	DialogueManager.start_dialogue(
		target_npc.npc_data.dialogue_start_node,
		target_npc.npc_data.npc_name
	)
	
	actor.cooldown = 0  # Talking doesn't consume much action economy
	emit_signal("finished")
