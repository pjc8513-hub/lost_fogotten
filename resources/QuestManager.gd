# QuestManager.gd - autoload
extends Node

signal quest_started(quest_id)
signal quest_completed(quest_id)
signal quest_updated(quest_id)

var active_quests := {}
var completed_quests := {}

func accept_quest(quest_id: String):

	if completed_quests.has(quest_id):
		return

	if active_quests.has(quest_id):
		return

	active_quests[quest_id] = {
		"progress": 0
	}

	print("Quest accepted: ", quest_id)

	GameEvents.message_logged.emit(
		"[color=yellow]Quest Accepted:[/color] %s"
		% prettify_quest_name(quest_id)
	)

	emit_signal("quest_started", quest_id)


func complete_quest(quest_id: String):

	if not active_quests.has(quest_id):
		return

	active_quests.erase(quest_id)

	completed_quests[quest_id] = true

	print("Quest completed: ", quest_id)

	GameEvents.message_logged.emit(
		"[color=green]Quest Complete:[/color] %s"
		% prettify_quest_name(quest_id)
	)

	emit_signal("quest_completed", quest_id)


func has_quest(quest_id: String) -> bool:
	return active_quests.has(quest_id)


func is_complete(quest_id: String) -> bool:
	return completed_quests.has(quest_id)


func get_progress(quest_id: String) -> int:

	if not active_quests.has(quest_id):
		return 0

	return active_quests[quest_id].get("progress", 0)


func set_progress(quest_id: String, value: int):

	if not active_quests.has(quest_id):
		return

	active_quests[quest_id]["progress"] = value

	emit_signal("quest_updated", quest_id)


func add_progress(quest_id: String, amount := 1):

	if not active_quests.has(quest_id):
		return

	active_quests[quest_id]["progress"] += amount

	emit_signal("quest_updated", quest_id)


func prettify_quest_name(quest_id: String) -> String:
	return quest_id.replace("_", " ").capitalize()
