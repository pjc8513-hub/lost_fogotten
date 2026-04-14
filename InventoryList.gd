extends ItemList

@onready var item_list = self

func _ready():
	GameEvents.inventory_changed.connect(_on_inventory_changed)
	GameEvents.selected_character_changed.connect(_on_inventory_changed)

func set_inventory(items: Array[ItemInstance]):
	item_list.clear()

	var sorted = sort_inventory(items)

	for inst in sorted:
		var item = inst.item_data

		var idx = item_list.add_item(item.name, item.icon)

		if inst.is_equipped:
			item_list.set_item_custom_bg_color(idx, Color(0.5, 0.1, 0.1))

		if inst.is_marked_junk:
			item_list.set_item_custom_fg_color(idx, Color(0.5, 0.5, 0.5))

		item_list.set_item_metadata(idx, inst)

func _on_inventory_changed(character):
	if character == PartyState.get_selected():
		set_inventory(character.inventory)

func get_sort_value(inst: ItemInstance) -> int:
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
