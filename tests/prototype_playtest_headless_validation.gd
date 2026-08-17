extends Node

const PLAYTEST_SCENE: PackedScene = preload("res://tests/prototype_playtest.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_validate_playtest")


func _validate_playtest() -> void:
	var errors: Array[String] = []
	var playtest := PLAYTEST_SCENE.instantiate()
	get_tree().root.add_child(playtest)
	await get_tree().process_frame

	var player := playtest.get_node(^"World/PlayerAnchor/Player") as SterlingPlayer
	var progression := playtest.get_node(^"World/ProgressionController") as ProgressionController
	var inventory := playtest.get_node(^"World/WeaponInventory") as WeaponInventory
	var spawner := playtest.get_node(^"World/EnemySpawner") as EnemySpawner
	if player == null or progression == null or inventory == null or spawner == null:
		printerr("PROTOTYPE INTEGRATION TEST: Playtest scene is missing a required runtime node.")
		get_tree().quit(1)
		return

	## Drive the assembled P1 -> E1 -> XP event -> X1 -> W0 path through public
	## runtime interfaces. P1's independent test covers the auto-aim heuristic;
	## this keeps cross-branch validation deterministic.
	var focus_enemy := spawner.spawn_enemy_at(player.global_position + Vector2(-110.0, 0.0))
	if focus_enemy == null:
		errors.append("Integrated EnemySpawner could not create a focus target.")
	else:
		player.set_manual_aim_enabled(true)
		player.set_manual_aim_direction(Vector2.LEFT)
		player.fire_basic_once_for_test()
		## The swarm zombie keeps its real death frame on screen briefly before
		## freeing, so wait through that visual duration before asserting removal.
		for _frame in range(32):
			await get_tree().physics_frame
		if is_instance_valid(focus_enemy):
			errors.append("Sterling's pistol did not defeat a nearby swarm zombie in the assembled build.")

	## The first kill gives one collectable XP. The remaining temporary test XP is
	## awarded through the same shared event source used by E1.
	GameplayEvents.award_xp(XpAward.new(self, 14, player.global_position))
	for _frame in range(18):
		await get_tree().process_frame
	if progression.total_xp < 15:
		errors.append("Enemy/XP events did not collect into the integrated progression state.")
	if RunController.state != RunController.RunState.UPGRADE_PAUSED:
		errors.append("Integrated level-up did not fully pause the gameplay tree.")
	elif not progression.select_upgrade(0):
		errors.append("Integrated upgrade flow rejected a generated legal choice.")

	await get_tree().process_frame
	if RunController.state != RunController.RunState.RUNNING:
		errors.append("Integrated run did not resume after selecting an upgrade.")
	if inventory.equipped_count() != 1:
		errors.append("Integrated choice did not acquire a W0 weapon through WeaponInventory.")
	elif inventory.get_entries()[0].runtime == null:
		errors.append("Integrated weapon acquisition did not create its shared runtime.")

	playtest.queue_free()
	await get_tree().process_frame
	if errors.is_empty():
		print("PROTOTYPE INTEGRATION TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("PROTOTYPE INTEGRATION TEST: " + error_text)
	get_tree().quit(1)
