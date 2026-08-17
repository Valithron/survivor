extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://game/player/sterling_player.tscn")
const TARGET_DUMMY_SCENE: PackedScene = preload("res://tests/p1_target_dummy.tscn")
const TUNING: SterlingBasicTuning = preload("res://data/characters/sterling_basic_tuning.tres")


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	errors.append_array(TUNING.validate_contract())

	var player := PLAYER_SCENE.instantiate() as SterlingPlayer
	root.add_child(player)
	await process_frame
	if not is_equal_approx(player.health_component.maximum_health, player.character_definition.base_max_health):
		errors.append("SterlingPlayer did not configure HealthComponent from CharacterDefinition.")

	player.set_manual_aim_enabled(true)
	player.set_manual_aim_direction(Vector2.UP)
	if player.get_basic_aim_direction().distance_to(Vector2.UP) > 0.001:
		errors.append("Manual Aim did not accept the supplied mouse-direction equivalent.")

	var shots: Array[Dictionary] = []
	player.basic_fired.connect(func(direction: Vector2, _position: Vector2, muzzle_side: int, fire_rate: float) -> void:
		shots.append({"direction": direction, "side": muzzle_side, "rate": fire_rate})
	)
	player.fire_basic_once_for_test()
	player.fire_basic_once_for_test()
	if shots.size() != 2 or shots[0].side == shots[1].side:
		errors.append("Dual pistols did not emit alternating shots.")
	elif shots[0].direction.distance_to(Vector2.UP) > 0.001:
		errors.append("Manual Aim direction was not used for a pistol shot.")

	player.velocity = Vector2.ZERO
	var idle_rate := player.get_current_fire_rate()
	player.velocity = Vector2.RIGHT * player.character_definition.move_speed * 2.0
	var moving_rate := player.get_current_fire_rate()
	if moving_rate <= idle_rate or moving_rate > TUNING.maximum_shots_per_second:
		errors.append("Movement-to-fire-rate relationship is not increasing and bounded.")

	var health_before := player.health_component.current_health
	player.apply_damage(DamageEvent.new(self, 7.0, &"p1_validation"))
	if not is_equal_approx(player.health_component.current_health, health_before - 7.0):
		errors.append("SterlingPlayer did not delegate DamageEvent to HealthComponent.")

	var damage_target := TARGET_DUMMY_SCENE.instantiate() as P1TargetDummy
	damage_target.global_position = player.global_position + Vector2(110.0, 0.0)
	root.add_child(damage_target)
	await process_frame
	player.set_manual_aim_enabled(true)
	player.set_manual_aim_direction(Vector2.RIGHT)
	var target_health_before := damage_target.health_component.current_health
	player.fire_basic_once_for_test()
	for frame in 10:
		await physics_frame
	if damage_target.health_component.current_health >= target_health_before:
		errors.append("Sterling projectile did not apply DamageEvent through an enemy target interface.")

	var target := Node2D.new()
	target.global_position = player.global_position + Vector2(100.0, 0.0)
	target.add_to_group(AutoAimResolver.TARGET_GROUP)
	root.add_child(target)
	await process_frame
	player.set_manual_aim_enabled(false)
	player._update_aim_solution(1.0)
	if player.get_basic_aim_direction().distance_to(Vector2.RIGHT) > 0.001:
		errors.append("Auto Aim did not choose the closest valid target direction.")

	target.queue_free()
	damage_target.queue_free()
	player.queue_free()
	if errors.is_empty():
		print("P1 PLAYER TEST: PASS")
		quit(0)
	else:
		for error_text in errors:
			printerr("P1 PLAYER TEST: " + error_text)
		quit(1)
