extends Node

const PLAYTEST_SCENE: PackedScene = preload("res://tests/prototype_playtest.tscn")
const PROFILE: RunProfile = preload("res://data/run_profiles/first_playable_12_min.tres")


func _ready() -> void:
	call_deferred("_validate")


func _validate() -> void:
	var errors: Array[String] = []
	errors.append_array(PROFILE.validate_contract())
	var expected_times := [150.0, 300.0, 450.0, 600.0, 720.0]
	if PROFILE.scheduled_phases.size() != expected_times.size():
		errors.append("R1 profile does not define all five locked phase markers.")
	else:
		for index in range(expected_times.size()):
			if not is_equal_approx(PROFILE.scheduled_phases[index].at_seconds, expected_times[index]):
				errors.append("R1 phase %d has the wrong locked schedule time." % index)

	var playtest := PLAYTEST_SCENE.instantiate()
	get_tree().root.add_child(playtest)
	await get_tree().process_frame
	var director := playtest.get_node(^"World/RunDirector") as RunDirector
	var swarm := playtest.get_node(^"World/EnemySpawner") as EnemySpawner
	var fast := playtest.get_node(^"World/FastSpawner") as EnemySpawner
	var tank := playtest.get_node(^"World/TankSpawner") as EnemySpawner
	if director == null or swarm == null or fast == null or tank == null:
		errors.append("R1 workbench is missing a director or one of the three enemy streams.")
	else:
		var boss_requests: Array[bool] = []
		director.boss_arrival_requested.connect(func() -> void: boss_requests.append(true))
		RunController.set_elapsed_seconds(150.0)
		await get_tree().process_frame
		if swarm.get_spawn_intensity() <= 1.0 or fast.get_spawn_intensity() != 0.0 or tank.get_spawn_intensity() != 0.0:
			errors.append("2:30 swarm surge did not create swarm-only emphasis.")
		RunController.set_elapsed_seconds(300.0)
		await get_tree().process_frame
		if fast.get_spawn_intensity() <= 0.0 or tank.get_spawn_intensity() != 0.0:
			errors.append("5:00 fast surge did not activate fast-zombie pressure.")
		RunController.set_elapsed_seconds(450.0)
		await get_tree().process_frame
		if tank.get_spawn_intensity() <= 0.0:
			errors.append("7:30 tank surge did not activate tank-zombie pressure.")
		RunController.set_elapsed_seconds(600.0)
		await get_tree().process_frame
		if swarm.get_spawn_intensity() <= 0.0 or fast.get_spawn_intensity() <= 0.0 or tank.get_spawn_intensity() <= 0.0:
			errors.append("10:00 combined surge did not keep all archetypes active.")
		RunController.set_elapsed_seconds(720.0)
		await get_tree().process_frame
		if boss_requests.is_empty():
			errors.append("12:00 boss-arrival hook was not emitted while combined horde pressure remained active.")
	playtest.queue_free()
	await get_tree().process_frame
	if errors.is_empty():
		print("R1 RUN DIRECTOR TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("R1 RUN DIRECTOR TEST: " + error_text)
	get_tree().quit(1)
