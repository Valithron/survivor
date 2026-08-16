class_name MolotovRuntime
extends SharedWeaponRuntime

signal molotov_thrown(origin: Vector2, target: Vector2)
signal fire_patch_created(position: Vector2)

var _tuning: Dictionary = {}
var _cooldown_remaining := 0.0
var _projectiles: Array[MolotovProjectileEffect] = []
var _patches: Array[MolotovFirePatch] = []


func _process(delta: float) -> void:
	if current_rank <= 0:
		return
	_cooldown_remaining -= delta
	if _cooldown_remaining <= 0.0:
		_launch_at_nearest_target()


func force_attack() -> bool:
	## Developer-test hook; normal use is fully automatic through _process().
	return _launch_at_nearest_target()


func shutdown() -> void:
	for projectile in _projectiles:
		if projectile != null and is_instance_valid(projectile):
			projectile.queue_free()
	for patch in _patches:
		if patch != null and is_instance_valid(patch):
			patch.queue_free()
	_projectiles.clear()
	_patches.clear()
	super.shutdown()


func _on_rank_applied(rank_definition: WeaponRankDefinition) -> void:
	_tuning = rank_definition.tuning.duplicate(true)
	_cooldown_remaining = minf(_cooldown_remaining, _cooldown())


func _launch_at_nearest_target() -> bool:
	if current_rank <= 0:
		return false
	var origin := _owner_position()
	var targets := WeaponTargeting.nearby_targets(self, origin, _toss_range())
	if targets.is_empty():
		_cooldown_remaining = 0.1
		return false
	_cooldown_remaining = _cooldown()
	var projectile := MolotovProjectileEffect.new()
	var parent := get_parent()
	if parent == null:
		return false
	parent.add_child(projectile)
	projectile.configure(origin, targets[0].global_position, _flight_duration())
	projectile.landed.connect(_on_projectile_landed.bind(projectile))
	projectile.tree_exited.connect(func() -> void: _projectiles.erase(projectile))
	_projectiles.append(projectile)
	molotov_thrown.emit(origin, targets[0].global_position)
	return true


func _on_projectile_landed(landed_position: Vector2, _projectile: MolotovProjectileEffect) -> void:
	var patch_count := maxi(int(_tuning.get("patch_count", 1)), 1)
	for index in range(patch_count):
		var offset := Vector2.ZERO
		if patch_count > 1:
			offset = Vector2.RIGHT.rotated(TAU * float(index) / float(patch_count)) * _radius() * 0.35
		_spawn_patch(landed_position + offset)


func _spawn_patch(position: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var patch := MolotovFirePatch.new()
	parent.add_child(patch)
	patch.global_position = position
	patch.configure(self, _radius(), _damage_per_tick(), _tick_interval(), _duration())
	patch.tree_exited.connect(func() -> void: _patches.erase(patch))
	_patches.append(patch)
	_apply_impact_damage(position)
	fire_patch_created.emit(position)


func _apply_impact_damage(position: Vector2) -> void:
	var impact_damage := maxf(float(_tuning.get("impact_damage", 0.0)), 0.0)
	if impact_damage <= 0.0:
		return
	for target in WeaponTargeting.nearby_targets(self, position, _radius()):
		WeaponTargeting.apply_damage(target, self, impact_damage, &"shared_weapon_molotov_impact")


func _owner_position() -> Vector2:
	if weapon_owner is Node2D:
		return (weapon_owner as Node2D).global_position
	return Vector2.ZERO


func _cooldown() -> float:
	return maxf(float(_tuning.get("cooldown", 2.0)), 0.01)


func _toss_range() -> float:
	return maxf(float(_tuning.get("toss_range", 280.0)), 1.0)


func _flight_duration() -> float:
	return maxf(float(_tuning.get("flight_duration", 0.2)), 0.01)


func _radius() -> float:
	return maxf(float(_tuning.get("radius", 52.0)), 1.0)


func _damage_per_tick() -> float:
	return maxf(float(_tuning.get("damage_per_tick", 8.0)), 0.0)


func _tick_interval() -> float:
	return maxf(float(_tuning.get("tick_interval", 0.5)), 0.01)


func _duration() -> float:
	return maxf(float(_tuning.get("duration", 3.0)), 0.01)
