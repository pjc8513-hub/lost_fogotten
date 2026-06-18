extends Control

@onready var enemy_name_label: Label = $PanelContainer/VBoxContainer/EnemyNameLabel
@onready var progress_bar: ProgressBar = $PanelContainer/VBoxContainer/EnemyHPBar
@onready var status_label: Label = $PanelContainer/VBoxContainer/StatusLabel

var current_enemy: Enemy = null
var tween: Tween = null

func _ready() -> void:
	# Listen for damage updates so the HP bar stays in sync.
	if not GameEvents.is_connected("enemy_took_damage", Callable(self, "_on_enemy_took_damage")):
		GameEvents.connect("enemy_took_damage", Callable(self, "_on_enemy_took_damage"))
	if not GameEvents.is_connected("enemy_status_changed", Callable(self, "_on_enemy_status_changed")):
		GameEvents.connect("enemy_status_changed", Callable(self, "_on_enemy_status_changed"))

	# Listen for selection changes from the world state.
	if not World.is_connected("selected_enemy_changed", Callable(self, "_on_selected_enemy_changed")):
		World.connect("selected_enemy_changed", Callable(self, "_on_selected_enemy_changed"))
	
	# Start with card hidden
	visible = false

	if World.selected_enemy != null:
		set_enemy(World.selected_enemy)

func set_enemy(enemy: Enemy = null) -> void:
	# Disconnect from previous enemy if any
	if current_enemy != null:
		if current_enemy.is_connected("selected", Callable(self, "_on_enemy_selected")):
			current_enemy.disconnect("selected", Callable(self, "_on_enemy_selected"))
	
	current_enemy = enemy
	
	if current_enemy == null:
		visible = false
		return
	
	# Connect to this enemy's signals
	if not current_enemy.is_connected("selected", Callable(self, "_on_enemy_selected")):
		current_enemy.connect("selected", Callable(self, "_on_enemy_selected"))
	
	# Update card display
	_update_card_display()
	visible = true

func _update_card_display() -> void:
	if current_enemy == null or current_enemy.enemy_data == null:
		return
	
	enemy_name_label.text = current_enemy.enemy_data.enemy_name
	var max_hp = max(1, current_enemy.max_hp)
	var current_hp = current_enemy.enemy_data.hp
	
	progress_bar.max_value = max_hp
	progress_bar.value = current_hp
	status_label.text = _format_statuses(current_enemy.enemy_data.status_effects)
	status_label.visible = not status_label.text.is_empty()

func _format_statuses(status_effects: Array[String]) -> String:
	if status_effects.is_empty():
		return ""
	var statuses: Array[String] = []
	for status_name in status_effects:
		var status_type := StatusEffects.from_string(status_name)
		if status_type != StatusEffects.Type.NONE:
			statuses.append(StatusEffects.get_display_name(status_type))
		else:
			statuses.append(status_name.capitalize())
	return "Status: %s" % ", ".join(statuses)

func _on_selected_enemy_changed(enemy) -> void:
	set_enemy(enemy)

func _on_enemy_selected(enemy: Enemy) -> void:
	if enemy != current_enemy:
		set_enemy(enemy)

func _on_enemy_status_changed(enemy_data: EnemyData) -> void:
	if current_enemy == null or current_enemy.enemy_data != enemy_data:
		return
	_update_card_display()

func _on_enemy_took_damage(enemy: Enemy, damage: int) -> void:
	if enemy != current_enemy or current_enemy == null:
		return
	
	# Kill existing tween if any
	if tween:
		tween.kill()
	
	# Tween the HP bar from old value to new value over 0.3 seconds
	var new_hp = current_enemy.enemy_data.hp
	
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(progress_bar, "value", new_hp, 0.3)
	
	if new_hp <= 0:
		tween.finished.connect(Callable(self, "_hide_if_current_enemy_dead"), CONNECT_ONE_SHOT)

func _hide_if_current_enemy_dead() -> void:
	if current_enemy == null or not is_instance_valid(current_enemy) or current_enemy.enemy_data.hp <= 0:
		set_enemy()
