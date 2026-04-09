extends ScrollContainer

@onready var label = $RichTextLabel # Adjust path if you added a PanelContainer

func _ready():
	# Listen for any messages sent through the Event Bus
	GameEvents.message_logged.connect(add_message)

func add_message(text: String):
	label.append_text(text + "\n")
	await get_tree().process_frame
	set_v_scroll(get_v_scroll_bar().max_value)
