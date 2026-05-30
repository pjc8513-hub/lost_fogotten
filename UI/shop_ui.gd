extends Control

# UI Elements from your original code
@onready var shop_name_label: Label = $VBoxContainer/HBoxContainer2/ShopName
@onready var player_label: Label = $VBoxContainer/HBoxContainer2/PlayerLabel
@onready var store_inventory: ItemList = $VBoxContainer/HBoxContainer/ScrollContainer/StoreInventory
@onready var character_inventory: ItemList = $VBoxContainer/HBoxContainer/ScrollContainer2/CharacterInventory
@onready var description: Label = $VBoxContainer/Description
@onready var amount: Label = $VBoxContainer/Amount
@onready var close_button: Button = $VBoxContainer/CloseButton


# The active shop component injected at runtime
var current_shop_component: ShopComponent = null
var current_shop_data: ShopData = null
# Track who the active customer is (useful for multi-character parties)
var active_buyer = null

func _ready() -> void:
	# Hide on start
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	if not ShopManager.shop_opened.is_connected(_on_shop_manager_opened):
		ShopManager.shop_opened.connect(_on_shop_manager_opened)
	if not ShopManager.shop_closed.is_connected(close_shop):
		ShopManager.shop_closed.connect(close_shop)
	
	# Connect UI item clicks to our internal click handlers
	store_inventory.item_selected.connect(_on_store_item_selected)
	store_inventory.item_activated.connect(_on_store_item_double_clicked)
	
	character_inventory.item_selected.connect(_on_character_item_selected)
	character_inventory.item_activated.connect(_on_character_item_double_clicked)


func _on_shop_manager_opened(shop_id: String) -> void:
	var shop_data := ShopDatabase.get_shop(shop_id)
	if shop_data == null:
		return

	current_shop_component = null
	current_shop_data = shop_data
	active_buyer = PartyState.get_selected()

	visible = true
	move_to_front()
	refresh_ui("")


# 1. TIE IT TOGETHER: The opening method called by your game world
func open_shop(shop_component: ShopComponent, buyer):
	current_shop_component = shop_component
	current_shop_data = null
	active_buyer = buyer
	
	# Listen for successful trades so the UI automatically redraws
	if not current_shop_component.transaction.transaction_succeeded.is_connected(refresh_ui):
		current_shop_component.transaction.transaction_succeeded.connect(refresh_ui)
	
	visible = true
	move_to_front()
	refresh_ui("")


func close_shop():
	if current_shop_component and current_shop_component.transaction.transaction_succeeded.is_connected(refresh_ui):
		# Always clean up dynamic signal connections when closing
		current_shop_component.transaction.transaction_succeeded.disconnect(refresh_ui)
	
	current_shop_component = null
	current_shop_data = null
	active_buyer = null
	visible = false


# 2. REFRESH: Redraw lists based on components and global data state
func refresh_ui(_msg: String = "") -> void:
	if _get_shop_name() == "":
		return
		
	# Update top labels
	shop_name_label.text = _get_shop_name()
	amount.text = "Gold: %d" % PartyState.party_gold
	
	# Clear old list entries
	store_inventory.clear()
	character_inventory.clear()
	
	# Populate Store Inventory using data component methods
	var markup = _get_buy_markup()
	for item_id in _get_shop_items():
		var item_data = ItemData.get_item(item_id)
		if item_data:
			var final_price = int(item_data.value * markup)
			var text = "%s (%d G)" % [item_data.name, final_price]
			
			var index = store_inventory.add_item(text)
			# Store the item_id inside the list item's metadata slot so we can grab it on click
			store_inventory.set_item_metadata(index, item_id)
			
	# Populate Character Inventory
	# (Assumes InventoryManager.get_items(active_buyer) returns an array of ItemInstances)
	var player_items = InventoryManager.get_items(active_buyer)
	var sell_ratio = _get_sell_ratio()
	
	for item_instance in player_items:
		var item_data = item_instance.item_data
		var sell_price = int(item_data.value * sell_ratio)
		var text = "%s [%d G]" % [item_data.name, sell_price]
		
		var index = character_inventory.add_item(text)
		# Store the literal ItemInstance reference so we know exactly which one to sell
		character_inventory.set_item_metadata(index, item_instance)


# 3. INTERACTION: Respond to selections and double clicks
func _on_store_item_selected(index: int) -> void:
	var item_id = store_inventory.get_item_metadata(index)
	var item_data = ItemData.get_item(item_id)
	if item_data:
		var markup = _get_buy_markup()
		description.text = "%s\nCost: %d Gold\n%s" % [item_data.name, int(item_data.value * markup), item_data.description]

func _on_store_item_double_clicked(index: int) -> void:
	var item_id = store_inventory.get_item_metadata(index)
	if current_shop_component:
		# Safely push the transaction down to the business logic node
		current_shop_component.request_buy(item_id, active_buyer)
	else:
		_buy_item(item_id)


func _on_character_item_selected(index: int) -> void:
	var item_instance = character_inventory.get_item_metadata(index)
	if item_instance:
		var sell_ratio = _get_sell_ratio()
		var sell_price = int(item_instance.item_data.value * sell_ratio)
		description.text = "%s\nSells for: %d Gold\n%s" % [item_instance.item_data.name, sell_price, item_instance.item_data.description]

func _on_character_item_double_clicked(index: int) -> void:
	var item_instance = character_inventory.get_item_metadata(index)
	if current_shop_component:
		# Safely push the transaction down to the business logic node
		current_shop_component.request_sell(active_buyer, item_instance)
	else:
		_sell_item(item_instance)


func _get_shop_name() -> String:
	if current_shop_component:
		return current_shop_component.shop_data.get_shop_name()
	return current_shop_data.shop_name if current_shop_data else ""


func _get_buy_markup() -> float:
	if current_shop_component:
		return current_shop_component.shop_data.get_buy_markup()
	return current_shop_data.buy_markup if current_shop_data else 1.0


func _get_sell_ratio() -> float:
	if current_shop_component:
		return current_shop_component.shop_data.get_sell_ratio()
	return current_shop_data.sell_ratio if current_shop_data else 0.5


func _get_shop_items() -> Array[String]:
	if current_shop_component:
		return current_shop_component.shop_data.get_items()
	return current_shop_data.items if current_shop_data else []


func _buy_item(item_id: String) -> void:
	if active_buyer == null:
		GameEvents.message_logged.emit("No buyer selected")
		return

	var item_data := ItemData.get_item(item_id)
	if item_data == null:
		return

	var price := int(item_data.value * _get_buy_markup())
	if PartyState.party_gold < price:
		GameEvents.message_logged.emit("Not enough gold")
		return

	PartyState.remove_gold(price)
	var instance := ItemInstance.new()
	instance.item_data = item_data
	InventoryManager.add_item(active_buyer, instance)
	GameEvents.message_logged.emit("Purchased %s" % item_data.name)
	refresh_ui("")


func _sell_item(item_instance: ItemInstance) -> void:
	if item_instance == null:
		return

	var sell_price := int(item_instance.item_data.value * _get_sell_ratio())
	if InventoryManager.remove_item(active_buyer, item_instance):
		PartyState.add_gold(sell_price)
		GameEvents.message_logged.emit("Sold %s for %d gold" % [item_instance.item_data.name, sell_price])
		refresh_ui("")
