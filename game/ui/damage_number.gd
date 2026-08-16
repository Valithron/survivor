class_name DamageNumber
extends Node2D

## Presentation-only U1 hit feedback. It subscribes to HealthComponent's shared
## event convention rather than making weapons or enemies depend on UI code.
var _amount := 0
var _color := Color.WHITE
var _elapsed := 0.0
var _lifetime := 0.58
var _label: Label


func configure(world_position: Vector2, amount: float, color: Color) -> void:
	global_position = world_position
	_amount = maxi(roundi(amount), 1)
	_color = color


func _ready() -> void:
	z_index = 22
	_label = Label.new()
	_label.text = str(_amount)
	_label.add_theme_color_override(&"font_color", _color)
	_label.add_theme_color_override(&"font_outline_color", Color(0.035, 0.045, 0.075, 0.96))
	_label.add_theme_constant_override(&"outline_size", 3)
	_label.add_theme_font_size_override(&"font_size", 17)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(-28.0, -10.0)
	_label.size = Vector2(56.0, 24.0)
	add_child(_label)


func _process(delta: float) -> void:
	_elapsed += delta
	position.y -= 34.0 * delta
	var alpha := clampf(1.0 - _elapsed / _lifetime, 0.0, 1.0)
	modulate.a = alpha
	if _elapsed >= _lifetime:
		queue_free()
