class_name MutantBossVisual
extends Node2D

## Animated presentation adapter for B1's raster source. The sprite remains
## intentionally static-frame for the First Playable, while the readable
## windup/charge/death motion comes from restrained transform animation.
@onready var sprite: Sprite2D = $Sprite

var _action: StringName = &"idle"
var _direction := Vector2.RIGHT
var _elapsed := 0.0
var _hurt_remaining := 0.0


func set_motion_state(action: StringName, direction: Vector2) -> void:
	_action = action
	if direction.length_squared() > 0.0001:
		_direction = direction.normalized()
		sprite.flip_h = _direction.x < 0.0


func play_hurt() -> void:
	_hurt_remaining = 0.16


func play_death() -> void:
	_action = &"death"


func _process(delta: float) -> void:
	_elapsed += delta
	_hurt_remaining = maxf(_hurt_remaining - delta, 0.0)
	var bob := sin(_elapsed * (9.0 if _action == &"charge" else 3.2))
	position.y = -75.0 + bob * (2.4 if _action == &"charge" else 1.2)
	if _action == &"windup":
		scale = Vector2(1.05, 0.96)
	elif _action == &"death":
		rotation = lerpf(rotation, deg_to_rad(78.0), minf(delta * 3.8, 1.0))
		scale = scale.lerp(Vector2(1.12, 0.72), minf(delta * 2.5, 1.0))
	else:
		scale = scale.lerp(Vector2.ONE, minf(delta * 8.0, 1.0))
	sprite.modulate = Color(1.0, 0.62, 0.62, 1.0) if _hurt_remaining > 0.0 else Color.WHITE

