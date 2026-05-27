extends Control
@onready var player_label: Label = $VBoxContainer/HBoxContainer2/PlayerLabel
@onready var store_inventory: ItemList = $VBoxContainer/HBoxContainer/ScrollContainer/StoreInventory
@onready var character_inventory: ItemList = $VBoxContainer/HBoxContainer/ScrollContainer2/CharacterInventory
@onready var description: Label = $VBoxContainer/Description
@onready var amount: Label = $VBoxContainer/Amount


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
