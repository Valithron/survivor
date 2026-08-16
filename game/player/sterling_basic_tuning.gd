class_name SterlingBasicTuning
extends Resource

## Temporary P1 balance values. They deliberately live outside the player
## script so combat feel can be iterated without changing runtime code.
@export_category("Cadence")
@export_range(0.1, 30.0, 0.05) var shots_per_second_idle: float = 4.5
@export_range(0.1, 30.0, 0.05) var shots_per_second_at_max_speed: float = 8.5
@export_range(0.1, 30.0, 0.05) var maximum_shots_per_second: float = 9.0
@export_range(0.1, 3.0, 0.05) var movement_rate_exponent: float = 0.8

@export_category("Projectiles")
@export_range(0.1, 1000.0, 0.1) var projectile_damage: float = 16.0
@export_range(10.0, 3000.0, 1.0) var projectile_speed: float = 720.0
@export_range(0.1, 10.0, 0.05) var projectile_lifetime_seconds: float = 1.25
@export_range(1.0, 64.0, 1.0) var projectile_radius: float = 3.0
@export_range(0.0, 64.0, 1.0) var muzzle_offset: float = 12.0
@export_range(0.02, 0.5, 0.01) var basic_animation_hold_seconds: float = 0.1

@export_category("Auto Aim")
@export_range(10.0, 2000.0, 10.0) var auto_aim_range: float = 820.0
@export_range(0.02, 1.0, 0.01) var target_refresh_seconds: float = 0.12
@export_range(0.1, 1.0, 0.01) var target_switch_distance_ratio: float = 0.82


func fire_rate_for_speed(current_speed: float, reference_speed: float) -> float:
	var speed_ratio := clampf(current_speed / maxf(reference_speed, 0.01), 0.0, 1.0)
	var curved_ratio := pow(speed_ratio, movement_rate_exponent)
	var requested_rate := lerpf(shots_per_second_idle, shots_per_second_at_max_speed, curved_ratio)
	return clampf(requested_rate, 0.01, maxf(maximum_shots_per_second, 0.01))


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if shots_per_second_idle <= 0.0:
		errors.append("SterlingBasicTuning idle fire rate must be positive.")
	if shots_per_second_at_max_speed < shots_per_second_idle:
		errors.append("SterlingBasicTuning moving fire rate must not be below idle fire rate.")
	if maximum_shots_per_second < shots_per_second_at_max_speed:
		errors.append("SterlingBasicTuning maximum fire rate must cap at or above moving fire rate.")
	if projectile_damage <= 0.0 or projectile_speed <= 0.0 or projectile_lifetime_seconds <= 0.0 or basic_animation_hold_seconds <= 0.0:
		errors.append("SterlingBasicTuning projectile values must be positive.")
	if auto_aim_range <= 0.0 or target_refresh_seconds <= 0.0:
		errors.append("SterlingBasicTuning auto aim values must be positive.")
	return errors
