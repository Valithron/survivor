class_name CooperPlayer
extends CharacterBody2D

## Cooper's independent Glass Cannon runtime. It shares only established aim,
## health, DamageEvent, and animation naming contracts with the existing game.
signal aim_mode_changed(manual_aim_enabled: bool)
signal aim_direction_changed(direction: Vector2)
signal basic_fired(direction: Vector2, muzzle_position: Vector2, fire_rate: float, damage: float)
signal animation_state_changed(animation_name: StringName)
signal health_changed(current_health: float, maximum_health: float)
signal damage_received(event: DamageEvent, applied_amount: float)
signal died(event: DamageEvent)
signal kit_level_changed(level: int)
signal ability_milestone_unlocked(ability_id: StringName, level: int)
signal tactical_activated(duration_seconds: float, damage_multiplier: float, move_speed_multiplier: float)
signal ultimate_activated(duration_seconds: float, damage_multiplier: float, fire_rate_multiplier: float)

@export var character_definition: CharacterDefinition
@export var basic_tuning: CooperBasicTuning
@export var kit_tuning: CooperKitTuning

@onready var health_component: HealthComponent = $HealthComponent

var manual_aim_enabled := false
var manual_aim_direction := Vector2.RIGHT
var basic_aim_direction := Vector2.RIGHT
var current_animation_name: StringName = &"idle_e"
var current_auto_target: Node2D
var character_level := 1
var basic_milestone_active := false
var tactical_milestone_active := false
var ultimate_milestone_active := false
var tactical_cooldown_remaining := 0.0
var ultimate_cooldown_remaining := 0.0

var _fire_cooldown_remaining := 0.0
var _target_refresh_remaining := 0.0
var _basic_animation_remaining := 0.0
var _overclock_remaining := 0.0
var _ultimate_remaining := 0.0


func _ready() -> void:
	if character_definition == null or basic_tuning == null or kit_tuning == null:
		push_error("CooperPlayer requires CharacterDefinition, CooperBasicTuning, and CooperKitTuning resources.")
		set_physics_process(false)
		return
	health_component.configure(character_definition.base_max_health)
	health_component.health_changed.connect(_on_health_changed)
	health_component.damage_received.connect(_on_health_damage_received)
	health_component.died.connect(_on_health_died)
	_add_configured_visual_if_available()
	_update_animation_state()


func _physics_process(delta: float) -> void:
	if not health_component.is_alive():
		return
	_basic_animation_remaining = maxf(_basic_animation_remaining - delta, 0.0)
	_process_kit_state(delta)
	_process_movement()
	_update_aim_solution(delta)
	_process_basic_attack(delta)
	_update_animation_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_aim_mode") and not event.is_echo():
		set_manual_aim_enabled(not manual_aim_enabled)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"tactical") and not event.is_echo():
		try_activate_tactical()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ultimate") and not event.is_echo():
		try_activate_ultimate()
		get_viewport().set_input_as_handled()


func set_manual_aim_enabled(enabled: bool) -> void:
	if manual_aim_enabled == enabled:
		return
	manual_aim_enabled = enabled
	aim_mode_changed.emit(manual_aim_enabled)


func set_manual_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	manual_aim_direction = direction.normalized()
	if manual_aim_enabled:
		_set_basic_aim_direction(manual_aim_direction)


func get_current_fire_rate() -> float:
	if basic_tuning == null or kit_tuning == null:
		return 0.0
	var rate := basic_tuning.fire_rate_for(basic_milestone_active)
	if is_ultimate_active():
		rate *= kit_tuning.ultimate_fire_rate_for(ultimate_milestone_active)
	return rate


func get_effective_basic_damage() -> float:
	if basic_tuning == null or kit_tuning == null:
		return 0.0
	var damage := basic_tuning.damage_for(basic_milestone_active)
	if is_overclock_active():
		damage *= kit_tuning.overclock_damage_for(tactical_milestone_active)
	if is_ultimate_active():
		damage *= kit_tuning.ultimate_damage_for(ultimate_milestone_active)
	return damage


