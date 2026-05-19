# res://resources/effects/ChangeMapEffect.gd
extends TriggerEffect
class_name ChangeMapEffect

@export var target_map_path: String = ""
@export var target_spawn_id: String = ""
@export var prompt_text: String = "Would you like to travel to the next area?"

func execute() -> void:
	if target_map_path.is_empty():
		push_warning("ChangeMapEffect executed but target_map_path is empty.")
		return
		
	# Call your DialogueManager system and pass the travel function as a callback
	if Engine.has_meta("DialogueManager"): # or however your global is named
		DialogueManager.show_prompt(prompt_text, _on_travel_confirmed)
	else:
		# Fallback if DialogueManager is a global Autoload singleton
		DialogueManager.show_prompt(prompt_text, _on_travel_confirmed)

func _on_travel_confirmed() -> void:
	# needs to follow similar logic to player action to leave dungeons
		#World.set_current_dungeon(exit.dungeon_data)
		SceneManager.change_scene("res://Main.tscn")
