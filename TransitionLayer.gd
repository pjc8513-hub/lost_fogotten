# TransitionLayer.gd
extends Node

var canvas_layer: CanvasLayer
var overlay: ColorRect
var tween: Tween

func _ready():
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # renders on top of everything
	add_child(canvas_layer)
	

	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)  # start fully black
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	# Makes it fill the screen regardless of resolution
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(overlay)

	# Fade in immediately on game start (clears the initial black)
	# fade_in()

func fade_out() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.4)

func fade_in() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.4)

# Awaitable version for SceneManager to use
func fade_out_and_wait() -> void:
	if tween:
		tween.kill()
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP # block input during fade
	tween = create_tween()
	tween.tween_property(overlay, "color:a", 1.0, 0.4)
	await tween.finished

func fade_in_and_wait() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(overlay, "color:a", 0.0, 0.4)
	await tween.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE # re-enable input
