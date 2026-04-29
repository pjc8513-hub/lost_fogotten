# PartySetupScene.gd
extends Node
@onready var points_label: Label = $PanelContainer/VBoxContainer/PointsLabel
func _ready() -> void:
	$PanelContainer/VBoxContainer/quick_start.pressed.connect(_on_quick_start_pressed)
	$PanelContainer/VBoxContainer/PedalContainer/HM2Toggle.pressed.connect(_on_HM2Toggle_pressed)
	$PanelContainer/VBoxContainer/PedalContainer2/Phase90Toggle.pressed.connect(_on_phaser90_pressed)
	$PanelContainer/VBoxContainer/PedalContainer3/Cathedral.pressed.connect(_on_Cathedral_pressed)
	$PanelContainer/VBoxContainer/PedalContainer4/ClearAll.pressed.connect(_clear_all)
	
	_update_ui()


	
func _on_quick_start_pressed():
	PartyState.reset_default_party()  # already exists, sets up default party
	SceneManager.change_scene("res://Main.tscn")

func _update_ui() -> void:
	points_label.text = "EP: %d / %d" % [LoadoutManager.get_points_remaining(), LoadoutManager.total_points]

	# Apply visuals to your WorldEnvironment
	var world_env_node: WorldEnvironment = get_tree().get_first_node_in_group("world_environment")
	if world_env_node:
		var vis := LoadoutManager.get_visual_params()
		world_env_node.fog_density = vis.fog_density
		world_env_node.glow_enabled = true
		world_env_node.glow_intensity = vis.bloom_intensity
	
	# Example: use stats in combat
	print("Current phys bonus: ", LoadoutManager.get_stat_modifier("phys_damage"))


func _clear_all() -> void:
	for slot in EffectLoadout.Slot.values():
		LoadoutManager.unequip_slot(slot)

func _on_HM2Toggle_pressed():
	var hm2 := load("res://data/pedals/HM-2 Chainsaw.tres")
	LoadoutManager.equip_effect(hm2)
	
	_update_ui()

func _on_phaser90_pressed():
	var phase := load("res://data/pedals/Phase90.tres")
	LoadoutManager.equip_effect(phase)
	
func _on_Cathedral_pressed():
	var verb = load("res://data/pedals/Cathedral.tres")
	LoadoutManager.equip_effect(verb)