func get_effective_move_speed() -> float:
	if character_definition == null or kit_tuning == null:
		return 0.0
	var speed := character_definition.move_speed
	if is_overclock_active():
		speed *= kit_tuning.overclock_move_speed_for(tactical_milestone_active)
	if is_ultimate_active():
		speed *= kit_tuning.ultimate_move_speed_multiplier
	return speed


func get_tactical_cooldown_ratio() -> float:
	return _cooldown_ratio(tactical_cooldown_remaining, _tactical_cooldown_seconds())


func get_ultimate_cooldown_ratio() -> float:
	return _cooldown_ratio(ultimate_cooldown_remaining, _ultimate_cooldown_seconds())


func is_overclock_active() -> bool:
	return _overclock_remaining > 0.0


func is_ultimate_active() -> bool:
	return _ultimate_remaining > 0.0


func set_character_level(level: int) -> void:
	var next_level := maxi(level, 1)
	var previous_basic := basic_milestone_active
	var previous_tactical := tactical_milestone_active
	var previous_ultimate := ultimate_milestone_active
	character_level = next_level
	if character_definition != null and character_definition.milestones != null:
		basic_milestone_active = character_level >= character_definition.milestones.basic_upgrade_level
		tactical_milestone_active = character_level >= character_definition.milestones.tactical_upgrade_level
		ultimate_milestone_active = character_level >= character_definition.milestones.ultimate_upgrade_level
	kit_level_changed.emit(character_level)
	if basic_milestone_active and not previous_basic:
		ability_milestone_unlocked.emit(&"cooper_automatic_rifle", character_definition.milestones.basic_upgrade_level)
	if tactical_milestone_active and not previous_tactical:
		ability_milestone_unlocked.emit(&"cooper_damage_overclock", character_definition.milestones.tactical_upgrade_level)
	if ultimate_milestone_active and not previous_ultimate:
		ability_milestone_unlocked.emit(&"cooper_anchored_sustained_fire", character_definition.milestones.ultimate_upgrade_level)


func try_activate_tactical() -> bool:
	if not _can_use_abilities() or tactical_cooldown_remaining > 0.0 or is_overclock_active():
		return false
	_overclock_remaining = kit_tuning.overclock_duration_for(tactical_milestone_active)
	tactical_cooldown_remaining = _tactical_cooldown_seconds()
	tactical_activated.emit(_overclock_remaining, kit_tuning.overclock_damage_for(tactical_milestone_active), kit_tuning.overclock_move_speed_for(tactical_milestone_active))
	return true


func try_activate_ultimate() -> bool:
	if not _can_use_abilities() or ultimate_cooldown_remaining > 0.0 or is_ultimate_active():
		return false
	_ultimate_remaining = kit_tuning.ultimate_duration_for(ultimate_milestone_active)
	ultimate_cooldown_remaining = _ultimate_cooldown_seconds()
	ultimate_activated.emit(_ultimate_remaining, kit_tuning.ultimate_damage_for(ultimate_milestone_active), kit_tuning.ultimate_fire_rate_for(ultimate_milestone_active))
	return true


func apply_damage(event: DamageEvent) -> float:
	return health_component.apply_damage(event)


func fire_basic_once_for_test() -> void:
	if health_component.is_alive():
		_fire_basic()


func _process_kit_state(delta: float) -> void:
	tactical_cooldown_remaining = maxf(tactical_cooldown_remaining - delta, 0.0)
	ultimate_cooldown_remaining = maxf(ultimate_cooldown_remaining - delta, 0.0)
	_overclock_remaining = maxf(_overclock_remaining - delta, 0.0)
	_ultimate_remaining = maxf(_ultimate_remaining - delta, 0.0)


func _process_movement() -> void:
	var input_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = input_direction * get_effective_move_speed()
	move_and_slide()


