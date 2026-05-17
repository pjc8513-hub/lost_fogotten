# InventoryManager.gd

extends Node

func add_item(character, item_instance: ItemInstance) -> bool:

	if character == null:
		return false

	if item_instance == null:
		return false

	character.inventory.append(item_instance)

	GameEvents.inventory_changed.emit(character)

	return true


func remove_item(character, item_instance: ItemInstance) -> bool:

	if character == null:
		return false

	if item_instance == null:
		return false

	if not character.inventory.has(item_instance):
		return false

	character.inventory.erase(item_instance)

	GameEvents.inventory_changed.emit(character)

	return true


func has_item(character, item_id: String) -> bool:

	if character == null:
		return false

	for inst in character.inventory:

		if inst == null:
			continue

		if inst.item_data == null:
			continue

		if inst.item_data.id == item_id:
			return true

	return false

func party_has_item(item_id: String) -> bool:

	for member in PartyState.active_party:

		if member == null:
			continue

		if has_item(member, item_id):
			return true

	return false

func get_item_count(character, item_id: String) -> int:

	if character == null:
		return 0

	var count := 0

	for inst in character.inventory:

		if inst == null:
			continue

		if inst.item_data == null:
			continue

		if inst.item_data.id == item_id:
			count += 1

	return count


func equip_item(character, item_instance: ItemInstance):

	if character == null:
		return

	if item_instance == null:
		return

	if item_instance.item_data == null:
		return

	var slot = item_instance.item_data.equip_slot

	# Unequip existing
	for inst in character.inventory:

		if inst == null:
			continue

		if inst.item_data == null:
			continue

		if inst.item_data.equip_slot == slot:
			inst.is_equipped = false

	item_instance.is_equipped = true

	GameEvents.inventory_changed.emit(character)


func unequip_item(character, item_instance: ItemInstance):

	if character == null:
		return

	if item_instance == null:
		return

	item_instance.is_equipped = false

	GameEvents.inventory_changed.emit(character)


func mark_as_junk(character, item_instance: ItemInstance, junk := true):

	if character == null:
		return

	if item_instance == null:
		return

	item_instance.is_marked_junk = junk

	GameEvents.inventory_changed.emit(character)
