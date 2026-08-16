class_name CooperBasicTuning
extends Resource

## Editable baseline for Cooper's locked continuous automatic-rifle stream.
## Exact values stay intentionally provisional until character playtesting.
@export_category("Automatic Rifle")
@export_range(0.1, 40.0, 0.05) var shots_per_second: float = 10.5
@export_range(0.1, 1000.0, 0.1) var projectile_damage: float = 9.0
@export_range(10.0, 3000.0, 1.0) var projectile_speed: float = 860.0
@export_range(0.1, 10.0, 0.05) var projectile_lifetime_seconds: float = 1.15
@export_range(1.0, 64.0, 1.0) var projectile_radius: float = 2.0
@export_range(0.0, 64.0, 1.0) var muzzle_offset: float = 11.0
@export_range(0.02, 0.5, 0.01) var basic_animation_hold_seconds: float = 0.09

@export_category("Level 5 Basic Milestone")
@export_range(1.0, 5.0, 0.05) var level_five_damage_multiplier: float = 1.2
@export_range(1.0, 4.0, 0.05) var level_five_fire_rate_multiplier: float = 1.25

@export_category("Auto Aim")
@export_range(10.0, 2000.0, 10.0) var auto_aim_range: float = 760.0
@export_range(0.02, 1.0, 0.01) var target_refresh_seconds: float = 0.1
@export_range(0.1, 1.0, 0.01) var target_switch_distance_ratio: float = 0.82


func damage_for(basic_milestone_active: bool) -> float:
	return projectile_damage * (level_five_damage_multiplier if basic_milestone_active else 1.0)


func fire_rate_for(basic_milestone_active: bool) -> float:
	return shots_per_second * (level_five_fire_rate_multiplier if basic_milestone_active else 1.0)


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if shots_per_second <= 0.0 or projectile_damage <= 0.0 or projectile_speed <= 0.0 or projectile_lifetime_seconds <= 0.0:
		errors.append("CooperBasicTuning rifle cadence and projectile values must be positive.")
	if level_five_damage_multiplier < 1.0 or level_five_fire_rate_multiplier < 1.0:
		errors.append("CooperBasicTuning Level 5 milestone must not weaken sustained fire.")
	if auto_aim_range <= 0.0 or target_refresh_seconds <= 0.0:
		errors.append("CooperBasicTuning auto-aim values must be positive.")
	return errors
