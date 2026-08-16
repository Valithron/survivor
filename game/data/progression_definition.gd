class_name ProgressionDefinition
extends Resource

## Editable run-local XP pacing. Values are total XP required to reach Level 2,
## then Level 3, and so on. They are temporary tuning data, not locked balance.
@export_range(1, 99, 1) var starting_level: int = 1
@export var level_up_total_xp_thresholds: PackedInt32Array = PackedInt32Array([15, 35, 60, 90, 125, 165, 210, 260, 315, 375, 440, 510, 585, 665, 750])
## Keeps progression usable past the explicitly tuned portion of the curve.
@export_range(1, 100000, 1) var overflow_threshold_step: int = 100
@export_range(1.0, 2000.0, 1.0) var xp_attraction_radius: float = 220.0
@export_range(1.0, 5000.0, 1.0) var xp_attraction_speed: float = 720.0
@export_range(1.0, 128.0, 1.0) var xp_collect_radius: float = 18.0


func total_xp_required_for_level(target_level: int) -> int:
	if target_level <= starting_level:
		return 0
	var threshold_index := target_level - starting_level - 1
	if threshold_index < level_up_total_xp_thresholds.size():
		return level_up_total_xp_thresholds[threshold_index]
	if level_up_total_xp_thresholds.is_empty():
		return (threshold_index + 1) * overflow_threshold_step
	var overflow_count := threshold_index - level_up_total_xp_thresholds.size() + 1
	return level_up_total_xp_thresholds[level_up_total_xp_thresholds.size() - 1] + overflow_count * overflow_threshold_step


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if starting_level < 1:
		errors.append("ProgressionDefinition starting_level must be at least 1.")
	if overflow_threshold_step <= 0:
		errors.append("ProgressionDefinition overflow_threshold_step must be positive.")
	var previous_threshold := 0
	for threshold in level_up_total_xp_thresholds:
		if threshold <= previous_threshold:
			errors.append("ProgressionDefinition thresholds must be strictly increasing positive totals.")
			break
		previous_threshold = threshold
	return errors
