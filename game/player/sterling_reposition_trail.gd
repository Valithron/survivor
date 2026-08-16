class_name SterlingRepositionTrail
extends Node2D

## Lightweight, independent tactical VFX. It does not alter collision or
## gameplay state and can later be replaced by production effect art.
var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var duration_seconds := 0.3
var _remaining_seconds := 0.0


func configure(world_start: Vector2, world_end: Vector2, duration: float) -> void:
	start_position = world_start
	end_position = world_end
	duration_seconds = maxf(duration, 0.01)
	_remaining_seconds = duration_seconds
	global_position = Vector2.ZERO
	queue_redraw()


func _process(delta: float) -> void:
	_remaining_seconds -= delta
	if _remaining_seconds <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var alpha := clampf(_remaining_seconds / duration_seconds, 0.0, 1.0)
	var local_start := to_local(start_position)
	var local_end := to_local(end_position)
	draw_line(local_start, local_end, Color(0.43, 0.84, 1.0, 0.16 * alpha), 20.0 * alpha, true)
	draw_line(local_start, local_end, Color(0.78, 0.95, 1.0, 0.85 * alpha), 3.0 * alpha, true)
