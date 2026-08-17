class_name EliteHealthBar
extends Node2D

## Presentation-only health bar for elite normal zombies. Ordinary zombies do
## not instantiate this node, preserving the locked readability rule.
var health_component: HealthComponent


func configure(component: HealthComponent) -> void:
	health_component = component
	if health_component != null and not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)
	queue_redraw()


func _exit_tree() -> void:
	if health_component != null and health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.disconnect(_on_health_changed)


func _on_health_changed(_current: float, _maximum: float) -> void:
	queue_redraw()


func _draw() -> void:
	var ratio := health_component.health_ratio() if health_component != null else 0.0
	var bounds := Rect2(-23.0, -2.5, 46.0, 5.0)
	draw_rect(bounds.grow(1.5), Color(0.04, 0.015, 0.02, 0.95), true)
	draw_rect(bounds, Color(0.22, 0.035, 0.05, 1.0), true)
	draw_rect(Rect2(bounds.position, Vector2(bounds.size.x * ratio, bounds.size.y)), Color(1.0, 0.38, 0.22, 1.0), true)
