extends Node
const LIGHTNING: WeaponDefinition = preload("res://data/weapons/chain_lightning.tres")
const GRENADES: WeaponDefinition = preload("res://data/weapons/grenade_launcher.tres")
class TargetDummy extends Node2D:
	var events: Array[DamageEvent] = []
	func _ready() -> void: add_to_group(WeaponTargeting.ENEMY_TARGET_GROUP)
	func receive_damage(event: DamageEvent) -> float:
		events.append(event)
		return event.amount
func _ready() -> void: call_deferred("_run_validation")
func _run_validation() -> void:
	var errors: Array[String] = []
	errors.append_array(LIGHTNING.validate_contract())
	errors.append_array(GRENADES.validate_contract())
	var world := Node2D.new(); get_tree().root.add_child(world)
	var player := Node2D.new(); world.add_child(player)
	var targets: Array[TargetDummy] = []
	for position_x in [110.0, 190.0, 270.0, 350.0]:
		var target := TargetDummy.new(); target.position = Vector2(position_x, 0.0); world.add_child(target); targets.append(target)
	var inventory := WeaponInventory.new(); world.add_child(inventory)
	await get_tree().process_frame
	inventory.configure_runtime(player, world)
	if not inventory.apply_choice(WeaponUpgradeChoice.new(LIGHTNING, 1)): errors.append("Chain Lightning acquisition failed.")
	var lightning_entry := _entry_for(inventory, LIGHTNING)
	if lightning_entry == null or not (lightning_entry.runtime is ChainLightningRuntime):
		errors.append("Chain Lightning did not instantiate its runtime.")
	else:
		var lightning := lightning_entry.runtime as ChainLightningRuntime
		if not lightning.force_attack() or not _has_tag(targets, &"shared_weapon_chain_lightning"):
			errors.append("Chain Lightning did not chain shared DamageEvents across nearby targets.")
		for rank in range(2, 6): inventory.apply_choice(WeaponUpgradeChoice.new(LIGHTNING, rank))
		if int(LIGHTNING.get_rank_definition(5).tuning.get("chain_volley_count", 0)) < 2 or int(LIGHTNING.get_rank_definition(5).tuning.get("chain_count", 0)) < 7:
			errors.append("Chain Lightning Rank 5 lacks its forked-chain capstone.")
	if not inventory.apply_choice(WeaponUpgradeChoice.new(GRENADES, 1)): errors.append("Grenade Launcher acquisition failed.")
	var grenade_entry := _entry_for(inventory, GRENADES)
	if grenade_entry == null or not (grenade_entry.runtime is GrenadeLauncherRuntime):
		errors.append("Grenade Launcher did not instantiate its runtime.")
	else:
		var grenades := grenade_entry.runtime as GrenadeLauncherRuntime
		if not grenades.force_attack(): errors.append("Grenade Launcher could not launch at a target.")
		await get_tree().create_timer(0.5).timeout
		if not _has_tag(targets, &"shared_weapon_grenade_launcher"):
			errors.append("Grenade Launcher landing did not apply local explosion damage.")
		for rank in range(2, 6): inventory.apply_choice(WeaponUpgradeChoice.new(GRENADES, rank))
		if int(GRENADES.get_rank_definition(5).tuning.get("grenade_count", 0)) < 3:
			errors.append("Grenade Launcher Rank 5 lacks its triple-barrage capstone.")
	inventory.reset_loadout()
	world.queue_free()
	if errors.is_empty():
		print("W2 WEAPON TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("W2 WEAPON TEST: " + error_text)
	get_tree().quit(1)
func _entry_for(inventory: WeaponInventory, definition: WeaponDefinition) -> WeaponLoadoutEntry:
	for entry in inventory.get_entries():
		if entry.definition == definition: return entry
	return null
func _has_tag(targets: Array[TargetDummy], tag: StringName) -> bool:
	for target in targets:
		for event in target.events:
			if event.tag == tag: return true
	return false
