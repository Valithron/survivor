extends Node

const KNIVES: WeaponDefinition = preload("res://data/weapons/throwing_knives.tres")
const TURRET: WeaponDefinition = preload("res://data/weapons/auto_turret.tres")


class TargetDummy extends Area2D:
	var received_events: Array[DamageEvent] = []

	func _ready() -> void:
		collision_layer = 2
		add_to_group(WeaponTargeting.ENEMY_TARGET_GROUP)
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 16.0
		collision.shape = shape
		add_child(collision)

	func receive_damage(event: DamageEvent) -> float:
		received_events.append(event)
		return event.amount


func _ready() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	errors.append_array(KNIVES.validate_contract())
	errors.append_array(TURRET.validate_contract())
	var world := Node2D.new()
	get_tree().root.add_child(world)
	var player := Node2D.new()
	world.add_child(player)
	var target := TargetDummy.new()
	target.position = Vector2(120.0, 0.0)
	world.add_child(target)
	var inventory := WeaponInventory.new()
	world.add_child(inventory)
	await get_tree().process_frame
	inventory.configure_runtime(player, world)

	if not inventory.apply_choice(WeaponUpgradeChoice.new(KNIVES, 1)):
		errors.append("Throwing Knives could not be acquired through WeaponInventory.")
	var knives_entry := _entry_for(inventory, KNIVES)
	if knives_entry == null or not (knives_entry.runtime is ThrowingKnivesRuntime):
		errors.append("Throwing Knives did not instantiate its shared runtime scene.")
	else:
		var knives := knives_entry.runtime as ThrowingKnivesRuntime
		var volleys: Array[int] = []
		knives.volley_fired.connect(func(_origin: Vector2, _direction: Vector2, projectile_count: int) -> void: volleys.append(projectile_count))
		var hits_before := target.received_events.size()
		if not knives.force_attack():
			errors.append("Throwing Knives could not fire at a valid nearby target.")
		for _frame in range(15):
			await get_tree().physics_frame
		if target.received_events.size() <= hits_before or not _has_damage_tag(target.received_events, &"shared_weapon_throwing_knives"):
			errors.append("Throwing Knives did not deliver shared projectile DamageEvents.")
		for rank in range(2, WeaponDefinition.MAX_RANK + 1):
			if not inventory.apply_choice(WeaponUpgradeChoice.new(KNIVES, rank)):
				errors.append("Throwing Knives could not apply Rank %d." % rank)
		if not knives.force_attack() or volleys.is_empty() or volleys.back() != 5:
			errors.append("Throwing Knives Rank 5 did not produce its five-knife capstone volley.")
		elif int(KNIVES.get_rank_definition(5).tuning.get("pierce_count", 0)) < 3:
			errors.append("Throwing Knives Rank 5 lacks its piercing capstone.")

	if not inventory.apply_choice(WeaponUpgradeChoice.new(TURRET, 1)):
		errors.append("Auto-Turret could not be acquired through WeaponInventory.")
	var turret_entry := _entry_for(inventory, TURRET)
	if turret_entry == null or not (turret_entry.runtime is AutoTurretRuntime):
		errors.append("Auto-Turret did not instantiate its shared runtime scene.")
	else:
		var turret_runtime := turret_entry.runtime as AutoTurretRuntime
		var deployed: Array[AutoTurret] = []
		turret_runtime.turret_deployed.connect(func(turret: AutoTurret) -> void: deployed.append(turret))
		if not turret_runtime.force_deploy():
			errors.append("Auto-Turret could not deploy its first autonomous sentry.")
		await get_tree().process_frame
		if not deployed.is_empty():
			var turret_sprite := _first_sprite(deployed[0])
			if turret_sprite == null or turret_sprite.texture == null or turret_sprite.texture.get_size() != Vector2(64, 64):
				errors.append("Auto-Turret did not instantiate its 64px raster presentation sprite.")
		await get_tree().create_timer(1.0).timeout
		if deployed.is_empty():
			errors.append("Auto-Turret did not emit a deployment event.")
		elif not _has_damage_tag(target.received_events, &"shared_weapon_auto_turret"):
			errors.append("Auto-Turret did not autonomously fire through the shared damage seam.")
		for rank in range(2, WeaponDefinition.MAX_RANK + 1):
			if not inventory.apply_choice(WeaponUpgradeChoice.new(TURRET, rank)):
				errors.append("Auto-Turret could not apply Rank %d." % rank)
		if not turret_runtime.force_deploy() or int(TURRET.get_rank_definition(5).tuning.get("capacity", 0)) < 3 or int(TURRET.get_rank_definition(5).tuning.get("shots_per_cycle", 0)) < 2:
			errors.append("Auto-Turret Rank 5 lacks its multi-sentry twin-shot capstone.")

	inventory.reset_loadout()
	await get_tree().process_frame
	if inventory.equipped_count() != 0:
		errors.append("WeaponInventory did not clean up the W1 loadout.")
	world.queue_free()
	if errors.is_empty():
		print("W1 WEAPON TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("W1 WEAPON TEST: " + error_text)
	get_tree().quit(1)


func _entry_for(inventory: WeaponInventory, definition: WeaponDefinition) -> WeaponLoadoutEntry:
	for entry in inventory.get_entries():
		if entry.definition == definition:
			return entry
	return null


func _has_damage_tag(events: Array[DamageEvent], tag: StringName) -> bool:
	for event in events:
		if event.tag == tag:
			return true
	return false


func _first_sprite(node: Node) -> Sprite2D:
	for child in node.get_children():
		if child is Sprite2D:
			return child as Sprite2D
	return null
