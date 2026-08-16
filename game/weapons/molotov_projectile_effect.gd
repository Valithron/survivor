class_name MolotovProjectileEffect
extends Node2D

## Temporary readable toss; production sprite/VFX integration is deferred.
signal landed(world_position: Vector2)

const PROJECTILE_SHEET: Texture2D = preload("res://art/vfx/molotov/molotov_projectile_sheet_v1.png")
const FRAME_SIZE := 64
var destination := Vector2.ZERO
var flight_duration := 0.2
var _elapsed := 0.0
var _start := Vector2.ZERO
var _sprite: Sprite2D


func configure(start_position: Vector2, end_position: Vector2, duration: float) -> void:
	_start = start_position
	destination = end_position
	flight_duration = maxf(duration, 0.01)
	global_position = _start


func _process(delta: float) -> void:
	_elapsed += delta
	var travel := clampf(_elapsed / flight_duration, 0.0, 1.0)
	global_position = _start.lerp(destination, travel) + Vector2(0.0, -42.0 * sin(travel * PI))
	_update_visual(travel)
	if travel >= 1.0:
		landed.emit(destination)
		queue_free()
		return


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = PROJECTILE_SHEET
	_sprite.region_enabled = true
	_sprite.centered = true
	add_child(_sprite)
	_update_visual(0.0)


func _update_visual(travel: float) -> void:
	if _sprite == null:
		return
	_sprite.region_rect = Rect2(64.0 if travel > 0.5 else 0.0, 0.0, FRAME_SIZE, FRAME_SIZE)
	_sprite.rotation = sin(travel * PI) * 0.28
