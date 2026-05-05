extends Resource
class_name SpellCastRequest

var spell_data: SpellData = null
var spell_result: SpellResult = null
var caster: ClassData = null
var guitar: GuitarData = null
var is_valid: bool = false
var validation_errors: Array[String] = []

func get_primary_error() -> String:
	return "" if validation_errors.is_empty() else validation_errors[0]

