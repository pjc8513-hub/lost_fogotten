class_name ShopComponent
extends Node

signal opened
signal closed

@onready var shop_data: ShopDataComponent = $ShopDataComponent
@onready var transaction: TransactionComponent = $TransactionComponent

func _ready():
	# Connect the transaction's success/fail directly to your global logger
	transaction.transaction_succeeded.connect(func(msg): GameEvents.message_logged.emit(msg))
	transaction.transaction_failed.connect(func(msg): GameEvents.message_logged.emit(msg))

func open_shop():
	opened.emit(shop_data.shop_id)

func close_shop():
	closed.emit()

# Forward the requests down to the specialized component
func request_buy(item_id: String, buyer):
	transaction.buy_item(item_id, buyer)

func request_sell(seller, item_instance: ItemInstance):
	transaction.sell_item(seller, item_instance)
