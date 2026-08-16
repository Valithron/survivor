class_name ZombieEnemy
extends CharacterBody2D

## Shared runtime for every ordinary zombie archetype: simple pursuit/contact
## pressure, definition-driven stats, and an optional elite stat variant.
signal defeated(enemy: ZombieEnemy, award: XpAward)

@export var definition: EnemyDefinition

@onready var health_component: HealthComponent = get_node_or_null(^"HealthComponent") as HealthComponent

var _target: Node2D
var _target_health: HealthComponent
var _target_contact_radius: float = 16.0
var _defeat_reported := false
var is_elite := false
var _knockback_velocity := Vector2.ZERO

const KNOCKBACK_DECELERATION := 980.0


func _ready() -> void:
	add_to_group(&"auto_aim_target")
	add_to_group(&"survivor_enemy_targets")
	collision_layer = 2
	if definition == null:
		push_error("ZombieEnemy requires an EnemyDefinition before entering the tree.")
		set_physics_process(false)
		return
	if health_component == null:
		push_error("ZombieEnemy requires a child HealthComponent.")
		set_physics_process(false)
		return

	health_component.died.connect(_on_health_died)
	health_component.configure(get_maximum_health())
	_update_collision_radius()
	_add_configured_visual()
	if is_elite:
		_add_elite_presentation()


func configure(new_definition: EnemyDefinition, elite_variant: bool = false) -> void:
	definition = new_definition
	is_elite = elite_variant


func set_target(target: Node2D, target_health: HealthComponent = null, target_contact_radius: float = 16.0) -> void:
	_target = target
	_target_health = target_health
	_target_contact_radius = maxf(target_contact_radius, 0.0)
	if _target_health == null and is_instance_valid(_target):
		_target_health = _target.get_node_or_null(^"HealthComponent") as HealthComponent


func apply_damage_event(event: DamageEvent) -> float:
	if health_component == null:
		return 0.0
	var applied_amount := health_component.apply_damage(event)
	if applied_amount > 0.0 and event != null and event.knockback.length_squared() > 0.0001:
		## This is the shared, intentionally narrow displacement seam used by
		## Ryan's locked shotgun/charge/ultimate and existing weapon knockback.
		## Bosses are intentionally not forced through it.
		_knockback_velocity += event.knockback
	return applied_amount


func receive_damage(event: DamageEvent) -> float:
	return apply_damage_event(event)


func has_live_target() -> bool:
	return is_instance_valid(_target) and is_instance_valid(_target_health) and _target_health.is_alive()


func get_maximum_health() -> float:
	if definition == null:
		return 1.0
	return definition.base_max_health * (definition.elite_health_multiplier if is_elite else 1.0)


func get_move_speed() -> float:
	if definition == null:
		return 0.0
	return definition.move_speed * (definition.elite_speed_multiplier if is_elite else 1.0)


func get_contact_damage_per_second() -> float:
	if definition == null:
		return 0.0
	return definition.contact_damage_per_second * (definition.elite_damage_multiplier if is_elite else 1.0)


func _physics_process(delta: float) -> void:
	if _defeat_reported or definition == null:
		return
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECELERATION * delta)
	if not is_instance_valid(_target):
		velocity = _knockback_velocity
		if velocity.length_squared() > 0.0001:
			move_and_slide()
		return

	var toward_target := _target.global_position - global_position
	var contact_distance := definition.collision_radius + _target_contact_radius
	if toward_target.length_squared() > contact_distance * contact_distance:
		velocity = toward_target.normalized() * get_move_speed() + _knockback_velocity
		move_and_slide()
		_set_visual_motion(&"run", toward_target)
	else:
		velocity = _knockback_velocity
		if velocity.length_squared() > 0.0001:
			move_and_slide()
		_set_visual_motion(&"attack", toward_target)

	if has_live_target() and global_position.distance_squared_to(_target.global_position) <= contact_distance * contact_distance:
		_target_health.apply_damage(DamageEvent.new(self, get_contact_damage_per_second() * delta, &"enemy_contact"))


func _on_health_died(final_event: DamageEvent) -> void:
	if _defeat_reported:
		return
	_defeat_reported = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	remove_from_group(&"auto_aim_target")
	remove_from_group(&"survivor_enemy_targets")

	var award := XpAward.new(self, definition.xp_value, global_position)
	GameplayEvents.report_enemy_defeated(self, award)
	defeated.emit(self, award)
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"play_death"):
		visual.call(&"play_death")
		var death_duration := 0.25
		if visual.has_method(&"death_duration_seconds"):
			death_duration = float(visual.call(&"death_duration_seconds"))
		await get_tree().create_timer(death_duration).timeout
	queue_free()


func _update_collision_radius() -> void:
	var collision_shape := get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if collision_shape == null:
		return
	var circle_shape := collision_shape.shape as CircleShape2D
	if circle_shape != null:
		circle_shape.radius = definition.collision_radius


func _add_configured_visual() -> void:
	if get_node_or_null(^"Visual") != null:
		return
	if definition.visual_scene == null:
		push_error("ZombieEnemy requires EnemyDefinition.visual_scene for final enemy art.")
		return
	var visual := definition.visual_scene.instantiate()
	visual.name = &"Visual"
	add_child(visual)
	if is_elite and visual is CanvasItem:
		(visual as CanvasItem).modulate = Color(1.0, 0.86, 0.64, 1.0)


func _add_elite_presentation() -> void:
	if get_node_or_null(^"EliteHealthBar") != null or health_component == null:
		return
	var health_bar := EliteHealthBar.new()
	health_bar.name = &"EliteHealthBar"
	health_bar.position = Vector2(0.0, -62.0)
	add_child(health_bar)
	health_bar.configure(health_component)


func _set_visual_motion(action: StringName, direction: Vector2) -> void:
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"set_motion_state"):
		visual.call(&"set_motion_state", action, direction)
