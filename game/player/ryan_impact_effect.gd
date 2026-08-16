class_name RyanImpactEffect
extends Node2D

## Presentation adapter for the escalating radial-impact ability. The actual
## damage radius/timing remains owned by RyanPlayer and its tuning Resource.
const IMPACT_SHEET: Texture2D = preload("res://art/vfx/ryan/ryan_radial_impact_sheet_v1.png")
const FRAME_SIZE := 128
const FRAME_COUNT := 3

var radius := 96.0
var lifetime := 0.24
var _remaining := 0.24
var _sprite: Sprite2D


func configure(effect_radius: float, final_impact: bool) -> void:
	radius = maxf(effect_radius, 1.0)
	lifetime = 0.30 if final_impact else 0.20
	_remaining = lifetime
	_update_visual()


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = IMPACT_SHEET
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
	var progress := clampf(1.0 - _remaining / maxf(lifetime, 0.01), 0.0, 1.0)
	var frame_index := mini(int(floor(progress * float(FRAME_COUNT))), FRAME_COUNT - 1)
	_sprite.region_rect = Rect2(float(frame_index * FRAME_SIZE), 0.0, FRAME_SIZE, FRAME_SIZE)
	_sprite.scale = Vector2.ONE * (radius / 64.0)
	_sprite.modulate.a = clampf(1.15 - progress, 0.0, 1.0)
