class_name SterlingSpriteVisual
extends Node2D

## Presentation-only adapter for the canonical 8-column Sterling sheet.
## Rows: idle 0..2, run 3..8, basic 9..10, hurt 11, death 12..15.
const CELL_SIZE := 64
const DIRECTION_COLUMNS := {
	"n": 0, "ne": 1, "e": 2, "se": 3,
	"s": 4, "sw": 5, "w": 6, "nw": 7,
}
const ANIMATION_LAYOUT := {
	"idle": {"row": 0, "frames": 3, "fps": 3.0},
	"run": {"row": 3, "frames": 6, "fps": 11.0},
	"basic": {"row": 9, "frames": 2, "fps": 14.0},
	"hurt": {"row": 11, "frames": 1, "fps": 1.0},
	"death": {"row": 12, "frames": 4, "fps": 8.0},
}

@onready var sprite: Sprite2D = $Sprite

var _action := "idle"
var _direction := "e"
var _elapsed := 0.0
var _reaction_action := ""
var _reaction_remaining := 0.0
var _forced_basic_frame := -1
var _forced_basic_remaining := 0.0


func _ready() -> void:
	_apply_frame()


func set_animation_state(animation_name: StringName) -> void:
	var pieces := String(animation_name).split("_", false, 1)
	var requested_action := pieces[0] if not pieces.is_empty() else "idle"
	var requested_direction := pieces[1] if pieces.size() > 1 else "s"
	if not ANIMATION_LAYOUT.has(requested_action):
		requested_action = "idle"
	if not DIRECTION_COLUMNS.has(requested_direction):
		requested_direction = "s"
	if requested_action != _action or requested_direction != _direction:
		_action = requested_action
		_direction = requested_direction
		_elapsed = 0.0
	_apply_frame()


func play_hurt() -> void:
	if _action == "death":
		return
	_forced_basic_frame = -1
	_forced_basic_remaining = 0.0
	_reaction_action = "hurt"
	_reaction_remaining = 0.12
	_apply_frame()


func play_death() -> void:
	_action = "death"
	_elapsed = 0.0
	_reaction_action = ""
	_reaction_remaining = 0.0
	_forced_basic_frame = -1
	_forced_basic_remaining = 0.0
	_apply_frame()


func play_basic_shot(muzzle_side: int) -> void:
	## Align the authored alternating recoil cells with the real alternating
	## muzzle. This remains presentation-only; combat timing stays in SterlingPlayer.
	if _action == "death":
		return
	_forced_basic_frame = 0 if muzzle_side > 0 else 1
	_forced_basic_remaining = 0.075
	_apply_frame()


func _process(delta: float) -> void:
	_elapsed += delta
	if _reaction_remaining > 0.0:
		_reaction_remaining = maxf(_reaction_remaining - delta, 0.0)
	if _forced_basic_remaining > 0.0:
		_forced_basic_remaining = maxf(_forced_basic_remaining - delta, 0.0)
		if is_zero_approx(_forced_basic_remaining):
			_forced_basic_frame = -1
	_apply_frame()


func _apply_frame() -> void:
	var active_action := _reaction_action if _reaction_remaining > 0.0 else _action
	if _forced_basic_frame >= 0 and _reaction_remaining <= 0.0:
		active_action = "basic"
	var layout: Dictionary = ANIMATION_LAYOUT[active_action]
	var frame_count: int = layout["frames"]
	var frame_index := 0
	if active_action == "basic" and _forced_basic_frame >= 0:
		frame_index = _forced_basic_frame
	elif frame_count > 1:
		frame_index = posmod(int(floor(_elapsed * float(layout["fps"]))), frame_count)
	sprite.region_rect = Rect2(
		float(DIRECTION_COLUMNS[_direction] * CELL_SIZE),
		float((int(layout["row"]) + frame_index) * CELL_SIZE),
		CELL_SIZE,
		CELL_SIZE,
	)
