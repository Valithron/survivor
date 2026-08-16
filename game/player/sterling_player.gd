class_name SterlingPlayer
extends CharacterBody2D

## Sterling's movement, unique basic, and P2 character-kit runtime. Shared
## weapons remain separate from this character-specific component.
signal aim_mode_changed(manual_aim_enabled: bool)
signal aim_direction_changed(direction: Vector2)
signal basic_fired(direction: Vector2, muzzle_position: Vector2, muzzle_side: int, fire_rate: float)
signal animation_state_changed(animation_name: StringName)
signal health_changed(current_health: float, maximum_health: float)
signal damage_received(event: DamageEvent, applied_amount: float)
signal died(event: DamageEvent)
signal kit_level_changed(level: int)
signal ability_milestone_unlocked(ability_id: StringName, level: int)
signal tactical_activated(direction: Vector2, start_position: Vector2, end_position: Vector2, buff_seconds: float)
signal ultimate_activated(burst_count: int, projectiles_per_burst: int)
signal radial_burst_fired(projectiles_per_burst: int, projectile_damage: float)

@export var character_definition: CharacterDefinition
@export var basic_tuning: SterlingBasicTuning
@export var kit_tuning: SterlingKitTuning

@onready var health_component: HealthComponent = $HealthComponent

var manual_aim_enabled := false
var manual_aim_direction := Vector2.RIGHT
var basic_aim_direction := Vector2.RIGHT
var current_animation_name: StringName = &"idle_e"
var current_auto_target: Node2D

var _fire_cooldown_remaining := 0.0
var _target_refresh_remaining := 0.0
var _basic_animation_remaining := 0.0
var _next_muzzle_side := -1
var character_level := 1
var basic_milestone_active := false
var tactical_milestone_active := false
var ultimate_milestone_active := false
var tactical_cooldown_remaining := 0.0
var ultimate_cooldown_remaining := 0.0
var fire_rate_buff_remaining := 0.0
var _radial_bursts_remaining := 0
var _radial_burst_delay_remaining := 0.0
var _radial_phase := 0.0


func _ready() -> void:
	if character_definition == null:
		push_error("SterlingPlayer requires a CharacterDefinition.")
		return
	if basic_tuning == null:
		push_error("SterlingPlayer requires SterlingBasicTuning.")
		return
	if kit_tuning == null:
		push_error("SterlingPlayer requires SterlingKitTuning.")
		return
	health_component.configure(character_definition.base_max_health)
	health_component.health_changed.connect(_on_health_changed)
	health_component.damage_received.connect(_on_health_damage_received)
	health_component.died.connect(_on_health_died)
	_add_configured_visual()
	_update_animation_state(false)
	_sync_visual_animation()


func _physics_process(delta: float) -> void:
	if character_definition == null or basic_tuning == null or kit_tuning == null or not health_component.is_alive():
		return
	_basic_animation_remaining = maxf(_basic_animation_remaining - delta, 0.0)
	_process_kit_state(delta)
	var input_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	velocity = input_direction * character_definition.move_speed
	move_and_slide()
	_update_aim_solution(delta)
	_process_basic_attack(delta)
	_update_animation_state(_basic_animation_remaining > 0.0)


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
	if character_definition == null or basic_tuning == null or kit_tuning == null:
		return 0.0
	var fire_rate := basic_tuning.fire_rate_for_speed(velocity.length(), character_definition.move_speed)
	if basic_milestone_active:
		fire_rate *= kit_tuning.level_five_basic_fire_rate_multiplier
	if fire_rate_buff_remaining > 0.0:
		fire_rate *= kit_tuning.tactical_fire_rate_multiplier_for(tactical_milestone_active)
	return minf(fire_rate, kit_tuning.maximum_buffed_basic_shots_per_second)


func get_basic_aim_direction() -> Vector2:
	return basic_aim_direction


func get_effective_basic_damage() -> float:
	if basic_tuning == null or kit_tuning == null:
		return 0.0
	return basic_tuning.projectile_damage * kit_tuning.basic_damage_multiplier(character_level, basic_milestone_active)


func get_tactical_cooldown_ratio() -> float:
	return _cooldown_ratio(tactical_cooldown_remaining, _tactical_cooldown_seconds())


