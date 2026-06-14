extends SceneTree

const MASTERY_CASES := [
	["FireMastery", SpellData.Element.FIRE],
	["EarthMastery", SpellData.Element.EARTH],
	["ElectricMastery", SpellData.Element.ELECTRIC],
	["IceMastery", SpellData.Element.WATER],
	["DarkMastery", SpellData.Element.DARK],
	["LightMastery", SpellData.Element.LIGHT],
	["SpiritMastery", SpellData.Element.SPIRIT],
]

func _initialize() -> void:
	await process_frame
	var caster := ClassData.new()
	var skill_registry := root.get_node("SkillRegistry")
	var spell_executor := root.get_node("SpellExecutor")

	for test_case in MASTERY_CASES:
		var skill_id: String = test_case[0]
		var element: int = test_case[1]
		var skill = skill_registry.get_skill(skill_id)
		assert(skill != null, "%s was not loaded by SkillRegistry." % skill_id)

		for rank in range(1, 5):
			caster.learned_skills = {skill_id: rank}
			assert(
				caster.get_spell_element_roll_bonus(element) == rank,
				"%s rank %d did not grant %d bonus dice." % [skill_id, rank, rank]
			)

			var spell := SpellData.new()
			spell.spell_id = "mastery_test"
			spell.spellbook = element
			spell.element_notes = [element]
			spell.damage = "3d8"
			assert(
				spell_executor.get_spell_dice_rolls(spell, caster) == 3 + rank,
				"%s rank %d did not turn 3d8 into %dd8." % [skill_id, rank, 3 + rank]
			)

	print("PASS: all seven elemental masteries add one spell die per rank.")
	quit()
