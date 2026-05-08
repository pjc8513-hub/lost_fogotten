extends Node3D
@onready var sprite_3d: Sprite3D = $Sprite3D

var start_pos: Vector3
var target_pos: Vector3
var duration: float = 0.5
var elapsed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	if elapsed >= duration:
		_on_impact()
		return
	
	elapsed += delta
	var progress = elapsed / duration
	global_position = start_pos.lerp(target_pos, progress)

func launch(from: Vector3, to: Vector3, travel_time: float = 0.5) -> void:
	start_pos = from
	target_pos = to
	duration = travel_time
	elapsed = 0.0
	global_position = start_pos

func _on_impact() -> void:
	# Emit impact signal or play impact animation
	GameEvents.spell_impact_animation_finished.emit()
	queue_free()
