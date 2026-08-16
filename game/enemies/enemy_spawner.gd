class_name EnemySpawner
extends Node2D

## Owns one tunable stream of a single enemy scene. R1 will decide which
## streams are active at each time; E1 deliberately has no surge scheduling.
signal enemy_spawned(enemy: ZombieEnemy)
signal active_enemy_count_changed(active_enemy_count: int)

@export var spawn_configuration: EnemySpawnConfiguration
@export var enemy_scene: PackedScene
@export var auto_start := false
@export_range(0.0, 1000.0, 0.5) var target_contact_radius: float = 16.0

var _target: Node2D
var _target_health: HealthComponent
var _spawning := false
var _remaining_initial_delay := 0.0
var _spawn_accumulator := 0.0
var _spawn_intensity := 1.0
var _active_enemies: Array[ZombieEnemy] = []
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	_random.randomize()
	DevTools.enemy_spawn_requested.connect(_on_dev_enemy_spawn_requested)
	if auto_start:
		start_spawning()


func _exit_tree() -> void:
	if DevTools.enemy_spawn_requested.is_connected(_on_dev_enemy_spawn_requested):
		DevTools.enemy_spawn_requested.disconnect(_on_dev_enemy_spawn_requested)


func _process(delta: float) -> void:
	if not _spawning or _spawn_intensity <= 0.0 or not _has_target() or not _has_valid_configuration():
		return
	if _remaining_initial_delay > 0.0:
		_remaining_initial_delay = maxf(_remaining_initial_delay - delta, 0.0)
		return

	_spawn_accumulator += delta * _spawn_intensity
	if _spawn_accumulator < spawn_configuration.spawn_interval_seconds:
		return
	_spawn_accumulator = fmod(_spawn_accumulator, spawn_configuration.spawn_interval_seconds)
	spawn_burst(spawn_configuration.enemies_per_batch)


func set_target(target: Node2D, target_health: HealthComponent = null, contact_radius: float = 16.0) -> void:
	_target = target
	_target_health = target_health
	target_contact_radius = maxf(contact_radius, 0.0)
	if _target_health == null and is_instance_valid(_target):
		_target_health = _target.get_node_or_null(^"HealthComponent") as HealthComponent
	for enemy in _active_enemies:
		if is_instance_valid(enemy):
			enemy.set_target(_target, _target_health, target_contact_radius)


func start_spawning() -> bool:
	if not _has_valid_configuration():
		return false
	_spawning = true
	_remaining_initial_delay = spawn_configuration.initial_delay_seconds
	_spawn_accumulator = 0.0
	return true


func stop_spawning() -> void:
	_spawning = false


func set_spawn_intensity(multiplier: float) -> void:
	_spawn_intensity = maxf(multiplier, 0.0)


func get_spawn_intensity() -> float:
	return _spawn_intensity


func is_spawning() -> bool:
	return _spawning


func get_active_enemy_count() -> int:
	_prune_inactive_enemies()
	return _active_enemies.size()


func get_active_enemies() -> Array[ZombieEnemy]:
	_prune_inactive_enemies()
	return _active_enemies.duplicate()


func spawn_burst(count: int) -> int:
	if not _has_target() or not _has_valid_configuration():
		return 0
	var spawned_count := 0
	for _index in range(maxi(count, 0)):
		if get_active_enemy_count() >= spawn_configuration.maximum_active_enemies:
			break
		var is_elite := _random.randf() < spawn_configuration.elite_spawn_chance
		if spawn_enemy_at(_random_spawn_position(), is_elite) != null:
			spawned_count += 1
	return spawned_count


func spawn_enemy_at(world_position: Vector2, elite_variant: bool = false) -> ZombieEnemy:
	if not _has_valid_configuration() or enemy_scene == null:
		return null
	if get_active_enemy_count() >= spawn_configuration.maximum_active_enemies:
		return null
	var spawned_node := enemy_scene.instantiate()
	if not (spawned_node is ZombieEnemy):
		push_error("EnemySpawner enemy_scene must instantiate a ZombieEnemy.")
		spawned_node.queue_free()
		return null
	var enemy := spawned_node as ZombieEnemy
	enemy.configure(spawn_configuration.enemy_definition, elite_variant)
	enemy.set_target(_target, _target_health, target_contact_radius)
	add_child(enemy)
	enemy.global_position = world_position
	_active_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy))
	enemy_spawned.emit(enemy)
	active_enemy_count_changed.emit(_active_enemies.size())
	return enemy


func _on_dev_enemy_spawn_requested(enemy_id: StringName, count: int) -> void:
	if spawn_configuration == null or spawn_configuration.enemy_definition == null:
		return
	if enemy_id == spawn_configuration.enemy_definition.enemy_id:
		spawn_burst(count)


func _on_enemy_tree_exited(enemy: ZombieEnemy) -> void:
	var was_tracked := _active_enemies.has(enemy)
	_active_enemies.erase(enemy)
	if was_tracked:
		active_enemy_count_changed.emit(_active_enemies.size())


func _random_spawn_position() -> Vector2:
	var angle := _random.randf_range(0.0, TAU)
	var distance := _random.randf_range(
		spawn_configuration.minimum_spawn_distance,
		spawn_configuration.maximum_spawn_distance,
	)
	return _target.global_position + Vector2.RIGHT.rotated(angle) * distance


func _has_target() -> bool:
	return is_instance_valid(_target)


func _has_valid_configuration() -> bool:
	return (
		spawn_configuration != null
		and spawn_configuration.enemy_definition != null
		and spawn_configuration.spawn_interval_seconds > 0.0
		and spawn_configuration.enemies_per_batch > 0
		and spawn_configuration.maximum_active_enemies > 0
		and spawn_configuration.minimum_spawn_distance > 0.0
		and spawn_configuration.maximum_spawn_distance >= spawn_configuration.minimum_spawn_distance
		and enemy_scene != null
	)


func _prune_inactive_enemies() -> void:
	var retained: Array[ZombieEnemy] = []
	for enemy in _active_enemies:
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			retained.append(enemy)
	if retained.size() != _active_enemies.size():
		_active_enemies = retained
		active_enemy_count_changed.emit(_active_enemies.size())
