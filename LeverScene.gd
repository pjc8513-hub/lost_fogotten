extends Node3D
class_name Trigger

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var animation_player: AnimationPlayer = $Sprite3D/AnimationPlayer
signal selected(trigger: Trigger)
signal pull_lever_completed

@export var trigger_data: TriggerData
var grid_position: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame  # same trick as Enemy to wait for world


func execute() -> void:
	pass
	
func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var msg := "[color=yellow]Inspecting lever[/color]"
		GameEvents.message_logged.emit(msg)
		selected.emit(self)
		World.set_selected_trigger(self)

func play_pull_animation() -> void:
	print("play pull animation")
	var anim_player = get_node_or_null("Sprite3D/AnimationPlayer")

	if anim_player and anim_player is AnimationPlayer:
		if anim_player.has_animation("lever_pull"):
			anim_player.play("lever_pull")
		else:
			call_deferred("_emit_pull_animation_completed")
	else:
		call_deferred("_emit_pull_animation_completed")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"pull_lever":
		pull_lever_completed.emit()

func _emit_pull_animation_completed() -> void:
	pull_lever_completed.emit()
