extends Control

@onready var progress_bar: ProgressBar = $ProgressBar # Adjust path if needed


func _ready() -> void:
	# Hide the bar by default until a valid torch connects to it
	hide()

# Call this from your Player scene, Map setup, or Level initializer 
# whenever the active player/torch node is spawned or found.
func hook_up_torch(torch_node: Node) -> void:
	if torch_node and torch_node.has_signal("torch_durability_changed"):
		# Connect the torch updates to our UI updater function
		torch_node.torch_durability_changed.connect(_on_torch_durability_changed)
		
		# Immediately catch up to the torch's current values
		_on_torch_durability_changed(torch_node.current_durability, torch_node.max_durability, torch_node.is_lit)
		show()

func _on_torch_durability_changed(current: float, max_val: float, torch_is_lit: bool) -> void:
	if progress_bar == null:
		return
		
	progress_bar.max_value = max_val
	progress_bar.value = current
	
	# The UI bar is only visible if the torch has fuel AND is turned on!
	visible = current > 0.0 and torch_is_lit
