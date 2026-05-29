class_name ShopDataComponent
extends Node

@export var shop_id: String = ""

# This will hold the actual runtime data injected from the resource
var data: ShopData

func _ready() -> void:
	if shop_id == "":
		push_error("ShopDataComponent on %s has no shop_id set!" % owner.name)
		return
		
	# Fetch the resource data from our new Autoload
	data = ShopDatabase.get_shop(shop_id)


# Helper methods so other components don't have to reach through "data"
func get_shop_name() -> String:
	return data.shop_name if data else "Unknown Shop"

func get_buy_markup() -> float:
	return data.buy_markup if data else 1.0

func get_sell_ratio() -> float:
	return data.sell_ratio if data else 0.5

func get_items() -> Array[String]:
	return data.items if data else []

func has_item(item_id: String) -> bool:
	return item_id in get_items()
