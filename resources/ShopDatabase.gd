extends Node

# A dictionary to store the loaded ShopData resources, keyed by shop_id
# Format: { "tavern_shop": ShopDataResource, "blacksmith_shop": ShopDataResource }
var _shops: Dictionary = {}

const SHOPS_DIR_PATH = "res://data/shops/"

func _ready() -> void:
	_load_shop_resources()


# Scans the directory and loads every .tres file into memory
func _load_shop_resources() -> void:
	if not DirAccess.dir_exists_absolute(SHOPS_DIR_PATH):
		push_error("ShopDatabase: Directory not found at " + SHOPS_DIR_PATH)
		return

	var dir = DirAccess.open(SHOPS_DIR_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Ignore directories and ensure we are only loading .tres files
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = SHOPS_DIR_PATH + file_name
				var resource = ResourceLoader.load(full_path)
				
				if resource is ShopData:
					if resource.shop_id == "":
						push_warning("ShopDatabase: %s has an empty shop_id!" % file_name)
					else:
						_shops[resource.shop_id] = resource
				else:
					push_warning("ShopDatabase: File at %s is not a valid ShopData resource." % full_path)
					
			file_name = dir.get_next()
		dir.list_dir_end()
		
		print("ShopDatabase: Successfully loaded %d shops." % _shops.size())
	else:
		push_error("ShopDatabase: Failed to open directory at " + SHOPS_DIR_PATH)


# Public API to get a shop's data from anywhere in your game
func get_shop(shop_id: String) -> ShopData:
	if _shops.has(shop_id):
		return _shops[shop_id]
	
	push_error("ShopDatabase: Request for non-existent shop_id: '%s'" % shop_id)
	return null


# Public API to check if a shop exists
func has_shop(shop_id: String) -> bool:
	return _shops.has(shop_id)
