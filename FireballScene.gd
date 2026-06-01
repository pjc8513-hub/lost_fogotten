extends Node3D

@onready var sprite: Sprite3D = $Sprite3D
@onready var anim_player: AnimationPlayer = $Sprite3D/AnimationPlayer
var cast_particles: Node = null


var start_pos: Vector3
var target_pos: Vector3
var duration: float = 0.5
var elapsed: float = 0.0

func _ready() -> void:
	var player = World.get_player()
	if player:
		cast_particles = player.get_node_or_null("Camera3D/CastParticles")
		if RenderingServer.get_rendering_device() == null:
			print("No RenderingDevice available — GPU particles will not work")
			cast_particles = player.get_node_or_null("Camera3D/CastParticlesCPU")
	if cast_particles:
		print("Particles!")
		cast_particles.restart()
	else:
		print ("Particle node problem: CastParticles not found on Player.")
	
	anim_player.play("FireballCast")

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
	SfxManager.play_sfx("fireball")

func _on_impact() -> void:
	# Emit impact signal or play impact animation
	GameEvents.spell_impact_animation_finished.emit()
	queue_free()
