class_name AutoTurretRuntime
extends SharedWeaponRuntime

signal turret_deployed(turret: AutoTurret)

var _tuning: Dictionary = {}
var _deploy_cooldown_remaining := 0.0
var _turrets: Array[AutoTurret] = []


func _process(delta: float) -> void:
	if current_rank <= 0:
		return
	_prune_turrets()
	_deploy_cooldown_remaining -= delta
	if _turrets.size() < _capacity() and _deploy_cooldown_remaining <= 0.0:
		_deploy_turret()


func force_deploy() -> bool:
	_prune_turrets()
	if _turrets.size() >= _capacity():
		return false
	_deploy_turret()
	return true


func shutdown() -> void:
	for turret in _turrets:
		if turret != null and is_instance_valid(turret):
			turret.queue_free()
	_turrets.clear()
	super.shutdown()


func _on_rank_applied(rank_definition: WeaponRankDefinition) -> void:
	_tuning = rank_definition.tuning.duplicate(true)
	_deploy_cooldown_remaining = minf(_deploy_cooldown_remaining, _deploy_cooldown())
	for turret in _turrets:
		if turret != null and is_instance_valid(turret):
			turret.apply_tuning(_tuning)


func _deploy_turret() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var turret := AutoTurret.new()
	parent.add_child(turret)
	var angle := TAU * float(_turrets.size()) / float(maxi(_capacity(), 1))
	turret.global_position = _owner_position() + Vector2.RIGHT.rotated(angle) * _deploy_radius()
	turret.configure(self, _tuning)
	turret.tree_exited.connect(func() -> void: _turrets.erase(turret))
	_turrets.append(turret)
	_deploy_cooldown_remaining = _deploy_cooldown()
	turret_deployed.emit(turret)


func _prune_turrets() -> void:
	_turrets = _turrets.filter(func(turret: AutoTurret) -> bool: return turret != null and is_instance_valid(turret) and not turret.is_queued_for_deletion())


func _owner_position() -> Vector2:
	return (weapon_owner as Node2D).global_position if weapon_owner is Node2D else Vector2.ZERO


func _capacity() -> int: return maxi(int(_tuning.get("capacity", 1)), 1)
func _deploy_cooldown() -> float: return maxf(float(_tuning.get("deploy_cooldown", 1.0)), 0.01)
func _deploy_radius() -> float: return maxf(float(_tuning.get("deploy_radius", 45.0)), 0.0)
