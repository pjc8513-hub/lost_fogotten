extends Node

signal message_logged(text: String)
signal party_member_stats_changed(member_data: ClassData)
signal selected_character_changed(character)
signal inventory_changed(character)
signal combat_status_changed(member_data: ClassData, new_status: int)

# Animation events
# Add to GameEvents.gd
signal attack_animation_started(attacker, target, damage)
signal attack_animation_finished(attacker, target)
signal damage_animation_started(target, damage_amount)  
signal movement_animation_started(actor, destination)
signal movement_animation_finished(actor)
signal character_status_changed_visually(character, status)
signal character_died_animation_started(character)
