extends PanelContainer

# Drag your UI nodes here to create references
@onready var portrait = $HBoxContainer/PortraitOne
@onready var hp_bar: ProgressBar = $HBoxContainer/VBoxContainer/ProgressBar
@onready var mp_bar: ProgressBar = $HBoxContainer/VBoxContainer/ProgressBar2
@onready var xp_bar: ProgressBar = $HBoxContainer/VBoxContainer/ProgressBar3
@onready var label = $HBoxContainer/VBoxContainer/Label
@onready var status_icon = $HBoxContainer/StatusIcon

# combatFX layer for animation

@onready var combat_fx: Control = $HBoxContainer/PortraitOne/CombatFX
@onready var fx_sprite: Sprite2D = $HBoxContainer/PortraitOne/CombatFX/FXSprite
@onready var damage_label: Label = $HBoxContainer/PortraitOne/CombatFX/DamageLabel
@onready var animation_player: AnimationPlayer = $HBoxContainer/PortraitOne/CombatFX/AnimationPlayer


var my_member_data: ClassData
var member_index: int = -1
var normal_style: StyleBoxFlat
var selected_style: StyleBoxFlat
var _pending_member_data: ClassData
var _pending_member_index: int = -1
var _last_hp_value: int = -1
var _portrait_flash_tween: Tween = null

enum CombatStatus { IDLE, WAITING, ACTING, STUN, DONE }
var wait_texture = preload("res://assets/icons/wait.png")
var turn_texture = preload("res://assets/icons/turn.png")
var stun_texture = preload("res://assets/icons/stun.png")

func _enter_tree():
	print("[FRAME ", Engine.get_process_frames(), "] Portrait ", name, " _enter_tree")
	
func _ready():
	#print("[FRAME ", Engine.get_process_frames(), "] Portrait ", name, " _ready start member_index=", member_index, " pending_index=", _pending_member_index)
	_create_styles()
	GameEvents.selected_character_changed.connect(_on_selection_changed)
	GameEvents.combat_status_changed.connect(_on_combat_status_changed)
	if _pending_member_data:
		_apply_setup(_pending_member_data, _pending_member_index)		
	call_deferred("_update_border")
	#print("[FRAME ", Engine.get_process_frames(), "] Portrait ", name, " _ready end texture=", portrait.texture, " visible=", visible)
	#GameEvents.level_increase.connect(_on_level_increase)

func _create_styles():
	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.1, 0.1, 0.1, 1)
	normal_style.border_width_left = 0
	normal_style.border_width_right = 0
	normal_style.border_width_top = 0
	normal_style.border_width_bottom = 0
	
	selected_style = normal_style.duplicate()
	selected_style.border_width_left = 3
	selected_style.border_width_right = 3
	selected_style.border_width_top = 3
	selected_style.border_width_bottom = 3
	selected_style.border_color = Color("FFD700") # gold

# This function takes a .tres file and fills the UI
func setup(data: ClassData, index: int): # We leave 'data' untyped here too just to be safe
	#print("[FRAME ", Engine.get_process_frames(), "] Portrait ", name, " setup called index=", index, " node_ready=", is_node_ready(), " data=", data)
	_pending_member_data = data
	_pending_member_index = index
	if is_node_ready():
		_apply_setup(data, index)

func _apply_setup(data: ClassData, index: int) -> void:
	if not data:
		return

	#print("[FRAME ", Engine.get_process_frames(), "] Portrait ", name, " _apply_setup index=", index, " member=", data.member_name, " texture=", data.sprite_texture)
	member_index = index
	# Use the variable names from your ClassData.gd
	portrait.texture = null
	portrait.texture = data.sprite_texture
	portrait.queue_redraw()
	hp_bar.max_value = data.get_max_hp()
	hp_bar.value = data.current_hp
	mp_bar.max_value = data.get_max_mp()
	mp_bar.value = data.current_mp
	xp_bar.value = data.xp
	label.text = data.member_name

	my_member_data = data
	_last_hp_value = data.current_hp
	# Listen for any stat changes globally
	if !GameEvents.party_member_stats_changed.is_connected(_on_stats_changed):
		GameEvents.party_member_stats_changed.connect(_on_stats_changed)

	update_ui()
	call_deferred("_update_border")
	#print("[FRAME ", Engine.get_process_frames(), "] Portrait ", name, " _apply_setup done texture=", portrait.texture)
	call_deferred("show")

