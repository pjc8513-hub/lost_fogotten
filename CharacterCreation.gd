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

# Node references - CharacterCard
@onready var class_option_button: OptionButton = $HBoxContainer/CharacterCard/class_option_button
@onready var name_input: LineEdit = $HBoxContainer/CharacterCard/name_input
@onready var points_label: Label = $HBoxContainer/CharacterCard/PointsContainer/points_label
@onready var might_button: Button = $HBoxContainer/CharacterCard/MightContainer/MightButton
@onready var end_button: Button = $HBoxContainer/CharacterCard/EndContainer/EndButton
@onready var wis_button: Button = $HBoxContainer/CharacterCard/WisContainer/WisButton
@onready var dex_button: Button = $HBoxContainer/CharacterCard/DexContainer/DexButton
@onready var save_button: Button = $HBoxContainer/CharacterCard/save_button

@onready var might_label: Label = $HBoxContainer/CharacterCard/MightContainer/might_label
@onready var end_label: Label = $HBoxContainer/CharacterCard/EndContainer/end_label
@onready var wis_label: Label = $HBoxContainer/CharacterCard/WisContainer/wis_label
@onready var dex_label: Label = $HBoxContainer/CharacterCard/DexContainer/dex_label


#CharacterStats
@onready var damage_label: Label = $HBoxContainer/CharacterStats/DamageContainer/DamageLabel
@onready var damage_mod_container: Label = $HBoxContainer/CharacterStats/DamageModContainer/DamageModContainer
@onready var accuracy_label: Label = $HBoxContainer/CharacterStats/AccuracyContainer/AccuracyLabel
@onready var critical_chance_label: Label = $HBoxContainer/CharacterStats/CritChanceContainer/CriticalChanceLabel
@onready var critical_amp_label: Label = $HBoxContainer/CharacterStats/CritAmpContainer/CriticalAmpLabel
@onready var counter_chance_label: Label = $HBoxContainer/CharacterStats/CounterChanceContainer/CounterChanceLabel
@onready var attack_speed_label: Label = $HBoxContainer/CharacterStats/AttackSpeedContainer/AttackSpeedLabel
@onready var movement_speed_label: Label = $HBoxContainer/CharacterStats/MovementSpeedContainer2/MovementSpeedLabel
@onready var magic_damage_label: Label = $HBoxContainer/CharacterStats/MagicDamageMod/MagicDamageLabel

# SkillContainer
@onready var skill_list: ItemList = $HBoxContainer/SkillContainer/ScrollContainer/SkillList



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_setup_class_options()
	_populate_skill_list(current_class) # populate for initial class
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
	_populate_skill_list(current_class)

func _on_save_button_pressed():
	var member_name := name_input.text.strip_edges()
	if member_name.is_empty():
		member_name = "Hero %d" % randi_range(100, 999)

	var new_member := ClassData.create_custom_member(current_class, member_name, stats)
	PartyState.add_roster_member(new_member, false)
	SceneManager.change_scene("res://PartyMemberSelection.tscn")

func _populate_skill_list(class_enum: ClassData.Class_Names) -> void:
	skill_list.clear()
	
	var available_skills: Array[SkillData] = SkillRegistry.get_skills_for_class(class_enum)
	
	for skill: SkillData in available_skills:
		var idx: int = skill_list.add_item(skill.display_name)
		skill_list.set_item_metadata(idx, skill.skill_id) # store ID for later
		skill_list.set_item_tooltip(idx, skill.description) # nice UX
		if skill.icon:
			skill_list.set_item_icon(idx, skill.icon)


func _on_item_list_mouse_entered() -> void:
	pass # Replace with function body.
