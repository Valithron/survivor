class_name GrenadeExplosionEffect
extends Node2D
var radius := 60.0
var lifetime := 0.22
var _remaining := 0.22
func configure(effect_radius: float) -> void:
	radius = maxf(effect_radius, 1.0)
	_remaining = lifetime
	queue_redraw()
func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	queue_redraw()
func _draw() -> void:
	var progress := 1.0 - clampf(_remaining / lifetime, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius * progress, Color(1.0, 0.22, 0.05, 0.38 * (1.0 - progress)))
	draw_arc(Vector2.ZERO, radius * progress, 0.0, TAU, 24, Color(1.0, 0.78, 0.28, 0.95 * (1.0 - progress)), 2.5, true)
