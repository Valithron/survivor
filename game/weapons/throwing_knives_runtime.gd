class_name ThrowingKnivesRuntime
extends SharedWeaponRuntime

signal volley_fired(origin: Vector2, direction: Vector2, projectile_count: int)

var _tuning: Dictionary = {}
var _cooldown_remaining := 0.0


func _process(delta: float) -> void:
	if current_rank <= 0:
		return
	_cooldown_remaining -= delta
	if _cooldown_remaining <= 0.0:
		fire_volley()


func force_attack() -> bool:
	return fire_volley()


func _on_rank_applied(rank_definition: WeaponRankDefinition) -> void:
	_tuning = rank_definition.tuning.duplicate(true)
	_cooldown_remaining = minf(_cooldown_remaining, _cooldown())


func fire_volley() -> bool:
	var origin := _owner_position()
	var targets := WeaponTargeting.nearby_targets(self, origin, _range())
	if targets.is_empty():
		_cooldown_remaining = 0.1
		return false
	_cooldown_remaining = _cooldown()
	var direction := (targets[0].global_position - origin).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	var projectile_count := maxi(int(_tuning.get("projectile_count", 1)), 1)
	var spread_radians := deg_to_rad(float(_tuning.get("spread_degrees", 0.0)))
	for index in range(projectile_count):
		var ratio := 0.5 if projectile_count == 1 else float(index) / float(projectile_count - 1)
		_spawn_knife(origin, direction.rotated(lerpf(-spread_radians * 0.5, spread_radians * 0.5, ratio)))
	volley_fired.emit(origin, direction, projectile_count)
	return true


func _spawn_knife(origin: Vector2, direction: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var knife := ThrowingKnifeProjectile.new()
	parent.add_child(knife)
	knife.configure(origin + direction * 10.0, direction, _speed(), _damage(), _lifetime(), _radius(), _pierce_count(), self, &"shared_weapon_throwing_knives")


func _owner_position() -> Vector2:
	return (weapon_owner as Node2D).global_position if weapon_owner is Node2D else Vector2.ZERO


func _cooldown() -> float: return maxf(float(_tuning.get("cooldown", 1.0)), 0.01)
func _range() -> float: return maxf(float(_tuning.get("range", 360.0)), 1.0)
func _damage() -> float: return maxf(float(_tuning.get("damage", 0.0)), 0.0)
func _speed() -> float: return maxf(float(_tuning.get("speed", 700.0)), 1.0)
func _lifetime() -> float: return maxf(float(_tuning.get("lifetime", 0.8)), 0.01)
func _radius() -> float: return maxf(float(_tuning.get("radius", 3.0)), 1.0)
func _pierce_count() -> int: return maxi(int(_tuning.get("pierce_count", 1)), 1)
