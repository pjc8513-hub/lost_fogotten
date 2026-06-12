# item_tooltip.gd
extends PanelContainer

@onready var name_label = $VBoxContainer/NameLabel
@onready var type_label = $VBoxContainer/TypeLabel
@onready var bonuses_label = $VBoxContainer/BonusesLabel
@onready var stat_label: Label = $VBoxContainer/StatLabel
@onready var definition_label: Label = $VBoxContainer/DefinitionLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel

func _ready():
	hide() # Start hidden

## Populates the tooltip labels using your item data and Godot tag resources
func display_item(inst: ItemInstance) -> void:
	if inst == null or inst.item_data == null:
		hide()
		return
		
	var item = inst.item_data
	name_label.text = inst.get_display_name()
	
	# Match colors or append text based on rarity tier
	# (Assuming you mapped your Godot Tier enum somewhere)
	type_label.text = "Tier: %s" % str(inst.tier) 
	
	# Loop through your bonuses array we set up earlier
	var bonus_text = ""
	for bonus in inst.bonuses:
		# Grabs the pre-computed text string or the dynamic display function
		bonus_text += "- " + bonus["display_text"] + "\n"
		
	bonuses_label.text = bonus_text
	show()

func _process(_delta):
	if visible:
		# Follow the cursor slightly offset so it doesn't clip under the pointer
		global_position = get_global_mouse_position() + Vector2(15, 15)
