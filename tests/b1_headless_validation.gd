extends Node

const PLAYTEST_SCENE: PackedScene = preload("res://tests/prototype_playtest.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_validate")


func _validate() -> void:
	var errors: Array[String] = []
	var playtest := PLAYTEST_SCENE.instantiate() as PrototypePlaytest
	get_tree().root.add_child(playtest)
	await get_tree().process_frame
	RunController.set_elapsed_seconds(720.0)
	await get_tree().process_frame
	await get_tree().process_frame

	var boss := playtest.get_node_or_null(^"World/MutantBoss") as MutantBoss
	var arena := playtest.get_node_or_null(^"World/Arena") as ShoppingCenterArena
	var boss_bar := playtest.get_node_or_null(^"CanvasLayer/BossBar") as ColorRect
	var boss_bar_was_visible := boss_bar != null and boss_bar.visible
	if boss == null:
		errors.append("B1 boss-arrival phase did not instantiate the MutantBoss runtime.")
	else:
		if not boss.is_in_group(&"auto_aim_target") or not boss.is_in_group(&"survivor_enemy_targets"):
			errors.append("B1 boss does not participate in the existing player/shared-weapon target contracts.")
		if boss.get_node_or_null(^"Visual") == null:
			errors.append("B1 boss is missing its raster visual integration.")
		var telegraphs: Array[StringName] = []
		boss.attack_telegraph_started.connect(func(attack_id: StringName) -> void: telegraphs.append(attack_id))
		for attack_id in [&"ground_slam", &"arm_sweep", &"mutant_charge"]:
			if not boss.force_attack_for_test(attack_id):
				errors.append("B1 could not begin locked attack %s." % attack_id)
				continue
			await get_tree().process_frame
			var wait_seconds := boss.definition.ground_slam_windup_seconds + 0.08
			if attack_id == &"arm_sweep":
				wait_seconds = boss.definition.sweep_windup_seconds + 0.08
			elif attack_id == &"mutant_charge":
				wait_seconds = boss.definition.charge_windup_seconds + boss.definition.charge_max_seconds + 0.12
			await get_tree().create_timer(wait_seconds).timeout
		for attack_id in [&"ground_slam", &"arm_sweep", &"mutant_charge"]:
			if not telegraphs.has(attack_id):
				errors.append("B1 attack %s did not publish a telegraph before resolving." % attack_id)
		boss.apply_damage_event(DamageEvent.new(self, boss.health_component.current_health + 1.0, &"b1_test_kill"))
		await get_tree().process_frame
		if RunController.state != RunController.RunState.ENDED:
			errors.append("B1 boss death did not finish the run in victory.")
	if arena == null or arena.get_pickups().size() < 5:
		errors.append("B1 boss arrival did not create its guaranteed nearby medical pickup.")
	var swarm := playtest.get_node_or_null(^"World/EnemySpawner") as EnemySpawner
	var fast := playtest.get_node_or_null(^"World/FastSpawner") as EnemySpawner
	var tank := playtest.get_node_or_null(^"World/TankSpawner") as EnemySpawner
	if swarm == null or fast == null or tank == null or swarm.get_spawn_intensity() <= 0.0 or fast.get_spawn_intensity() <= 0.0 or tank.get_spawn_intensity() <= 0.0:
		errors.append("B1 boss phase did not retain full late-game three-archetype spawn pressure.")
	if not boss_bar_was_visible:
		errors.append("B1 boss health-bar treatment was not shown on arrival.")

	playtest.queue_free()
	await get_tree().process_frame
	if errors.is_empty():
		print("B1 BOSS TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("B1 BOSS TEST: " + error_text)
	get_tree().quit(1)
