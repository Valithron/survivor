extends Node

## Headless convergence validation for the developer-only P1 + E1 sandbox.
## It uses the scene exactly as an engineer would: through SterlingPlayer and
## EnemySpawner's public contracts, with no progression or weapon dependencies.
const SANDBOX_SCENE: PackedScene = preload("res://tests/prototype_combat_sandbox.tscn")
const SWARM_DEFINITION: EnemyDefinition = preload("res://data/enemies/swarm_zombie.tres")

var _xp_awards_seen := 0


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	var sandbox := SANDBOX_SCENE.instantiate() as PrototypeCombatSandbox
	if sandbox == null:
		printerr("P1 + E1 SANDBOX TEST: Could not instantiate PrototypeCombatSandbox.")
		get_tree().quit(1)
		return
	## Keep the validation short while still exercising the same local pressure
	## controls a developer uses in the sandbox Inspector.
	sandbox.initial_spawn_burst = 0
	sandbox.enemies_per_batch = 1
	sandbox.spawn_interval_seconds = 10.0
	sandbox.maximum_active_enemies = 12
	get_tree().root.add_child(sandbox)
	GameplayEvents.xp_awarded.connect(_on_xp_awarded)
	await get_tree().process_frame
	await get_tree().physics_frame

	var player := sandbox.player
	var spawner := sandbox.enemy_spawner
	if player == null or player.health_component == null or not player.health_component.is_alive():
		errors.append("Sandbox did not construct a live SterlingPlayer health contract.")
	if spawner == null or not spawner.is_spawning():
		errors.append("Sandbox did not start EnemySpawner through its published configuration contract.")

	var position_before_move := player.global_position
	Input.action_press(&"move_right")
	await get_tree().physics_frame
	Input.action_release(&"move_right")
	if player.global_position.x <= position_before_move.x:
		errors.append("SterlingPlayer did not respond to the mapped movement action inside the sandbox.")

	var enemy := spawner.spawn_enemy_at(player.global_position + Vector2(-160.0, 0.0))
	if enemy == null:
		errors.append("Sandbox EnemySpawner could not create a swarm zombie through its public spawn interface.")
	else:
		## Sterling's published basic tuning intentionally refreshes Auto Aim on a
		## short cadence; let that runtime cadence execute instead of reaching into
		## a private player implementation detail.
		for _frame in range(10):
			await get_tree().physics_frame
		player.set_manual_aim_enabled(false)
		if player.get_basic_aim_direction().distance_to(Vector2.LEFT) > 0.05:
			errors.append("Sandbox Auto Aim did not resolve the spawned swarm target.")
		player.set_manual_aim_enabled(true)
		player.set_manual_aim_direction(Vector2.LEFT)
		if player.get_basic_aim_direction().distance_to(Vector2.LEFT) > 0.001:
			errors.append("Sandbox Manual Aim did not immediately override Auto Aim.")
		var target_health_before := enemy.health_component.current_health
		player.fire_basic_once_for_test()
		for _frame in range(18):
			await get_tree().physics_frame
		if is_instance_valid(enemy) and enemy.health_component.current_health >= target_health_before:
			errors.append("Sterling's basic projectile did not damage the spawned swarm through the shared contract.")
		if _xp_awards_seen != 1:
			errors.append("Defeating a sandbox swarm did not emit exactly one XP award event.")

	var health_before_contact := player.health_component.current_health
	var contact_enemy := spawner.spawn_enemy_at(player.global_position)
	if contact_enemy == null:
		errors.append("Sandbox could not create a contact-pressure swarm enemy.")
	else:
		await get_tree().physics_frame
		if player.health_component.current_health >= health_before_contact:
			errors.append("Sandbox swarm contact did not damage Sterling through HealthComponent.")

	var pressure_spawned := spawner.spawn_burst(20)
	if pressure_spawned <= 0 or spawner.get_active_enemy_count() > sandbox.maximum_active_enemies:
		errors.append("Sandbox spawn-pressure controls did not respect the tunable active-enemy cap.")

	if GameplayEvents.xp_awarded.is_connected(_on_xp_awarded):
		GameplayEvents.xp_awarded.disconnect(_on_xp_awarded)
	sandbox.queue_free()
	if errors.is_empty():
		print("P1 + E1 SANDBOX TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("P1 + E1 SANDBOX TEST: " + error_text)
	get_tree().quit(1)


func _on_xp_awarded(award: XpAward) -> void:
	if award != null and award.amount == SWARM_DEFINITION.xp_value:
		_xp_awards_seen += 1
