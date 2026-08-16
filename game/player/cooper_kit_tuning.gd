class_name CooperKitTuning
extends Resource

## Tunable commitment states for Cooper. The locked identity is a major damage
## tradeoff and near-rooted sustained-fire ultimate, not a new weapon system.
@export_category("Damage Overclock")
@export_range(0.05, 30.0, 0.05) var overclock_duration_seconds: float = 4.0
@export_range(1.0, 8.0, 0.05) var overclock_damage_multiplier: float = 2.15
@export_range(0.05, 1.0, 0.01) var overclock_move_speed_multiplier: float = 0.56
@export_range(1.0, 5.0, 0.05) var level_ten_overclock_duration_multiplier: float = 1.2
@export_range(1.0, 5.0, 0.05) var level_ten_overclock_damage_multiplier: float = 1.25
@export_range(0.05, 1.0, 0.01) var level_ten_overclock_move_multiplier: float = 0.72

@export_category("Anchored Sustained Fire")
@export_range(0.05, 30.0, 0.05) var ultimate_duration_seconds: float = 4.5
@export_range(1.0, 10.0, 0.05) var ultimate_damage_multiplier: float = 2.85
@export_range(1.0, 6.0, 0.05) var ultimate_fire_rate_multiplier: float = 1.55
@export_range(0.0, 0.3, 0.005) var ultimate_move_speed_multiplier: float = 0.08
@export_range(1.0, 5.0, 0.05) var level_fifteen_ultimate_duration_multiplier: float = 1.18
@export_range(1.0, 5.0, 0.05) var level_fifteen_ultimate_damage_multiplier: float = 1.3
@export_range(1.0, 5.0, 0.05) var level_fifteen_ultimate_fire_rate_multiplier: float = 1.2


func overclock_duration_for(tactical_milestone_active: bool) -> float:
	return overclock_duration_seconds * (level_ten_overclock_duration_multiplier if tactical_milestone_active else 1.0)


func overclock_damage_for(tactical_milestone_active: bool) -> float:
	return overclock_damage_multiplier * (level_ten_overclock_damage_multiplier if tactical_milestone_active else 1.0)


func overclock_move_speed_for(tactical_milestone_active: bool) -> float:
	return overclock_move_speed_multiplier * (level_ten_overclock_move_multiplier if tactical_milestone_active else 1.0)


func ultimate_duration_for(ultimate_milestone_active: bool) -> float:
	return ultimate_duration_seconds * (level_fifteen_ultimate_duration_multiplier if ultimate_milestone_active else 1.0)


func ultimate_damage_for(ultimate_milestone_active: bool) -> float:
	return ultimate_damage_multiplier * (level_fifteen_ultimate_damage_multiplier if ultimate_milestone_active else 1.0)


func ultimate_fire_rate_for(ultimate_milestone_active: bool) -> float:
	return ultimate_fire_rate_multiplier * (level_fifteen_ultimate_fire_rate_multiplier if ultimate_milestone_active else 1.0)


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if overclock_duration_seconds <= 0.0 or overclock_damage_multiplier <= 1.0:
		errors.append("CooperKitTuning Overclock must create a meaningful temporary damage increase.")
	if overclock_move_speed_multiplier >= 1.0 or level_ten_overclock_move_multiplier > 1.0:
		errors.append("CooperKitTuning Overclock must retain its movement-speed tradeoff.")
	if ultimate_duration_seconds <= 0.0 or ultimate_damage_multiplier <= 1.0 or ultimate_fire_rate_multiplier <= 1.0:
		errors.append("CooperKitTuning ultimate must create extreme sustained damage.")
	if ultimate_move_speed_multiplier > 0.2:
		errors.append("CooperKitTuning ultimate must remain nearly rooted.")
	return errors
