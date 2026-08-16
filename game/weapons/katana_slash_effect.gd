class_name KatanaSlashEffect
extends Node2D

## Temporary geometric readability aid; final weapon VFX remains an art task.
var direction := Vector2.RIGHT
var radius := 80.0
var arc_degrees := 120.0
var lifetime := 0.16
var _remaining := 0.16


func configure(effect_direction: Vector2, effect_radius: float, effect_arc_degrees: float, effect_lifetime: float) -> void:
	direction = effect_direction.normalized() if not effect_direction.is_zero_approx() else Vector2.RIGHT
	radius = effect_radius
	arc_degrees = effect_arc_degrees
	lifetime = maxf(effect_lifetime, 0.01)
	_remaining = lifetime
	queue_redraw()


func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_remaining / lifetime, 0.0, 1.0)
	var center_angle := direction.angle()
	var half_arc := deg_to_rad(arc_degrees * 0.5)
	var alpha := 0.25 + progress * 0.7
	draw_arc(Vector2.ZERO, radius, center_angle - half_arc, center_angle + half_arc, 28, Color(0.72, 0.9, 1.0, alpha), 4.0, true)
	draw_arc(Vector2.ZERO, radius * 0.72, center_angle - half_arc, center_angle + half_arc, 28, Color(0.38, 0.72, 1.0, alpha * 0.8), 2.0, true)
