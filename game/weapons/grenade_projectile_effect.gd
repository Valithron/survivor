class_name GrenadeProjectileEffect
extends Node2D

signal landed(world_position: Vector2)
const SHEET: Texture2D = preload("res://art/vfx/grenade/grenade_projectile_sheet_v1.png")
var _start := Vector2.ZERO
var destination := Vector2.ZERO
var flight_duration := 0.35
var arc_height := 58.0
var _elapsed := 0.0
var _sprite: Sprite2D

func configure(start_position: Vector2, end_position: Vector2, duration: float, arc: float) -> void:
	_start = start_position
	destination = end_position
	flight_duration = maxf(duration, 0.01)
	arc_height = maxf(arc, 0.0)
	global_position = _start

func _process(delta: float) -> void:
	_elapsed += delta
	var progress := clampf(_elapsed / flight_duration, 0.0, 1.0)
	global_position = _start.lerp(destination, progress) + Vector2(0.0, -arc_height * sin(progress * PI))
	if _sprite: _sprite.region_rect = Rect2(64.0 if progress > 0.5 else 0.0, 0.0, 64.0, 64.0)
	if progress >= 1.0:
		landed.emit(destination)
		queue_free()
		return
func _ready() -> void:
	_sprite=Sprite2D.new(); _sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; _sprite.texture=SHEET; _sprite.region_enabled=true; add_child(_sprite)
