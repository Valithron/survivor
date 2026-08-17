class_name ArenaDefinition
extends Resource

## M1's intentionally small data contract. Layout values stay data-driven so
## the shopping-center play space can be retuned without touching combat code.
@export var arena_id: StringName = &"abandoned_shopping_center"
@export var display_name := "Abandoned Shopping Center"
@export var arena_size := Vector2(2560.0, 2560.0)
@export var player_start_position := Vector2(1280.0, 1320.0)
@export_range(0.0, 512.0, 1.0) var boundary_inset := 96.0
@export var health_pickup_positions: PackedVector2Array = PackedVector2Array([
	Vector2(690.0, 780.0),
	Vector2(1840.0, 700.0),
	Vector2(580.0, 1830.0),
	Vector2(1970.0, 1860.0),
])
@export_range(1.0, 1000.0, 1.0) var health_pickup_heal_amount := 36.0
@export_range(1.0, 600.0, 1.0) var health_pickup_respawn_seconds := 48.0
@export_range(16.0, 512.0, 1.0) var health_pickup_collect_radius := 42.0
@export_range(16.0, 1024.0, 1.0) var guaranteed_pickup_distance := 220.0

