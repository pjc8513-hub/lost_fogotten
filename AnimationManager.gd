# AnimationManager.gd (autoload in project.godot)
extends Node

var shake_intensity: float = 0.0
var shake_decay: float = 5.0
var _shake_camera: Camera3D = null
var _shake_original_position: Vector3 = Vector3.ZERO

func _ready():
	GameEvents.attack_animation_started.connect(_on_attack_started)
	GameEvents.damage_animation_started.connect(_on_damage_started)
	GameEvents.enemy_took_damage.connect(_on_enemy_took_damage)
	GameEvents.movement_animation_started.connect(_on_movement_started)
	GameEvents.open_chest_animation_started.connect(_on_open_chest_started)
	GameEvents.pull_lever_animation_started.connect(_on_lever_pull_started)
	GameEvents.spell_projectile_cast.connect(_on_spell_projectile_cast)
	GameEvents.party_spell_animation_requested.connect(_on_party_spell_animation_requested)
	GameEvents.camera_shake_requested.connect(_on_camera_shake_requested)

func _process(delta: float) -> void:
	if shake_intensity <= 0.0:
		if _shake_camera != null and is_instance_valid(_shake_camera):
			_shake_camera.position = _shake_original_position
		return

	var camera: Camera3D = _get_shake_camera()
	if camera == null:
		shake_intensity = 0.0
		return

	camera.position.x = _shake_original_position.x + randf_range(-shake_intensity, shake_intensity)
	camera.position.y = _shake_original_position.y + randf_range(-shake_intensity, shake_intensity)
	shake_intensity = move_toward(shake_intensity, 0.0, shake_decay * delta)

func _on_attack_started(attacker, target, damage):
	#print("[AnimationManager] attack started attacker=", attacker, " target=", target, " damage=", damage)
	if attacker.has_method("play_attack_animation"):
		attacker.play_attack_animation()
	if target.has_method("play_hit_effect"):
		target.play_hit_effect()

func _on_damage_started(target, damage):
	# Flash screen red, shake camera, float damage text, etc.
	if target and target.has_method("animate_take_damage"):
		target.animate_take_damage(damage)
	if has_node("DamageFloater"):
		$DamageFloater.show_damage(target, damage)

func _on_enemy_took_damage(enemy, damage):
	if enemy and enemy.has_method("animate_take_damage"):
		enemy.animate_take_damage(damage)

func _on_movement_started(actor, destination):
	# Play footstep sounds, particle effects, etc.
	if actor.has_method("animate_move_to"):
		actor.animate_move_to(destination)
	pass

func _on_lever_pull_started(trigger):
	print ("_on_lever_pull")
	if trigger and trigger.has_method("play_pull_animation"):
		trigger.play_pull_animation()

func _on_open_chest_started(chest):
	if chest and chest.has_method("play_open_animation"):
		chest.play_open_animation()

func _on_spell_projectile_cast(caster_pos: Vector3, target_pos: Vector3, anim_path: String, travel_time: float) -> void:
	if anim_path.is_empty():
		return
		
	if ResourceLoader.exists(anim_path):
		var fireball_scene = load(anim_path)
		if fireball_scene:
			var fireball = fireball_scene.instantiate()
			# Add the projectile to the SubViewport so it renders in the game world
			var main = get_tree().root.get_node_or_null("Main")
			if main and main.has_node("SubViewportContainer/SubViewport"):
				var sub_viewport = main.get_node("SubViewportContainer/SubViewport")
				sub_viewport.add_child(fireball)
			else:
				# Fallback to root if Main/SubViewport not found
				get_tree().root.add_child(fireball)
			if fireball.has_method("launch"):
				fireball.launch(caster_pos, target_pos, max(0.01, travel_time))

func _on_party_spell_animation_requested(member: ClassData, animation_name: String) -> void:
	if member == null or animation_name.strip_edges().is_empty():
		return

	var main := get_tree().root.get_node_or_null("Main")
	if main == null:
		return
	var party_list := main.get_node_or_null("Control/MarginContainer/VBoxContainer")
	if party_list == null:
		return

	for member_ui in party_list.get_children():
		if member_ui.get("my_member_data") == member and member_ui.has_method("play_combat_fx"):
			member_ui.play_combat_fx(animation_name)
			return

func _on_camera_shake_requested(intensity: float, decay: float) -> void:
	var camera: Camera3D = _get_shake_camera()
	if camera == null:
		return
	shake_intensity = max(shake_intensity, max(0.0, intensity))
	shake_decay = max(0.01, decay)

func _get_shake_camera() -> Camera3D:
	if _shake_camera != null and is_instance_valid(_shake_camera):
		return _shake_camera

	var player: Node = World.get_player()
	if player != null:
		_shake_camera = player.get_node_or_null("Camera3D") as Camera3D

	if _shake_camera == null:
		_shake_camera = get_viewport().get_camera_3d()

	if _shake_camera != null:
		_shake_original_position = _shake_camera.position

	return _shake_camera
