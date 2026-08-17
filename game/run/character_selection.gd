extends Node

## Ephemeral selection state for entering a run. Persistent unlock legality
## remains MetaProgression's responsibility; this autoload merely passes a
## roster entry from character select to the active run scene.
signal character_selected(entry: CharacterRosterEntry)

const ROSTER: CharacterRosterDefinition = preload("res://data/characters/roster.tres")
const DEFAULT_CHARACTER_ID: StringName = &"sterling"

var selected_character_id: StringName = DEFAULT_CHARACTER_ID


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if get_selected_entry() == null:
		selected_character_id = DEFAULT_CHARACTER_ID


func get_selected_entry() -> CharacterRosterEntry:
	return ROSTER.get_entry(selected_character_id)


func select_character(character_id: StringName) -> bool:
	var entry := ROSTER.get_entry(character_id)
	if entry == null or not entry.validate_contract().is_empty():
		return false
	selected_character_id = character_id
	character_selected.emit(entry)
	return true
