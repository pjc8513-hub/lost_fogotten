# SceneManager.gd
extends Node

func change_scene(path: String) -> void:
	await TransitionLayer.fade_out_and_wait()
	_clear_world_state()
	get_tree().change_scene_to_file(path)
	# Wait two frame for the new scene to be ready
	await get_tree().process_frame
	await get_tree().process_frame
	await TransitionLayer.fade_in_and_wait()

func _clear_world_state() -> void:
	#CombatState.reset()
	World.selected_enemy = null
	World.selected_chest = null
	World.enemies.clear()
	World.treasure_chests.clear()
	World.player_ref = null
