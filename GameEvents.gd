extends Node

signal message_logged(text: String)
signal party_member_stats_changed(member_data: ClassData)
signal selected_character_changed(character)
signal inventory_changed(character)
signal combat_status_changed(member_data: ClassData, new_status: int)
