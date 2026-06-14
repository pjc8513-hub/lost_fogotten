# SkillUiRow.gd
extends VBoxContainer

signal upgrade_requested(skill_id: String)

@onready var name_label: Label = $Label
@onready var blocks_container: HBoxContainer = $HBoxContainer

var current_skill_id: String = ""
var active_color := Color.GREEN
var inactive_color := Color.WHITE

func setup_row(
	skill_id: String,
	display_name: String,
	current_rank: int,
	max_rank: int,
	ranks_available: int,
	has_skill_points: bool
) -> void:
	current_skill_id = skill_id
	name_label.text = "%s - Rank %d/%d" % [
		display_name,
		current_rank,
		max_rank
	]
	
	# Clear out any leftover mock nodes
	for child in blocks_container.get_children():
		child.queue_free()
		
	# Populate filled and unfilled segment boxes matching your visual mockup
	for i in range(max_rank):
		var block := TextureRect.new()
		
		block.texture = load("res://assets/icons/skill_meter_unfilled.png") 
		
		if i < current_rank:
			block.modulate = active_color
		else:
			block.modulate = inactive_color
			
		blocks_container.add_child(block)

	if current_rank < max_rank:
		var upgrade_button := Button.new()
		upgrade_button.text = "+"
		upgrade_button.custom_minimum_size = Vector2(28, 28)
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)
		upgrade_button.disabled = not has_skill_points
		blocks_container.add_child(upgrade_button)

func _on_upgrade_button_pressed() -> void:
	upgrade_requested.emit(current_skill_id)
