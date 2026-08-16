extends Node

const ARENA_SCENE: PackedScene = preload("res://game/arena/shopping_center_arena.tscn")


func _ready() -> void:
	call_deferred("_validate")


func _validate() -> void:
	var errors: Array[String] = []
	var target := Node2D.new()
	var health := HealthComponent.new()
	health.maximum_health = 100.0
	target.add_child(health)
	get_tree().root.add_child(target)
	await get_tree().process_frame
	health.configure(100.0)
	health.apply_damage(DamageEvent.new(self, 64.0, &"m1_test"))

	var arena := ARENA_SCENE.instantiate() as ShoppingCenterArena
	get_tree().root.add_child(arena)
	await get_tree().process_frame
	arena.configure_pickups(target, health)
	var pickups := arena.get_pickups()
	if pickups.size() != 4:
		errors.append("M1 arena did not create every fixed health-pickup location.")
	if arena.get_node_or_null("ParkingLotBackground") == null:
		errors.append("M1 arena is missing its raster shopping-center background.")
	else:
		var background := arena.get_node("ParkingLotBackground") as Sprite2D
		if background.texture == null or background.texture.get_size() != arena.definition.arena_size:
			errors.append("M1 arena background is not baked to the exact playable-world texture size.")
		if background.scale != Vector2.ONE:
			errors.append("M1 arena background reintroduced runtime texture scaling that can expose backdrop seams.")
	if arena.get_children().filter(func(node: Node) -> bool: return node is StaticBody2D).size() < 10:
		errors.append("M1 arena is missing its perimeter/parking-lot obstacle collision bodies.")
	if not pickups.is_empty():
		var pickup := pickups[0]
		pickup.respawn_seconds = 0.12
		target.global_position = pickup.global_position
		await get_tree().process_frame
		if pickup.is_available():
			errors.append("M1 health pickup did not consume when the damaged player entered its fixed location.")
		if health.current_health <= 36.0:
			errors.append("M1 health pickup did not heal the damaged player.")
		await get_tree().create_timer(0.35).timeout
		await get_tree().process_frame
		if not pickup.is_available():
			errors.append("M1 health pickup did not respawn after its configured delay.")
	var guaranteed := arena.spawn_guaranteed_health_pickup_near(target)
	if guaranteed == null or not guaranteed.is_available() or guaranteed.global_position.distance_to(target.global_position) <= 1.0:
		errors.append("M1 could not produce a readable nearby boss-arrival health pickup.")
	if arena.clamp_to_playable_area(Vector2(-50.0, 9000.0)).x < arena.definition.boundary_inset:
		errors.append("M1 arena bounds do not clamp world positions into the playable lot.")

	arena.queue_free()
	target.queue_free()
	await get_tree().process_frame
	if errors.is_empty():
		print("M1 ARENA / HEALING TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("M1 ARENA / HEALING TEST: " + error_text)
	get_tree().quit(1)
