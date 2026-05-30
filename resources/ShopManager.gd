# ShopManager.gd - Add as an Autoload (Autoload > ShopManager)
extends Node

signal shop_opened(shop_id: String)
signal shop_closed

func open_shop(shop_id: String) -> void:
	if not ShopDatabase.has_shop(shop_id):
		push_error("ShopManager: Shop '%s' does not exist" % shop_id)
		return
	
	shop_opened.emit(shop_id)
	# Your UI layer would listen to this signal and display the shop

func close_shop() -> void:
	shop_closed.emit()
