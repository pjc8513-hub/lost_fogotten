extends Resource
class_name SpellData

var caster: ClassData = null
var guitar: GuitarData = null
var guitar_name: String = ""
var step_count: int = 0
var string_count: int = 0
var string_elements: Array[int] = []
var sequence_grid: Array[Array] = []
var complexity_limit: int = 0
var filled_slots: int = 0

func has_notes() -> bool:
	return filled_slots > 0