func _update_aim_solution(delta: float) -> void:
	var mouse_direction := get_global_mouse_position() - global_position
	if mouse_direction.length_squared() > 0.0001:
		manual_aim_direction = mouse_direction.normalized()
	if manual_aim_enabled:
		_set_basic_aim_direction(manual_aim_direction)
		return
	if current_auto_target != null and not is_instance_valid(current_auto_target):
		current_auto_target = null
		_target_refresh_remaining -= delta
	if _target_refresh_remaining <= 0.0:
		current_auto_target = AutoAimResolver.choose_target(
			global_position,
			get_tree().get_nodes_in_group(AutoAimResolver.TARGET_GROUP),
			current_auto_target,
			basic_tuning.auto_aim_range,
			basic_tuning.target_switch_distance_ratio,
		)
		_target_refresh_remaining = basic_tuning.target_refresh_seconds
	if current_auto_target != null:
		var target_direction := current_auto_target.global_position - global_position
		if target_direction.length_squared() > 0.0001:
			_set_basic_aim_direction(target_direction.normalized())


func _process_basic_attack(delta: float) -> void:
	_fire_cooldown_remaining -= delta
	var shots_this_frame := 0
	while _fire_cooldown_remaining <= 0.0 and shots_this_frame < 3:
		_fire_basic()
		_fire_cooldown_remaining += 1.0 / maxf(get_current_fire_rate(), 0.01)
		shots_this_frame += 1


func _fire_basic() -> void:
	if basic_tuning == null:
		return
	var side := Vector2(-basic_aim_direction.y, basic_aim_direction.x) * basic_tuning.muzzle_offset * (1.0 if _fire_cooldown_remaining >= 0.0 else -1.0)
	var muzzle_position := global_position + side + basic_aim_direction * 10.0
	var projectile := CooperRifleProjectile.new()
	projectile.configure(
		muzzle_position,
		basic_aim_direction,
		basic_tuning.projectile_speed,
		get_effective_basic_damage(),
		basic_tuning.projectile_lifetime_seconds,
		basic_tuning.projectile_radius,
		self,
	)
	var projectile_parent := get_parent()
	if projectile_parent != null:
		projectile_parent.add_child(projectile)
	basic_fired.emit(basic_aim_direction, muzzle_position, get_current_fire_rate(), get_effective_basic_damage())
	_basic_animation_remaining = basic_tuning.basic_animation_hold_seconds


func _can_use_abilities() -> bool:
	return character_definition != null and kit_tuning != null and health_component != null and health_component.is_alive()


func _tactical_cooldown_seconds() -> float:
	return maxf(character_definition.tactical.cooldown_seconds, 0.01) if character_definition.tactical != null else 0.01


func _ultimate_cooldown_seconds() -> float:
	return maxf(character_definition.ultimate.cooldown_seconds, 0.01) if character_definition.ultimate != null else 0.01


func _cooldown_ratio(remaining: float, maximum: float) -> float:
	return clampf(remaining / maxf(maximum, 0.01), 0.0, 1.0)


func _set_basic_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	basic_aim_direction = direction.normalized()
	aim_direction_changed.emit(basic_aim_direction)


func _update_animation_state() -> void:
	var action: StringName = &"basic" if _basic_animation_remaining > 0.0 else (&"run" if velocity.length_squared() > 0.1 else &"idle")
	var next_animation := AnimationConvention.player_animation(action, basic_aim_direction)
	if current_animation_name == next_animation:
		return
	current_animation_name = next_animation
	animation_state_changed.emit(current_animation_name)
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"set_animation_state"):
		visual.call(&"set_animation_state", current_animation_name)


func _add_configured_visual_if_available() -> void:
	## ART-ROSTER owns Cooper's final sprite. No debug silhouette is passed off
	## as art while this mechanical branch is independently validated.
	if character_definition.sprite_scene == null or get_node_or_null(^"Visual") != null:
		return
	var visual := character_definition.sprite_scene.instantiate()
	visual.name = &"Visual"
	add_child(visual)


func _on_health_changed(current: float, maximum: float) -> void:
	health_changed.emit(current, maximum)


func _on_health_damage_received(event: DamageEvent, amount: float) -> void:
	damage_received.emit(event, amount)
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"play_hurt"):
		visual.call(&"play_hurt")


func _on_health_died(event: DamageEvent) -> void:
	velocity = Vector2.ZERO
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"play_death"):
		visual.call(&"play_death")
	died.emit(event)
