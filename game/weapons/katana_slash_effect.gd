class_name KatanaSlashEffect
extends Node2D

## Presentation-only adapter for Katana's three-frame production raster slash.
## Damage geometry remains exclusively in KatanaRuntime.
const SLASH_SHEET: Texture2D = preload("res://art/vfx/katana/katana_slash_sheet_v1.png")
const FRAME_SIZE := 128
const FRAME_COUNT := 3

var direction := Vector2.RIGHT
var radius := 80.0
var arc_degrees := 120.0
var lifetime := 0.16
var _remaining := 0.16

var _sprite: Sprite2D


func configure(effect_direction: Vector2, effect_radius: float, effect_arc_degrees: float, effect_lifetime: float) -> void:
	direction = effect_direction.normalized() if not effect_direction.is_zero_approx() else Vector2.RIGHT
	radius = effect_radius
	arc_degrees = effect_arc_degrees
	lifetime = maxf(effect_lifetime, 0.01)
	_remaining = lifetime
	_update_visual()


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = SLASH_SHEET
	_sprite.region_enabled = true
	_sprite.centered = true
	add_child(_sprite)
	_update_visual()


func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	_update_visual()


func _update_visual() -> void:
	if _sprite == null:
		return
	var elapsed := clampf(lifetime - _remaining, 0.0, lifetime)
	var frame_index := mini(int(floor(elapsed / maxf(lifetime, 0.01) * float(FRAME_COUNT))), FRAME_COUNT - 1)
	_sprite.region_rect = Rect2(float(frame_index * FRAME_SIZE), 0.0, FRAME_SIZE, FRAME_SIZE)
	_sprite.rotation = direction.angle()
	_sprite.scale = Vector2.ONE * (radius / 80.0)
	_sprite.modulate.a = clampf(_remaining / maxf(lifetime, 0.01) * 1.25, 0.0, 1.0)
