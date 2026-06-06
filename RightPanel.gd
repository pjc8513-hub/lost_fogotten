extends VBoxContainer

@onready var tabs = $TabContainer

# Direct references to your child sub-views inside the TabContainer
@onready var skills_view = $TabContainer/SkillsView 

var current_character: ClassData = null

func _ready():
	GameEvents.selected_character_changed.connect(_on_character_changed)
	$ButtonBar/InventoryButton.pressed.connect(_on_inventory)
	$ButtonBar/SkillsButton.pressed.connect(_on_skills)
	$ButtonBar/StatsButton.pressed.connect(_on_stats)
	$ButtonBar/QuestButton.pressed.connect(_on_quests)
	
	# Default selection look
	_on_inventory()

func _on_inventory():
	tabs.current_tab = 0
	_set_active_button($ButtonBar/InventoryButton)

func _on_skills():
	tabs.current_tab = 1
	_set_active_button($ButtonBar/SkillsButton)
	# Force an update immediately when switching tabs
	if current_character and skills_view.has_method("update_ui"):
		skills_view.update_ui()

func _on_stats():
	tabs.current_tab = 2
	_set_active_button($ButtonBar/StatsButton)

func _on_quests():
	tabs.current_tab = 3
	_set_active_button($ButtonBar/QuestButton)

func _set_active_button(active_button):
	for b in $ButtonBar.get_children():
		b.modulate = Color(0.7, 0.7, 0.7)
	active_button.modulate = Color(1, 1, 1)
	
func _on_character_changed(character: ClassData):
	current_character = character
	
	# Inform the skills sub-panel who the new active party member is
	if skills_view and skills_view.has_method("set_character"):
		skills_view.set_character(character)
