class_name BossTelegraph
extends Node2D

## Presentation-only B1 danger-zone primitive. It stays above dense enemies
## but below the HUD, with a distinct silhouette for each locked attack.
enum TelegraphKind { SLAM, SWEEP, CHARGE, SHOCKWAVE }

var kind: TelegraphKind = TelegraphKind.SLAM
var radius := 160.0
var range_length := 400.0
var sweep_angle := deg_to_rad(110.0)
var duration := 1.0
var _elapsed := 0.0


func configure(next_kind: TelegraphKind, origin: Vector2, direction: Vector2, next_radius: float, next_range: float, next_sweep_angle: float, next_duration: float) -> void:
	kind = next_kind
	global_position = origin
	rotation = direction.angle() if direction.length_squared() > 0.0001 else 0.0
	radius = maxf(next_radius, 1.0)
	range_length = maxf(next_range, 1.0)
	sweep_angle = maxf(next_sweep_angle, 0.01)
	duration = maxf(next_duration, 0.01)
	z_index = 14


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()
	if _elapsed >= duration:
		queue_free()


func _draw() -> void:
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	var pulse := 0.65 + 0.35 * sin(_elapsed * 11.0)
	match kind:
		TelegraphKind.SLAM:
			draw_circle(Vector2.ZERO, radius, Color(1.0, 0.26, 0.14, 0.11 + progress * 0.12))
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 56, Color(1.0, 0.48, 0.14, 0.78), 3.0 + pulse * 2.0)
			draw_arc(Vector2.ZERO, radius * (0.24 + progress * 0.55), 0.0, TAU, 40, Color(1.0, 0.88, 0.38, 0.75), 2.0)
		TelegraphKind.SWEEP:
			var points := PackedVector2Array([Vector2.ZERO])
			for point_index in range(25):
				var angle := -sweep_angle * 0.5 + sweep_angle * float(point_index) / 24.0
				points.append(Vector2.RIGHT.rotated(angle) * range_length)
			draw_colored_polygon(points, Color(0.95, 0.25, 0.18, 0.17 + progress * 0.14))
			draw_arc(Vector2.ZERO, range_length, -sweep_angle * 0.5, sweep_angle * 0.5, 32, Color(1.0, 0.62, 0.14, 0.9), 4.0)
			draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(-sweep_angle * 0.5) * range_length, Color(1.0, 0.74, 0.18, 0.65), 2.0)
			draw_line(Vector2.ZERO, Vector2.RIGHT.rotated(sweep_angle * 0.5) * range_length, Color(1.0, 0.74, 0.18, 0.65), 2.0)
		TelegraphKind.CHARGE:
			var line_end := Vector2.RIGHT * range_length
			draw_line(Vector2.ZERO, line_end, Color(0.32, 0.88, 1.0, 0.25), 52.0)
			draw_line(Vector2.ZERO, line_end, Color(0.72, 0.96, 1.0, 0.9), 5.0 + pulse * 2.0)
			draw_circle(line_end, 25.0, Color(0.72, 0.96, 1.0, 0.52))
		TelegraphKind.SHOCKWAVE:
			var shock_radius := radius * progress
			draw_arc(Vector2.ZERO, shock_radius, 0.0, TAU, 48, Color(1.0, 0.74, 0.3, 1.0 - progress), 5.0)

