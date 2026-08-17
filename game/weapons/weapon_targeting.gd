class_name WeaponTargeting
extends RefCounted

## Narrow cross-branch seam for automatic shared weapons. E1 enemy roots join
## this group and adapt their F0 HealthComponent through receive_damage().
const ENEMY_TARGET_GROUP: StringName = &"survivor_enemy_targets"


static func nearby_targets(source: Node, origin: Vector2, radius: float) -> Array[Node2D]:
	var targets: Array[Node2D] = []
	if source == null or source.get_tree() == null:
		return targets
	var radius_squared := radius * radius
	for candidate in source.get_tree().get_nodes_in_group(ENEMY_TARGET_GROUP):
		if not (candidate is Node2D) or not is_instance_valid(candidate):
			continue
		var target := candidate as Node2D
		if target.global_position.distance_squared_to(origin) <= radius_squared:
			targets.append(target)
	targets.sort_custom(func(left: Node2D, right: Node2D) -> bool:
		return left.global_position.distance_squared_to(origin) < right.global_position.distance_squared_to(origin)
	)
	return targets


static func apply_damage(target: Node, source: Object, amount: float, tag: StringName, knockback: Vector2 = Vector2.ZERO) -> bool:
	if target == null or amount <= 0.0 or not target.has_method(&"receive_damage"):
		return false
	var damage := DamageEvent.new(source, amount, tag, knockback)
	target.call(&"receive_damage", damage)
	return true
