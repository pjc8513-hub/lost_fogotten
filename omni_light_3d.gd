extends OmniLight3D

signal torch_durability_changed(current: float, max_val: float, is_lit: bool)

@export var max_durability: float = 100.0
var current_durability: float = 100.0

var theme_ref: MapTheme
var time: float = 0.0

func _ready() -> void:
	World.player_stepped.connect(_on_player_stepped)

func configure_torch(theme: MapTheme) -> void:
	theme_ref = theme
	if theme_ref == null:
		return
	
	light_color = theme_ref.torch_color
	
	# If the theme allows flicker, we check PartyState to see if the player wants it on.
	# If they have no torches left, force it to false regardless.
	if theme_ref.enable_flicker and PartyState.party_torches > 0:
		# Torch state persists via PartyState instead of resetting to true automatically
		visible = PartyState.is_torch_lit 
	else:
		visible = false
		
	set_process(theme_ref.enable_flicker and visible)
	torch_durability_changed.emit(current_durability, max_durability, is_currently_lit())

# Clean helper to check both the global state and inventory status safely
func is_currently_lit() -> bool:
	return theme_ref != null and theme_ref.enable_flicker and PartyState.is_torch_lit and PartyState.party_torches > 0

func toggle_torch() -> void:
	if theme_ref == null or not theme_ref.enable_flicker:
		return
		
	# Invert the global variable state
	PartyState.is_torch_lit = !PartyState.is_torch_lit
	
	# Visual updates match the global state
	visible = PartyState.is_torch_lit
	set_process(visible)
	
	torch_durability_changed.emit(current_durability, max_durability, visible)
	print("Torch toggled via PartyState. Active: ", visible)

func _on_player_stepped(_total_steps: int) -> void:
	# Use our helper function to halt consumption if toggled off or empty
	if not is_currently_lit():
		return
		
	current_durability -= 1.0
	if current_durability <= 0.0:
		_try_consume_next_inventory_torch()
		
	_update_light_energy()
	torch_durability_changed.emit(current_durability, max_durability, is_currently_lit())

func _try_consume_next_inventory_torch() -> void:
	if PartyState.party_torches > 0:
		PartyState.party_torches -= 1
		current_durability = max_durability 
		_update_light_energy()
		print("Consumed a torch! Torches remaining: ", PartyState.party_torches)
	else:
		# Out of resources! Kill the flame globally and locally
		PartyState.is_torch_lit = false
		visible = false
		set_process(false)
		print("Your last torch burned out. You are in total darkness.")
		
	torch_durability_changed.emit(current_durability, max_durability, is_currently_lit())

func _process(delta: float) -> void:
	if not is_currently_lit():
		return

	time += delta * theme_ref.torch_flicker_speed
	var noise = sin(time) * cos(time * 0.7) + sin(time * 1.5)
	light_energy = _get_base_dynamic_energy() + (noise * theme_ref.torch_flicker_amount)

func _get_base_dynamic_energy() -> float:
	if theme_ref == null: return 0.0
	var health_pct = current_durability / max_durability
	return theme_ref.torch_base_energy * clamp(health_pct * 1.5, 0.2, 1.0)

func _update_light_energy() -> void:
	light_energy = _get_base_dynamic_energy()
