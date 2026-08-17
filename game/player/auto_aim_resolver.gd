class_name AutoAimResolver
extends RefCounted

## Enemy runtimes opt into this group when they are valid targets for automatic
## basics. Keeping the lookup here makes it reusable by later character basics
## without coupling this player to a particular enemy script.
const TARGET_GROUP: StringName = &"auto_aim_target"


static func choose_target(
		origin: Vector2,
		candidates: Array[Node],
		current_target: Variant,
		maximum_range: float,
		switch_distance_ratio: float
	) -> Node2D:
	var maximum_range_squared := maximum_range * maximum_range
	var nearest_target: Node2D
	var nearest_distance_squared := INF
	for candidate in candidates:
		if candidate == null or not is_instance_valid(candidate):
			continue
		var target := candidate as Node2D
		if not _is_valid_target(target):
			continue
		var distance_squared := origin.distance_squared_to(target.global_position)
		if distance_squared > maximum_range_squared or distance_squared >= nearest_distance_squared:
			continue
		nearest_target = target
		nearest_distance_squared = distance_squared

	if nearest_target == null:
		return null
	var valid_current_target: Node2D
	if current_target != null and is_instance_valid(current_target):
		valid_current_target = current_target as Node2D
	if not _is_valid_target(valid_current_target):
		return nearest_target

	var current_distance_squared := origin.distance_squared_to(valid_current_target.global_position)
	if current_distance_squared > maximum_range_squared:
		return nearest_target
	if nearest_target == valid_current_target:
		return valid_current_target

	## A challenger must be materially closer before changing target. This small
	## hysteresis prevents rapid visual aim flicker in similarly close hordes.
	var ratio := clampf(switch_distance_ratio, 0.05, 1.0)
	if nearest_distance_squared <= current_distance_squared * ratio * ratio:
		return nearest_target
	return valid_current_target


static func _is_valid_target(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return false
	if target.has_method("is_auto_aim_target") and not target.is_auto_aim_target():
		return false
	var health := target.get_node_or_null("HealthComponent") as HealthComponent
	return health == null or health.is_alive()