func get_ultimate_cooldown_ratio() -> float:
	return _cooldown_ratio(ultimate_cooldown_remaining, _ultimate_cooldown_seconds())


func is_ultimate_active() -> bool:
	return _radial_bursts_remaining > 0


func set_character_level(level: int) -> void:
	var next_level: int = maxi(level, 1)
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
		ability_milestone_unlocked.emit(&"sterling_dual_pistols", character_definition.milestones.basic_upgrade_level)
	if tactical_milestone_active and not previous_tactical:
		ability_milestone_unlocked.emit(&"sterling_reposition_burst", character_definition.milestones.tactical_upgrade_level)
	if ultimate_milestone_active and not previous_ultimate:
		ability_milestone_unlocked.emit(&"sterling_radial_storm", character_definition.milestones.ultimate_upgrade_level)


func try_activate_tactical(explicit_direction: Vector2 = Vector2.ZERO) -> bool:
	if not _can_use_abilities() or tactical_cooldown_remaining > 0.0:
		return false
	var direction := _resolve_tactical_direction(explicit_direction)
	var start_position := global_position
	## M1 arena props and perimeter use layer 8. Move through the dash motion so
	## this immediate reposition respects the same readable parking-lot blockers
	## as ordinary movement instead of silently tunneling through a car.
	move_and_collide(direction * kit_tuning.tactical_distance_for(tactical_milestone_active))
	var end_position := global_position
	tactical_cooldown_remaining = _tactical_cooldown_seconds()
	fire_rate_buff_remaining = kit_tuning.tactical_buff_seconds_for(tactical_milestone_active)
	_spawn_tactical_trail(start_position, end_position)
	tactical_activated.emit(direction, start_position, end_position, fire_rate_buff_remaining)
	return true


func try_activate_ultimate() -> bool:
	if not _can_use_abilities() or ultimate_cooldown_remaining > 0.0 or _radial_bursts_remaining > 0:
		return false
	ultimate_cooldown_remaining = _ultimate_cooldown_seconds()
	_radial_bursts_remaining = kit_tuning.ultimate_burst_count_for(ultimate_milestone_active)
	_radial_burst_delay_remaining = 0.0
	ultimate_activated.emit(
		_radial_bursts_remaining,
		kit_tuning.ultimate_projectiles_per_burst_for(ultimate_milestone_active),
	)
	_fire_next_radial_burst()
	return true


func apply_damage(event: DamageEvent) -> float:
	return health_component.apply_damage(event)


func fire_basic_once_for_test() -> void:
	if character_definition == null or basic_tuning == null or not health_component.is_alive():
		return
	_fire_basic()


func _update_aim_solution(delta: float) -> void:
	var mouse_direction := get_global_mouse_position() - global_position
	if mouse_direction.length_squared() > 0.0001:
		manual_aim_direction = mouse_direction.normalized()
	if manual_aim_enabled:
		_set_basic_aim_direction(manual_aim_direction)
		return

	## Enemies remove themselves immediately on death. Never pass a freed target
	## into the typed resolver while the next target refresh is pending.
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
	var side := Vector2(-basic_aim_direction.y, basic_aim_direction.x) * basic_tuning.muzzle_offset * _next_muzzle_side
	var muzzle_position := global_position + side + basic_aim_direction * 8.0
	var projectile := SterlingBasicProjectile.new()
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
	_next_muzzle_side *= -1
	basic_fired.emit(basic_aim_direction, muzzle_position, _next_muzzle_side * -1, get_current_fire_rate())
	_basic_animation_remaining = basic_tuning.basic_animation_hold_seconds
	_update_animation_state(true)


func _process_kit_state(delta: float) -> void:
	tactical_cooldown_remaining = maxf(tactical_cooldown_remaining - delta, 0.0)
	ultimate_cooldown_remaining = maxf(ultimate_cooldown_remaining - delta, 0.0)
	fire_rate_buff_remaining = maxf(fire_rate_buff_remaining - delta, 0.0)
	if _radial_bursts_remaining <= 0:
		return
	_radial_burst_delay_remaining -= delta
	var safety := 0
	while _radial_bursts_remaining > 0 and _radial_burst_delay_remaining <= 0.0 and safety < 2:
		_fire_next_radial_burst()
		safety += 1


