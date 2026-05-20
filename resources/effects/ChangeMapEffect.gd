# res://resources/effects/ChangeMapEffect.gd
extends TriggerEffect
class_name ChangeMapEffect

@export var target_map_path: String = ""
@export var target_spawn_id: String = ""
@export var target_theme_path: String = ""
@export var prompt_text: String = "Would you like to travel to the next area?"

func execute() -> void:
	if target_map_path.is_empty():
		push_warning("ChangeMapEffect executed but target_map_path is empty.")
		return

	DialogueManager.show_confirmation(prompt_text, func():
		_on_travel_confirmed()
	)

func _on_travel_confirmed() -> void:
	var theme_path := target_theme_path
	if theme_path.is_empty():
		theme_path = World.current_map_theme_path

	World.set_current_map(target_map_path, _get_target_spawn_id(), theme_path)
	SceneManager.change_scene("res://Main.tscn")

func _get_target_spawn_id() -> String:
	if target_spawn_id.is_empty():
		return ""

	if ResourceLoader.exists(target_spawn_id):
		var spawn_data := load(target_spawn_id) as PlayerSpawnData
		if spawn_data != null:
			return spawn_data.SpawnID

	return target_spawn_id
