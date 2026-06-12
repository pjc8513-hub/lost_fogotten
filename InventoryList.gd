extends ItemList

const ITEM_TOOLTIP_SCENE := preload("res://UI/item_tooltip.tscn")

@onready var item_list = self
var item_tooltip: ItemTooltip
var hovered_item_index := -1

func _ready():
	GameEvents.inventory_changed.connect(_on_inventory_changed)
	GameEvents.selected_character_changed.connect(_on_inventory_changed)
	mouse_exited.connect(_on_mouse_exited)
	item_tooltip = ITEM_TOOLTIP_SCENE.instantiate()
	get_tree().root.add_child(item_tooltip)
	
	if PartyState.get_selected():
		set_inventory(PartyState.get_selected().inventory)

func _exit_tree() -> void:
	if is_instance_valid(item_tooltip):
		item_tooltip.queue_free()

func set_inventory(items: Array[ItemInstance]):
	item_list.clear()

	var sorted = sort_inventory(items)

	for inst in sorted:
		if inst == null or inst.item_data == null:
			continue
			
		var item = inst.item_data
		var equip_slot_string = _equip_slot_to_string(item.equip_slot)
		var inventory_name = "%s: %s" % [equip_slot_string, inst.get_display_name()]
		var idx = item_list.add_item(inventory_name, item.icon)
		item_list.set_item_tooltip_enabled(idx, false)

		if inst.is_equipped:
			item_list.set_item_custom_bg_color(idx, Color(0.5, 0.1, 0.1))

		if inst.is_marked_junk:
			item_list.set_item_custom_fg_color(idx, Color(0.5, 0.5, 0.5))

		item_list.set_item_metadata(idx, inst)

func _on_inventory_changed(character):
	_hide_item_tooltip()
	if character == PartyState.get_selected():
		set_inventory(character.inventory)

func get_sort_value(inst: ItemInstance) -> int:
	if inst == null or inst.item_data == null:
		return 999
		
	var item := inst.item_data

	# Junk always at bottom
	if inst.is_marked_junk:
		return 100

	match item.item_type:
		ItemData.ItemType.EQUIPMENT:
			return 0 if inst.is_equipped else 1
		ItemData.ItemType.CONSUMABLE:
			return 2
		ItemData.ItemType.QUEST:
			return 3
		ItemData.ItemType.JUNK:
			return 100

	return 999

func sort_inventory(items: Array[ItemInstance]) -> Array:
	var sorted = items.duplicate()

	sorted.sort_custom(func(a: ItemInstance, b: ItemInstance):
		return get_sort_value(a) < get_sort_value(b)
	)

	return sorted

func _on_item_gui_input(event):
	print("Event!")
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		print("Right")
		var idx = item_list.get_item_at_position(event.position)
		if idx == -1:
			return
		item_list.select(idx)
		var inst: ItemInstance = item_list.get_item_metadata(idx)
		$PopupMenuMain.open_for(inst, get_global_mouse_position())

func _equip_slot_to_string(equip_slot: ItemData.Equip_Slot) -> String:
		return ItemData.Equip_Slot.keys()[equip_slot].to_lower().capitalize()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_item_tooltip(event.position)
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_hide_item_tooltip()
		var idx = item_list.get_item_at_position(event.position)
		if idx == -1:
			return
		item_list.select(idx)
		var inst: ItemInstance = item_list.get_item_metadata(idx)
		$"../PopupMenuMain".open_for(inst, get_global_mouse_position())

func _update_item_tooltip(mouse_position: Vector2) -> void:
	var idx := item_list.get_item_at_position(mouse_position, true)
	if idx == hovered_item_index:
		return
	hovered_item_index = idx
	if idx < 0:
		_hide_item_tooltip()
		return
	var inst := item_list.get_item_metadata(idx) as ItemInstance
	if inst == null:
		_hide_item_tooltip()
		return
	if is_instance_valid(item_tooltip):
		item_tooltip.display_item(inst)

func _on_mouse_exited() -> void:
	_hide_item_tooltip()

func _hide_item_tooltip() -> void:
	hovered_item_index = -1
	if is_instance_valid(item_tooltip):
		item_tooltip.hide()
