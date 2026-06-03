# GoldUI.gd
extends Control

@onready var gold_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Label2
@onready var food_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Label2
@onready var torch_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Label2

func _ready():
	update_display()
	GameEvents.gold_changed.connect(_on_gold_changed)
	GameEvents.food_changed.connect(_on_food_changed)
	GameEvents.torch_changed.connect(_on_torch_changed)
	
func update_display():
	gold_label.text = str(PartyState.party_gold)
	food_label.text = str(PartyState.party_food)

func _on_gold_changed(new_amount: int):
	gold_label.text = str(new_amount)

func _on_food_changed(new_amount: int):
	food_label.text = str(new_amount)

func _on_torch_changed(new_amount: int):
	torch_label.text = str(new_amount)
