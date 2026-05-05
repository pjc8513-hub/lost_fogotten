extends Node

signal cast_request_built(request: SpellCastRequest)
signal cast_request_rejected(request: SpellCastRequest)

func build_request(spell_data: SpellData) -> SpellCastRequest:
	var request := _create_request(spell_data)
	if request.is_valid:
		cast_request_built.emit(request)
	else:
		cast_request_rejected.emit(request)

	return request

func can_cast(spell_data: SpellData) -> bool:
	return _create_request(spell_data).is_valid

func _create_request(spell_data: SpellData) -> SpellCastRequest:
	var request := SpellCastRequest.new()
	request.spell_data = spell_data
	request.spell_result = SpellResolver.resolve_spell_preview(spell_data)
	request.caster = spell_data.caster if spell_data != null else null
	request.guitar = spell_data.guitar if spell_data != null else null
	_validate_request(request)
	return request

func _validate_request(request: SpellCastRequest) -> void:
	request.validation_errors.clear()

	if request.spell_data == null:
		request.validation_errors.append("No spell data to resolve.")
	elif not request.spell_data.has_notes():
		request.validation_errors.append("No notes have been placed.")

	if request.caster == null:
		request.validation_errors.append("No caster selected.")

	if request.guitar == null:
		request.validation_errors.append("No guitar equipped.")

	if request.spell_result == null:
		request.validation_errors.append("No spell result generated.")
	elif not request.spell_result.has_output():
		request.validation_errors.append("Spell has no effect after resolution.")
	elif not request.spell_result.mana_sufficient:
		request.validation_errors.append("Not enough mana.")

	request.is_valid = request.validation_errors.is_empty()
