class_name MolotovFirePatch
extends Node2D

## A persistent, data-tuned damage zone. Its simple shape is explicitly
## temporary presentation, while its timing/damage path is production runtime.
const FIRE_SHEET: Texture2D = preload("res://art/vfx/molotov/molotov_fire_sheet_v1.png")
const FRAME_SIZE := 128
var damage_source: Object
var radius := 52.0
var damage_per_tick := 8.0
var tick_interval := 0.5
var duration := 3.0
var _remaining := 3.0
var _tick_remaining := 0.0
var _sprite: Sprite2D


func configure(source: Object, patch_radius: float, tick_damage: float, interval: float, lifetime: float) -> void:
	damage_source = source
	radius = maxf(patch_radius, 1.0)
	damage_per_tick = maxf(tick_damage, 0.0)
	tick_interval = maxf(interval, 0.01)
	duration = maxf(lifetime, 0.01)
	_remaining = duration
	_tick_remaining = 0.0
	_update_visual()


func _process(delta: float) -> void:
	_remaining -= delta
	_tick_remaining -= delta
	if _tick_remaining <= 0.0:
		_apply_tick()
		_tick_remaining += tick_interval
	if _remaining <= 0.0:
		queue_free()
		return
	_update_visual()


func _apply_tick() -> void:
	for target in WeaponTargeting.nearby_targets(self, global_position, radius):
		WeaponTargeting.apply_damage(target, damage_source, damage_per_tick, &"shared_weapon_molotov")


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = FIRE_SHEET
	_sprite.region_enabled = true
	_sprite.centered = true
	add_child(_sprite)
	_update_visual()


func _update_visual() -> void:
	if _sprite == null:
		return
	var progress := 1.0 - (_remaining / duration)
	_sprite.region_rect = Rect2(128.0 if posmod(int(floor(progress * 8.0)), 2) == 1 else 0.0, 0.0, FRAME_SIZE, FRAME_SIZE)
	var scale_factor := radius / 58.0
	_sprite.scale = Vector2.ONE * scale_factor
	_sprite.modulate.a = clampf(_remaining / minf(duration, 0.65), 0.0, 1.0)