func _on_stats_changed(updated_data: ClassData):
	# Check: Is the person who changed actually ME?
	if updated_data == my_member_data:
		update_ui()

func update_ui():
	var previous_hp := _last_hp_value
	# Use Tween for a smooth sliding animation instead of a sudden jump
	hp_bar.max_value = my_member_data.get_max_hp()
	mp_bar.max_value = my_member_data.get_max_mp()
	xp_bar.max_value = my_member_data.xp_to_next_level
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", my_member_data.current_hp, 0.2)
	#print(my_member_data.class_name, " max mp: ", my_member_data.max_mp)
	#print(my_member_data.class_name, " current mp: ", my_member_data.current_mp)
	#print(my_member_data.class_name, " max hp: ", my_member_data.max_hp)
	#print(my_member_data.class_name, " current hp: ", my_member_data.current_hp)
	mp_bar.value = my_member_data.current_mp
	xp_bar.value = my_member_data.xp
	if previous_hp >= 0 and my_member_data.current_hp < previous_hp:
		_flash_portrait_on_damage()
	_last_hp_value = my_member_data.current_hp
	if my_member_data.current_hp <=0:
		portrait.texture = preload("res://assets/portraits/dead_p.png")
	else:
		portrait.texture = my_member_data.sprite_texture
	_sync_status_overlay()

func _sync_status_overlay() -> void:
	if combat_fx != null and combat_fx.has_method("set_statuses"):
		combat_fx.call("set_statuses", my_member_data.status_effects)

func _flash_portrait_on_damage() -> void:
	if portrait == null:
		return
	if _portrait_flash_tween:
		_portrait_flash_tween.kill()
	portrait.modulate = Color(2.0, 0.6, 0.6, 1.0)
	_portrait_flash_tween = create_tween()
	_portrait_flash_tween.tween_property(portrait, "modulate", Color(1, 1, 1, 1), 0.18)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
func _on_selection_changed(_character: ClassData):
	_update_border()

func _update_border():
	#print("[FRAME ", Engine.get_process_frames(), "] Portrait ", name, " _update_border selected_index=", PartyState.selected_index, " member_index=", member_index)
	if PartyState.selected_index == member_index:
		add_theme_stylebox_override("panel", selected_style)
	else:
		add_theme_stylebox_override("panel", normal_style)

func _on_combat_status_changed(updated_data: ClassData, new_status: int):
	if updated_data == my_member_data:
		update_status_icon(new_status)

func update_status_icon(status: CombatStatus):
	match status:
		CombatStatus.IDLE, CombatStatus.DONE:
			status_icon.texture = null
		CombatStatus.WAITING:
			status_icon.texture = wait_texture
		CombatStatus.ACTING:
			status_icon.texture = turn_texture
		CombatStatus.STUN:
			status_icon.texture = stun_texture

func play_combat_fx(animation_name: String) -> void:
	if animation_player == null or not animation_player.has_animation(animation_name):
		push_warning("Party member combat FX animation not found: %s" % animation_name)
		return

	var combat_fx := animation_player.get_parent() as Control
	if combat_fx != null:
		combat_fx.show()
	fx_sprite.show()
	animation_player.stop()
	animation_player.play(animation_name)
	await animation_player.animation_finished
	fx_sprite.hide()
	if combat_fx != null:
		if combat_fx.has_method("_refresh_visibility"):
			combat_fx.call("_refresh_visibility")
		else:
			combat_fx.hide()


func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if my_member_data == null:
		return

	if SpellExecutor.try_target_party_member(my_member_data):
		accept_event()
		return

	if PartyState.select_member(member_index):
		accept_event()
		return

	if CombatState.is_in_combat():
		var acting_member := CombatState.get_acting_member()
		if acting_member != null:
			GameEvents.message_logged.emit("[color=gray]You cannot change characters during combat. It is %s's turn.[/color]" % acting_member.member_name)
		else:
			GameEvents.message_logged.emit("[color=gray]You cannot change characters during combat.[/color]")
	accept_event()
