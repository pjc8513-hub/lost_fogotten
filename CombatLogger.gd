extends Node

const MAX_LOG_ENTRIES := 50
const DUMP_HOTKEY := KEY_F10

var entries: Array[Dictionary] = []

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == DUMP_HOTKEY:
			dump_to_json()

func log_attack(entry: Dictionary) -> void:
	entry["timestamp"] = _timestamp()
	entries.append(entry)
	while entries.size() > MAX_LOG_ENTRIES:
		entries.pop_front()

func dump_to_json() -> String:
	var file_stamp := _timestamp().replace(" ", "_").replace(":", "-")
	var path := "user://combat_log_%s.json" % file_stamp
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("CombatLogger failed to open %s for writing." % path)
		return ""

	file.store_string(JSON.stringify(entries, "\t"))
	file.close()

	var global_path := ProjectSettings.globalize_path(path)
	print("Combat log dumped to %s" % global_path)
	if Engine.has_singleton("GameEvents") or get_node_or_null("/root/GameEvents") != null:
		GameEvents.message_logged.emit("[color=gray]Combat log dumped to %s[/color]" % global_path)
	return global_path

func clear() -> void:
	entries.clear()

func describe_character(member: ClassData, slot: ItemData.Equip_Slot) -> Dictionary:
	if member == null:
		return {}

	return {
		"name": member.member_name,
		"class": ClassData.get_class_display_name(member.get_resolved_class_name()),
		"level": member.level,
		"hp": member.current_hp,
		"mp": member.current_mp,
		"base_stats": {
			"might": member.base_might,
			"dexterity": member.base_dexterity,
			"endurance": member.base_endurance,
			"wisdom": member.base_wisdom
		},
		"effective_stats": {
			"might": member.get_might(),
			"attack_might": member.get_attack_might(slot),
			"dexterity": member.get_dexterity(),
			"endurance": member.get_endurance(),
			"wisdom": member.get_wisdom(),
			"accuracy": member.get_accuracy(),
			"attack_accuracy": member.get_attack_accuracy(slot),
			"critical_chance": member.get_critical_chance(),
			"attack_critical_chance": member.get_attack_critical_chance(slot),
			"attack_speed": member.get_attack_speed_bonus(),
			"total_attack_speed": member.get_total_attack_speed(slot),
			"bonus_damage": member.get_bonus_damage(),
			"attack_bonus_damage": member.get_attack_bonus_damage(slot),
			"magic_amp": member.get_magic_amp(),
			"max_mp": member.get_max_mp(),
			"armor_class": member.get_armor_class()
		},
		"skills": _describe_relevant_skills(member),
		"gear": describe_equipped_gear(member)
	}

func describe_enemy(enemy: Enemy) -> Dictionary:
	if enemy == null or enemy.enemy_data == null:
		return {}

	return {
		"name": enemy.enemy_data.enemy_name,
		"hp": enemy.enemy_data.hp,
		"armor_class": enemy.enemy_data.armor_class,
		"physical_resistance": enemy.enemy_data.get_resistance("physical"),
		"status_effects": enemy.enemy_data.status_effects.duplicate()
	}

func describe_equipped_gear(member: ClassData) -> Dictionary:
	var gear := {}
	if member == null:
		return gear

	for inst in member.inventory:
		if not inst.is_equipped or inst.item_data == null:
			continue
		var item := inst.item_data
		var slot_name := ItemData.get_equip_slot_key(item.equip_slot)
		if not gear.has(slot_name):
			gear[slot_name] = []
		gear[slot_name].append(describe_item(item))
	return gear

func describe_item(item: ItemData) -> Dictionary:
	if item == null:
		return {}

	var data := {
		"item_id": item.item_id,
		"name": item.name,
		"type": item.get_class(),
		"slot": ItemData.get_equip_slot_key(item.equip_slot),
		"stat_bonuses": _item_stat_bonuses(item)
	}
	if item is WeaponData:
		var weapon := item as WeaponData
		data["weapon_type"] = WeaponData.Weapon_Type.keys()[weapon.weapon_type]
		data["dice"] = "%dd%d" % [weapon.dice_rolls, weapon.dice_sides]
		data["attack_speed"] = weapon.attack_speed
		data["tile_range"] = weapon.tile_range
	elif item is ArmorData:
		var armor := item as ArmorData
		data["armor_type"] = ArmorData.Armor_Type.keys()[armor.armor_type]
		data["armor_class"] = armor.armor_class
	return data

func _describe_relevant_skills(member: ClassData) -> Dictionary:
	var skill_ids := [
		"blade_skill",
		"bow_skill",
		"poleaxe_skill",
		"staff_mastery",
		"polearm_mastery",
		"bow_mastery",
		"blade_mastery",
		"axe_mastery",
		"cudgel_mastery",
		"heavy_armor_skill",
		"light_armor_skill"
	]
	var result := {}
	for skill_id in skill_ids:
		result[skill_id] = member.get_skill_rank_value(skill_id)
	return result

func _item_stat_bonuses(item: ItemData) -> Dictionary:
	var fields := [
		"might_bonus",
		"endurance_bonus",
		"wisdom_bonus",
		"dexterity_bonus",
		"accuracy_bonus",
		"armor_class_bonus",
		"critical_chance_bonus",
		"initiative_bonus",
		"attack_speed_bonus",
		"max_hp_bonus",
		"max_mp_bonus",
		"bonus_damage_bonus",
		"magic_amp_bonus",
		"critical_amp_bonus",
		"counter_chance_bonus",
		"lockpicking_bonus",
		"perception_bonus"
	]
	var bonuses := {}
	for field in fields:
		var value := int(item.get(field))
		if value != 0:
			bonuses[field] = value
	return bonuses

func _timestamp() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [
		now["year"],
		now["month"],
		now["day"],
		now["hour"],
		now["minute"],
		now["second"]
	]
