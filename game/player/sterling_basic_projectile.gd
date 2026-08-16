class_name SterlingBasicProjectile
extends Area2D

## A deliberately small runtime projectile for Sterling's unique basic. It
## hands damage to the shared HealthComponent convention rather than knowing
## enemy classes or owning enemy death/XP behavior.
var direction := Vector2.RIGHT
var speed := 720.0
var damage := 16.0
var lifetime_seconds := 1.25
var radius := 3.0
var damage_source: Object
var damage_tag: StringName = &"sterling_dual_pistols"

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
		shot_damage_tag: StringName = &"sterling_dual_pistols"
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
	draw_circle(Vector2.ZERO, radius + 2.0, Color("8ad7ff"))
	draw_circle(Vector2.ZERO, radius, Color("f5fbff"))
	draw_line(Vector2(-radius * 2.0, 0.0), Vector2(radius * 3.0, 0.0), Color("6cb6e7"), 1.5, true)


func _on_area_entered(area: Area2D) -> void:
	_apply_damage_to(area)


func _on_body_entered(body: Node2D) -> void:
	_apply_damage_to(body)


func _apply_damage_to(target: Node) -> void:
	if _spent or target == null:
		return
	var event := DamageEvent.new(damage_source, damage, damage_tag)
	if target.has_method("apply_damage_event"):
		target.apply_damage_event(event)
		_spent = true
	elif target.get_node_or_null("HealthComponent") is HealthComponent:
		var health := target.get_node("HealthComponent") as HealthComponent
		health.apply_damage(event)
		_spent = true
	if _spent:
		queue_free()
