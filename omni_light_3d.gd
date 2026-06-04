extends OmniLight3D

signal torch_durability_changed(current: float, max_val: float, is_lit: bool)
signal torch_type_changed(is_magic: bool)  # New signal to notify UI of torch type

@export var max_durability: float = 100.0
var current_durability: float = 100.0

var theme_ref: MapTheme
var time: float = 0.0
var is_magic_torch: bool = false  # True when magic torch is active

func _ready() -> void:
	World.player_stepped.connect(_on_player_stepped)
	PartyState.magic_torch_toggled.connect(_on_magic_torch_toggled)

func configure_torch(theme: MapTheme) -> void:
	theme_ref = theme
	if theme_ref == null:
		return
	
	light_color = theme_ref.torch_color
	is_magic_torch = PartyState.is_magic_torch_lit
	
	# If the theme allows flicker, we check PartyState to see if the player wants it on.
	# If they have no torches left, force it to false regardless.
	if theme_ref.enable_flicker and PartyState.party_torches > 0:
		# Torch state persists via PartyState instead of resetting to true automatically
		visible = PartyState.is_torch_lit 
	elif PartyState.is_magic_torch_lit:
		# Show magic torch if active
		visible = true
		_apply_magic_torch_appearance()
	else:
		visible = false
		
	set_process(theme_ref.enable_flicker and visible)
	torch_durability_changed.emit(current_durability, max_durability, is_currently_lit())
	torch_type_changed.emit(is_magic_torch)

# Clean helper to check both the global state and inventory status safely
func is_currently_lit() -> bool:
	var regular_lit = theme_ref != null and theme_ref.enable_flicker and PartyState.is_torch_lit and PartyState.party_torches > 0
	var magic_lit = PartyState.is_magic_torch_lit
	return regular_lit or magic_lit

func toggle_torch() -> void:
	if theme_ref == null or not theme_ref.enable_flicker:
		return
		
	# Invert the global variable state
	PartyState.is_torch_lit = !PartyState.is_torch_lit
	
	# Visual updates match the global state
	visible = PartyState.is_torch_lit
	set_process(visible)
	
	# Reset to regular torch appearance if switching away from magic torch
	if not PartyState.is_magic_torch_lit:
		light_color = theme_ref.torch_color
		is_magic_torch = false
		torch_type_changed.emit(false)
	
	torch_durability_changed.emit(current_durability, max_durability, visible)
	print("Torch toggled via PartyState. Active: ", visible)

func _on_magic_torch_toggled(is_active: bool) -> void:
	# Immediately respond to magic torch state changes
	if is_active:
		# Magic torch turned on - show it immediately
		is_magic_torch = true
		visible = true
		_apply_magic_torch_appearance()
		torch_type_changed.emit(true)
		torch_durability_changed.emit(current_durability, max_durability, true)
	else:
		# Magic torch turned off - hide it immediately
		is_magic_torch = false
		if theme_ref != null and PartyState.is_torch_lit and PartyState.party_torches > 0:
			# Switch back to regular torch if it's still active
			visible = true
			light_color = theme_ref.torch_color
			set_process(true)
		else:
			# No regular torch, just hide the light
			visible = false
			set_process(false)
		torch_type_changed.emit(false)
		torch_durability_changed.emit(current_durability, max_durability, is_currently_lit())

func _on_player_stepped(_total_steps: int) -> void:
	# Check if magic torch is still active and has mana
	if PartyState.is_magic_torch_lit:
		var had_magic = PartyState.is_magic_torch_lit
		if not PartyState.drain_magic_torch_mana():
			# Magic torch ran out of mana
			visible = false
			set_process(false)
			is_magic_torch = false
			torch_type_changed.emit(false)
			torch_durability_changed.emit(0, max_durability, false)
			return
		else:
			# Magic torch is still active
			if not is_magic_torch:
				is_magic_torch = true
				_apply_magic_torch_appearance()
				torch_type_changed.emit(true)
			visible = true
			set_process(false)  # Magic torch doesn't flicker like regular torch
			torch_durability_changed.emit(current_durability, max_durability, true)
			return
	
	# Regular torch logic
	# Use our helper function to halt consumption if toggled off or empty
	if not is_currently_lit():
		return
		
	current_durability -= 1.0
	if current_durability <= 0.0:
		_try_consume_next_inventory_torch()
		
	_update_light_energy()
	torch_durability_changed.emit(current_durability, max_durability, is_currently_lit())

func _try_consume_next_inventory_torch() -> void:
	# If we have more than 1 torch, it means we can safely consume a backup from inventory
	if PartyState.party_torches > 1:
		PartyState.party_torches -= 1
		current_durability = max_durability 
		_update_light_energy()
		print("Consumed a torch! Torches remaining in backup: ", PartyState.party_torches - 1)
	else:
		# We were on our last torch (party_torches == 1 or somehow 0) and it just fully expired.
		PartyState.party_torches = 0
		PartyState.is_torch_lit = false
		visible = false
		set_process(false)
		
		GameEvents.message_logged.emit("Your last torch burned out!")
		print("Your last torch burned out. You are in total darkness.")
		# e.g., MessageLog.add_message("Your last torch burned out...")
		
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

func _apply_magic_torch_appearance() -> void:
	# Set the magic torch to a bright green color
	light_color = Color.GREEN  # Can adjust to a specific shade like Color(0.3, 1.0, 0.3)
	is_magic_torch = true
	# Magic torch has consistent, slightly brighter energy than regular torch
	if theme_ref != null:
		light_energy = theme_ref.torch_base_energy * 1.2
	else:
		light_energy = 2.0
