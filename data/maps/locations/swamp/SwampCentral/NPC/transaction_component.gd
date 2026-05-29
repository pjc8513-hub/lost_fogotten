class_name TransactionComponent
extends Node

signal transaction_succeeded(message: String)
signal transaction_failed(reason: String)

# We can pass a reference to the local shop's data if needed
@export var shop_data: ShopDataComponent

func buy_item(item_id: String, buyer) -> bool:
	var item_data = ItemDatabase.get_item(item_id)
	if not item_data:
		return false
		
	var price = item_data.value
	
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
	var modifier = shop_data.base_sell_modifier if shop_data else 0.5
	var sell_price = int(item_instance.item_data.value * modifier)
	
	InventoryManager.remove_item(seller, item_instance)
	PartyState.add_gold(sell_price)
	
	transaction_succeeded.emit("Sold %s for %d gold" % [item_instance.item_data.name, sell_price])
	return true
