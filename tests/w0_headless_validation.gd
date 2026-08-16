extends Node

const KATANA: WeaponDefinition = preload("res://data/weapons/katana.tres")
const MOLOTOV: WeaponDefinition = preload("res://data/weapons/molotov.tres")


class TargetDummy extends Node2D:
	var received_events: Array[DamageEvent] = []

	func _ready() -> void:
		add_to_group(WeaponTargeting.ENEMY_TARGET_GROUP)

	func receive_damage(event: DamageEvent) -> float:
		received_events.append(event)
		return event.amount


func _ready() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	var world := Node2D.new()
	get_tree().root.add_child(world)
	var player := Node2D.new()
	world.add_child(player)
	var target := TargetDummy.new()
	target.position = Vector2(64.0, 0.0)
	world.add_child(target)
	var inventory := WeaponInventory.new()
	world.add_child(inventory)
	await get_tree().process_frame

	errors.append_array(KATANA.validate_contract())
	errors.append_array(MOLOTOV.validate_contract())
	if KATANA.runtime_scene == null or MOLOTOV.runtime_scene == null:
		errors.append("W0 definitions must assign runtime scenes.")
	inventory.configure_runtime(player, world)

	if not inventory.apply_choice(WeaponUpgradeChoice.new(KATANA, 1)):
		errors.append("Katana could not be acquired through WeaponInventory.")
	var katana_entry := inventory.get_entries()[0] if inventory.equipped_count() > 0 else null
	if katana_entry == null or not (katana_entry.runtime is KatanaRuntime):
		errors.append("Katana did not instantiate KatanaRuntime from its resource scene.")
	else:
		var katana := katana_entry.runtime as KatanaRuntime
		var events_before_katana := target.received_events.size()
		if not katana.force_attack():
			errors.append("Katana automatic attack runtime could not fire.")
		if target.received_events.size() <= events_before_katana:
			errors.append("Katana attack did not emit shared DamageEvent through target seam.")
		elif target.received_events.back().tag != &"shared_weapon_katana":
			errors.append("Katana damage event used the wrong tag.")
		await get_tree().process_frame
		var slash_effect := _first_katana_effect(world)
		if slash_effect == null:
			errors.append("Katana attack did not create its presentation effect.")
		else:
			var slash_sprite := _first_sprite(slash_effect)
			if slash_sprite == null or slash_sprite.texture == null:
				errors.append("Katana presentation is missing the production raster Sprite2D.")
			elif slash_sprite.texture.get_size() != Vector2(384.0, 128.0):
				errors.append("Katana production VFX atlas has the wrong raster dimensions.")
		for rank in range(2, WeaponDefinition.MAX_RANK + 1):
			if not inventory.apply_choice(WeaponUpgradeChoice.new(KATANA, rank)):
				errors.append("Katana could not apply Rank %d through shared inventory." % rank)
		if katana.current_rank != WeaponDefinition.MAX_RANK:
			errors.append("Katana runtime did not receive the Rank 5 transition.")
		if int(KATANA.get_rank_definition(5).tuning.get("slash_count", 0)) < 2 or float(KATANA.get_rank_definition(5).tuning.get("arc_degrees", 0.0)) < 359.0:
			errors.append("Katana Rank 5 lacks its tuned twin full-circle capstone.")

	if not inventory.apply_choice(WeaponUpgradeChoice.new(MOLOTOV, 1)):
		errors.append("Molotov could not be acquired through WeaponInventory.")
	var molotov_entry := _entry_for(inventory, MOLOTOV)
	if molotov_entry == null or not (molotov_entry.runtime is MolotovRuntime):
		errors.append("Molotov did not instantiate MolotovRuntime from its resource scene.")
	else:
		var molotov := molotov_entry.runtime as MolotovRuntime
		var fire_patch_positions: Array[Vector2] = []
		molotov.fire_patch_created.connect(func(position: Vector2) -> void: fire_patch_positions.append(position))
		if not molotov.force_attack():
			errors.append("Molotov automatic attack runtime could not target and throw.")
		await get_tree().create_timer(0.35).timeout
		await get_tree().process_frame
		if fire_patch_positions.size() != 1:
			errors.append("Molotov Rank 1 did not create exactly one persistent fire patch.")
		var fire_patch := _first_node_of_type(world, MolotovFirePatch)
		if fire_patch == null or _first_sprite(fire_patch) == null:
			errors.append("Molotov fire patch did not instantiate its raster VFX sprite.")
		if not _has_damage_tag(target.received_events, &"shared_weapon_molotov"):
			errors.append("Molotov fire patch did not emit shared DamageEvent ticks.")
		for rank in range(2, WeaponDefinition.MAX_RANK + 1):
			if not inventory.apply_choice(WeaponUpgradeChoice.new(MOLOTOV, rank)):
				errors.append("Molotov could not apply Rank %d through shared inventory." % rank)
		var patches_before_capstone := fire_patch_positions.size()
		if not molotov.force_attack():
			errors.append("Molotov Rank 5 could not target and throw.")
		await get_tree().create_timer(0.35).timeout
		await get_tree().process_frame
		if fire_patch_positions.size() - patches_before_capstone != 3:
			errors.append("Molotov Rank 5 did not create its three-patch inferno capstone.")
		if not _has_damage_tag(target.received_events, &"shared_weapon_molotov_impact"):
			errors.append("Molotov Rank 5 did not apply its impact capstone damage.")

	inventory.reset_loadout()
	await get_tree().process_frame
	if inventory.equipped_count() != 0:
		errors.append("WeaponInventory did not clean up the run-local W0 loadout.")
	world.queue_free()
	if errors.is_empty():
		print("W0 WEAPON TEST: PASS")
		get_tree().quit(0)
	else:
		for error_text in errors:
			printerr("W0 WEAPON TEST: " + error_text)
		get_tree().quit(1)


func _entry_for(inventory: WeaponInventory, definition: WeaponDefinition) -> WeaponLoadoutEntry:
	for entry in inventory.get_entries():
		if entry.definition == definition:
			return entry
	return null


func _first_katana_effect(parent: Node) -> KatanaSlashEffect:
	for child in parent.get_children():
		if child is KatanaSlashEffect:
			return child as KatanaSlashEffect
	return null


func _first_sprite(parent: Node) -> Sprite2D:
	for child in parent.get_children():
		if child is Sprite2D:
			return child as Sprite2D
	return null


func _has_damage_tag(events: Array[DamageEvent], tag: StringName) -> bool:
	for event in events:
		if event.tag == tag:
			return true
	return false


func _first_node_of_type(root: Node, script_type: Variant) -> Node:
	for child in root.get_children():
		if is_instance_of(child, script_type):
			return child
		var nested := _first_node_of_type(child, script_type)
		if nested != null:
			return nested
	return null

