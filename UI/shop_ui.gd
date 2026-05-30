extends Control

# UI Elements from your original code
@onready var shop_name_label: Label = $VBoxContainer/HBoxContainer2/ShopName
@onready var player_label: Label = $VBoxContainer/HBoxContainer2/PlayerLabel
@onready var store_inventory: ItemList = $VBoxContainer/HBoxContainer/ScrollContainer/StoreInventory
@onready var character_inventory: ItemList = $VBoxContainer/HBoxContainer/ScrollContainer2/CharacterInventory
@onready var description: Label = $VBoxContainer/Description
@onready var amount: Label = $VBoxContainer/Amount

# The active shop component injected at runtime
var current_shop_component: ShopComponent = null
# Track who the active customer is (useful for multi-character parties)
var active_buyer = null

func _ready() -> void:
	# Hide on start
	visible = false
	
	# Connect UI item clicks to our internal click handlers
	store_inventory.item_selected.connect(_on_store_item_selected)
	store_inventory.item_activated.connect(_on_store_item_double_clicked)
	
	character_inventory.item_selected.connect(_on_character_item_selected)
	character_inventory.item_activated.connect(_on_character_item_double_clicked)


# 1. TIE IT TOGETHER: The opening method called by your game world
func open_shop(shop_component: ShopComponent, buyer):
	current_shop_component = shop_component
	active_buyer = buyer
	
	# Listen for successful trades so the UI automatically redraws
	current_shop_component.transaction.transaction_succeeded.connect(refresh_ui)
	
	visible = true
	refresh_ui("")


func close_shop():
	if current_shop_component:
		# Always clean up dynamic signal connections when closing
		current_shop_component.transaction.transaction_succeeded.disconnect(refresh_ui)
	
	current_shop_component = null
	active_buyer = null
	visible = false


# 2. REFRESH: Redraw lists based on components and global data state
func refresh_ui(_msg: String = "") -> void:
	if not current_shop_component:
		return
		
	# Update top labels
	shop_name_label.text = current_shop_component.shop_data.get_shop_name()
	amount.text = "Gold: %d" % PartyState.gold
	
	# Clear old list entries
	store_inventory.clear()
	character_inventory.clear()
	
	# Populate Store Inventory using data component methods
	var markup = current_shop_component.shop_data.get_buy_markup()
	for item_id in current_shop_component.shop_data.get_items():
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
	var sell_ratio = current_shop_component.shop_data.get_sell_ratio()
	
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
		var markup = current_shop_component.shop_data.get_buy_markup()
		description.text = "%s\nCost: %d Gold\n%s" % [item_data.name, int(item_data.value * markup), item_data.description]

func _on_store_item_double_clicked(index: int) -> void:
	var item_id = store_inventory.get_item_metadata(index)
	# Safely push the transaction down to the business logic node
	current_shop_component.request_buy(item_id, active_buyer)


func _on_character_item_selected(index: int) -> void:
	var item_instance = character_inventory.get_item_metadata(index)
	if item_instance:
		var sell_ratio = current_shop_component.shop_data.get_sell_ratio()
		var sell_price = int(item_instance.item_data.value * sell_ratio)
		description.text = "%s\nSells for: %d Gold\n%s" % [item_instance.item_data.name, sell_price, item_instance.item_data.description]

func _on_character_item_double_clicked(index: int) -> void:
	var item_instance = character_inventory.get_item_metadata(index)
	# Safely push the transaction down to the business logic node
	current_shop_component.request_sell(active_buyer, item_instance)
