class_name CharacterDefinition
extends Resource

@export var character_id: StringName
@export var display_name: String
@export_multiline var archetype_summary: String
@export_range(1.0, 10000.0, 0.1) var base_max_health: float = 100.0
@export_range(1.0, 5000.0, 0.1) var move_speed: float = 200.0
@export var basic_attack: AbilityDefinition
@export var tactical: AbilityDefinition
@export var ultimate: AbilityDefinition
@export var milestones: CharacterMilestones
@export var sprite_scene: PackedScene
@export var portrait: Texture2D


func validate_contract() -> Array[String]:
	var errors: Array[String] = []
	if character_id.is_empty():
		errors.append("CharacterDefinition requires character_id.")
	if display_name.is_empty():
		errors.append("CharacterDefinition requires display_name.")
	if basic_attack == null:
		errors.append("CharacterDefinition requires a basic_attack definition.")
	if milestones == null or not milestones.is_valid():
		errors.append("CharacterDefinition requires ordered milestone levels.")
	return errors
