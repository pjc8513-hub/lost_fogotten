extends Node

signal dialogue_opened
signal dialogue_closed
signal dialogue_changed

var dialogue_data = {}
var current_node = ""
var current_npc = ""

var _password_success_callback: Callable = Callable()
var _password_fail_callback: Callable = Callable()
var _expected_password: String = ""

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
	# Handle array of actions (new format)
	if choice.has("actions"):
		var actions = choice["actions"]
		for act in actions:
			execute_action(act)
		
		# Apply transition after all actions are processed
		if choice.has("goto"):
			show_node(choice["goto"])
		elif choice.get("close", false):
			close_dialogue()
		else:
			close_dialogue()
		return

	# Handle single action (backwards compatibility)
	if choice.has("action"):
		execute_action(choice)
		# Apply transition after action
		if choice.has("goto"):
			show_node(choice["goto"])
		elif choice.get("close", false):
			close_dialogue()
		else:
			close_dialogue()
		return

	# Handle direct navigation
	if choice.has("goto"):
		show_node(choice["goto"])
		return

	if choice.get("close", false):
		close_dialogue()
		return

func execute_action(action_dict: Dictionary):
	"""Execute a single action without handling navigation."""
	var action = action_dict.get("action", "")

	match action:

		"open_shop":
			#ShopManager.open_shop(action_dict.get("shop_id", ""))
			pass

		"accept_quest":
			QuestManager.accept_quest(action_dict.get("quest_id", ""))

		"complete_quest":
			QuestManager.complete_quest(action_dict.get("quest_id", ""))

		"rotate_object":
			#PuzzleManager.rotate(action_dict.get("target", ""))
			pass

		"give_item":
			var item_id = action_dict.get("item_id", "")
			var amount = action_dict.get("amount", 1)
			
			for i in range(amount):
				# Optional: you could check if it's blocked here, but usually NPCs giving items is intentional
				var item_instance = LootManager.create_item_instance(item_id)
				if item_instance:
					var target_member = PartyState.active_party.pick_random()
					InventoryManager.add_item(target_member, item_instance)
					GameEvents.message_logged.emit(
						"[color=yellow]%s[/color] [color=cyan]Received: %s[/color]"
						% [target_member.member_name, item_instance.item_data.name]
					)

		"take_item":
			InventoryManager.remove_item_by_id(action_dict.get("item_id", ""), action_dict.get("amount", 1))

		"update_quest":
			var qid = action_dict.get("quest_id", "")
			QuestManager.add_progress(qid, 1)

		"start_battle":
			#Spawn enemy trigger when that gets added
			pass

		_:
			if action != "":
				push_warning("Unknown dialogue action: " + action)

func check_condition(condition: String) -> bool:
	var conditions = condition.split(",")
	for cond in conditions:
		if not _check_single_condition(cond.strip_edges()):
			return false
	return true

func _check_single_condition(condition: String) -> bool:
	var parts = condition.split(":")

	if parts.size() < 2:
		return true

	var condition_type = parts[0]
	var value = parts[1]

	match condition_type:

		"quest_started":
			return QuestManager.has_quest(value)

		"quest_complete", "quest_completed":
			return QuestManager.is_complete(value)
			
		"quest_not_complete", "quest_not_completed":
			return not QuestManager.is_complete(value)

		"has_item":
			return InventoryManager.party_has_item(value)

		"missing_item":
			return not InventoryManager.party_has_item(value)
			
		"quest_ready":
			if not QuestManager.has_quest(value):
				return false
			var progress = QuestManager.get_progress(value)
			var target   = QuestManager.quest_data.get(value, {}).get("target_amount", 0)
			return progress >= target and target > 0

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
	
func show_password_prompt(password: String, success_callback: Callable, fail_callback: Callable = Callable()) -> void:
	"""Show a password input dialog for dungeon entrance or other purposes."""
	if ui == null:
		push_error("Dialogue UI not registered")
		return
	
	ui.show()
	ui.npc_name_label.text = ""
	ui.dialogue_text.text = "Enter the password:"
	ui.clear_choices()
	ui.password_input.show()
	ui.password_input.text = ""
	ui.password_input.placeholder_text = "Password"
	
	# Disconnect any existing connections
	if ui.password_input.text_submitted.is_connected(_on_password_submitted):
		ui.password_input.text_submitted.disconnect(_on_password_submitted)
	
	# Store callbacks in temporary variables for this submission
	_password_success_callback = success_callback
	_password_fail_callback = fail_callback
	_expected_password = password
	
	ui.password_input.text_submitted.connect(_on_password_submitted)
	ui.password_input.grab_focus()

func _on_password_submitted(text: String) -> void:
	"""Handle password submission for custom password prompts."""
	if text.to_lower() == _expected_password.to_lower():
		close_dialogue()
		if _password_success_callback.is_valid():
			_password_success_callback.call()
	else:
		close_dialogue()
		if _password_fail_callback.is_valid():
			_password_fail_callback.call()
	
	# Clear callbacks
	_password_success_callback = Callable()
	_password_fail_callback = Callable()
	_expected_password = ""

func close_dialogue():

	if ui:
		ui.hide()

	current_node = ""

	emit_signal("dialogue_closed")
