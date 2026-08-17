class_name SterlingKitTuning
extends Resource

## P2's editable Sterling-kit numbers. The behaviors are locked by the design
## documents; these values deliberately remain provisional playtest tuning.
@export_category("Automatic Basic Scaling")
@export_range(0.0, 1.0, 0.005) var basic_damage_growth_per_level: float = 0.05
@export_range(1.0, 5.0, 0.05) var level_five_basic_damage_multiplier: float = 1.25
@export_range(1.0, 3.0, 0.05) var level_five_basic_fire_rate_multiplier: float = 1.18

@export_category("Reposition Burst")
@export_range(16.0, 1000.0, 1.0) var tactical_distance: float = 190.0
@export_range(0.05, 20.0, 0.05) var tactical_fire_rate_buff_seconds: float = 2.5
@export_range(1.0, 4.0, 0.05) var tactical_fire_rate_multiplier: float = 1.45
@export_range(1.0, 3.0, 0.05) var level_ten_tactical_distance_multiplier: float = 1.25
@export_range(1.0, 3.0, 0.05) var level_ten_tactical_buff_duration_multiplier: float = 1.25
@export_range(1.0, 3.0, 0.05) var level_ten_tactical_fire_rate_multiplier: float = 1.7
@export_range(0.05, 3.0, 0.01) var tactical_trail_seconds: float = 0.3

@export_category("Radial Bullet Storm")
@export_range(1, 20, 1) var ultimate_burst_count: int = 4
@export_range(0.03, 2.0, 0.01) var ultimate_burst_interval_seconds: float = 0.18
@export_range(1, 48, 1) var ultimate_projectiles_per_burst: int = 8
@export_range(0.1, 1000.0, 0.1) var ultimate_projectile_damage: float = 20.0
@export_range(10.0, 3000.0, 1.0) var ultimate_projectile_speed: float = 640.0
@export_range(0.1, 10.0, 0.05) var ultimate_projectile_lifetime_seconds: float = 0.9
@export_range(1.0, 64.0, 1.0) var ultimate_projectile_radius: float = 3.0
@export_range(1, 20, 1) var level_fifteen_ultimate_bonus_bursts: int = 2
@export_range(1, 48, 1) var level_fifteen_ultimate_bonus_projectiles_per_burst: int = 4
@export_range(1.0, 5.0, 0.05) var level_fifteen_ultimate_damage_multiplier: float = 1.35

@export_category("Safety Caps")
@export_range(1.0, 60.0, 0.1) var maximum_buffed_basic_shots_per_second: float = 16.0


func basic_damage_multiplier(character_level: int, basic_milestone_active: bool) -> float:
	var multiplier: float = 1.0 + basic_damage_growth_per_level * float(maxi(character_level - 1, 0))
	if basic_milestone_active:
		multiplier *= level_five_basic_damage_multiplier
	return multiplier


func tactical_distance_for(tactical_milestone_active: bool) -> float:
	return tactical_distance * (level_ten_tactical_distance_multiplier if tactical_milestone_active else 1.0)


func tactical_buff_seconds_for(tactical_milestone_active: bool) -> float:
	return tactical_fire_rate_buff_seconds * (level_ten_tactical_buff_duration_multiplier if tactical_milestone_active else 1.0)


func tactical_fire_rate_multiplier_for(tactical_milestone_active: bool) -> float:
	return level_ten_tactical_fire_rate_multiplier if tactical_milestone_active else tactical_fire_rate_multiplier


func ultimate_burst_count_for(ultimate_milestone_active: bool) -> int:
	return ultimate_burst_count + (level_fifteen_ultimate_bonus_bursts if ultimate_milestone_active else 0)


func ultimate_projectiles_per_burst_for(ultimate_milestone_active: bool) -> int:
	return ultimate_projectiles_per_burst + (level_fifteen_ultimate_bonus_projectiles_per_burst if ultimate_milestone_active else 0)


func ultimate_damage_for(ultimate_milestone_active: bool) -> float:
	return ultimate_projectile_damage * (level_fifteen_ultimate_damage_multiplier if ultimate_milestone_active else 1.0)


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if basic_damage_growth_per_level < 0.0 or level_five_basic_damage_multiplier < 1.0 or level_five_basic_fire_rate_multiplier < 1.0:
		errors.append("SterlingKitTuning basic scaling must not weaken Sterling.")
	if tactical_distance <= 0.0 or tactical_fire_rate_buff_seconds <= 0.0 or tactical_fire_rate_multiplier < 1.0:
		errors.append("SterlingKitTuning tactical values must be positive and non-weakening.")
	if ultimate_burst_count <= 0 or ultimate_burst_interval_seconds <= 0.0 or ultimate_projectiles_per_burst <= 0:
		errors.append("SterlingKitTuning ultimate burst configuration is invalid.")
	if ultimate_projectile_damage <= 0.0 or ultimate_projectile_speed <= 0.0 or ultimate_projectile_lifetime_seconds <= 0.0:
		errors.append("SterlingKitTuning ultimate projectile values must be positive.")
	if maximum_buffed_basic_shots_per_second <= 0.0:
		errors.append("SterlingKitTuning requires a positive buffed fire-rate cap.")
	return errors
