# NPCManager.gd
extends Node

var npcs: Array[NPC] = []
var npcs_by_id: Dictionary = {}

func register_npc(npc: NPC):
	if not npcs.has(npc):
		npcs.append(npc)
	if npc.npc_data:
		npcs_by_id[npc.npc_data.npc_id] = npc

func get_npc(npc_id: String) -> NPC:
	return npcs_by_id.get(npc_id)

func talk_to_npc(npc: NPC) -> void:
	if npc == null or npc.npc_data == null:
		return
	
	DialogueManager.start_dialogue(
		npc.npc_data.dialogue_start_node,
		npc.npc_data.npc_name
	)
