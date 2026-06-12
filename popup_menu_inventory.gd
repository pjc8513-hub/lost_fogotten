extends PopupMenu

# The ItemInstance the player right-clicked on
var _context_inst: ItemInstance = null

# We keep a reference to the submenu node so we can populate it each time.
# Add a child PopupMenu named "TradeMenu" in the scene tree under this node.
@onready var trade_menu: PopupMenu = $TradeMenu

func _ready():
	# Connect our own id_pressed signal
	id_pressed.connect(_on_id_pressed)
	trade_menu.id_pressed.connect(_on_trade_id_pressed)

# ─────────────────────────────────────────────
#  Public API – called by InventoryList
# ─────────────────────────────────────────────

## Call this from InventoryList when the player right-clicks an item.
## `inst`  – the ItemInstance stored as item metadata
## `pos`   – global mouse position for placement
func open_for(inst: ItemInstance, pos: Vector2) -> void:
	_context_inst = inst
	_build_context_menu(inst)
	position = pos
	popup()

# ─────────────────────────────────────────────
#  Menu building
# ─────────────────────────────────────────────

enum Action {
	EQUIP_TOGGLE  = 0,
	USE           = 1,
	MARK_JUNK     = 2,
	DISCARD       = 3,
}

func _build_context_menu(inst: ItemInstance) -> void:
	clear()

	var item := inst.item_data

	# EQUIPMENT – equip / unequip
	if item.item_type == ItemData.ItemType.EQUIPMENT:
		if inst.is_equipped:
			add_item("Unequip", Action.EQUIP_TOGGLE)
		else:
			var owner_char = PartyState.get_selected()
			if owner_char != null and owner_char.can_equip_item(item) and not owner_char.is_slot_equipped(item.equip_slot):
				add_item("Equip", Action.EQUIP_TOGGLE)

	# CONSUMABLE – use
	if item.item_type == ItemData.ItemType.CONSUMABLE:
		add_item("Use", Action.USE)

	# ── PROTECTION GATE ──────────────────────────────────────────
	# Only show Transfer, Junk, and Discard if the item is NOT equipped
	# ─────────────────────────────────────────────────────────────
	if not inst.is_equipped:
		# TRANSFER
		_build_trade_menu()
		if trade_menu.item_count > 0:
			add_submenu_item("Transfer to…", "TradeMenu")

		# JUNK / DISCARD (Only for non-quest items)
		if item.item_type != ItemData.ItemType.QUEST:
			if inst.is_marked_junk:
				add_item("Unmark Junk", Action.MARK_JUNK)
			else:
				add_item("Mark as Junk", Action.MARK_JUNK)

			add_item("Discard", Action.DISCARD)

func _build_trade_menu() -> void:
	trade_menu.clear()
	var selected := PartyState.get_selected()

	for i in PartyState.active_party.size():
		var member: ClassData = PartyState.active_party[i]
		# Don't offer a transfer to the character who already owns it
		if member == selected:
			continue
		trade_menu.add_item(member.member_name, i)

# ─────────────────────────────────────────────
#  Signal handlers
# ─────────────────────────────────────────────

func _on_id_pressed(id: int) -> void:
	if _context_inst == null:
		return

	match id:
		Action.EQUIP_TOGGLE:
			_toggle_equip(_context_inst)
		Action.USE:
			_use_item(_context_inst)
		Action.MARK_JUNK:
			_toggle_junk(_context_inst)
		Action.DISCARD:
			_discard_item(_context_inst)

func _on_trade_id_pressed(party_index: int) -> void:
	if _context_inst == null:
		return
	var target: ClassData = PartyState.active_party[party_index]
	_transfer_item(_context_inst, target)

# ─────────────────────────────────────────────
#  Actions
# ─────────────────────────────────────────────

func _toggle_equip(inst: ItemInstance) -> void:
	var owner_char := PartyState.get_selected()
	if owner_char == null:
		return
	if not inst.is_equipped and not owner_char.can_equip_item(inst.item_data):
		push_warning("%s cannot equip %s." % [owner_char.member_name, inst.item_data.name])
		return

	var was_equipped := inst.is_equipped
	if was_equipped:
		InventoryManager.unequip_item(owner_char, inst)
	else:
		InventoryManager.equip_item(owner_char, inst)

	# Notify if a guitar was unequipped
	if was_equipped and inst.item_data.equip_slot == ItemData.Equip_Slot.GUITAR:
		GameEvents.message_logged.emit("[color=gray]%s unequipped %s.[/color]" % [owner_char.member_name, inst.item_data.name])

func _use_item(inst: ItemInstance) -> void:
	var owner_char := PartyState.get_selected()
	if owner_char == null:
		return

	# ── Apply consumable effect here ──────────────────────────────────────
	if inst.item_data is ConsumableData:
		(inst.item_data as ConsumableData).apply_to_character(owner_char)

	# Remove one instance of the item after use
	owner_char.inventory.erase(inst)
	GameEvents.inventory_changed.emit(owner_char)
	GameEvents.party_member_stats_changed.emit(owner_char)

func _toggle_junk(inst: ItemInstance) -> void:
	var owner_char := PartyState.get_selected()
	if owner_char == null:
		return

	inst.is_marked_junk = not inst.is_marked_junk
	GameEvents.inventory_changed.emit(owner_char)

func _discard_item(inst: ItemInstance) -> void:
	var owner_char := PartyState.get_selected()
	if owner_char == null:
		return

	# Cannot discard an equipped item directly – unequip first
	if inst.is_equipped:
		push_warning("PopupMenuInventory: tried to discard an equipped item. Unequip first.")
		return

	owner_char.inventory.erase(inst)
	GameEvents.inventory_changed.emit(owner_char)

func _transfer_item(inst: ItemInstance, target: ClassData) -> void:
	var source := PartyState.get_selected()
	if source == null or target == null or source == target:
		return

	# Equipped items travel with a character; unequip before transferring
	if inst.is_equipped:
		InventoryManager.unequip_item(source, inst)
	inst.is_marked_junk = false  # reset junk flag on transfer (optional, remove if unwanted)

	source.inventory.erase(inst)
	target.inventory.append(inst)

	GameEvents.inventory_changed.emit(source)
	GameEvents.inventory_changed.emit(target)
