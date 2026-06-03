extends OmniLight3D

signal torch_durability_changed(current: float, max_val: float, is_lit: bool)

# Durability parameters (Now measured in steps instead of seconds!)
@export var max_durability: float = 100.0 # e.g., 100 steps per torch
var current_durability: float = 100.0
var is_lit: bool = true

var theme_ref: MapTheme
var time: float = 0.0

func _ready() -> void:
	# Connect to the step counter signal
	World.player_stepped.connect(_on_player_stepped)

func configure_torch(theme: MapTheme) -> void:
	theme_ref = theme
	if theme_ref == null:
		return
	
	light_color = theme_ref.torch_color
	is_lit = theme_ref.enable_flicker
	visible = is_lit
	set_process(theme_ref.enable_flicker)
	torch_durability_changed.emit(current_durability, max_durability, is_lit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_torch") and theme_ref and theme_ref.enable_flicker:
		is_lit = !is_lit
		visible = is_lit

# Called when the player actually moves a space
func _on_player_stepped(_total_steps: int) -> void:
	if theme_ref == null or not is_lit:
		return
		
	# 1. Consume Durability per step
	current_durability -= 1.0
	if current_durability <= 0.0:
		_try_consume_next_inventory_torch()
		
	_update_light_energy()
	
	torch_durability_changed.emit(current_durability, max_durability, is_lit)

# Purely handles the visual flame animation loop
func _process(delta: float) -> void:
	if theme_ref == null or not is_lit:
		return

	# Apply continuous flicker effect while standing still
	time += delta * theme_ref.torch_flicker_speed
	var noise = sin(time) * cos(time * 0.7) + sin(time * 1.5)
	
	# Combine dynamic energy calculations with aesthetic flicker
	light_energy = _get_base_dynamic_energy() + (noise * theme_ref.torch_flicker_amount)

func _get_base_dynamic_energy() -> float:
	if theme_ref == null: return 0.0
	var health_pct = current_durability / max_durability
	return theme_ref.torch_base_energy * clamp(health_pct * 1.5, 0.2, 1.0)

# Updates energy immediately on step changes
func _update_light_energy() -> void:
	light_energy = _get_base_dynamic_energy()

func toggle_torch() -> void:
	# Ignore if the current map theme doesn't allow/need a torch (e.g., bright daytime)
	if theme_ref == null or not theme_ref.enable_flicker:
		return
		
	is_lit = !is_lit
	visible = is_lit
	
	# Broadcast the change immediately so the UI bar can update its visibility/values
	torch_durability_changed.emit(current_durability, max_durability, is_lit)
	print("Torch toggled. Active: ", is_lit)

func _try_consume_next_inventory_torch() -> void:
	if PartyState.total_torches > 0:
		PartyState.total_torches -= 1
		current_durability = max_durability 
		_update_light_energy()
		print("Consumed a torch! Torches remaining: ", PartyState.total_torches)
		GameEvents.message_logged.emit("Consumed a torch! Torches remaining: %d" % PartyState.total_torches)
	else:
		is_lit = false
		visible = false
		print("Your last torch burned out. You are in total darkness.")
		GameEvents.message_logged.emit("Your last torch burned out.")
		torch_durability_changed.emit(current_durability, max_durability, is_lit)
