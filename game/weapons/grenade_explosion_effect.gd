class_name GrenadeExplosionEffect
extends Node2D
const SHEET: Texture2D = preload("res://art/vfx/grenade/grenade_explosion_sheet_v1.png")
var radius := 60.0
var lifetime := 0.22
var _remaining := 0.22
var _sprite: Sprite2D
func configure(effect_radius: float) -> void:
	radius = maxf(effect_radius, 1.0)
	_remaining = lifetime
func _process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	if _sprite:
		var p:=1.0-_remaining/lifetime; _sprite.region_rect=Rect2(128.0 if p>0.5 else 0.0,0,128,128); _sprite.scale=Vector2.ONE*(radius/60.0); _sprite.modulate.a=1.0-p
func _ready() -> void:
	_sprite=Sprite2D.new(); _sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST; _sprite.texture=SHEET; _sprite.region_enabled=true; add_child(_sprite)
