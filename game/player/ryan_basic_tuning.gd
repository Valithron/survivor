class_name RyanBasicTuning
extends Resource

## Editable implementation values for Ryan's locked close-range shotgun basic.
## They are deliberately provisional; the Bruiser rhythm is specified, while
## exact damage, cadence, and reach remain playtest tuning.
@export_category("Shotgun")
@export_range(0.1, 20.0, 0.05) var shots_per_second: float = 1.2
@export_range(16.0, 800.0, 1.0) var cone_range: float = 172.0
@export_range(5.0, 175.0, 1.0) var cone_angle_degrees: float = 48.0
@export_range(0.1, 1000.0, 0.1) var damage_per_target: float = 34.0
@export_range(0.0, 2000.0, 1.0) var knockback_strength: float = 92.0
@export_range(1, 128, 1) var maximum_targets_per_blast: int = 14
@export_range(0.02, 0.5, 0.01) var basic_animation_hold_seconds: float = 0.14

@export_category("Level 5 Basic Milestone")
@export_range(1.0, 5.0, 0.05) var level_five_damage_multiplier: float = 1.3
@export_range(0.0, 90.0, 1.0) var level_five_cone_angle_bonus_degrees: float = 10.0
@export_range(1.0, 5.0, 0.05) var level_five_knockback_multiplier: float = 1.28
@export_range(0, 64, 1) var level_five_bonus_targets: int = 3

@export_category("Auto Aim")
@export_range(10.0, 2000.0, 10.0) var auto_aim_range: float = 540.0
@export_range(0.02, 1.0, 0.01) var target_refresh_seconds: float = 0.12
@export_range(0.1, 1.0, 0.01) var target_switch_distance_ratio: float = 0.82


func cone_angle_for(basic_milestone_active: bool) -> float:
	return cone_angle_degrees + (level_five_cone_angle_bonus_degrees if basic_milestone_active else 0.0)


func damage_for(basic_milestone_active: bool) -> float:
	return damage_per_target * (level_five_damage_multiplier if basic_milestone_active else 1.0)


func knockback_for(basic_milestone_active: bool) -> float:
	return knockback_strength * (level_five_knockback_multiplier if basic_milestone_active else 1.0)


func maximum_targets_for(basic_milestone_active: bool) -> int:
	return maximum_targets_per_blast + (level_five_bonus_targets if basic_milestone_active else 0)


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if shots_per_second <= 0.0 or cone_range <= 0.0 or cone_angle_degrees <= 0.0:
		errors.append("RyanBasicTuning shotgun cadence and cone must be positive.")
	if damage_per_target <= 0.0 or maximum_targets_per_blast <= 0:
		errors.append("RyanBasicTuning shotgun damage and target cap must be positive.")
	if level_five_damage_multiplier < 1.0 or level_five_knockback_multiplier < 1.0:
		errors.append("RyanBasicTuning Level 5 milestone must not weaken the shotgun.")
	if auto_aim_range <= 0.0 or target_refresh_seconds <= 0.0:
		errors.append("RyanBasicTuning auto-aim values must be positive.")
	return errors
