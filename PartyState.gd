extends Node

# Remove the [ClassData] type hint to prevent the compilation error
var active_party = [
	preload("res://data/classes/knight.tres"),
	preload("res://data/classes/cleric.tres"),
	preload("res://data/classes/rogue.tres"),
	preload("res://data/classes/sorcerer.tres")
]