func _fire_next_radial_burst() -> void:
	if _radial_bursts_remaining <= 0 or kit_tuning == null:
		return
	var projectile_count := kit_tuning.ultimate_projectiles_per_burst_for(ultimate_milestone_active)
	var projectile_damage := kit_tuning.ultimate_damage_for(ultimate_milestone_active)
	var projectile_parent := get_parent()
	if projectile_parent != null:
		for projectile_index in range(projectile_count):
			var angle := _radial_phase + TAU * float(projectile_index) / float(projectile_count)
			var direction := Vector2.RIGHT.rotated(angle)
			var projectile := SterlingBasicProjectile.new()
			projectile.configure(
				global_position + direction * 12.0,
				direction,
				kit_tuning.ultimate_projectile_speed,
				projectile_damage,
				kit_tuning.ultimate_projectile_lifetime_seconds,
				kit_tuning.ultimate_projectile_radius,
				self,
				&"sterling_radial_storm",
			)
			projectile_parent.add_child(projectile)
	radial_burst_fired.emit(projectile_count, projectile_damage)
	_radial_bursts_remaining -= 1
	_radial_burst_delay_remaining += kit_tuning.ultimate_burst_interval_seconds
	_radial_phase = fposmod(_radial_phase + PI / float(projectile_count), TAU)


func _resolve_tactical_direction(explicit_direction: Vector2) -> Vector2:
	if explicit_direction.length_squared() > 0.0001:
		return explicit_direction.normalized()
	var movement_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if movement_direction.length_squared() > 0.0001:
		return movement_direction.normalized()
	if manual_aim_direction.length_squared() > 0.0001:
		return manual_aim_direction.normalized()
	return basic_aim_direction.normalized() if basic_aim_direction.length_squared() > 0.0001 else Vector2.RIGHT


func _spawn_tactical_trail(start_position: Vector2, end_position: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	var trail := SterlingRepositionTrail.new()
	parent.add_child(trail)
	trail.configure(start_position, end_position, kit_tuning.tactical_trail_seconds)


func _can_use_abilities() -> bool:
	return character_definition != null and kit_tuning != null and health_component != null and health_component.is_alive()


func _tactical_cooldown_seconds() -> float:
	return maxf(character_definition.tactical.cooldown_seconds, 0.01) if character_definition != null and character_definition.tactical != null else 0.01


func _ultimate_cooldown_seconds() -> float:
	return maxf(character_definition.ultimate.cooldown_seconds, 0.01) if character_definition != null and character_definition.ultimate != null else 0.01


func _cooldown_ratio(remaining: float, maximum: float) -> float:
	return clampf(remaining / maxf(maximum, 0.01), 0.0, 1.0)


func _set_basic_aim_direction(direction: Vector2) -> void:
	if direction.length_squared() <= 0.0001:
		return
	basic_aim_direction = direction.normalized()
	aim_direction_changed.emit(basic_aim_direction)


func _update_animation_state(firing: bool) -> void:
	var action: StringName = &"basic" if firing else (&"run" if velocity.length_squared() > 0.1 else &"idle")
	var next_animation := AnimationConvention.player_animation(action, basic_aim_direction)
	if current_animation_name == next_animation:
		return
	current_animation_name = next_animation
	animation_state_changed.emit(current_animation_name)
	_sync_visual_animation()


func _add_configured_visual() -> void:
	if character_definition.sprite_scene == null:
		push_error("SterlingPlayer requires CharacterDefinition.sprite_scene for final Prototype art.")
		return
	if get_node_or_null(^"Visual") != null:
		return
	var visual := character_definition.sprite_scene.instantiate()
	visual.name = &"Visual"
	add_child(visual)


func _sync_visual_animation() -> void:
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"set_animation_state"):
		visual.call(&"set_animation_state", current_animation_name)


func _on_health_changed(current: float, maximum: float) -> void:
	health_changed.emit(current, maximum)


func _on_health_damage_received(event: DamageEvent, amount: float) -> void:
	damage_received.emit(event, amount)
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"play_hurt"):
		visual.call(&"play_hurt")


func _on_health_died(event: DamageEvent) -> void:
	var visual := get_node_or_null(^"Visual")
	if visual != null and visual.has_method(&"play_death"):
		visual.call(&"play_death")
	died.emit(event)
