class_name MolotovFirePatch
extends Node2D

## A persistent, data-tuned damage zone. Its simple shape is explicitly
## temporary presentation, while its timing/damage path is production runtime.
var damage_source: Object
var radius := 52.0
var damage_per_tick := 8.0
var tick_interval := 0.5
var duration := 3.0
var _remaining := 3.0
var _tick_remaining := 0.0


func configure(source: Object, patch_radius: float, tick_damage: float, interval: float, lifetime: float) -> void:
	damage_source = source
	radius = maxf(patch_radius, 1.0)
	damage_per_tick = maxf(tick_damage, 0.0)
	tick_interval = maxf(interval, 0.01)
	duration = maxf(lifetime, 0.01)
	_remaining = duration
	_tick_remaining = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_remaining -= delta
	_tick_remaining -= delta
	if _tick_remaining <= 0.0:
		_apply_tick()
		_tick_remaining += tick_interval
	if _remaining <= 0.0:
		queue_free()
		return
	queue_redraw()


func _apply_tick() -> void:
	for target in WeaponTargeting.nearby_targets(self, global_position, radius):
		WeaponTargeting.apply_damage(target, damage_source, damage_per_tick, &"shared_weapon_molotov")


func _draw() -> void:
	var pulse := 0.85 + 0.15 * sin(_remaining * 12.0)
	draw_circle(Vector2.ZERO, radius * pulse, Color(1.0, 0.27, 0.05, 0.18))
	draw_circle(Vector2.ZERO, radius * 0.58, Color(1.0, 0.65, 0.08, 0.28))
