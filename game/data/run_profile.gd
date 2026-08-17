class_name RunProfile
extends Resource

@export var profile_id: StringName
@export var display_name: String
@export_range(1.0, 3600.0, 1.0) var survival_duration_seconds: float = 300.0
## Prototype-style timed tests end here. A full run uses this moment for the
## boss-arrival phase, then B1 ends the run through victory or player death.
@export var end_run_at_duration: bool = true
@export var scheduled_phases: Array[RunPhaseDefinition] = []


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if profile_id.is_empty():
		errors.append("RunProfile requires profile_id.")
	if display_name.is_empty():
		errors.append("RunProfile requires display_name.")
	var previous_time := -1.0
	for phase in scheduled_phases:
		if phase == null:
			errors.append("RunProfile contains a missing phase resource.")
			continue
		if phase.at_seconds <= previous_time:
			errors.append("RunProfile phases must be ordered by time.")
		previous_time = phase.at_seconds
	return errors
