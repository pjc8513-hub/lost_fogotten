# Questsview.gd
extends Control

@onready var quest_display: RichTextLabel = $ScrollContainer/quest_display

func _ready() -> void:
	# Connect to QuestManager signals to automatically refresh the view
	QuestManager.quest_started.connect(_on_quests_changed)
	QuestManager.quest_completed.connect(_on_quests_changed)
	QuestManager.quest_updated.connect(_on_quests_changed)
	
	# Initial draw check
	update_quest_log()


func _on_quests_changed(_quest_id: String) -> void:
	update_quest_log()


func update_quest_log() -> void:
	quest_display.clear()
	
	if QuestManager.active_quests.is_empty():
		quest_display.append_text("[center][color=gray]No active quests.[/color][/center]")
		return
		
	var full_text = ""
	
	for quest_id in QuestManager.active_quests:
		# Safeguard if the quest isn't defined in our static database yet
		if not QuestManager.quest_data.has(quest_id):
			continue
			
		var data = QuestManager.quest_data[quest_id]
		var current_progress = QuestManager.get_progress(quest_id)
		
		# Build the string layout using BBCode formatting
		full_text += "[b]Quest name: %s[/b]\n" % data["name"]
		full_text += "-Objective: %s\n" % data["objective"]
		full_text += "-Turn in area: %s\n" % data["area"]
		
		# Conditional progress format based on whether it's a collection or state quest
		if data["target_amount"] > 0:
			full_text += "-%s: %d/%d\n" % [data["name"], current_progress, int(data["target_amount"])]
		else:
			full_text += "-In Progress\n"
			
		full_text += "-Description: %s\n" % data["description"]
		full_text += "\n" # Spacing between quests
		
	quest_display.append_text(full_text)
