# combat_event.gd
class_name CombatEvent

var type: String
var source
var target

var damage: float = 0
var accuracy: float = 1.0

var tags: Array[String] = []

var cancelled: bool = false
