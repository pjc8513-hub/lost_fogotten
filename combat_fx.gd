extends Control # Or PanelContainer / Control for your faceplate

@onready var status_overlay: ColorRect = $StatusOverlay

# Track what effects are currently active on this specific character
var active_visual_statuses: Array[String] = []
var current_index: int = 0
var cycle_timer: float = 0.0

# How long to display each status overlay before switching (in seconds)
const DISPLAY_DURATION: float = 1.5 

# Dictionary defining the visual parameters for our shader
const STATUS_STYLES = {
	"poison": {"color": Color(0.6, 0.1, 0.8, 0.6), "count": 16.0, "speed": 1.0},
	"paralyze": {"color": Color(1.0, 0.9, 0.0, 0.7), "count": 12.0, "speed": 0.0},
	"weakness": {"color": Color(0.902, 0.698, 0.102, 0.855), "count": 8.0, "speed": -0.5},
	"disease": {"color": Color(0.9, 0.4, 0.0, 0.6), "count": 22.0, "speed": 2.0},
	"fear": {"color": Color(0.1, 0.1, 0.1, 0.75), "count": 25.0, "speed": 4.0},
	"frozen": {"color": Color(0.5, 0.8, 1.0, 0.6), "count": 20.0, "speed": 1.5},
	"burn": {"color": Color(1.0, 0.15, 0.0, 0.65), "count": 18.0, "speed": 2.5},
	"blind": {"color": Color(0.02, 0.02, 0.02, 0.8), "count": 10.0, "speed": 0.6},
	"curse": {"color": Color(0.45, 0.0, 0.55, 0.65), "count": 14.0, "speed": -1.0},
	"confusion": {"color": Color(0.1, 0.9, 0.9, 0.55), "count": 28.0, "speed": -3.0},
	"stun": {"color": Color(1.0, 1.0, 1.0, 0.55), "count": 7.0, "speed": 0.0},
	"stone_skin": {"color": Color(0.6, 0.6, 0.55, 0.6), "count": 11.0, "speed": 0.2}
}

func _ready() -> void:
	status_overlay.hide()
	_refresh_visibility()

func _process(delta: float) -> void:
	if active_visual_statuses.is_empty():
		return
		
	# Manage our rotation cycle using delta time
	cycle_timer += delta
	if cycle_timer >= DISPLAY_DURATION:
		cycle_timer = 0.0
		# Advance to next status, wrapping around to 0 at the end of the array
		current_index = (current_index + 1) % active_visual_statuses.size()
		_update_shader_visuals()

func set_statuses(statuses: Array[String]) -> void:
	var supported_statuses: Array[String] = []
	for status_name in statuses:
		var normalized := StatusEffects.normalize_id(status_name)
		if STATUS_STYLES.has(normalized):
			supported_statuses.append(normalized)

	active_visual_statuses = supported_statuses
	if active_visual_statuses.is_empty():
		current_index = 0
		cycle_timer = 0.0
		status_overlay.hide()
		_refresh_visibility()
		return

	current_index = min(current_index, active_visual_statuses.size() - 1)
	cycle_timer = 0.0
	status_overlay.show()
	_update_shader_visuals()
	_refresh_visibility()

# Call this whenever a character gains a status effect
func add_status(effect_name: String) -> void:
	var normalized := StatusEffects.normalize_id(effect_name)
	if STATUS_STYLES.has(normalized) and not active_visual_statuses.has(normalized):
		active_visual_statuses.append(normalized)
		if active_visual_statuses.size() == 1:
			current_index = 0
			cycle_timer = 0.0
			status_overlay.show()
			_update_shader_visuals()
			_refresh_visibility()

# Call this whenever a character is cured
func remove_status(effect_name: String) -> void:
	var normalized := StatusEffects.normalize_id(effect_name)
	if active_visual_statuses.has(normalized):
		var strictly_current_playing = active_visual_statuses[current_index]
		active_visual_statuses.erase(normalized)
		
		if active_visual_statuses.is_empty():
			status_overlay.hide()
		else:
			# Re-align index safely so we don't look up an out-of-bounds element
			current_index = active_visual_statuses.find(strictly_current_playing)
			if current_index == -1:
				current_index = 0
			cycle_timer = 0.0
			_update_shader_visuals()
		_refresh_visibility()

func _update_shader_visuals() -> void:
	var mat = status_overlay.material as ShaderMaterial
	if not mat: return
	
	var current_status = active_visual_statuses[current_index]
	var style = STATUS_STYLES[current_status]
	
	# Push the values into your uniform shader variables
	mat.set_shader_parameter("line_color", style["color"])
	mat.set_shader_parameter("line_count", style["count"])
	mat.set_shader_parameter("speed", style["speed"])

func has_active_status_overlay() -> bool:
	return not active_visual_statuses.is_empty()

func _refresh_visibility() -> void:
	visible = status_overlay.visible or _has_visible_transient_fx()

func _has_visible_transient_fx() -> bool:
	for child in get_children():
		if child != status_overlay and child is CanvasItem and child.visible:
			return true
	return false
