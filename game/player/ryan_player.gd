class_name RyanPlayer
extends CharacterBody2D

const IMPACT_EFFECT_SCRIPT := preload("res://game/player/ryan_impact_effect.gd")

## Ryan's independent Bruiser runtime. It deliberately reuses only the narrow
## F0 targeting/damage and animation seams, leaving Sterling's Speedster code
## untouched and avoiding character-specific branches in shared systems.
signal aim_mode_changed(manual_aim_enabled: bool)
signal aim_direction_changed(direction: Vector2)
signal basic_fired(direction: Vector2, hit_count: int, damage_per_target: float)
signal animation_state_changed(animation_name: StringName)
signal health_changed(current_health: float, maximum_health: float)
signal damage_received(event: DamageEvent, applied_amount: float)
signal died(event: DamageEvent)
signal kit_level_changed(level: int)
signal ability_milestone_unlocked(ability_id: StringName, level: int)
signal tactical_activated(direction: Vector2, duration_seconds: float, charge_speed: float)
signal charge_hit(target: Node2D, damage: float)
signal ultimate_activated(impact_count: int)
signal radial_impact_fired(impact_index: int, radius: float, damage: float, final_shockwave: bool, hit_count: int)

@export var character_definition: CharacterDefinition
@export var basic_tuning: RyanBasicTuning
@export var kit_tuning: RyanKitTuning

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
var _charge_duration_remaining := 0.0
var _charge_direction := Vector2.RIGHT
var _charge_hit_ids: Dictionary = {}
var _impacts_remaining := 0
var _impact_delay_remaining := 0.0
var _impact_index := 0


func _ready() -> void:
	if character_definition == null or basic_tuning == null or kit_tuning == null:
		push_error("RyanPlayer requires CharacterDefinition, RyanBasicTuning, and RyanKitTuning resources.")
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
	_update_aim_solution(delta)
	if _charge_duration_remaining > 0.0:
		_process_armored_charge(delta)
	else:
		_process_movement()
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
	return basic_tuning.shots_per_second if basic_tuning != null else 0.0


func get_effective_basic_damage() -> float:
	return basic_tuning.damage_for(basic_milestone_active) if basic_tuning != null else 0.0


func get_tactical_cooldown_ratio() -> float:
	return _cooldown_ratio(tactical_cooldown_remaining, _tactical_cooldown_seconds())


func get_ultimate_cooldown_ratio() -> float:
	return _cooldown_ratio(ultimate_cooldown_remaining, _ultimate_cooldown_seconds())


func is_ultimate_active() -> bool:
	return _impacts_remaining > 0


func is_charging() -> bool:
	return _charge_duration_remaining > 0.0


func get_tactical_total_distance() -> float:
	return kit_tuning.charge_duration_for(tactical_milestone_active) * kit_tuning.charge_speed if kit_tuning != null else 0.0


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
		ability_milestone_unlocked.emit(&"ryan_combat_shotgun", character_definition.milestones.basic_upgrade_level)
	if tactical_milestone_active and not previous_tactical:
		ability_milestone_unlocked.emit(&"ryan_armored_charge", character_definition.milestones.tactical_upgrade_level)
	if ultimate_milestone_active and not previous_ultimate:
		ability_milestone_unlocked.emit(&"ryan_escalating_impacts", character_definition.milestones.ultimate_upgrade_level)


func try_activate_tactical(explicit_direction: Vector2 = Vector2.ZERO) -> bool:
	if not _can_use_abilities() or tactical_cooldown_remaining > 0.0 or is_charging():
		return false
	_charge_direction = _resolve_tactical_direction(explicit_direction)
	_charge_duration_remaining = kit_tuning.charge_duration_for(tactical_milestone_active)
	_charge_hit_ids.clear()
	tactical_cooldown_remaining = _tactical_cooldown_seconds()
	tactical_activated.emit(_charge_direction, _charge_duration_remaining, kit_tuning.charge_speed)
	return true


func try_activate_ultimate() -> bool:
	if not _can_use_abilities() or ultimate_cooldown_remaining > 0.0 or is_ultimate_active():
		return false
	ultimate_cooldown_remaining = _ultimate_cooldown_seconds()
	_impacts_remaining = kit_tuning.impact_count_for(ultimate_milestone_active)
	_impact_delay_remaining = 0.0
	_impact_index = 0
	ultimate_activated.emit(_impacts_remaining)
	_fire_next_radial_impact()
	return true


func apply_damage(event: DamageEvent) -> float:
	return health_component.apply_damage(event)


func fire_basic_once_for_test() -> void:
	if health_component.is_alive():
		_fire_basic()


func _process_movement() -> void:
	var input_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = input_direction * character_definition.move_speed
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
	while _fire_cooldown_remaining <= 0.0 and shots_this_frame < 2:
		_fire_basic()
		_fire_cooldown_remaining += 1.0 / maxf(get_current_fire_rate(), 0.01)
		shots_this_frame += 1


