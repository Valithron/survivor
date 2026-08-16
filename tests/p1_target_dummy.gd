class_name P1TargetDummy
extends Area2D

@export var maximum_health := 500.0
var health_component: HealthComponent


func _ready() -> void:
	add_to_group(AutoAimResolver.TARGET_GROUP)
	health_component = $HealthComponent
	health_component.configure(maximum_health)
	health_component.health_changed.connect(func(_current: float, _maximum: float) -> void: queue_redraw())
	queue_redraw()


func is_auto_aim_target() -> bool:
	return health_component != null and health_component.is_alive()


func apply_damage_event(event: DamageEvent) -> float:
	return health_component.apply_damage(event)


func _draw() -> void:
	var ratio := health_component.health_ratio() if health_component != null else 1.0
	draw_circle(Vector2.ZERO, 21.0, Color("5b2831") if ratio > 0.0 else Color("2d2d35"))
	draw_circle(Vector2.ZERO, 15.0, Color("b9505d") if ratio > 0.0 else Color("555565"))
	draw_rect(Rect2(-20.0, -34.0, 40.0, 5.0), Color("1a2130"))
	draw_rect(Rect2(-20.0, -34.0, 40.0 * ratio, 5.0), Color("9af07a"))
