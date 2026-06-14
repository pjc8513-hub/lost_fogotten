# SkillsView.gd
extends Control

@export var skill_row_prefab: PackedScene # Drop your UI Row entry scene here
@onready var points_label: Label = $VBoxContainer/Header/AvailablePointsLabel
@onready var list_container: VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer

var current_character: ClassData = null

func _ready() -> void:
	GameEvents.party_member_stats_changed.connect(_on_party_member_stats_changed)

func set_character(character: ClassData) -> void:
	current_character = character
	update_ui()

func update_ui() -> void:
	# Handle cases where no character is selected or scene tree isn't ready
	if not current_character or not is_inside_tree(): 
		return
	
	# Update point counter tracking
	points_label.text = "Available Skill Points: " + str(current_character.get_available_skill_points())
	
	# Wipe old rows
	for child in list_container.get_children():
		child.queue_free()
		
	for skill in current_character.get_learned_skill_resources():
		var row_inst = skill_row_prefab.instantiate()
		list_container.add_child(row_inst)
		
		var current_rank = current_character.get_skill_rank(skill.skill_id)
		var class_max = skill.get_max_rank_for_class(current_character.get_resolved_class_name())
		var ranks_available := maxi(0, class_max - current_rank)
		
		row_inst.setup_row(
			skill.skill_id,
			skill.display_name,
			current_rank,
			class_max,
			ranks_available,
			current_character.get_available_skill_points() > 0
		)
		
		# Listen for the player clicking a point upgrade button
		row_inst.upgrade_requested.connect(_on_upgrade_triggered)

func _on_upgrade_triggered(skill_id: String) -> void:
	if current_character and current_character.upgrade_skill(skill_id):
		# Refresh view elements instantly to show diminished point total and filled box
		update_ui()

func _on_party_member_stats_changed(character: ClassData) -> void:
	if character == current_character:
		update_ui()
