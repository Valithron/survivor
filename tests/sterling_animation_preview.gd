extends Node2D

## Development-only visual review room for Sterling's authored 64 px animation
## sheet. It is intentionally not part of the production scene flow.
const DIRECTIONS := ["n", "ne", "e", "se", "s", "sw", "w", "nw"]
const ACTIONS := ["idle", "run", "basic", "hurt", "death"]
const VISUAL_SCENE: PackedScene = preload("res://art/characters/sterling/sterling_visual.tscn")

@onready var hero: SterlingSpriteVisual = $Hero
@onready var gameplay_scale: SterlingSpriteVisual = $GameplayScale
@onready var title_label: Label = $CanvasLayer/Title
@onready var controls_label: Label = $CanvasLayer/Controls

var _direction_index := 2 # East matches the normal player start-facing.
var _action_index := 0
var _direction_strip: Array[SterlingSpriteVisual] = []


func _ready() -> void:
	for index in range(DIRECTIONS.size()):
		var visual := VISUAL_SCENE.instantiate() as SterlingSpriteVisual
		visual.position = Vector2(72.0 + float(index) * 145.0, 570.0)
		visual.scale = Vector2(1.5, 1.5)
		add_child(visual)
		_direction_strip.append(visual)
	_apply_preview_state()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_LEFT:
			_direction_index = posmod(_direction_index - 1, DIRECTIONS.size())
		KEY_RIGHT:
			_direction_index = posmod(_direction_index + 1, DIRECTIONS.size())
		KEY_SPACE:
			_action_index = posmod(_action_index + 1, ACTIONS.size())
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
			_action_index = key_event.keycode - KEY_1
		KEY_H:
			_action_index = ACTIONS.find("hurt")
		KEY_D:
			_action_index = ACTIONS.find("death")
		KEY_R:
			_action_index = ACTIONS.find("run")
		_:
			return
	_apply_preview_state()
	get_viewport().set_input_as_handled()


func _apply_preview_state() -> void:
	var action: String = ACTIONS[_action_index]
	var direction: String = DIRECTIONS[_direction_index]
	var state := StringName("%s_%s" % [action, direction])
	hero.set_animation_state(state)
	gameplay_scale.set_animation_state(state)
	if action == "hurt":
		hero.play_hurt()
		gameplay_scale.play_hurt()
	elif action == "death":
		hero.play_death()
		gameplay_scale.play_death()
	for index in range(_direction_strip.size()):
		var strip_visual := _direction_strip[index]
		strip_visual.set_animation_state(StringName("%s_%s" % [action, DIRECTIONS[index]]))
		if action == "hurt":
			strip_visual.play_hurt()
		elif action == "death":
			strip_visual.play_death()
	title_label.text = "STERLING ANIMATION REVIEW  //  %s  //  %s" % [action.to_upper(), direction.to_upper()]
	controls_label.text = "Left/Right: direction    Space: next action    1-5: Idle / Run / Basic / Hurt / Death\nH: replay hurt    D: death    R: run\n\nLarge: pixel-detail review    Small: normal gameplay-scale read    Bottom: all eight screen-space directions"
