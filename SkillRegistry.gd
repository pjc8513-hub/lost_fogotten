# SkillRegistry.gd — autoload
extends Node

var _all_skills: Array[SkillData] = []

func _ready() -> void:
	_load_all_skills()

func _load_all_skills() -> void:
	_all_skills.clear()
	_scan_skills_folder("res://data/skills/")

func _scan_skills_folder(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Failed to open skills folder: %s" % path)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		# Skip hidden files and folders
		if not dir.current_is_dir() and not file_name.begins_with("."):
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var full_path := path.path_join(file_name)
				var skill_resource := load(full_path)
				if skill_resource:
					_all_skills.append(skill_resource)
				else:
					push_warning("Failed to load skill: %s" % full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Loaded %d skills from %s" % [_all_skills.size(), path])

func get_skills_for_class(class_names: ClassData.Class_Names) -> Array[SkillData]:
	return _all_skills.filter(func(s): 
		return s.available_classes.is_empty() or s.available_classes.has(class_names)
	)

func get_skill(skill_id: String) -> SkillData:
	for s in _all_skills:
		if s.skill_id == skill_id:
			return s
	return null
