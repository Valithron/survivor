class_name ShoppingCenterArena
extends Node2D

## M1 presentation + collision layout. The generated texture carries the
## environmental read; these few collision boxes only back the visible larger
## parking-lot props and perimeter, preserving broad horde movement lanes.
signal health_pickup_collected(pickup: HealthPickup, healed_amount: float)
signal guaranteed_health_pickup_spawned(pickup: HealthPickup)

@export var definition: ArenaDefinition

var _pickups: Array[HealthPickup] = []
var _pickup_target: Node2D
var _pickup_health: HealthComponent


func _ready() -> void:
	if definition == null:
		push_error("ShoppingCenterArena requires an ArenaDefinition.")
		return
	_add_boundary_colliders()
	_add_visible_prop_colliders()


func configure_pickups(target: Node2D, health_component: HealthComponent) -> void:
	_pickup_target = target
	_pickup_health = health_component
	for pickup in _pickups:
		if is_instance_valid(pickup):
			pickup.configure(target, health_component, definition.health_pickup_heal_amount, definition.health_pickup_respawn_seconds, definition.health_pickup_collect_radius)
	if _pickups.is_empty():
		for pickup_position in definition.health_pickup_positions:
			_create_pickup(pickup_position)


func clamp_to_playable_area(world_position: Vector2) -> Vector2:
	var inset := definition.boundary_inset
	return Vector2(
		clampf(world_position.x, inset, definition.arena_size.x - inset),
		clampf(world_position.y, inset, definition.arena_size.y - inset),
	)


func spawn_guaranteed_health_pickup_near(target: Node2D) -> HealthPickup:
	if definition == null or not is_instance_valid(target):
		return null
	var desired := clamp_to_playable_area(target.global_position + Vector2(1.0, -0.35).normalized() * definition.guaranteed_pickup_distance)
	var pickup := _create_pickup(desired)
	pickup.force_available()
	guaranteed_health_pickup_spawned.emit(pickup)
	return pickup


func get_pickups() -> Array[HealthPickup]:
	var valid_pickups: Array[HealthPickup] = []
	for pickup in _pickups:
		if is_instance_valid(pickup):
			valid_pickups.append(pickup)
	_pickups = valid_pickups
	return _pickups.duplicate()


func _create_pickup(world_position: Vector2) -> HealthPickup:
	var pickup := HealthPickup.new()
	pickup.name = "HealthPickup%d" % _pickups.size()
	pickup.global_position = clamp_to_playable_area(world_position)
	add_child(pickup)
	pickup.configure(_pickup_target, _pickup_health, definition.health_pickup_heal_amount, definition.health_pickup_respawn_seconds, definition.health_pickup_collect_radius)
	pickup.collected.connect(_on_pickup_collected)
	_pickups.append(pickup)
	return pickup


func _on_pickup_collected(pickup: HealthPickup, healed_amount: float) -> void:
	health_pickup_collected.emit(pickup, healed_amount)


func _add_boundary_colliders() -> void:
	var size := definition.arena_size
	var thickness := 48.0
	_add_static_box(Vector2(size.x * 0.5, -thickness * 0.5), Vector2(size.x + thickness * 2.0, thickness))
	_add_static_box(Vector2(size.x * 0.5, size.y + thickness * 0.5), Vector2(size.x + thickness * 2.0, thickness))
	_add_static_box(Vector2(-thickness * 0.5, size.y * 0.5), Vector2(thickness, size.y))
	_add_static_box(Vector2(size.x + thickness * 0.5, size.y * 0.5), Vector2(thickness, size.y))


func _add_visible_prop_colliders() -> void:
	## Cars, cart-return shelters, and islands sit at the lot's outskirts. The
	## center remains deliberately clear for the documented horde pressure.
	for prop in [
		[Vector2(480.0, 630.0), Vector2(150.0, 86.0)],
		[Vector2(2050.0, 730.0), Vector2(150.0, 86.0)],
		[Vector2(500.0, 1720.0), Vector2(140.0, 84.0)],
		[Vector2(2100.0, 1960.0), Vector2(150.0, 86.0)],
		[Vector2(2050.0, 1420.0), Vector2(220.0, 100.0)],
		[Vector2(350.0, 1320.0), Vector2(120.0, 120.0)],
		[Vector2(1880.0, 480.0), Vector2(105.0, 105.0)],
	]:
		_add_static_box(prop[0], prop[1])


func _add_static_box(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 8
	body.collision_mask = 0
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
