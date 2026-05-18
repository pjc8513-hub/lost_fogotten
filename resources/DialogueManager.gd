extends Node

signal dialogue_opened
signal dialogue_closed
signal dialogue_changed

var dialogue_data = {}
var current_node = ""
var current_npc = ""

var ui = null

func _ready():
	load_dialogue_file("res://data/dialogue/dialogue.json")
	

func register_ui(dialogue_ui):
	ui = dialogue_ui

func load_dialogue_file(path: String):
	if not FileAccess.file_exists(path):
		push_error("Dialogue file missing: " + path)
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var text = file.get_as_text()

	var json = JSON.new()
	var result = json.parse(text)

	if result != OK:
		push_error("Failed to parse dialogue JSON")
		return

	dialogue_data = json.data

func start_dialogue(node_id: String, npc_name := ""):
	if not dialogue_data.has(node_id):
		push_error("Dialogue node missing: " + node_id)
		return

	current_node = node_id
	current_npc = npc_name

	show_node(node_id)

	emit_signal("dialogue_opened")

func show_node(node_id: String):
	if ui == null:
		push_error("Dialogue UI not registered")
		return

	if not dialogue_data.has(node_id):
		push_error("Missing node: " + node_id)
		return

	current_node = node_id

	var node = dialogue_data[node_id]

	if node.has("condition"):
		if not check_condition(node["condition"]):
			if node.has("fail_goto"):
				show_node(node["fail_goto"])
			else:
				close_dialogue()
			return

	ui.show()

	ui.npc_name_label.text = current_npc
	ui.dialogue_text.text = node.get("text", "")

	ui.clear_choices()

	ui.password_input.hide()

	if node.get("input", false):
		setup_input_node(node)
	else:
		setup_choice_node(node)

	emit_signal("dialogue_changed")

func setup_choice_node(node: Dictionary):
	if not node.has("choices"):
		return

	for choice in node["choices"]:

		if choice.has("condition"):
			if not check_condition(choice["condition"]):
				continue

		var button = ui.choice_button_scene.instantiate()

		button.text = choice.get("text", "Continue")

		ui.choice_container.add_child(button)

		button.pressed.connect(func():
			process_choice(choice)
		)

func setup_input_node(node: Dictionary):
	ui.password_input.show()
	ui.password_input.text = ""
	ui.password_input.placeholder_text = node.get("placeholder", "Enter text")

	if ui.password_input.text_submitted.is_connected(_on_input_submitted):
		ui.password_input.text_submitted.disconnect(_on_input_submitted)

	ui.password_input.text_submitted.connect(func(text):
		_on_input_submitted(text, node)
	)

	ui.password_input.grab_focus()

func _on_input_submitted(text: String, node: Dictionary):
	var expected = node.get("answer", "")

	if text.to_lower() == expected.to_lower():
		if node.has("success_goto"):
			show_node(node["success_goto"])
		else:
			close_dialogue()
	else:
		if node.has("fail_goto"):
			show_node(node["fail_goto"])
		else:
			close_dialogue()

func process_choice(choice: Dictionary):

	if choice.has("goto"):
		show_node(choice["goto"])
		return

	if choice.get("close", false):
		close_dialogue()
		return

	if choice.has("action"):
		process_action(choice)

func process_action(choice: Dictionary):

	var action = choice["action"]

	match action:

		"open_shop":
			#ShopManager.open_shop(choice.get("shop_id", ""))
			close_dialogue()

		"accept_quest":
			QuestManager.accept_quest(choice.get("quest_id", ""))

			if choice.has("goto"):
				show_node(choice["goto"])
			else:
				close_dialogue()

		"complete_quest":
			QuestManager.complete_quest(choice.get("quest_id", ""))

			if choice.has("goto"):
				show_node(choice["goto"])
			else:
				close_dialogue()

		"rotate_object":
			#PuzzleManager.rotate(choice.get("target", ""))

			if choice.has("goto"):
				show_node(choice["goto"])
			else:
				close_dialogue()

		"give_item":
			#InventoryManager.add_item(choice.get("item_id", ""), choice.get("amount", 1))

			if choice.has("goto"):
				show_node(choice["goto"])
			else:
				close_dialogue()

		"take_item":
			#InventoryManager.remove_item(choice.get("item_id", ""), choice.get("amount", 1))

			if choice.has("goto"):
				show_node(choice["goto"])
			else:
				close_dialogue()

		"start_battle":
			#Spawn enemy trigger when that gets added
			close_dialogue()

		_:
			push_warning("Unknown dialogue action: " + action)
			close_dialogue()

func check_condition(condition: String) -> bool:

	var parts = condition.split(":")

	if parts.size() < 2:
		return true

	var condition_type = parts[0]
	var value = parts[1]

	match condition_type:

		"quest_started":
			return QuestManager.has_quest(value)

		"quest_complete":
			return QuestManager.is_complete(value)

		"has_item":
			return InventoryManager.party_has_item(value)

		"missing_item":
			return InventoryManager.party_has_item(value)

		_:
			return true

func show_confirmation(prompt_text: String, yes_callback: Callable, no_callback: Callable = Callable()) -> void:
	#Show a simple Yes/No confirmation dialog with dynamic text.
	if ui == null:
		push_error("Dialogue UI not registered")
		return
	
	ui.show()
	ui.npc_name_label.text = ""  # Clear NPC name for generic confirmations
	ui.dialogue_text.text = prompt_text
	ui.clear_choices()
	ui.password_input.hide()
	
	# Yes button
	var yes_button = ui.choice_button_scene.instantiate()
	yes_button.text = "Yes"
	ui.choice_container.add_child(yes_button)
	yes_button.pressed.connect(func():
		yes_callback.call()
		close_dialogue()
	)
	
	# No button
	var no_button = ui.choice_button_scene.instantiate()
	no_button.text = "No"
	ui.choice_container.add_child(no_button)
	no_button.pressed.connect(func():
		if no_callback.is_valid():
			no_callback.call()
		close_dialogue()
	)

func close_dialogue():

	if ui:
		ui.hide()

	current_node = ""

	emit_signal("dialogue_closed")
