class_name MutantBoss
extends CharacterBody2D

## B1's deliberately explicit three-attack runtime. It has no phases,
## summons, ranged attacks, or generic ability extension points by design.
signal defeated(boss: MutantBoss, final_event: DamageEvent)
signal attack_telegraph_started(attack_id: StringName)
signal attack_resolved(attack_id: StringName)
signal health_changed(current: float, maximum: float)

enum State { PURSUING, SLAM_WINDUP, SWEEP_WINDUP, CHARGE_WINDUP, CHARGING, DEAD }

@export var definition: BossDefinition

@onready var health_component: HealthComponent = $HealthComponent

var _target: Node2D
var _target_health: HealthComponent
var _target_contact_radius := 16.0
var _state: State = State.PURSUING
var _state_remaining := 0.0
var _attack_cooldown_remaining := 0.0
var _attack_direction := Vector2.RIGHT
var _charge_remaining_distance := 0.0
var _charge_did_hit := false
var _next_attack_index := 0
var _defeat_reported := false


func _ready() -> void:
	if definition == null:
		push_error("MutantBoss requires a BossDefinition.")
		set_physics_process(false)
		return
	if health_component == null:
		push_error("MutantBoss requires a HealthComponent.")
		set_physics_process(false)
		return
	collision_layer = 2
	collision_mask = 8
	add_to_group(&"auto_aim_target")
	add_to_group(&"survivor_enemy_targets")
	health_component.configure(definition.maximum_health)
	health_component.health_changed.connect(_on_health_changed)
	health_component.damage_received.connect(_on_damage_received)
	health_component.died.connect(_on_health_died)
	_update_collision_radius()
	_add_configured_visual()


func configure(next_definition: BossDefinition) -> void:
	definition = next_definition


func set_target(target: Node2D, target_health: HealthComponent = null, contact_radius: float = 16.0) -> void:
	_target = target
	_target_health = target_health
	_target_contact_radius = maxf(contact_radius, 0.0)
	if _target_health == null and is_instance_valid(_target):
		_target_health = _target.get_node_or_null(^"HealthComponent") as HealthComponent


func apply_damage_event(event: DamageEvent) -> float:
	return health_component.apply_damage(event) if health_component != null else 0.0


func receive_damage(event: DamageEvent) -> float:
	return apply_damage_event(event)


func force_attack_for_test(attack_id: StringName) -> bool:
	if _state != State.PURSUING or not _has_live_target():
		return false
	match attack_id:
		&"ground_slam":
			_begin_slam()
		&"arm_sweep":
			_begin_sweep()
		&"mutant_charge":
			_begin_charge()
		_:
			return false
	return true


func _physics_process(delta: float) -> void:
	if _state == State.DEAD or definition == null or not _has_live_target() or RunController.state != RunController.RunState.RUNNING:
		velocity = Vector2.ZERO
		return
	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	match _state:
		State.PURSUING:
			_process_pursuit(delta)
		State.SLAM_WINDUP:
			_process_windup(delta, &"ground_slam")
		State.SWEEP_WINDUP:
			_process_windup(delta, &"arm_sweep")
		State.CHARGE_WINDUP:
			_process_windup(delta, &"mutant_charge")
		State.CHARGING:
			_process_charge(delta)


func _process_pursuit(delta: float) -> void:
	var toward_target := _target.global_position - global_position
	if toward_target.length_squared() > 0.0001:
		_attack_direction = toward_target.normalized()
		velocity = _attack_direction * definition.move_speed
		move_and_slide()
		_set_visual_motion(&"run", _attack_direction)
	else:
		velocity = Vector2.ZERO
	_set_contact_damage(delta)
	if _attack_cooldown_remaining <= 0.0 and toward_target.length() <= definition.attack_trigger_distance:
		_begin_next_attack()


func _process_windup(delta: float, attack_id: StringName) -> void:
	velocity = Vector2.ZERO
	_state_remaining -= delta
	_set_visual_motion(&"windup", _attack_direction)
	if _state_remaining > 0.0:
		return
	match attack_id:
		&"ground_slam":
			_resolve_slam()
		&"arm_sweep":
			_resolve_sweep()
		&"mutant_charge":
			_state = State.CHARGING
			_state_remaining = definition.charge_max_seconds
			_set_visual_motion(&"charge", _attack_direction)


func _process_charge(delta: float) -> void:
	var traveled := minf(definition.charge_speed * delta, _charge_remaining_distance)
	velocity = _attack_direction * (traveled / maxf(delta, 0.0001))
	move_and_slide()
	_charge_remaining_distance -= traveled
	_state_remaining -= delta
	_set_visual_motion(&"charge", _attack_direction)
	if not _charge_did_hit and global_position.distance_squared_to(_target.global_position) <= pow(definition.collision_radius + _target_contact_radius + 20.0, 2.0):
		_apply_damage_to_target(definition.charge_damage, &"boss_mutant_charge")
		_charge_did_hit = true
	if _charge_remaining_distance <= 0.0 or _state_remaining <= 0.0 or velocity.length_squared() <= 0.01:
		_finish_attack(&"mutant_charge")


