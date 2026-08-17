class_name AutoTurret
extends Node2D

signal shot_fired(origin: Vector2, target_position: Vector2, projectile_count: int)

const TURRET_SPRITE: Texture2D = preload("res://art/vfx/turret/auto_turret_v1.png")

var _damage_source: Object
var _tuning: Dictionary = {}
var _remaining_lifetime := 0.0
var _cooldown_remaining := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = TURRET_SPRITE
	_sprite.centered = true
	add_child(_sprite)


func configure(source: Object, tuning: Dictionary) -> void:
	_damage_source = source
	apply_tuning(tuning)
	_remaining_lifetime = _lifetime()


func apply_tuning(tuning: Dictionary) -> void:
	_tuning = tuning.duplicate(true)
	_cooldown_remaining = minf(_cooldown_remaining, _cooldown())
	_remaining_lifetime = minf(_remaining_lifetime, _lifetime()) if _remaining_lifetime > 0.0 else _lifetime()


func _process(delta: float) -> void:
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		queue_free()
		return
	_cooldown_remaining -= delta
	if _cooldown_remaining <= 0.0:
		_fire_at_nearest_target()


func _fire_at_nearest_target() -> bool:
	var targets := WeaponTargeting.nearby_targets(self, global_position, _range())
	if targets.is_empty():
		_cooldown_remaining = 0.12
		return false
	var target := targets[0]
	var direction := (target.global_position - global_position).normalized()
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	rotation = direction.angle()
	_cooldown_remaining = _cooldown()
	var projectile_count := maxi(int(_tuning.get("shots_per_cycle", 1)), 1)
	var spread_radians := deg_to_rad(float(_tuning.get("spread_degrees", 0.0)))
	for index in range(projectile_count):
		var ratio := 0.5 if projectile_count == 1 else float(index) / float(projectile_count - 1)
		_spawn_projectile(direction.rotated(lerpf(-spread_radians * 0.5, spread_radians * 0.5, ratio)))
	shot_fired.emit(global_position, target.global_position, projectile_count)
	return true


func _spawn_projectile(direction: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var projectile := ThrowingKnifeProjectile.new()
	parent.add_child(projectile)
	projectile.configure(global_position + direction * 12.0, direction, _speed(), _damage(), _projectile_lifetime(), _projectile_radius(), _pierce_count(), _damage_source, &"shared_weapon_auto_turret")


func _cooldown() -> float: return maxf(float(_tuning.get("fire_cooldown", 0.6)), 0.01)
func _range() -> float: return maxf(float(_tuning.get("range", 340.0)), 1.0)
func _damage() -> float: return maxf(float(_tuning.get("damage", 0.0)), 0.0)
func _speed() -> float: return maxf(float(_tuning.get("projectile_speed", 620.0)), 1.0)
func _projectile_lifetime() -> float: return maxf(float(_tuning.get("projectile_lifetime", 0.8)), 0.01)
func _projectile_radius() -> float: return maxf(float(_tuning.get("projectile_radius", 3.0)), 1.0)
func _pierce_count() -> int: return maxi(int(_tuning.get("pierce_count", 1)), 1)
func _lifetime() -> float: return maxf(float(_tuning.get("lifetime", 8.0)), 0.01)
