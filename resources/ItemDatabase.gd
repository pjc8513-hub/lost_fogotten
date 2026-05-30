class_name ItemDatabase
extends RefCounted

static var _items: Dictionary = {}
static var _loaded: bool = false

# Public API to get an item by its ID
static func get_item(item_id: String) -> ItemData:
	if not _loaded:
		_load_items()
	
	if item_id == "":
		return null
		
	# Try direct match
	if _items.has(item_id):
		return _items[item_id]
	
	# Try lowercase
	var lower_id = item_id.to_lower()
	if _items.has(lower_id):
		return _items[lower_id]
		
	# Try snake_case
	var snake_id = item_id.to_snake_case()
	if _items.has(snake_id):
		return _items[snake_id]
		
	push_warning("ItemDatabase: Item not found: '%s'" % item_id)
	return null

# Scans the directory and loads every ItemData resource into memory
static func _load_items() -> void:
	_loaded = true
	var dir_path = "res://data/weapons/"
	
	if not DirAccess.dir_exists_absolute(dir_path):
		push_error("ItemDatabase: Directory not found at %s" % dir_path)
		return
		
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = dir_path + file_name
				var resource = ResourceLoader.load(full_path)
				
				if resource is ItemData:
					var id = resource.item_id
					if id == "":
						# Fallback to filename without extension
						id = file_name.get_basename()
					
					# Register using various forms for bulletproof matching
					_items[id] = resource
					_items[id.to_lower()] = resource
					_items[id.to_snake_case()] = resource
					
					var file_basename = file_name.get_basename()
					_items[file_basename] = resource
					_items[file_basename.to_lower()] = resource
					_items[file_basename.to_snake_case()] = resource
					
			file_name = dir.get_next()
		dir.list_dir_end()
		print("ItemDatabase: Successfully loaded %d items from %s." % [_items.size(), dir_path])
	else:
		push_error("ItemDatabase: Failed to open directory at %s" % dir_path)