func _begin_next_attack() -> void:
	var attack_ids: Array[StringName] = [&"ground_slam", &"arm_sweep", &"mutant_charge"]
	var attack_id := attack_ids[_next_attack_index % attack_ids.size()]
	_next_attack_index += 1
	match attack_id:
		&"ground_slam": _begin_slam()
		&"arm_sweep": _begin_sweep()
		&"mutant_charge": _begin_charge()


func _begin_slam() -> void:
	_state = State.SLAM_WINDUP
	_state_remaining = definition.ground_slam_windup_seconds
	_spawn_telegraph(BossTelegraph.TelegraphKind.SLAM, global_position, Vector2.RIGHT, definition.ground_slam_radius, definition.ground_slam_radius, TAU, _state_remaining)
	attack_telegraph_started.emit(&"ground_slam")


func _begin_sweep() -> void:
	_state = State.SWEEP_WINDUP
	_state_remaining = definition.sweep_windup_seconds
	_attack_direction = (_target.global_position - global_position).normalized() if _target.global_position.distance_squared_to(global_position) > 0.0001 else _attack_direction
	_spawn_telegraph(BossTelegraph.TelegraphKind.SWEEP, global_position, _attack_direction, definition.sweep_range, definition.sweep_range, deg_to_rad(definition.sweep_angle_degrees), _state_remaining)
	attack_telegraph_started.emit(&"arm_sweep")


func _begin_charge() -> void:
	_state = State.CHARGE_WINDUP
	_state_remaining = definition.charge_windup_seconds
	_attack_direction = (_target.global_position - global_position).normalized() if _target.global_position.distance_squared_to(global_position) > 0.0001 else _attack_direction
	_charge_remaining_distance = definition.charge_distance
	_charge_did_hit = false
	_spawn_telegraph(BossTelegraph.TelegraphKind.CHARGE, global_position, _attack_direction, 0.0, definition.charge_distance, 0.0, _state_remaining)
	attack_telegraph_started.emit(&"mutant_charge")


func _resolve_slam() -> void:
	if global_position.distance_squared_to(_target.global_position) <= definition.ground_slam_radius * definition.ground_slam_radius:
		_apply_damage_to_target(definition.ground_slam_damage, &"boss_ground_slam")
	_spawn_telegraph(BossTelegraph.TelegraphKind.SHOCKWAVE, global_position, Vector2.RIGHT, definition.ground_slam_radius, 0.0, 0.0, 0.38)
	_finish_attack(&"ground_slam")


func _resolve_sweep() -> void:
	var target_offset := _target.global_position - global_position
	var in_range := target_offset.length() <= definition.sweep_range
	var angle_matches := absf(_attack_direction.angle_to(target_offset.normalized())) <= deg_to_rad(definition.sweep_angle_degrees * 0.5) if target_offset.length_squared() > 0.0001 else true
	if in_range and angle_matches:
		_apply_damage_to_target(definition.sweep_damage, &"boss_arm_sweep")
	_finish_attack(&"arm_sweep")


func _finish_attack(attack_id: StringName) -> void:
	_state = State.PURSUING
	_state_remaining = 0.0
	_attack_cooldown_remaining = definition.attack_cooldown_seconds
	attack_resolved.emit(attack_id)


func _set_contact_damage(delta: float) -> void:
	if global_position.distance_squared_to(_target.global_position) <= pow(definition.collision_radius + _target_contact_radius, 2.0):
		_apply_damage_to_target(definition.contact_damage_per_second * delta, &"boss_contact")


func _apply_damage_to_target(amount: float, tag: StringName) -> void:
	if _has_live_target():
		_target_health.apply_damage(DamageEvent.new(self, amount, tag))


func _has_live_target() -> bool:
	return is_instance_valid(_target) and is_instance_valid(_target_health) and _target_health.is_alive()


func _spawn_telegraph(kind: BossTelegraph.TelegraphKind, origin: Vector2, direction: Vector2, radius: float, range_length: float, angle: float, duration: float) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var telegraph := BossTelegraph.new()
	parent.add_child(telegraph)
	telegraph.configure(kind, origin, direction, radius, range_length, angle, duration)


func _update_collision_radius() -> void:
	var collision := get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if collision != null and collision.shape is CircleShape2D:
		(collision.shape as CircleShape2D).radius = definition.collision_radius


func _add_configured_visual() -> void:
	if definition.visual_scene == null or get_node_or_null(^"Visual") != null:
		return
	var visual := definition.visual_scene.instantiate()
	visual.name = &"Visual"
	add_child(visual)


func _set_visual_motion(action: StringName, direction: Vector2) -> void:
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"set_motion_state"):
		visual.call(&"set_motion_state", action, direction)


func _on_health_changed(current: float, maximum: float) -> void:
	health_changed.emit(current, maximum)


func _on_damage_received(_event: DamageEvent, _amount: float) -> void:
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"play_hurt"):
		visual.call(&"play_hurt")


func _on_health_died(final_event: DamageEvent) -> void:
	if _defeat_reported:
		return
	_defeat_reported = true
	_state = State.DEAD
	velocity = Vector2.ZERO
	remove_from_group(&"auto_aim_target")
	remove_from_group(&"survivor_enemy_targets")
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"play_death"):
		visual.call(&"play_death")
	defeated.emit(self, final_event)
