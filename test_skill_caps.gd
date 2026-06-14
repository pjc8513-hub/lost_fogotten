extends Node

func _ready() -> void:
	var fire_mastery := load("res://data/skills/fire_mastery.tres") as SkillData
	assert(fire_mastery != null)
	assert(fire_mastery.get_max_rank_for_class(ClassData.Class_Names.BARD) == 2)
	assert(fire_mastery.get_max_rank_for_class(ClassData.Class_Names.RANGER) == 1)
	assert(fire_mastery.get_max_rank_for_class(ClassData.Class_Names.SORCERER) == 4)

	var bard := (load("res://data/classes/sorcerer.tres") as ClassData).create_party_member_instance()
	bard.class_names = ClassData.Class_Names.BARD
	bard.learned_skills = {"FireMastery": 2}
	bard.available_skill_points = 1
	assert(not bard.upgrade_skill("FireMastery"))
	assert(bard.get_skill_rank("FireMastery") == 2)
	assert(bard.available_skill_points == 1)

	var sorcerer := (load("res://data/classes/sorcerer.tres") as ClassData).create_party_member_instance()
	sorcerer.learned_skills = {"FireMastery": 2}
	sorcerer.available_skill_points = 1
	var inferno := load("res://data/spells/inferno.tres") as SpellData
	assert(not SpellExecutor.build_request(inferno, sorcerer).is_valid)
	sorcerer.learned_skills["FireMastery"] = 3
	assert(SpellExecutor.build_request(inferno, sorcerer).is_valid)

	print("PASS: class skill caps and spell-level mastery gates work.")
	get_tree().quit()
