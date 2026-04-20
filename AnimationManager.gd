# AnimationManager.gd (autoload in project.godot)
extends Node

func _ready():
	GameEvents.attack_animation_started.connect(_on_attack_started)
	GameEvents.damage_animation_started.connect(_on_damage_started)
	GameEvents.movement_animation_started.connect(_on_movement_started)
	GameEvents.open_chest_animation_started.connect(_on_open_chest_started)

func _on_attack_started(attacker, target, damage):
	#print("[AnimationManager] attack started attacker=", attacker, " target=", target, " damage=", damage)
	if attacker.has_method("play_attack_animation"):
		attacker.play_attack_animation()
	if target.has_method("play_hit_effect"):
		target.play_hit_effect()

func _on_damage_started(target, damage):
	# Flash screen red, shake camera, float damage text, etc.
	if has_node("DamageFloater"):
		$DamageFloater.show_damage(target, damage)

func _on_movement_started(actor, destination):
	# Play footstep sounds, particle effects, etc.
	if actor.has_method("animate_move_to"):
		actor.animate_move_to(destination)
	pass

func _on_open_chest_started(chest):
	if chest and chest.has_method("play_open_animation"):
		chest.play_open_animation()
