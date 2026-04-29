extends Control

# Temporary working stats
var stats = {
	"might": 0,
	"endurance": 0,
	"wisdom": 0,
	"dexterity": 0
}

# Node references
@onready var class_option_button: Button = $VBoxContainer/class_option_button
@onready var name_input: LineEdit = $VBoxContainer/name_input
@onready var points_label: Label = $VBoxContainer/PointsContainer/points_label
@onready var might_button: Button = $VBoxContainer/MightContainer/MightButton
@onready var end_button: Button = $VBoxContainer/EndContainer/EndButton
@onready var wis_button: Button = $VBoxContainer/WisContainer/WisButton
@onready var dex_button: Button = $VBoxContainer/DexContainer/DexButton
@onready var save_button: Button = $VBoxContainer/save_button

@onready var might_label: Label = $VBoxContainer/MightContainer/might_label
@onready var end_label: Label = $VBoxContainer/EndContainer/end_label
@onready var wis_label: Label = $VBoxContainer/WisContainer/wis_label
@onready var dex_label: Label = $VBoxContainer/DexContainer/dex_label


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup_class_options()
	_reset_stats()
	save_button.pressed.connect(_on_save_button_pressed)
	
func _setup_class_options():
	class_option_button.clear()
	for class_id in ClassData.Class_Names.keys():
		if class_id == "UNKNOWN": continue
		class_option_button.add_item(class_id)
	
	class_option_button.item_selected.connect(_on_class_selected)

func _reset_stats():
	var base = ClassData.CLASS_STAT_MAP[current_class]
	stats.might = base.get("base_might", 10)
	stats.endurance = base.get("base_end", 10)
	stats.wisdom = base.get("base_wis", 10)
	stats.dexterity = base.get("base_dex", 10)
	bonus_points = max_bonus_points
	_update_ui()

func _update_ui():
	points_label.text = "Bonus Points: " + str(bonus_points)
	might_label.text = "Might: " + str(stats.might)
	end_label.text = "Endurance: " + str(stats.endurance)
	wis_label.text = "Wisdom: " + str(stats.wisdom)
	dex_label.text = "Dexterity: " + str(stats.dexterity)

# Signal handlers for the [+] buttons
func _on_add_stat(stat_name: String):
	if bonus_points > 0:
		stats[stat_name] += 1
		bonus_points -= 1
		_update_ui()

func _on_class_selected(index: int):
	# Map the OptionButton index back to the Enum
	var class_name_str = class_option_button.get_item_text(index)
	current_class = ClassData.Class_Names[class_name_str]
	_reset_stats()

func _on_save_button_pressed():
	# Create the character data package
	var new_character = {
		"name": "Hero " + str(randi() % 100), # Replace with a LineEdit if you want names
		"class": current_class,
		"level": 1,
		"stats": stats.duplicate(),
		"derived": _calculate_derived_stats()
	}
	
	# Push to your PartyManager (Assuming it's an Autoload/Global)
	if PartyManager.has_method("add_member"):
		PartyManager.add_member(new_character)
		print("Character added to party!")
