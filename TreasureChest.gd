# TreasureChest.gd
extends Node3D
class_name TreasureChest

signal chest_opened(chest: TreasureChest, gold: int, loot: Array)
signal chest_trap_triggered(chest: TreasureChest, damage: int)
signal selected(chest: TreasureChest)
signal open_animation_completed

@onready var sprite: Sprite3D = $Sprite3D
@onready var area: Area3D = $Area3D

@export var treasure_data: TreasureData:
	set(value):
		treasure_data = value
		if is_inside_tree() and sprite:
			_apply_treasure_data()
			
var grid_position: Vector2i
var is_opened: bool = false
var is_disarmed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame  # same trick as Enemy to wait for world
	
	area.input_ray_pickable = true
	add_to_group("treasure_chests")
	
	if treasure_data and sprite:
		_apply_treasure_data()
	
	World.register_treasure_chest(self)  # assuming you have this in World.gd
	pass # Replace with function body.

func _apply_treasure_data() -> void:
	if not treasure_data:
		print("ERROR: _apply_treasure_data called without valid treasure_data.")
		return
	if not sprite:
		push_error("Sprite3D node not found for chest! Cannot apply data.")
		return
		
	if treasure_data.sprite_texture:
		sprite.texture = treasure_data.sprite_texture
	else:
		print("WARNING: Chest has no sprite texture assigned")
		
	sprite.scale = treasure_data.custom_scale
	sprite.position = treasure_data.custom_position
	print(treasure_data.chest_name, " spawned: tier ", treasure_data.tier)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_opened:
			GameEvents.message_logged.emit("[color=gray]This chest is empty.[/color]")
			return
		var name_str = TreasureData.Chest_Name.keys()[treasure_data.chest_name]
		print("Chest clicked:", name_str)
		selected.emit(self)
		var msg := "[color=yellow]Inspecting %s[/color]" % name_str
		GameEvents.message_logged.emit(msg)
		World.set_selected_chest(self)  # similar to set_selected_enemy

# Call these from your UI/Player skill check system
func attempt_disarm(player_skill_bonus: int) -> bool:
	if not treasure_data.is_trapped or is_disarmed:
		return true
		
	var roll = randi_range(1, 20) + player_skill_bonus
	var success = roll >= treasure_data.trap_disarm_dc
	
	if success:
		is_disarmed = true
		GameEvents.message_logged.emit("[color=green]Trap disarmed! Rolled %d vs DC %d[/color]" % [roll, treasure_data.trap_disarm_dc])
	else:
		_trigger_trap()
		GameEvents.message_logged.emit("[color=red]Failed to disarm! Rolled %d vs DC %d[/color]" % [roll, treasure_data.trap_disarm_dc])
	return success

func attempt_unlock(player_skill_bonus: int = 0) -> bool:
	if is_opened:
		return false
		
	var roll = randi_range(1, 20) + player_skill_bonus
	var success = roll >= treasure_data.lock_dc
	
	if success:
		GameEvents.message_logged.emit("[color=green]Unlocked! Rolled %d vs DC %d[/color]" % [roll, treasure_data.lock_dc])
	else:
		GameEvents.message_logged.emit("[color=red]Failed to pick lock. Rolled %d vs DC %d[/color]" % [roll, treasure_data.lock_dc])
		# If not disarmed and it fails, trigger trap
		if treasure_data.is_trapped and not is_disarmed:
			_trigger_trap()
	return success

func _trigger_trap():
	var damage = 0
	for i in treasure_data.trap_damage_num_dice:
		damage += randi_range(1, treasure_data.trap_damage_die)
	
	GameEvents.message_logged.emit("[color=red]Trap triggered! Took %d damage![/color]" % damage)
	chest_trap_triggered.emit(self, damage)
	# Player.take_damage(damage) - call this however your player handles it

func open_chest():
	if is_opened:
		return
	is_opened = true
	
	var gold_roll = randi_range(1, treasure_data.gold_die)
	var gold_total = gold_roll * treasure_data.gold_multiplier
	
	# New: roll all tables in the array
	var loot_ids = LootManager.roll_loot(treasure_data.loot_table, 0) # pass player luck later
	
	GameEvents.message_logged.emit("[color=gold]Found %d gold![/color]" % gold_total)
	if loot_ids.size() > 0:
		var loot_names = loot_ids.map(func(id): return id.replace("_", " ").capitalize())
		GameEvents.message_logged.emit("[color=cyan]Found: %s[/color]" % ", ".join(loot_names))
	
	# Emit local signal for direct connections to this chest
	chest_opened.emit(self, gold_total, loot_ids)
	# Emit global signal for LootDistributor and other systems
	GameEvents.chest_opened.emit(self, gold_total, loot_ids)
	
	sprite.modulate = Color.DARK_GRAY

func play_open_animation() -> void:
	var anim_player = get_node_or_null("Sprite3D/AnimationPlayer")

	if anim_player and anim_player is AnimationPlayer:
		if anim_player.has_animation("open_chest"):
			anim_player.play("open_chest")
		else:
			call_deferred("_emit_open_animation_completed")
	else:
		call_deferred("_emit_open_animation_completed")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"open_chest":
		open_animation_completed.emit()

func _emit_open_animation_completed() -> void:
	open_animation_completed.emit()
