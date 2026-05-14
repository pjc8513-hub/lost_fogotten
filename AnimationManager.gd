# AnimationManager.gd (autoload in project.godot)
extends Node

func _ready():
	GameEvents.attack_animation_started.connect(_on_attack_started)
	GameEvents.damage_animation_started.connect(_on_damage_started)
	GameEvents.enemy_took_damage.connect(_on_enemy_took_damage)
	GameEvents.movement_animation_started.connect(_on_movement_started)
	GameEvents.open_chest_animation_started.connect(_on_open_chest_started)
	GameEvents.pull_lever_animation_started.connect(_on_lever_pull_started)
	GameEvents.spell_projectile_cast.connect(_on_spell_projectile_cast)

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

func _on_spell_projectile_cast(caster_pos: Vector3, target_pos: Vector3, anim_path: String) -> void:
	if anim_path.is_empty():
		return
		
	if ResourceLoader.exists(anim_path):
		var fireball_scene = load(anim_path)
		if fireball_scene:
			var fireball = fireball_scene.instantiate()
			get_tree().root.add_child(fireball)
			if fireball.has_method("launch"):
				fireball.launch(caster_pos, target_pos, 0.5)
