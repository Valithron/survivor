extends Node

const PLAYER_SCENE: PackedScene = preload("res://game/player/sterling_player.tscn")
const SWARM_DEFINITION: EnemyDefinition = preload("res://data/enemies/swarm_zombie.tres")
const FAST_DEFINITION: EnemyDefinition = preload("res://data/enemies/fast_zombie.tres")
const TANK_DEFINITION: EnemyDefinition = preload("res://data/enemies/tank_zombie.tres")
const FAST_SCENE: PackedScene = preload("res://game/enemies/fast_zombie.tscn")
const TANK_SCENE: PackedScene = preload("res://game/enemies/tank_zombie.tscn")


func _ready() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	errors.append_array(FAST_DEFINITION.validate_contract())
	errors.append_array(TANK_DEFINITION.validate_contract())
	if FAST_DEFINITION.base_max_health >= SWARM_DEFINITION.base_max_health or FAST_DEFINITION.move_speed <= SWARM_DEFINITION.move_speed:
		errors.append("Fast Zombie definition does not preserve its fragile positional-threat profile.")
	if TANK_DEFINITION.base_max_health <= SWARM_DEFINITION.base_max_health or TANK_DEFINITION.move_speed >= SWARM_DEFINITION.move_speed:
		errors.append("Tank Zombie definition does not preserve its slow space-denial profile.")

	var player := PLAYER_SCENE.instantiate() as SterlingPlayer
	get_tree().root.add_child(player)
	await get_tree().process_frame
	var fast := _spawn_enemy(FAST_SCENE, FAST_DEFINITION, player, false)
	var tank := _spawn_enemy(TANK_SCENE, TANK_DEFINITION, player, false)
	var elite_fast := _spawn_enemy(FAST_SCENE, FAST_DEFINITION, player, true)
	await get_tree().process_frame
	for enemy in [fast, tank, elite_fast]:
		if enemy == null:
			errors.append("E2 could not instantiate an ordinary zombie scene.")
			continue
		if enemy.get_node_or_null(^"Visual/Sprite") == null:
			errors.append("%s did not instantiate its configured raster visual." % enemy.definition.display_name)
		if not enemy.is_in_group(&"auto_aim_target") or not enemy.is_in_group(&"survivor_enemy_targets"):
			errors.append("%s did not satisfy the shared targeting groups." % enemy.definition.display_name)
	if elite_fast != null:
		if not elite_fast.is_elite or elite_fast.get_node_or_null(^"EliteHealthBar") == null:
			errors.append("Elite fast zombie did not create its visible elite presentation.")
		if not is_equal_approx(elite_fast.health_component.maximum_health, FAST_DEFINITION.base_max_health * FAST_DEFINITION.elite_health_multiplier):
			errors.append("Elite fast zombie did not apply definition-driven health scaling.")
		if elite_fast.get_move_speed() <= FAST_DEFINITION.move_speed or elite_fast.get_contact_damage_per_second() <= FAST_DEFINITION.contact_damage_per_second:
			errors.append("Elite fast zombie did not apply boosted stat multipliers.")
	if fast != null and fast.get_node_or_null(^"EliteHealthBar") != null:
		errors.append("Ordinary zombie incorrectly displayed an elite health bar.")

	for enemy in [fast, tank, elite_fast]:
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
	player.queue_free()
	await get_tree().process_frame
	if errors.is_empty():
		print("E2 ENEMY ROSTER TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("E2 ENEMY ROSTER TEST: " + error_text)
	get_tree().quit(1)


func _spawn_enemy(scene: PackedScene, definition: EnemyDefinition, player: SterlingPlayer, elite_variant: bool) -> ZombieEnemy:
	var enemy := scene.instantiate() as ZombieEnemy
	if enemy == null:
		return null
	enemy.configure(definition, elite_variant)
	enemy.set_target(player, player.health_component, 16.0)
	enemy.global_position = player.global_position + Vector2(240.0, 0.0)
	get_tree().root.add_child(enemy)
	return enemy
