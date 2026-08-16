class_name UnlockProgressionDefinition
extends Resource

## Versioned, content-only progression. New character rules can be added to
## this resource without altering the save manager or run-end contract.
@export_range(1, 1000, 1) var save_version := 1
@export var character_unlock_rules: Array[CharacterUnlockRule] = []


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	var known_ids: Dictionary = {}
	for rule in character_unlock_rules:
		if rule == null:
			errors.append("UnlockProgressionDefinition contains a missing character rule.")
			continue
		errors.append_array(rule.validate_contract())
		if known_ids.has(rule.character_id):
			errors.append("UnlockProgressionDefinition duplicates character rule %s." % rule.character_id)
		known_ids[rule.character_id] = true
	if character_unlock_rules.is_empty():
		errors.append("UnlockProgressionDefinition requires at least one character rule.")
	return errors
