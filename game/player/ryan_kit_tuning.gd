class_name RyanKitTuning
extends Resource

## Tunable values for Ryan's locked Armored Charge and escalating-impact
## ultimate. This resource owns no progression legality; CharacterMilestones
## decides when the three documented automatic improvements activate.
@export_category("Armored Charge")
@export_range(0.05, 30.0, 0.05) var charge_duration_seconds: float = 0.55
@export_range(10.0, 3000.0, 1.0) var charge_speed: float = 690.0
@export_range(8.0, 300.0, 1.0) var charge_hit_radius: float = 45.0
@export_range(0.1, 1000.0, 0.1) var charge_damage: float = 30.0
@export_range(0.0, 3000.0, 1.0) var charge_shove_strength: float = 255.0
@export_range(1.0, 5.0, 0.05) var level_ten_charge_duration_multiplier: float = 1.25
@export_range(1.0, 5.0, 0.05) var level_ten_charge_damage_multiplier: float = 1.35
@export_range(1.0, 5.0, 0.05) var level_ten_charge_shove_multiplier: float = 1.3

@export_category("Escalating Radial Impacts")
@export_range(1, 16, 1) var impact_count: int = 3
@export_range(0.03, 3.0, 0.01) var impact_interval_seconds: float = 0.3
@export_range(12.0, 1200.0, 1.0) var initial_impact_radius: float = 92.0
@export_range(0.0, 1000.0, 1.0) var impact_radius_step: float = 68.0
@export_range(0.1, 1000.0, 0.1) var initial_impact_damage: float = 25.0
@export_range(1.0, 5.0, 0.05) var damage_multiplier_per_impact: float = 1.18
@export_range(0.0, 3000.0, 1.0) var initial_impact_knockback: float = 180.0
@export_range(1.0, 5.0, 0.05) var knockback_multiplier_per_impact: float = 1.18
@export_range(1.0, 5.0, 0.05) var final_shockwave_radius_multiplier: float = 1.55
@export_range(1.0, 8.0, 0.05) var final_shockwave_damage_multiplier: float = 1.75
@export_range(1.0, 8.0, 0.05) var final_shockwave_knockback_multiplier: float = 1.85
@export_range(0, 12, 1) var level_fifteen_bonus_impacts: int = 2
@export_range(1.0, 5.0, 0.05) var level_fifteen_final_radius_multiplier: float = 1.2
@export_range(1.0, 5.0, 0.05) var level_fifteen_final_damage_multiplier: float = 1.35
@export_range(1.0, 5.0, 0.05) var level_fifteen_final_knockback_multiplier: float = 1.3


func charge_duration_for(tactical_milestone_active: bool) -> float:
	return charge_duration_seconds * (level_ten_charge_duration_multiplier if tactical_milestone_active else 1.0)


func charge_damage_for(tactical_milestone_active: bool) -> float:
	return charge_damage * (level_ten_charge_damage_multiplier if tactical_milestone_active else 1.0)


func charge_shove_for(tactical_milestone_active: bool) -> float:
	return charge_shove_strength * (level_ten_charge_shove_multiplier if tactical_milestone_active else 1.0)


func impact_count_for(ultimate_milestone_active: bool) -> int:
	return impact_count + (level_fifteen_bonus_impacts if ultimate_milestone_active else 0)


func impact_radius_for(impact_index: int, is_final: bool, ultimate_milestone_active: bool) -> float:
	var radius := initial_impact_radius + impact_radius_step * float(maxi(impact_index, 0))
	if is_final:
		radius *= final_shockwave_radius_multiplier
		if ultimate_milestone_active:
			radius *= level_fifteen_final_radius_multiplier
	return radius


func impact_damage_for(impact_index: int, is_final: bool, ultimate_milestone_active: bool) -> float:
	var damage := initial_impact_damage * pow(damage_multiplier_per_impact, maxi(impact_index, 0))
	if is_final:
		damage *= final_shockwave_damage_multiplier
		if ultimate_milestone_active:
			damage *= level_fifteen_final_damage_multiplier
	return damage


func impact_knockback_for(impact_index: int, is_final: bool, ultimate_milestone_active: bool) -> float:
	var strength := initial_impact_knockback * pow(knockback_multiplier_per_impact, maxi(impact_index, 0))
	if is_final:
		strength *= final_shockwave_knockback_multiplier
		if ultimate_milestone_active:
			strength *= level_fifteen_final_knockback_multiplier
	return strength


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if charge_duration_seconds <= 0.0 or charge_speed <= 0.0 or charge_hit_radius <= 0.0 or charge_damage <= 0.0:
		errors.append("RyanKitTuning Armored Charge values must be positive.")
	if level_ten_charge_duration_multiplier < 1.0 or level_ten_charge_damage_multiplier < 1.0 or level_ten_charge_shove_multiplier < 1.0:
		errors.append("RyanKitTuning Level 10 milestone must not weaken Armored Charge.")
	if impact_count <= 0 or impact_interval_seconds <= 0.0 or initial_impact_radius <= 0.0 or initial_impact_damage <= 0.0:
		errors.append("RyanKitTuning radial impact setup is invalid.")
	if damage_multiplier_per_impact < 1.0 or knockback_multiplier_per_impact < 1.0:
		errors.append("RyanKitTuning impacts must escalate rather than weaken.")
	if final_shockwave_radius_multiplier < 1.0 or final_shockwave_damage_multiplier < 1.0 or final_shockwave_knockback_multiplier < 1.0:
		errors.append("RyanKitTuning final shockwave must be the largest impact.")
	return errors
