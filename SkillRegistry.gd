# SkillRegistry.gd — autoload
extends Node

var _all_skills: Array[SkillData] = []

func _ready() -> void:
	_load_all_skills()

func _load_all_skills() -> void:
	# Preload your skills here, or scan a folder
	_all_skills = [
		preload("res://data/skills/stage_presence.tres"),
		preload("res://data/skills/experienced.tres"),
		preload("res://data/skills/quick_step.tres"),
	]

func get_skills_for_class(class_names: ClassData.Class_Names) -> Array[SkillData]:
	return _all_skills.filter(func(s): 
		return s.available_classes.is_empty() or s.available_classes.has(class_names)
	)

func get_skill(skill_id: String) -> SkillData:
	for s in _all_skills:
		if s.skill_id == skill_id:
			return s
	return null
