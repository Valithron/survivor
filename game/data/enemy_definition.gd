class_name EnemyDefinition
extends Resource

@export var enemy_id: StringName
@export var display_name: String
@export_range(0.01, 100000.0, 0.01) var base_max_health: float = 10.0
@export_range(0.0, 5000.0, 0.1) var move_speed: float = 80.0
@export_range(0.0, 10000.0, 0.01) var contact_damage_per_second: float = 5.0
@export_range(1.0, 1000.0, 0.5) var collision_radius: float = 16.0
@export_range(0, 100000, 1) var xp_value: int = 1
@export var visual_scene: PackedScene
@export_range(1.0, 100.0, 0.05) var elite_health_multiplier: float = 2.0
@export_range(1.0, 10.0, 0.05) var elite_damage_multiplier: float = 1.5
@export_range(1.0, 5.0, 0.05) var elite_speed_multiplier: float = 1.1


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if enemy_id.is_empty():
		errors.append("EnemyDefinition requires enemy_id.")
	if display_name.is_empty():
		errors.append("EnemyDefinition requires display_name.")
	if xp_value <= 0:
		errors.append("EnemyDefinition requires a positive XP value.")
	if elite_health_multiplier < 1.0 or elite_damage_multiplier < 1.0 or elite_speed_multiplier < 1.0:
		errors.append("EnemyDefinition elite multipliers must not weaken an elite.")
	return errors
