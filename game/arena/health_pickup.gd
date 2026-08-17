class_name HealthPickup
extends Node2D

## Fixed M1 healing location. This owns no global drop-table behavior: it is a
## learnable place in the arena that returns after its configured delay.
signal collected(pickup: HealthPickup, healed_amount: float)
signal respawned(pickup: HealthPickup)

const PICKUP_TEXTURE: Texture2D = preload("res://art/arena/health_pickup/health_pickup.png")

@export_range(1.0, 1000.0, 1.0) var heal_amount := 36.0
@export_range(1.0, 600.0, 1.0) var respawn_seconds := 48.0
@export_range(16.0, 512.0, 1.0) var collect_radius := 42.0

var _target: Node2D
var _target_health: HealthComponent
var _available := true
var _respawn_remaining := 0.0
var _pulse_elapsed := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	z_index = 3
	_sprite = Sprite2D.new()
	_sprite.texture = PICKUP_TEXTURE
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.scale = Vector2(0.13, 0.13)
	_sprite.position = Vector2(0.0, -18.0)
	add_child(_sprite)
	queue_redraw()


func configure(target: Node2D, target_health: HealthComponent, amount: float, cooldown_seconds: float, radius: float) -> void:
	_target = target
	_target_health = target_health
	heal_amount = maxf(amount, 1.0)
	respawn_seconds = maxf(cooldown_seconds, 1.0)
	collect_radius = maxf(radius, 1.0)


func is_available() -> bool:
	return _available


func force_available() -> void:
	_available = true
	_respawn_remaining = 0.0
	visible = true
	respawned.emit(self)


func _process(delta: float) -> void:
	_pulse_elapsed += delta
	if not _available:
		_respawn_remaining = maxf(_respawn_remaining - delta, 0.0)
		if _respawn_remaining <= 0.0:
			force_available()
		return
	if not is_instance_valid(_target) or not is_instance_valid(_target_health) or not _target_health.is_alive():
		return
	if global_position.distance_squared_to(_target.global_position) > collect_radius * collect_radius:
		return
	var healed_amount := _target_health.heal(heal_amount)
	if healed_amount <= 0.0:
		return
	_available = false
	_respawn_remaining = respawn_seconds
	visible = false
	collected.emit(self, healed_amount)


func _draw() -> void:
	if not _available:
		return
	var pulse := 0.5 + 0.5 * sin(_pulse_elapsed * 3.6)
	draw_circle(Vector2(0.0, 6.0), 25.0 + pulse * 4.0, Color(0.12, 0.82, 0.95, 0.10))
	draw_arc(Vector2(0.0, 6.0), 28.0 + pulse * 3.0, 0.0, TAU, 24, Color(0.38, 0.94, 1.0, 0.72), 1.8)

