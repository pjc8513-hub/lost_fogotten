extends Node

signal message_logged(text: String)
signal party_member_stats_changed(member_data: ClassData)
signal selected_character_changed(character)
signal inventory_changed(character)
signal combat_status_changed(member_data: ClassData, new_status: int)

# Treasure chests opening
signal chest_opened(chest: TreasureChest, gold: int, loot: Array)
signal chest_trap_triggered(chest: TreasureChest, damage: int)

# Resource tracking
signal gold_changed(new_amount: int)
signal food_changed(new_amount: int)

# Animation events

signal attack_animation_started(attacker, target, damage)
signal attack_animation_finished(attacker, target)
signal damage_animation_started(target, damage_amount)
signal enemy_took_damage(enemy: Enemy, damage: int)
signal movement_animation_started(actor, destination)
signal movement_animation_finished(actor)
signal character_status_changed_visually(character, status)
signal character_died_animation_started(character)
signal open_chest_animation_started(chest)
signal open_chest_animation_finished(chest)
signal pull_lever_animation_started(trigger)
signal pull_lever_animation_finished(trigger)

#signal particle_restart(element)

# Spell projectile animations
signal spell_projectile_cast(caster_pos: Vector3, target_pos: Vector3, anim_path: String)
signal spell_impact_animation_finished

#signal level_increase(character)
