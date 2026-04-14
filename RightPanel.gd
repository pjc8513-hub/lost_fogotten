extends VBoxContainer

@onready var tabs = $TabContainer

func _ready():
	GameEvents.selected_character_changed.connect(_on_character_changed)
	$ButtonBar/InventoryButton.pressed.connect(_on_inventory)
	$ButtonBar/SkillsButton.pressed.connect(_on_skills)
	$ButtonBar/InfoButton.pressed.connect(_on_info)

func _on_inventory():
	tabs.current_tab = 0
	_set_active_button($ButtonBar/InventoryButton)

func _on_skills():
	tabs.current_tab = 1
	_set_active_button($ButtonBar/SkillsButton)

func _on_info():
	tabs.current_tab = 2
	_set_active_button($ButtonBar/InfoButton)

func _set_active_button(active_button):
	for b in $ButtonBar.get_children():
		b.modulate = Color(0.7, 0.7, 0.7)

	active_button.modulate = Color(1, 1, 1)
	
func _on_character_changed(character):
	# InventoryList currently handles its own updates via GameEvents.
	# SkillsView and InfoView nodes do not exist yet.
	pass

func set_character(character):
	pass