func _fire_basic() -> void:
	if basic_tuning == null:
		return
	var hit_count := 0
	var maximum_targets := basic_tuning.maximum_targets_for(basic_milestone_active)
	var half_angle := deg_to_rad(basic_tuning.cone_angle_for(basic_milestone_active) * 0.5)
	var damage := get_effective_basic_damage()
	var knockback := basic_tuning.knockback_for(basic_milestone_active)
	for target in WeaponTargeting.nearby_targets(self, global_position, basic_tuning.cone_range):
		if hit_count >= maximum_targets:
			break
		var offset := target.global_position - global_position
		if offset.length_squared() <= 0.0001:
			continue
		var direction_to_target := offset.normalized()
		if absf(basic_aim_direction.angle_to(direction_to_target)) > half_angle:
			continue
		if WeaponTargeting.apply_damage(target, self, damage, &"ryan_combat_shotgun", direction_to_target * knockback):
			hit_count += 1
	basic_fired.emit(basic_aim_direction, hit_count, damage)
	_basic_animation_remaining = basic_tuning.basic_animation_hold_seconds


func _process_armored_charge(delta: float) -> void:
	_charge_duration_remaining = maxf(_charge_duration_remaining - delta, 0.0)
	velocity = _charge_direction * kit_tuning.charge_speed
	move_and_slide()
	_apply_charge_hits()
	if _charge_duration_remaining <= 0.0:
		velocity = Vector2.ZERO


func _apply_charge_hits() -> void:
	var damage := kit_tuning.charge_damage_for(tactical_milestone_active)
	var shove := kit_tuning.charge_shove_for(tactical_milestone_active)
	for target in WeaponTargeting.nearby_targets(self, global_position, kit_tuning.charge_hit_radius):
		var target_id := target.get_instance_id()
		if _charge_hit_ids.has(target_id):
			continue
		var offset := target.global_position - global_position
		var shove_direction := offset.normalized() if offset.length_squared() > 0.0001 else _charge_direction
		if WeaponTargeting.apply_damage(target, self, damage, &"ryan_armored_charge", shove_direction * shove):
			_charge_hit_ids[target_id] = true
			charge_hit.emit(target, damage)


func _process_kit_state(delta: float) -> void:
	tactical_cooldown_remaining = maxf(tactical_cooldown_remaining - delta, 0.0)
	ultimate_cooldown_remaining = maxf(ultimate_cooldown_remaining - delta, 0.0)
	if _impacts_remaining <= 0:
		return
	_impact_delay_remaining -= delta
	var safety := 0
	while _impacts_remaining > 0 and _impact_delay_remaining <= 0.0 and safety < 2:
		_fire_next_radial_impact()
		safety += 1


func _fire_next_radial_impact() -> void:
	if _impacts_remaining <= 0 or kit_tuning == null:
		return
	var is_final := _impacts_remaining == 1
	var radius := kit_tuning.impact_radius_for(_impact_index, is_final, ultimate_milestone_active)
	var damage := kit_tuning.impact_damage_for(_impact_index, is_final, ultimate_milestone_active)
	var knockback := kit_tuning.impact_knockback_for(_impact_index, is_final, ultimate_milestone_active)
	var hit_count := 0
	for target in WeaponTargeting.nearby_targets(self, global_position, radius):
		var offset := target.global_position - global_position
		var impact_direction := offset.normalized() if offset.length_squared() > 0.0001 else basic_aim_direction
		if WeaponTargeting.apply_damage(target, self, damage, &"ryan_final_shockwave" if is_final else &"ryan_radial_impact", impact_direction * knockback):
			hit_count += 1
	radial_impact_fired.emit(_impact_index, radius, damage, is_final, hit_count)
	_spawn_impact_effect(radius, is_final)
	_impacts_remaining -= 1
	_impact_index += 1
	_impact_delay_remaining += kit_tuning.impact_interval_seconds


func _spawn_impact_effect(effect_radius: float, final_impact: bool) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var effect := IMPACT_EFFECT_SCRIPT.new() as RyanImpactEffect
	parent.add_child(effect)
	effect.global_position = global_position
	effect.configure(effect_radius, final_impact)


func _resolve_tactical_direction(explicit_direction: Vector2) -> Vector2:
	if explicit_direction.length_squared() > 0.0001:
		return explicit_direction.normalized()
	## Tacticals are aimed directly; unlike the basic, this must not inherit the
	## persistent auto/manual toggle. Mouse aim is maintained in either mode.
	if manual_aim_direction.length_squared() > 0.0001:
		return manual_aim_direction.normalized()
	var movement_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if movement_direction.length_squared() > 0.0001:
		return movement_direction.normalized()
	return basic_aim_direction.normalized() if basic_aim_direction.length_squared() > 0.0001 else Vector2.RIGHT


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
	## ART-ROSTER owns Ryan's final sprite. Leaving this optional lets the combat
	## packet be tested truthfully without presenting debug geometry as final art.
	if character_definition.sprite_scene == null or get_node_or_null(^"Visual") != null:
		return
	var visual := character_definition.sprite_scene.instantiate()
	visual.name = &"Visual"
	add_child(visual)
	if visual.has_method(&"play_basic_shot"):
		basic_fired.connect(func(_direction: Vector2, _hits: int, _damage: float) -> void:
			if is_instance_valid(visual):
				visual.call(&"play_basic_shot", 0)
		)


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
