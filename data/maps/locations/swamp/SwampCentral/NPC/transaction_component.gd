class_name TransactionComponent
extends Node

signal transaction_succeeded(message: String)
signal transaction_failed(reason: String)

# We can pass a reference to the local shop's data if needed
@export var shop_data: ShopDataComponent

func _ready() -> void:
	if shop_data == null:
		shop_data = get_node_or_null("../ShopDataComponent") as ShopDataComponent

func buy_item(item_id: String, buyer) -> bool:
	if buyer == null:
		transaction_failed.emit("No buyer selected")
		return false

	var item_data = ItemDatabase.get_item(item_id)
	if not item_data:
		return false
		
	var modifier = shop_data.get_buy_markup() if shop_data else 1.0
	var price = int(item_data.value * modifier)
	
	# Rule 1: Can we afford it?
	if PartyState.gold < price:
		transaction_failed.emit("Not enough gold")
		return false
		
	# Execute the trade
	PartyState.remove_gold(price)
	
	var instance = ItemInstance.new()
	instance.item_data = item_data
	InventoryManager.add_item(buyer, instance)
	
	transaction_succeeded.emit("Purchased %s" % item_data.name)
	return true

func sell_item(seller, item_instance: ItemInstance) -> bool:
	if not item_instance:
		return false
		
	# Use the modifier from the attached shop data, or default to 0.5
	var modifier = shop_data.get_sell_ratio() if shop_data else 0.5
	var sell_price = int(item_instance.item_data.value * modifier)
	
	InventoryManager.remove_item(seller, item_instance)
	PartyState.add_gold(sell_price)
	
	transaction_succeeded.emit("Sold %s for %d gold" % [item_instance.item_data.name, sell_price])
	return true
