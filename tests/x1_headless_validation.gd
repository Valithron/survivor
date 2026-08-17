extends Node

const STERLING: CharacterDefinition = preload("res://data/characters/sterling.tres")
const PROTOTYPE_PROFILE: RunProfile = preload("res://data/run_profiles/prototype_5_min.tres")


func _ready() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	var world := Node2D.new()
	world.name = "X1ValidationWorld"
	get_tree().root.add_child(world)
	var player_anchor := Node2D.new()
	world.add_child(player_anchor)

	var inventory := WeaponInventory.new()
	world.add_child(inventory)
	var progression := ProgressionController.new()
	world.add_child(progression)
	await get_tree().process_frame

	var progression_data := _make_progression_data()
	var weapon_pool := _make_weapon_pool(6)
	errors.append_array(progression_data.validate_contract())
	for weapon in weapon_pool:
		errors.append_array(weapon.validate_contract())
	inventory.configure_runtime(player_anchor, world)
	progression.configure(progression_data, weapon_pool, inventory)
	progression.set_pickup_target(player_anchor, world)
	progression.set_choice_seed(7)

	RunController.reset_to_idle()
	if not RunController.begin_run(STERLING, PROTOTYPE_PROFILE):
		errors.append("Could not start RunController for X1 validation.")

	## A level-up must pause, expose exactly three legal options, and stay stable
	## until one is selected. With six entries these first cards should be unique.
	progression.collect_xp(XpAward.new(null, 5, Vector2.ZERO))
	var choices := progression.get_current_choices()
	if RunController.state != RunController.RunState.UPGRADE_PAUSED:
		errors.append("Level-up did not enter RunController UPGRADE_PAUSED.")
	if choices.size() != 3:
		errors.append("Level-up did not produce exactly three choices.")
	var first_choice_ids: Dictionary = {}
	for choice in choices:
		if choice == null or not choice.is_valid_shape() or not inventory.can_acquire(choice.weapon):
			errors.append("Initial level-up contained an invalid acquisition choice.")
			continue
		first_choice_ids[choice.weapon.weapon_id] = true
	if first_choice_ids.size() != 3:
		errors.append("A six-weapon pool should produce three distinct initial choices.")
	if not progression.select_upgrade(0):
		errors.append("A valid upgrade choice could not be selected.")
	if RunController.state != RunController.RunState.RUNNING:
		errors.append("RunController did not resume after a valid upgrade selection.")
	if inventory.equipped_count() != 1 or inventory.get_current_rank(choices[0].weapon) != 1:
		errors.append("Selection did not acquire the chosen weapon at Rank 1.")
	if not progression.get_current_choices().is_empty():
		errors.append("Selected level-up choices were retained as a hidden reroll state.")

	## XP from a spatial award should exist as a pickup, then be collected by the
	## target rather than added when the enemy event is first received.
	var previous_xp := progression.total_xp
	if not progression.receive_xp_award(XpAward.new(null, 1, Vector2(5, 0))):
		errors.append("Progression rejected a valid XP award.")
	if progression.active_pickup_count() != 1:
		errors.append("XP award did not create a collectable XP pickup.")
	await get_tree().process_frame
	await get_tree().process_frame
	if progression.total_xp != previous_xp + 1:
		errors.append("XP pickup did not collect into progression state.")

	## Four equipped weapons may only offer upgrades to those weapons. Rank 5 is
	## terminal and a fifth acquisition or Rank 6 must never be accepted.
	progression.reset_progression(true)
	for index in range(4):
		if not inventory.apply_choice(WeaponUpgradeChoice.new(weapon_pool[index], 1)):
			errors.append("Could not acquire fixture weapon %d." % index)
	for index in range(4):
		for target_rank in range(2, WeaponDefinition.MAX_RANK):
			if not inventory.apply_choice(WeaponUpgradeChoice.new(weapon_pool[index], target_rank)):
				errors.append("Could not rank fixture weapon %d to Rank %d." % [index, target_rank])
	var full_choices := UpgradeChoiceGenerator.new().generate(inventory, weapon_pool)
	if full_choices.size() != 3:
		errors.append("Full loadout did not still produce exactly three upgrade choices.")
	for choice in full_choices:
		if not inventory.is_equipped(choice.weapon) or choice.target_rank != 5:
			errors.append("Full loadout offered an unowned weapon or wrong next rank.")
	if inventory.apply_choice(WeaponUpgradeChoice.new(weapon_pool[4], 1)):
		errors.append("Inventory accepted an illegal fifth shared weapon.")
	for index in range(4):
		if not inventory.apply_choice(WeaponUpgradeChoice.new(weapon_pool[index], 5)):
			errors.append("Could not apply Rank 5 for fixture weapon %d." % index)
		if inventory.can_rank_up(weapon_pool[index]):
			errors.append("Rank 5 weapon reported that it could still rank up.")
		if inventory.apply_choice(WeaponUpgradeChoice.new(weapon_pool[index], 6)):
			errors.append("Inventory accepted illegal Rank 6.")

	var terminal_levels: Array[int] = []
	progression.level_advanced_without_upgrade.connect(func(level: int) -> void: terminal_levels.append(level))
	RunController.reset_to_idle()
	RunController.begin_run(STERLING, PROTOTYPE_PROFILE)
	progression.reset_progression(false)
	progression.collect_xp(XpAward.new(null, 5, Vector2.ZERO))
	if terminal_levels.is_empty():
		errors.append("All-Rank-5 loadout did not advance without an illegal upgrade card.")
	if RunController.state != RunController.RunState.RUNNING:
		errors.append("All-Rank-5 loadout left the run paused without a legal choice.")

	RunController.reset_to_idle()
	world.queue_free()
	if errors.is_empty():
		print("X1 PROGRESSION TEST: PASS")
		get_tree().quit(0)
	else:
		for error_text in errors:
			printerr("X1 PROGRESSION TEST: " + error_text)
		get_tree().quit(1)


func _make_progression_data() -> ProgressionDefinition:
	var data := ProgressionDefinition.new()
	data.level_up_total_xp_thresholds = PackedInt32Array([5, 10, 20])
	data.overflow_threshold_step = 20
	data.xp_attraction_radius = 64.0
	data.xp_attraction_speed = 2000.0
	data.xp_collect_radius = 18.0
	return data


func _make_weapon_pool(count: int) -> Array[WeaponDefinition]:
	var pool: Array[WeaponDefinition] = []
	for index in range(count):
		var weapon := WeaponDefinition.new()
		weapon.weapon_id = StringName("validation_weapon_%d" % index)
		weapon.display_name = "Validation Weapon %d" % index
		for rank in range(1, WeaponDefinition.MAX_RANK + 1):
			var rank_data := WeaponRankDefinition.new()
			rank_data.rank = rank
			rank_data.summary = "Validation Rank %d" % rank
			weapon.ranks.append(rank_data)
		pool.append(weapon)
	return pool
