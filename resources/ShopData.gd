# ShopData.gd
extends Resource
class_name ShopData

@export var shop_id : String = ""
@export var shop_name : String = ""

@export var buy_markup : float = 1.0
@export var sell_ratio : float = 0.5

@export var items : Array[String] = []
