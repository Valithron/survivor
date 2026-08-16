class_name GrenadeLauncherRuntime
extends SharedWeaponRuntime

signal grenade_launched(origin: Vector2, destination: Vector2)
signal explosion_created(position: Vector2, hit_count: int)
var _tuning: Dictionary = {}
var _cooldown_remaining := 0.0

func _process(delta: float) -> void:
	if current_rank <= 0:
		return
	_cooldown_remaining -= delta
	if _cooldown_remaining <= 0.0:
		launch_grenades()

func force_attack() -> bool: return launch_grenades()
func _on_rank_applied(rank_definition: WeaponRankDefinition) -> void:
	_tuning = rank_definition.tuning.duplicate(true)
	_cooldown_remaining = minf(_cooldown_remaining, _cooldown())

func launch_grenades() -> bool:
	var origin := _owner_position()
	var targets := WeaponTargeting.nearby_targets(self, origin, _range())
	if targets.is_empty():
		_cooldown_remaining = 0.1
		return false
	_cooldown_remaining = _cooldown()
	var direction := (targets[0].global_position - origin).normalized()
	if direction.is_zero_approx(): direction = Vector2.RIGHT
	var count := maxi(int(_tuning.get("grenade_count", 1)), 1)
	var spread := deg_to_rad(float(_tuning.get("spread_degrees", 0.0)))
	for index in range(count):
		var ratio := 0.5 if count == 1 else float(index) / float(count - 1)
		var offset := direction.rotated(lerpf(-spread * 0.5, spread * 0.5, ratio)) * _landing_spread()
		_launch_one(origin, targets[0].global_position + offset)
	return true

func _launch_one(origin: Vector2, destination: Vector2) -> void:
	if get_parent() == null: return
	var projectile := GrenadeProjectileEffect.new()
	get_parent().add_child(projectile)
	projectile.configure(origin, destination, _flight_duration(), _arc_height())
	projectile.landed.connect(_on_grenade_landed)
	grenade_launched.emit(origin, destination)

func _on_grenade_landed(position: Vector2) -> void:
	var hits := 0
	for target in WeaponTargeting.nearby_targets(self, position, _radius()):
		if WeaponTargeting.apply_damage(target, self, _damage(), &"shared_weapon_grenade_launcher"):
			hits += 1
	if get_parent() != null:
		var effect := GrenadeExplosionEffect.new()
		get_parent().add_child(effect)
		effect.global_position = position
		effect.configure(_radius())
	explosion_created.emit(position, hits)

func _owner_position() -> Vector2: return (weapon_owner as Node2D).global_position if weapon_owner is Node2D else Vector2.ZERO
func _cooldown() -> float: return maxf(float(_tuning.get("cooldown", 1.5)), 0.01)
func _range() -> float: return maxf(float(_tuning.get("range", 320.0)), 1.0)
func _damage() -> float: return maxf(float(_tuning.get("damage", 0.0)), 0.0)
func _radius() -> float: return maxf(float(_tuning.get("radius", 60.0)), 1.0)
func _flight_duration() -> float: return maxf(float(_tuning.get("flight_duration", 0.3)), 0.01)
func _arc_height() -> float: return maxf(float(_tuning.get("arc_height", 55.0)), 0.0)
func _landing_spread() -> float: return maxf(float(_tuning.get("landing_spread", 0.0)), 0.0)
