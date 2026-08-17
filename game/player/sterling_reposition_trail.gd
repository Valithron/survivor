class_name SterlingRepositionTrail
extends Node2D

## Lightweight, independent tactical VFX. It does not alter collision or
## gameplay state and can later be replaced by production effect art.
const DASH_RIBBON: Texture2D = preload("res://art/vfx/sterling/dash_ribbon_v1.png")
var start_position := Vector2.ZERO
var end_position := Vector2.ZERO
var duration_seconds := 0.3
var _remaining_seconds := 0.0
var _sprite: Sprite2D


func configure(world_start: Vector2, world_end: Vector2, duration: float) -> void:
	start_position = world_start
	end_position = world_end
	duration_seconds = maxf(duration, 0.01)
	_remaining_seconds = duration_seconds
	global_position = Vector2.ZERO
	_update_visual()


func _process(delta: float) -> void:
	_remaining_seconds -= delta
	if _remaining_seconds <= 0.0:
		queue_free()
		return
	_update_visual()


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = DASH_RIBBON
	_sprite.centered = false
	add_child(_sprite)
	_update_visual()


func _update_visual() -> void:
	if _sprite == null:
		return
	var delta := end_position - start_position
	_sprite.global_position = start_position
	_sprite.global_rotation = delta.angle() if delta.length_squared() > 0.0001 else 0.0
	_sprite.scale.x = maxf(delta.length() / 256.0, 0.01)
	_sprite.modulate.a = clampf(_remaining_seconds / duration_seconds, 0.0, 1.0)
