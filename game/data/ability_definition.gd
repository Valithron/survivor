class_name AbilityDefinition
extends Resource

@export var ability_id: StringName
@export var display_name: String
@export_multiline var summary: String
@export_range(0.0, 120.0, 0.05) var cooldown_seconds: float = 0.0
@export var runtime_scene: PackedScene
