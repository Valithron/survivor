class_name ZombieSpriteVisual
extends Node2D

## Presentation-only adapter shared by canonical ordinary-zombie sheets.
## Rows: run 0..3, attack 4..5, death 6..8.
const CELL_SIZE := 64
const DIRECTION_COLUMNS := {
	"n": 0, "ne": 1, "e": 2, "se": 3,
	"s": 4, "sw": 5, "w": 6, "nw": 7,
}
const ANIMATION_LAYOUT := {
	"run": {"row": 0, "frames": 4, "fps": 9.0},
	"attack": {"row": 4, "frames": 2, "fps": 8.0},
	"death": {"row": 6, "frames": 3, "fps": 8.0},
}

@onready var sprite: Sprite2D = $Sprite

var _action := "run"
var _direction := "s"
var _elapsed := 0.0


func _ready() -> void:
	_apply_frame()


func set_motion_state(action: StringName, direction: Vector2) -> void:
	var requested_action := String(action)
	if not ANIMATION_LAYOUT.has(requested_action):
		requested_action = "run"
	var requested_direction := String(AnimationConvention.direction_id(direction))
	if not DIRECTION_COLUMNS.has(requested_direction):
		requested_direction = "s"
	if requested_action != _action or requested_direction != _direction:
		_action = requested_action
		_direction = requested_direction
		_elapsed = 0.0
	_apply_frame()


func play_death() -> void:
	_action = "death"
	_elapsed = 0.0
	_apply_frame()


func death_duration_seconds() -> float:
	var layout: Dictionary = ANIMATION_LAYOUT["death"]
	return float(layout["frames"]) / float(layout["fps"])


func _process(delta: float) -> void:
	_elapsed += delta
	_apply_frame()


func _apply_frame() -> void:
	var layout: Dictionary = ANIMATION_LAYOUT[_action]
	var frame_count: int = layout["frames"]
	var frame_index := posmod(int(floor(_elapsed * float(layout["fps"]))), frame_count)
	sprite.region_rect = Rect2(
		float(DIRECTION_COLUMNS[_direction] * CELL_SIZE),
		float((int(layout["row"]) + frame_index) * CELL_SIZE),
		CELL_SIZE,
		CELL_SIZE,
	)
