class_name CharacterUnlockRule
extends Resource

## A small data contract for content unlocks. It intentionally represents only
## character availability; Survivor does not have permanent stat progression.
@export var character_id: StringName
@export_range(0, 1000000, 1) var required_natural_run_count := 0


func is_unlocked_at(completed_natural_runs: int) -> bool:
	return completed_natural_runs >= required_natural_run_count


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if character_id.is_empty():
		errors.append("CharacterUnlockRule requires a character_id.")
	return errors
