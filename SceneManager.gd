# SceneManager.gd
extends Node

func change_scene(path: String) -> void:
	#print("[FRAME ", Engine.get_process_frames(), "] SceneManager.change_scene start -> ", path)
	await TransitionLayer.fade_out_and_wait()
	#print("[FRAME ", Engine.get_process_frames(), "] SceneManager fade out finished")
	_clear_world_state()
	get_tree().change_scene_to_file(path)
	#print("[FRAME ", Engine.get_process_frames(), "] SceneManager scene changed, current scene: ", get_tree().current_scene)
	# Give the new scene a full frame and a post-draw pass before fading back in.
	# This helps controls and SubViewport content finish their first visual update.
	await get_tree().process_frame
	#print("[FRAME ", Engine.get_process_frames(), "] SceneManager after process_frame 1, focus owner: ", get_viewport().gui_get_focus_owner())
	await get_tree().process_frame
	#print("[FRAME ", Engine.get_process_frames(), "] SceneManager after process_frame 2, focus owner: ", get_viewport().gui_get_focus_owner())
	await RenderingServer.frame_post_draw
	#print("[FRAME ", Engine.get_process_frames(), "] SceneManager after frame_post_draw, focus owner: ", get_viewport().gui_get_focus_owner())
	await TransitionLayer.fade_in_and_wait()
	#print("[FRAME ", Engine.get_process_frames(), "] SceneManager fade in finished")

func _clear_world_state() -> void:
	CombatState.reset()
	World.selected_enemy = null
	World.selected_chest = null
	World.selected_dungeon = null
	World.enemies.clear()
	World.treasure_chests.clear()
	World.doors.clear()
	World.doors_by_position.clear()
	World.doors_by_id.clear()
	World.doors_by_switch_id.clear()
	World.step_triggers.clear()
	World.step_triggers_by_position.clear()
	World._last_step_event_position = null
	World.player_ref = null
	World.map_data.clear()
