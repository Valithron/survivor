class_name ChainLightningEffect
extends Node2D

var world_points: PackedVector2Array = PackedVector2Array()
var lifetime := 0.12
var _remaining := 0.12

func configure(points: PackedVector2Array, duration: float) -> void:
	world_points = points
	lifetime = maxf(duration, 0.01)
	_remaining = lifetime
	queue_redraw()

func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if world_points.size() < 2:
		return
	var alpha := clampf(_remaining / lifetime, 0.0, 1.0)
	for index in range(world_points.size() - 1):
		draw_line(to_local(world_points[index]), to_local(world_points[index + 1]), Color(0.42, 0.9, 1.0, 0.35 * alpha), 7.0 * alpha, true)
		draw_line(to_local(world_points[index]), to_local(world_points[index + 1]), Color(0.88, 0.98, 1.0, alpha), 2.0, true)
