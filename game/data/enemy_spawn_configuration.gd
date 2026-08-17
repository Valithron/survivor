class_name EnemySpawnConfiguration
extends Resource

## E1's small, reusable spawn tuning contract. The later run director chooses
## when and which configurations run; this resource only describes one stream.
@export var enemy_definition: EnemyDefinition
@export_range(0.0, 60.0, 0.05) var initial_delay_seconds: float = 0.0
@export_range(0.05, 60.0, 0.05) var spawn_interval_seconds: float = 0.4
@export_range(1, 100, 1) var enemies_per_batch: int = 3
@export_range(1, 2000, 1) var maximum_active_enemies: int = 240
@export_range(1.0, 10000.0, 1.0) var minimum_spawn_distance: float = 460.0
@export_range(1.0, 10000.0, 1.0) var maximum_spawn_distance: float = 700.0
@export_range(0.0, 1.0, 0.001) var elite_spawn_chance: float = 0.0


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if enemy_definition == null:
		errors.append("EnemySpawnConfiguration requires an EnemyDefinition.")
	if spawn_interval_seconds <= 0.0:
		errors.append("EnemySpawnConfiguration requires a positive spawn interval.")
	if enemies_per_batch <= 0:
		errors.append("EnemySpawnConfiguration requires at least one enemy per batch.")
	if maximum_active_enemies <= 0:
		errors.append("EnemySpawnConfiguration requires a positive active-enemy cap.")
	if minimum_spawn_distance <= 0.0 or maximum_spawn_distance < minimum_spawn_distance:
		errors.append("EnemySpawnConfiguration requires an ordered positive spawn-distance range.")
	return errors
