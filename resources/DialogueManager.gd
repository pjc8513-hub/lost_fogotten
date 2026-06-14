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
			ShopManager.open_shop(action_dict.get("shop_id", ""))

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


# ==============================================================================
# DEBUG / TESTING COMMAND PIPELINE
# TO REMOVE: Delete everything below this line, and remove show_command_prompt()
# and _on_command_submitted() references in this file.
# ==============================================================================

func show_command_prompt() -> void:
	"""Show a command prompt using the password input UI."""
	if ui == null:
		push_error("Dialogue UI not registered")
		return
	
	ui.show()
	ui.npc_name_label.text = "[DEBUG CONSOLE]"
	ui.dialogue_text.text = "Enter Cheat / Test Command:"
	ui.clear_choices()
	ui.password_input.show()
	ui.password_input.text = ""
	ui.password_input.placeholder_text = "e.g., LOADMAP BonePit, GIVEGOLD 100"
	
	# Disconnect any existing connections
	if ui.password_input.text_submitted.is_connected(_on_password_submitted):
		ui.password_input.text_submitted.disconnect(_on_password_submitted)
	if ui.password_input.text_submitted.is_connected(_on_command_submitted):
		ui.password_input.text_submitted.disconnect(_on_command_submitted)
	
	ui.password_input.text_submitted.connect(_on_command_submitted)
	ui.password_input.grab_focus()

func _on_command_submitted(text: String) -> void:
	"""Handle submission of debug console commands."""
	close_dialogue()
	if ui.password_input.text_submitted.is_connected(_on_command_submitted):
		ui.password_input.text_submitted.disconnect(_on_command_submitted)
	
	await execute_debug_command(text)

