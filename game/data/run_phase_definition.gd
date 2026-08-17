class_name RunPhaseDefinition
extends Resource

## R1 will interpret these data-only markers. F0 deliberately does not build a
## director or spawn logic around them.
@export_range(0.0, 3600.0, 0.1) var at_seconds: float = 0.0
@export var event_id: StringName
@export var composition_tags: PackedStringArray = []
