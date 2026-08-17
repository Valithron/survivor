class_name CooperRifleProjectile
extends Area2D

## Runtime projectile for Cooper's unique basic. Damage remains entirely on
## the shared F0 event contract; this node only owns the raster presentation.
const TRACER_SHEET: Texture2D = preload("res://art/vfx/cooper/cooper_rifle_tracer_sheet_v1.png")
const FRAME_SIZE := 64
const FRAME_COUNT := 2
var direction := Vector2.RIGHT
var speed := 860.0
var damage := 9.0
var lifetime_seconds := 1.15
var radius := 2.0
var damage_source: Object
var damage_tag: StringName = &"cooper_automatic_rifle"

var _remaining_lifetime := 0.0
var _spent := false
var _visual_elapsed := 0.0
var _sprite: Sprite2D


func configure(
	spawn_position: Vector2,
	shot_direction: Vector2,
	shot_speed: float,
	shot_damage: float,
	shot_lifetime_seconds: float,
	shot_radius: float,
	source: Object,
	shot_damage_tag: StringName = &"cooper_automatic_rifle",
) -> void:
	global_position = spawn_position
	direction = shot_direction.normalized() if shot_direction.length_squared() > 0.0001 else Vector2.RIGHT
	speed = maxf(shot_speed, 0.0)
	damage = maxf(shot_damage, 0.0)
	lifetime_seconds = maxf(shot_lifetime_seconds, 0.01)
	radius = maxf(shot_radius, 1.0)
	damage_source = source
	damage_tag = shot_damage_tag
	_remaining_lifetime = lifetime_seconds
	_visual_elapsed = 0.0
	rotation = direction.angle()
	_update_visual()


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)
	_sprite = Sprite2D.new()
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.texture = TRACER_SHEET
	_sprite.region_enabled = true
	_sprite.centered = true
	add_child(_sprite)
	_update_visual()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_remaining_lifetime -= delta
	_visual_elapsed += delta
	if _remaining_lifetime <= 0.0:
		queue_free()
		return
	_update_visual()


func _update_visual() -> void:
	if _sprite == null:
		return
	var frame_index := posmod(int(floor(_visual_elapsed * 22.0)), FRAME_COUNT)
	_sprite.region_rect = Rect2(float(frame_index * FRAME_SIZE), 0.0, FRAME_SIZE, FRAME_SIZE)


func _on_area_entered(area: Area2D) -> void:
	_apply_damage_to(area)


func _on_body_entered(body: Node2D) -> void:
	_apply_damage_to(body)


func _apply_damage_to(target: Node) -> void:
	if _spent or target == null:
		return
	if target.has_method(&"apply_damage_event"):
		target.call(&"apply_damage_event", DamageEvent.new(damage_source, damage, damage_tag))
		_spent = true
	elif target.get_node_or_null(^"HealthComponent") is HealthComponent:
		(target.get_node(^"HealthComponent") as HealthComponent).apply_damage(DamageEvent.new(damage_source, damage, damage_tag))
		_spent = true
	if _spent:
		queue_free()