func execute_debug_command(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
		
	var parts := trimmed.split(" ", false)
	if parts.is_empty():
		return
		
	var cmd_name := parts[0].to_lower()
	var args := parts.slice(1)
	var full_arg_string := " ".join(args)
	
	match cmd_name:
		"loadmap":
			if args.is_empty():
				GameEvents.message_logged.emit("[color=red]Usage: LOADMAP [MapName/Path][/color]")
				return
			_execute_loadmap(full_arg_string)
			
		"giveskill":
			if args.is_empty():
				GameEvents.message_logged.emit("[color=red]Usage: GIVESKILL [SkillID][/color]")
				return
			
			var skill_id := full_arg_string
			var skill_data: SkillData = null
			for s in SkillRegistry._all_skills:
				if s.skill_id.to_lower() == skill_id.to_lower() or s.display_name.to_lower() == skill_id.to_lower():
					skill_data = s
					break
					
			if skill_data == null:
				GameEvents.message_logged.emit("[color=red]Skill not found: %s[/color]" % skill_id)
				return
				
			var target_member = PartyState.get_selected()
			if target_member == null:
				target_member = PartyState.active_party[0] if not PartyState.active_party.is_empty() else null
				
			if target_member == null:
				GameEvents.message_logged.emit("[color=red]No active party members to learn skill.[/color]")
				return
				
			if target_member.learned_skills.has(skill_data.skill_id):
				GameEvents.message_logged.emit("[color=yellow]%s[/color] already knows [color=cyan]%s[/color]" % [target_member.member_name, skill_data.display_name])
				return
				
			target_member.learned_skills[skill_data.skill_id] = 1
			target_member.recalculate_derived_stats(false)
			GameEvents.party_member_stats_changed.emit(target_member)
			GameEvents.message_logged.emit("[color=magenta][Cheat][/color] [color=yellow]%s[/color] learned skill: [color=cyan]%s[/color]" % [target_member.member_name, skill_data.display_name])
			
		"giveitem":
			if args.is_empty():
				GameEvents.message_logged.emit("[color=red]Usage: GIVEITEM [ItemID] [Amount][/color]")
				return
			
			var item_id := args[0]
			var amount := 1
			if args.size() > 1:
				amount = int(args[1])
				if amount <= 0:
					amount = 1
					
			var target_member = PartyState.get_selected()
			if target_member == null:
				target_member = PartyState.active_party[0] if not PartyState.active_party.is_empty() else null
				
			if target_member == null:
				GameEvents.message_logged.emit("[color=red]No active party members to give item.[/color]")
				return
				
			var item_instance = LootManager.create_item_instance(item_id)
			if item_instance == null:
				var potential_id := " ".join(args)
				if args.size() > 1:
					potential_id = " ".join(args.slice(0, args.size() - 1))
				item_instance = LootManager.create_item_instance(potential_id)
				
			if item_instance == null:
				GameEvents.message_logged.emit("[color=red]Item not found: %s[/color]" % item_id)
				return
				
			var success := false
			for i in range(amount):
				var inst = item_instance if i == 0 else LootManager.create_item_instance(item_instance.item_data.item_id)
				if inst:
					if InventoryManager.add_item(target_member, inst):
						success = true
						
			if success:
				GameEvents.message_logged.emit("[color=magenta][Cheat][/color] Gave [color=yellow]%s[/color] x%d to [color=cyan]%s[/color]" % [item_instance.item_data.name, amount, target_member.member_name])
				
		"givegold":
			if args.is_empty():
				GameEvents.message_logged.emit("[color=red]Usage: GIVEGOLD [Amount][/color]")
				return
			var amount := int(args[0])
			PartyState.add_gold(amount)
			GameEvents.message_logged.emit("[color=magenta][Cheat][/color] Added [color=gold]%d gold[/color]. Total: [color=gold]%d[/color]" % [amount, PartyState.party_gold])
			
		"givetorch":
			PartyState.party_torches += 1
			GameEvents.message_logged.emit("[color=magenta][Cheat][/color] Received: Torch. Total torches: [color=cyan]%d[/color]" % PartyState.party_torches)
			
		"castspell":
			if args.is_empty():
				GameEvents.message_logged.emit("[color=red]Usage: CASTSPELL [SpellID][/color]")
				return
			
			var spell := SpellRegistry.find_by_id(full_arg_string)
			if spell == null:
				GameEvents.message_logged.emit("[color=red]Spell not found: %s[/color]" % full_arg_string)
				return
				
			var caster = PartyState.get_selected()
			if caster == null:
				caster = PartyState.active_party[0] if not PartyState.active_party.is_empty() else null
				
			if caster == null:
				GameEvents.message_logged.emit("[color=red]No active party members to cast the spell.[/color]")
				return
				
			var request := SpellExecutor.build_request(spell, caster)
			if not request.is_valid:
				GameEvents.message_logged.emit("[color=red]%s[/color]" % request.get_primary_error())
				return

			GameEvents.message_logged.emit("[color=magenta][Cheat][/color] Casting [color=gold]%s[/color]..." % spell.get_display_name())
			var party_target: ClassData = caster if spell.requires_individual_party_target() else null
			await SpellExecutor.execute_request(request, CombatState.targeted_enemy, party_target)
			
		_:
			GameEvents.message_logged.emit("[color=red]Unknown debug command: %s[/color]" % cmd_name)

func _execute_loadmap(map_path: String) -> void:
	var path := ""
	if map_path.begins_with("res://"):
		path = map_path
	else:
		path = _find_file_recursively("res://data/maps", map_path)
		if path.is_empty():
			path = _find_file_recursively("res://data", map_path)
			
	if path.is_empty() or not ResourceLoader.exists(path):
		GameEvents.message_logged.emit("[color=red]Map resource not found: %s[/color]" % map_path)
		return
		
	var dungeon_data = load(path) as DungeonData
	if dungeon_data == null:
		GameEvents.message_logged.emit("[color=red]Failed to load DungeonData from: %s[/color]" % path)
		return
		
	GameEvents.message_logged.emit("[color=magenta][Cheat][/color] Loading map: %s..." % dungeon_data.DungeonName)
	World.set_current_dungeon(dungeon_data)
	SceneManager.change_scene("res://Main.tscn")

func _find_file_recursively(dir_path: String, target_filename: String) -> String:
	var target := target_filename
	if not target.contains("."):
		target += ".tres"
		
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return ""
		
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				var found_path := _find_file_recursively(dir_path.path_join(file_name), target_filename)
				if not found_path.is_empty():
					dir.list_dir_end()
					return found_path
		else:
			if file_name.to_lower() == target.to_lower() or file_name.get_basename().to_lower() == target_filename.to_lower():
				var full_path := dir_path.path_join(file_name)
				dir.list_dir_end()
				return full_path
		file_name = dir.get_next()
	dir.list_dir_end()
	return ""
