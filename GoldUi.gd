# GoldUI.gd
extends Control

@onready var gold_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Label2
@onready var food_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Label2
@onready var torch_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Label2
@onready var torch_light_button: Button = $PanelContainer/MarginContainer/VBoxContainer/buffcontainer1/TorchLightButton

func _ready():
	update_display()
	GameEvents.gold_changed.connect(_on_gold_changed)
	GameEvents.food_changed.connect(_on_food_changed)
	GameEvents.torch_changed.connect(_on_torch_changed)
	PartyState.magic_torch_toggled.connect(_on_magic_torch_toggled)
	
	# Setup torch light button
	torch_light_button.pressed.connect(_on_torch_light_button_pressed)
	torch_light_button.visible = false
	torch_light_button.disabled = true
	
func update_display():
	gold_label.text = str(PartyState.party_gold)
	food_label.text = str(PartyState.party_food)
	torch_label.text = str(PartyState.party_torches)

func _on_gold_changed(new_amount: int):
	gold_label.text = str(new_amount)

func _on_food_changed(new_amount: int):
	food_label.text = str(new_amount)

func _on_torch_changed(new_amount: int):
	torch_label.text = str(new_amount)

func _on_magic_torch_toggled(is_active: bool) -> void:
	torch_light_button.visible = is_active
	torch_light_button.disabled = not is_active

func _on_torch_light_button_pressed() -> void:
	var selected = PartyState.get_selected()
	if selected != null and PartyState.is_magic_torch_lit:
		PartyState.toggle_magic_torch(selected)
