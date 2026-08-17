extends Node2D

## P1's playable developer test. It is intentionally separate from the F0
## contract screen while loading Sterling's integrated raster visual.
@onready var player: SterlingPlayer = $SterlingPlayer
@onready var state_label: Label = $CanvasLayer/Panel/State
@onready var event_label: Label = $CanvasLayer/Panel/Event

var shots_fired := 0
var last_event := "Sterling is ready. Move and keep shooting."


func _ready() -> void:
	player.basic_fired.connect(_on_basic_fired)
	player.aim_mode_changed.connect(_on_aim_mode_changed)
	player.damage_received.connect(_on_damage_received)
	player.died.connect(_on_died)


func _process(_delta: float) -> void:
	var target_name: String = player.current_auto_target.name if player.current_auto_target != null else "none (facing fallback)"
	state_label.text = "P1 // STERLING BASIC COMBAT\n\nAim mode: %s\nAim vector: (%.2f, %.2f)\nAuto target: %s\nSpeed: %.0f / %.0f\nFire rate: %.2f shots/sec\nHealth: %.0f / %.0f\nShots fired: %d\nSprite contract: %s" % [
		"Manual Aim" if player.manual_aim_enabled else "Auto Aim",
		player.get_basic_aim_direction().x,
		player.get_basic_aim_direction().y,
		target_name,
		player.velocity.length(),
		player.character_definition.move_speed,
		player.get_current_fire_rate(),
		player.health_component.current_health,
		player.health_component.maximum_health,
		shots_fired,
		player.current_animation_name,
	]
	event_label.text = "LAST EVENT\n%s\n\nControls\nWASD: move\nT: persistent Auto/Manual Aim toggle\nMouse: Manual Aim direction\n2: apply 10 shared-contract damage\nEsc: lifecycle pause (F0 contract)\n\nSterling uses the integrated Prototype pixel-art visual." % last_event


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_spawn_swarm") and not event.is_echo():
		player.apply_damage(DamageEvent.new(self, 10.0, &"p1_dev_contact"))
		get_viewport().set_input_as_handled()


func _on_basic_fired(direction: Vector2, _muzzle_position: Vector2, muzzle_side: int, fire_rate: float) -> void:
	shots_fired += 1
	last_event = "Pistol %s fired %s at %.2f shots/sec." % ["L" if muzzle_side < 0 else "R", direction, fire_rate]


func _on_aim_mode_changed(manual_enabled: bool) -> void:
	last_event = "Aim mode changed to %s without interrupting the fire loop." % ("Manual Aim" if manual_enabled else "Auto Aim")


func _on_damage_received(_event: DamageEvent, amount: float) -> void:
	last_event = "HealthComponent accepted %.0f damage through DamageEvent." % amount


func _on_died(_event: DamageEvent) -> void:
	last_event = "Sterling died. Reload this P1 test scene to reset the developer run."
