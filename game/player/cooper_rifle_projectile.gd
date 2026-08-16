class_name CooperRifleProjectile
extends Area2D

## Runtime projectile for Cooper's unique basic. The simple temporary tracer
## presentation is intentionally isolated here for ART-ROSTER replacement;
## damage remains entirely on the shared F0 event contract.
var direction := Vector2.RIGHT
var speed := 860.0
var damage := 9.0
var lifetime_seconds := 1.15
var radius := 2.0
var damage_source: Object
var damage_tag: StringName = &"cooper_automatic_rifle"

var _remaining_lifetime := 0.0
var _spent := false


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
	rotation = direction.angle()
	queue_redraw()


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
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	draw_line(Vector2(-7.0, 0.0), Vector2(7.0, 0.0), Color("f2dc8a"), 2.0, false)
	draw_circle(Vector2(7.0, 0.0), radius + 0.5, Color("fff8cf"))


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
