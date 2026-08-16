class_name ThrowingKnifeProjectile
extends Area2D

## Straightforward shared projectile used by both Knives and turret fire. The
## weapon runtime supplies all balance and DamageEvent identity.
var direction := Vector2.RIGHT
var speed := 700.0
var damage := 10.0
var lifetime_seconds := 1.0
var radius := 3.0
var remaining_hits := 1
var damage_source: Object
var damage_tag: StringName = &"shared_weapon_throwing_knives"
var _remaining_lifetime := 0.0
var _hit_ids: Dictionary = {}


func configure(spawn_position: Vector2, shot_direction: Vector2, shot_speed: float, shot_damage: float, shot_lifetime: float, shot_radius: float, pierce_count: int, source: Object, tag: StringName) -> void:
	global_position = spawn_position
	direction = shot_direction.normalized() if shot_direction.length_squared() > 0.0001 else Vector2.RIGHT
	speed = maxf(shot_speed, 0.0)
	damage = maxf(shot_damage, 0.0)
	lifetime_seconds = maxf(shot_lifetime, 0.01)
	radius = maxf(shot_radius, 1.0)
	remaining_hits = maxi(pierce_count, 1)
	damage_source = source
	damage_tag = tag
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
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	var blade := PackedVector2Array([Vector2(8, 0), Vector2(-6, -3), Vector2(-6, 3)])
	draw_colored_polygon(blade, Color(0.78, 0.9, 0.96, 1.0))
	draw_line(Vector2(-8, 0), Vector2(-3, 0), Color(0.22, 0.11, 0.08, 1.0), 2.0, true)


func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)


func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)


func _try_hit(target: Node) -> void:
	if target == null or remaining_hits <= 0:
		return
	var instance_id := target.get_instance_id()
	if _hit_ids.has(instance_id):
		return
	if WeaponTargeting.apply_damage(target, damage_source, damage, damage_tag):
		_hit_ids[instance_id] = true
		remaining_hits -= 1
		if remaining_hits <= 0:
			queue_free()
