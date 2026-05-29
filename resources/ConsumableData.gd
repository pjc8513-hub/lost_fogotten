extends ItemData
class_name ConsumableData

@export var description: String = ""
@export var hp_restore: int = 0
@export var mp_restore: int = 0
@export var remove_status: Array[String] = []


func apply_to_character(character: ClassData) -> void:
	if hp_restore > 0:
		character.current_hp = min(character.current_hp + hp_restore, character.get_max_hp())
	if mp_restore > 0:
		character.current_mp = min(character.current_mp + mp_restore, character.get_max_mp())
	# Add status removal logic here if needed
	for status in remove_status:
		if status in character.status_effects:
			character.status_effects.erase(status)
