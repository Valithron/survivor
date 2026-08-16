class_name GrenadeProjectileEffect
extends Node2D

signal landed(world_position: Vector2)
var _start := Vector2.ZERO
var destination := Vector2.ZERO
var flight_duration := 0.35
var arc_height := 58.0
var _elapsed := 0.0

func configure(start_position: Vector2, end_position: Vector2, duration: float, arc: float) -> void:
	_start = start_position
	destination = end_position
	flight_duration = maxf(duration, 0.01)
	arc_height = maxf(arc, 0.0)
	global_position = _start
	queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / flight_duration, 0.0, 1.0)
	global_position = _start.lerp(destination, progress) + Vector2(0.0, -arc_height * sin(progress * PI))
	if progress >= 1.0:
		landed.emit(destination)
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color(0.20, 0.29, 0.34, 1.0))
	draw_circle(Vector2.ZERO, 4.0, Color(0.82, 0.4, 0.12, 1.0))
	draw_circle(Vector2(2, -2), 1.5, Color(1.0, 0.9, 0.5, 1.0))
