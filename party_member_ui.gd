extends PanelContainer

# Drag your UI nodes here to create references
@onready var portrait = $HBoxContainer/PortraitOne
@onready var hp_bar = $HBoxContainer/VBoxContainer/ProgressBar
@onready var mp_bar = $HBoxContainer/VBoxContainer/ProgressBar2
@onready var label = $HBoxContainer/VBoxContainer/Label

var my_member_data: ClassData

# This function takes a .tres file and fills the UI
func setup(data): # We leave 'data' untyped here too just to be safe
	if data:
		# Use the variable names from your ClassData.gd
		portrait.texture = data.sprite_texture 
		hp_bar.max_value = data.max_hp
		hp_bar.value = data.current_hp
		mp_bar.max_value = data.max_mp
		mp_bar.value = data.current_mp
		label.text = data.member_name
		
		my_member_data = data
		# Listen for any stat changes globally
		if !GameEvents.party_member_stats_changed.is_connected(_on_stats_changed):
			GameEvents.party_member_stats_changed.connect(_on_stats_changed)
		
		update_ui()

func _on_stats_changed(updated_data: ClassData):
	# Check: Is the person who changed actually ME?
	if updated_data == my_member_data:
		update_ui()

func update_ui():
	# Use Tween for a smooth sliding animation instead of a sudden jump
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", my_member_data.current_hp, 0.2)
	#print(my_member_data.name, " max mp: ", my_member_data.max_mp)
	#print(my_member_data.name, " current mp: ", my_member_data.current_mp)
	#print(my_member_data.name, " max hp: ", my_member_data.max_hp)
	#print(my_member_data.name, " current hp: ", my_member_data.current_hp)
	mp_bar.value = my_member_data.current_mp
