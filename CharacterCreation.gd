extends Control

const BONUS_POINT_POOL := 6

var current_class: ClassData.Class_Names = ClassData.Class_Names.KNIGHT
var bonus_points: int = BONUS_POINT_POOL
var stats := {
	"might": 0,
	"endurance": 0,
	"wisdom": 0,
	"dexterity": 0,
}

# Node references
@onready var class_option_button: OptionButton = $VBoxContainer/class_option_button
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
	might_button.pressed.connect(func(): _on_add_stat("might"))
	end_button.pressed.connect(func(): _on_add_stat("endurance"))
	wis_button.pressed.connect(func(): _on_add_stat("wisdom"))
	dex_button.pressed.connect(func(): _on_add_stat("dexterity"))
	name_input.text_changed.connect(func(_new_text): _update_ui())
	_reset_stats()
	save_button.pressed.connect(_on_save_button_pressed)
	
func _setup_class_options():
	class_option_button.clear()
	var selected_index := 0
	var item_index := 0
	for class_id in ClassData.Class_Names.keys():
		if class_id == "UNKNOWN":
			continue
		class_option_button.add_item(class_id)
		if ClassData.Class_Names[class_id] == current_class:
			selected_index = item_index
		item_index += 1
	
	class_option_button.item_selected.connect(_on_class_selected)
	class_option_button.select(selected_index)

func _reset_stats():
	var base: Dictionary = ClassData.CLASS_STAT_MAP.get(current_class, {})
	stats.might = int(base.get("base_might", 10))
	stats.endurance = int(base.get("base_end", 10))
	stats.wisdom = int(base.get("base_wis", 10))
	stats.dexterity = int(base.get("base_dex", 10))
	bonus_points = BONUS_POINT_POOL
	_update_ui()

func _update_ui():
	points_label.text = str(bonus_points)
	might_label.text = str(stats.might)
	end_label.text = str(stats.endurance)
	wis_label.text = str(stats.wisdom)
	dex_label.text = str(stats.dexterity)
	save_button.disabled = name_input.text.strip_edges().is_empty()

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
	var member_name := name_input.text.strip_edges()
	if member_name.is_empty():
		member_name = "Hero %d" % randi_range(100, 999)

	var new_member := ClassData.create_custom_member(current_class, member_name, stats)
	PartyState.add_roster_member(new_member, false)
	SceneManager.change_scene("res://PartyMemberSelection.tscn")
