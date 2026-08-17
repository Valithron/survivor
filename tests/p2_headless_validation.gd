extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://game/player/sterling_player.tscn")
const KIT_TUNING: SterlingKitTuning = preload("res://data/characters/sterling_kit_tuning.tres")


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	errors.append_array(KIT_TUNING.validate_contract())
	var player := PLAYER_SCENE.instantiate() as SterlingPlayer
	root.add_child(player)
	await process_frame
	player.set_manual_aim_enabled(true)
	player.set_manual_aim_direction(Vector2.RIGHT)

	var level_one_damage := player.get_effective_basic_damage()
	var level_one_rate := player.get_current_fire_rate()
	player.set_character_level(5)
	if not player.basic_milestone_active:
		errors.append("Level 5 did not activate Sterling's basic milestone.")
	if player.get_effective_basic_damage() <= level_one_damage or player.get_current_fire_rate() <= level_one_rate:
		errors.append("Level 5 did not produce a meaningful automatic basic improvement.")

	player.set_character_level(10)
	var tactical_events: Array[Dictionary] = []
	player.tactical_activated.connect(func(direction: Vector2, start: Vector2, end: Vector2, buff_seconds: float) -> void:
		tactical_events.append({"direction": direction, "start": start, "end": end, "buff_seconds": buff_seconds})
	)
	var tactical_rate_before := player.get_current_fire_rate()
	if not player.try_activate_tactical(Vector2.RIGHT):
		errors.append("Reposition Burst did not activate when ready.")
	elif tactical_events.is_empty():
		errors.append("Reposition Burst did not emit its public activation event.")
	else:
		var event := tactical_events[0]
		var expected_distance := KIT_TUNING.tactical_distance_for(true)
		if (event.end as Vector2).distance_to(event.start + Vector2.RIGHT * expected_distance) > 0.01:
			errors.append("Reposition Burst did not use its Level 10 tunable distance.")
		if player.get_current_fire_rate() <= tactical_rate_before:
			errors.append("Reposition Burst did not grant the documented fire-rate buff.")
	if player.try_activate_tactical(Vector2.RIGHT):
		errors.append("Reposition Burst ignored its cooldown.")

	player.set_character_level(15)
	var radial_bursts: Array[Dictionary] = []
	player.radial_burst_fired.connect(func(projectile_count: int, projectile_damage: float) -> void:
		radial_bursts.append({"count": projectile_count, "damage": projectile_damage})
	)
	if not player.try_activate_ultimate():
		errors.append("Radial Bullet Storm did not activate when ready.")
	if player.try_activate_ultimate():
		errors.append("Radial Bullet Storm ignored its active/cooldown state.")
	var position_before_motion := player.global_position
	Input.action_press(&"move_right")
	for _frame in range(70):
		await physics_frame
	Input.action_release(&"move_right")
	if player.global_position.x <= position_before_motion.x:
		errors.append("Sterling could not continue moving during Radial Bullet Storm.")
	var expected_bursts := KIT_TUNING.ultimate_burst_count_for(true)
	var expected_projectiles := KIT_TUNING.ultimate_projectiles_per_burst_for(true)
	if radial_bursts.size() != expected_bursts:
		errors.append("Radial Bullet Storm emitted %d bursts instead of %d." % [radial_bursts.size(), expected_bursts])
	elif radial_bursts[0].count != expected_projectiles:
		errors.append("Level 15 Radial Bullet Storm did not use its upgraded projectile count.")
	elif radial_bursts[0].damage < KIT_TUNING.ultimate_damage_for(true):
		errors.append("Level 15 Radial Bullet Storm did not use its upgraded projectile damage.")

	player.queue_free()
	await process_frame
	if errors.is_empty():
		print("P2 STERLING KIT TEST: PASS")
		quit(0)
		return
	for error_text in errors:
		printerr("P2 STERLING KIT TEST: " + error_text)
	quit(1)
