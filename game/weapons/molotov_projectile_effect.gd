class_name MolotovProjectileEffect
extends Node2D

## Temporary readable toss; production sprite/VFX integration is deferred.
signal landed(world_position: Vector2)

var destination := Vector2.ZERO
var flight_duration := 0.2
var _elapsed := 0.0
var _start := Vector2.ZERO


func configure(start_position: Vector2, end_position: Vector2, duration: float) -> void:
	_start = start_position
	destination = end_position
	flight_duration = maxf(duration, 0.01)
	global_position = _start
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	var travel := clampf(_elapsed / flight_duration, 0.0, 1.0)
	global_position = _start.lerp(destination, travel) + Vector2(0.0, -42.0 * sin(travel * PI))
	if travel >= 1.0:
		landed.emit(destination)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 7.0, Color("ff9d4a"))
	draw_circle(Vector2.ZERO, 3.0, Color("fff0bd"))
