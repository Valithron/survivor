class_name KatanaRuntime
extends SharedWeaponRuntime

signal attack_performed(origin: Vector2, direction: Vector2, hit_count: int)

var _tuning: Dictionary = {}
var _cooldown_remaining := 0.0
var _effects: Array[KatanaSlashEffect] = []


func _process(delta: float) -> void:
	if current_rank <= 0:
		return
	_cooldown_remaining -= delta
	if _cooldown_remaining <= 0.0:
		_perform_attack()


func force_attack() -> bool:
	## Developer-test hook; normal use is fully automatic through _process().
	return _perform_attack()


func shutdown() -> void:
	for effect in _effects:
		if effect != null and is_instance_valid(effect):
			effect.queue_free()
	_effects.clear()
	super.shutdown()


func _on_rank_applied(rank_definition: WeaponRankDefinition) -> void:
	_tuning = rank_definition.tuning.duplicate(true)
	_cooldown_remaining = minf(_cooldown_remaining, _cooldown())


func _perform_attack() -> bool:
	if current_rank <= 0:
		return false
	_cooldown_remaining = _cooldown()
	var origin := _owner_position()
	var targets := WeaponTargeting.nearby_targets(self, origin, _radius())
	var primary_direction := Vector2.RIGHT
	if not targets.is_empty():
		primary_direction = (targets[0].global_position - origin).normalized()
	if primary_direction.is_zero_approx():
		primary_direction = Vector2.RIGHT
	var total_hits := 0
	var slash_count := maxi(int(_tuning.get("slash_count", 1)), 1)
	for slash_index in range(slash_count):
		var slash_direction := primary_direction.rotated(TAU * float(slash_index) / float(slash_count))
		total_hits += _apply_slash(origin, slash_direction, targets)
		_spawn_effect(origin, slash_direction)
	attack_performed.emit(origin, primary_direction, total_hits)
	return true


func _apply_slash(origin: Vector2, direction: Vector2, targets: Array[Node2D]) -> int:
	var hits := 0
	var arc_limit := deg_to_rad(_arc_degrees() * 0.5)
	var full_circle := _arc_degrees() >= 359.0
	var max_targets := maxi(int(_tuning.get("max_targets", 1)), 1)
	for target in targets:
		if hits >= max_targets:
			break
		var offset := target.global_position - origin
		if offset.is_zero_approx():
			continue
		if not full_circle and absf(direction.angle_to(offset.normalized())) > arc_limit:
			continue
		if WeaponTargeting.apply_damage(target, self, _damage(), &"shared_weapon_katana", direction * _knockback()):
			hits += 1
	return hits


func _spawn_effect(origin: Vector2, direction: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var effect := KatanaSlashEffect.new()
	parent.add_child(effect)
	effect.global_position = origin
	effect.configure(direction, _radius(), _arc_degrees(), 0.16)
	effect.tree_exited.connect(func() -> void: _effects.erase(effect))
	_effects.append(effect)


func _owner_position() -> Vector2:
	if weapon_owner is Node2D:
		return (weapon_owner as Node2D).global_position
	return Vector2.ZERO


func _damage() -> float:
	return float(_tuning.get("damage", 0.0))


func _cooldown() -> float:
	return maxf(float(_tuning.get("cooldown", 1.0)), 0.01)


func _radius() -> float:
	return maxf(float(_tuning.get("radius", 80.0)), 1.0)


func _arc_degrees() -> float:
	return clampf(float(_tuning.get("arc_degrees", 120.0)), 1.0, 360.0)


func _knockback() -> float:
	return maxf(float(_tuning.get("knockback", 0.0)), 0.0)
