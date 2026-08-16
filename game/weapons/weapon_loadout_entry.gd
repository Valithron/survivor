class_name WeaponLoadoutEntry
extends RefCounted

var definition: WeaponDefinition
var current_rank: int = 0
var runtime: SharedWeaponRuntime


func _init(weapon_definition: WeaponDefinition = null, rank: int = 0, weapon_runtime: SharedWeaponRuntime = null) -> void:
	definition = weapon_definition
	current_rank = rank
	runtime = weapon_runtime
