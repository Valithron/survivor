extends Node

const SWARM_ENEMY: EnemyDefinition = preload("res://data/enemies/swarm_zombie.tres")
const SWARM_SCENE: PackedScene = preload("res://game/enemies/swarm_zombie.tscn")

var _xp_awards_seen := 0


func _ready() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	var root_node := Node2D.new()
	get_tree().root.add_child(root_node)

	var target := CharacterBody2D.new()
	target.name = &"TestPlayer"
	root_node.add_child(target)
	var target_health := HealthComponent.new()
	target_health.name = &"HealthComponent"
	target.add_child(target_health)
	target_health.configure(25.0)

	var configuration := EnemySpawnConfiguration.new()
	configuration.enemy_definition = SWARM_ENEMY
	configuration.spawn_interval_seconds = 0.2
	configuration.enemies_per_batch = 1
	configuration.maximum_active_enemies = 2
	configuration.minimum_spawn_distance = 24.0
	configuration.maximum_spawn_distance = 40.0
	errors.append_array(configuration.validate_contract())

	var spawner := EnemySpawner.new()
	spawner.spawn_configuration = configuration
	spawner.enemy_scene = SWARM_SCENE
	root_node.add_child(spawner)
	spawner.set_target(target, target_health, 16.0)
	GameplayEvents.xp_awarded.connect(_on_xp_awarded)

	var enemy := spawner.spawn_enemy_at(target.global_position)
	if enemy == null:
		errors.append("EnemySpawner could not spawn the configured swarm zombie.")
	else:
		if not enemy.is_in_group(&"auto_aim_target"):
			errors.append("SwarmZombie is missing the auto_aim_target group.")
		if not enemy.is_in_group(&"survivor_enemy_targets"):
			errors.append("SwarmZombie is missing the survivor_enemy_targets group.")
		if enemy.collision_layer != 2:
			errors.append("SwarmZombie does not use collision layer 2 for player projectiles.")
		## Let the freshly-added CharacterBody2D enter at least two physics ticks;
		## the first tick can occur before the scene-tree test continuation.
		await get_tree().physics_frame
		await get_tree().physics_frame
		if target_health.current_health >= target_health.maximum_health:
			errors.append("SwarmZombie contact did not apply DamageEvent damage to target health.")
		enemy.apply_damage_event(DamageEvent.new(self, SWARM_ENEMY.base_max_health, &"e1_validation"))
		## The production zombie now plays its lean raster death sequence before
		## freeing, so wait for that legitimate presentation duration.
		await get_tree().create_timer(0.5).timeout
		if _xp_awards_seen != 1:
			errors.append("SwarmZombie death did not report exactly one XP award.")
		if spawner.get_active_enemy_count() != 0:
			errors.append("EnemySpawner did not remove a defeated swarm zombie from active tracking.")

	var spawned_count := spawner.spawn_burst(3)
	if spawned_count != 2 or spawner.get_active_enemy_count() != 2:
		errors.append("EnemySpawner did not enforce the configurable active-enemy cap.")

	if GameplayEvents.xp_awarded.is_connected(_on_xp_awarded):
		GameplayEvents.xp_awarded.disconnect(_on_xp_awarded)
	root_node.queue_free()
	if errors.is_empty():
		print("E1 validation passed.")
		get_tree().quit(0)
		return
	for error_text in errors:
		push_error(error_text)
	get_tree().quit(1)


func _on_xp_awarded(_award: XpAward) -> void:
	_xp_awards_seen += 1
