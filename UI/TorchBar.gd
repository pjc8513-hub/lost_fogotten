extends Control

@onready var progress_bar: ProgressBar = $ProgressBar # Adjust path if needed

var current_torch_is_magic: bool = false
var current_torch_node: Node = null

func _ready() -> void:
	# Hide the bar by default until a valid torch connects to it
	hide()

# Call this from your Player scene, Map setup, or Level initializer 
# whenever the active player/torch node is spawned or found.
func hook_up_torch(torch_node: Node) -> void:
	if torch_node and torch_node.has_signal("torch_durability_changed"):
		# Store reference for cleanup
		current_torch_node = torch_node
		# Connect the torch updates to our UI updater function
		torch_node.torch_durability_changed.connect(_on_torch_durability_changed)
		
		# Connect torch type changes to update color
		if torch_node.has_signal("torch_type_changed"):
			torch_node.torch_type_changed.connect(_on_torch_type_changed)
		
		# Immediately catch up to the torch's current values
		_on_torch_durability_changed(torch_node.current_durability, torch_node.max_durability, PartyState.is_torch_lit)
		if torch_node.has_meta("is_magic_torch"):
			current_torch_is_magic = torch_node.get_meta("is_magic_torch")
		show()

func _exit_tree() -> void:
	# Disconnect torch signals to prevent orphaned connections
	if current_torch_node != null and is_instance_valid(current_torch_node):
		if current_torch_node.torch_durability_changed.is_connected(_on_torch_durability_changed):
			current_torch_node.torch_durability_changed.disconnect(_on_torch_durability_changed)
		if current_torch_node.has_signal("torch_type_changed"):
			if current_torch_node.torch_type_changed.is_connected(_on_torch_type_changed):
				current_torch_node.torch_type_changed.disconnect(_on_torch_type_changed)
		current_torch_node = null

func _on_torch_durability_changed(current: float, max_val: float, torch_is_lit: bool) -> void:
	if progress_bar == null:
		return
		
	progress_bar.max_value = max_val
	progress_bar.value = current
	
	# The UI bar is only visible if:
	# - The torch has fuel AND is turned on (regular torch)
	# - AND it's NOT a magic torch (magic torch doesn't use durability)
	visible = current > 0.0 and torch_is_lit and not current_torch_is_magic
	
	# Update color based on torch type
	_update_progress_bar_color()

func _on_torch_type_changed(is_magic: bool) -> void:
	current_torch_is_magic = is_magic
	# Hide the bar when magic torch is active
	if is_magic:
		visible = false
	_update_progress_bar_color()

func _update_progress_bar_color() -> void:
	if progress_bar == null:
		return
	
	if current_torch_is_magic:
		# Green color for magic torch
		progress_bar.add_theme_color_override("fill_color", Color.GREEN)
	else:
		# Default orange/yellow for regular torch
		progress_bar.add_theme_color_override("fill_color", Color(1.0, 0.647, 0.0))  # Orange
