class_name CharacterRosterDefinition
extends Resource

@export var entries: Array[CharacterRosterEntry] = []


func get_entry(character_id: StringName) -> CharacterRosterEntry:
	for entry in entries:
		if entry != null and entry.character != null and entry.character.character_id == character_id:
			return entry
	return null


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	var ids: Dictionary = {}
	for entry in entries:
		if entry == null:
			errors.append("CharacterRosterDefinition contains a null roster entry.")
			continue
		errors.append_array(entry.validate_contract())
		if entry.character == null:
			continue
		if ids.has(entry.character.character_id):
			errors.append("CharacterRosterDefinition has duplicate character_id %s." % entry.character.character_id)
		ids[entry.character.character_id] = true
	if entries.is_empty():
		errors.append("CharacterRosterDefinition requires at least one character.")
	return errors
