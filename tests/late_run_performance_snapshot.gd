extends Node

## This is an instrumentation smoke test, not a hardware-specific frame-rate
## gate. It exercises the actual late-run composition (all active caps, a boss,
## Sterling's basic attack, and a four-weapon Rank 5 loadout) and prints CPU
## monitor samples for comparison on the intended Windows hardware.
const PLAYTEST_SCENE: PackedScene = preload("res://tests/prototype_playtest.tscn")
const AUTO_TURRET: WeaponDefinition = preload("res://data/weapons/auto_turret.tres")
const MOLOTOV: WeaponDefinition = preload("res://data/weapons/molotov.tres")
const CHAIN_LIGHTNING: WeaponDefinition = preload("res://data/weapons/chain_lightning.tres")
const GRENADE_LAUNCHER: WeaponDefinition = preload("res://data/weapons/grenade_launcher.tres")
const SAMPLE_FRAME_COUNT := 90


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_capture_snapshot")


func _capture_snapshot() -> void:
	var errors: Array[String] = []
	var playtest := PLAYTEST_SCENE.instantiate() as PrototypePlaytest
	get_tree().root.add_child(playtest)
	await get_tree().process_frame
	var swarm := playtest.get_node_or_null(^"World/EnemySpawner") as EnemySpawner
	var fast := playtest.get_node_or_null(^"World/FastSpawner") as EnemySpawner
	var tank := playtest.get_node_or_null(^"World/TankSpawner") as EnemySpawner
	var inventory := playtest.get_node_or_null(^"World/WeaponInventory") as WeaponInventory
	if swarm == null or fast == null or tank == null or inventory == null:
		errors.append("Performance snapshot is missing a required First Playable combat node.")
	else:
		RunController.set_elapsed_seconds(720.0)
		await get_tree().process_frame
		await get_tree().process_frame
		for spawner in [swarm, fast, tank]:
			_fill_spawner_to_active_cap(spawner)
		_equip_rank_five_loadout(inventory, [AUTO_TURRET, MOLOTOV, CHAIN_LIGHTNING, GRENADE_LAUNCHER], errors)
		await get_tree().process_frame
		var boss := playtest.get_node_or_null(^"World/MutantBoss") as MutantBoss
		var expected_enemy_count := (
			swarm.spawn_configuration.maximum_active_enemies
			+ fast.spawn_configuration.maximum_active_enemies
			+ tank.spawn_configuration.maximum_active_enemies
		)
		var active_enemy_count := swarm.get_active_enemy_count() + fast.get_active_enemy_count() + tank.get_active_enemy_count()
		if boss == null:
			errors.append("Performance snapshot did not instantiate the late-run boss.")
		if active_enemy_count != expected_enemy_count:
			errors.append("Performance snapshot expected %d enemies but found %d." % [expected_enemy_count, active_enemy_count])
		if inventory.get_entries().size() != WeaponInventory.MAX_SHARED_WEAPON_SLOTS:
			errors.append("Performance snapshot did not equip its four-weapon loadout.")
		var process_samples: Array[float] = []
		var physics_samples: Array[float] = []
		for _frame in SAMPLE_FRAME_COUNT:
			await get_tree().process_frame
			process_samples.append(Performance.get_monitor(Performance.TIME_PROCESS))
			physics_samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
		print("LATE RUN PERFORMANCE SNAPSHOT // enemies %d/%d // boss %s // nodes %d // process %.3fms avg %.3fms peak // physics %.3fms avg %.3fms peak" % [
			active_enemy_count,
			expected_enemy_count,
			"present" if boss != null else "missing",
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			_average(process_samples),
			_peak(process_samples),
			_average(physics_samples),
			_peak(physics_samples),
		])
	playtest.queue_free()
	await get_tree().process_frame
	if errors.is_empty():
		print("LATE RUN PERFORMANCE SMOKE TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("LATE RUN PERFORMANCE SMOKE TEST: " + error_text)
	get_tree().quit(1)


func _fill_spawner_to_active_cap(spawner: EnemySpawner) -> void:
	while spawner.get_active_enemy_count() < spawner.spawn_configuration.maximum_active_enemies:
		spawner.spawn_burst(spawner.spawn_configuration.enemies_per_batch)


func _equip_rank_five_loadout(inventory: WeaponInventory, definitions: Array[WeaponDefinition], errors: Array[String]) -> void:
	for definition in definitions:
		for rank in range(1, 6):
			if not inventory.apply_choice(WeaponUpgradeChoice.new(definition, rank)):
				errors.append("Performance snapshot could not apply %s Rank %d." % [definition.display_name, rank])


func _average(samples: Array[float]) -> float:
	if samples.is_empty():
		return 0.0
	var total := 0.0
	for sample in samples:
		total += sample
	return total / samples.size()


func _peak(samples: Array[float]) -> float:
	var highest := 0.0
	for sample in samples:
		highest = maxf(highest, sample)
	return highest
