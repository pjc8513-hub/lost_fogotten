# GoldUI.gd
extends Control

@onready var gold_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/Label2
@onready var food_label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Label2
@onready var torch_label: Label = $PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/Label2
@onready var torch_light_button: Button = $PanelContainer/MarginContainer/VBoxContainer/buffcontainer1/TorchLightButton
@onready var buff_container: HBoxContainer = $PanelContainer/MarginContainer/VBoxContainer/buffcontainer1

func _ready():
	update_display()
	GameEvents.gold_changed.connect(_on_gold_changed)
	GameEvents.food_changed.connect(_on_food_changed)
	GameEvents.torch_changed.connect(_on_torch_changed)
	PartyState.magic_torch_toggled.connect(_on_magic_torch_toggled)
	
	# Listen for active buff changes
	GameEvents.active_buffs_changed.connect(update_buff_icons)
	
	# Setup torch light button
	torch_light_button.pressed.connect(_on_torch_light_button_pressed)
	torch_light_button.visible = false
	torch_light_button.disabled = true
	
	# Initial display of active buffs
	update_buff_icons()
	
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

func update_buff_icons() -> void:
	# 1. Clear existing dynamic buff icons
	for child in buff_container.get_children():
		if child != torch_light_button:
			child.queue_free()
			buff_container.remove_child(child)
	
	# 2. Add current active buffs
	var active_buffs := SpellEffectTracker.get_active_buffs()
	for spell in active_buffs:
		var tex_rect := TextureRect.new()
		tex_rect.name = "BuffIcon_" + spell.spell_id
		tex_rect.custom_minimum_size = Vector2(32, 32)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Load and set texture
		var path: String = str(spell.buff_icon)
		if ResourceLoader.exists(path):
			tex_rect.texture = load(path)
		else:
			push_warning("Buff icon not found: %s" % path)
			
		# Tooltip and interaction
		tex_rect.tooltip_text = spell.get_display_name()
		tex_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		
		buff_container.add_child(tex_rect)
