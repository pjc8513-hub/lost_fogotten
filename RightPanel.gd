extends VBoxContainer

@onready var tabs = $TabContainer

func _ready():
	$ButtonBar/InventoryButton.pressed.connect(_on_inventory)
	$ButtonBar/SkillsButton.pressed.connect(_on_skills)
	$ButtonBar/InfoButton.pressed.connect(_on_info)

func _on_inventory():
	tabs.current_tab = 0

func _on_skills():
	tabs.current_tab = 1

func _on_info():
	tabs.current_tab = 2
