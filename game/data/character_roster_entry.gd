class_name CharacterRosterEntry
extends Resource

## Connects a data-defined character identity to its independently authored
## player runtime scene. It keeps the run/selection path from becoming a
## character-id switch as the locked three-character roster converges.
@export var character: CharacterDefinition
@export var player_scene: PackedScene


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if character == null:
		errors.append("CharacterRosterEntry requires a CharacterDefinition.")
	elif not character.validate_contract().is_empty():
		errors.append("CharacterRosterEntry has an invalid CharacterDefinition.")
	if player_scene == null:
		errors.append("CharacterRosterEntry requires a player runtime scene.")
	return errors
