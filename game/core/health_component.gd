class_name HealthComponent
extends Node

signal health_changed(current_health: float, maximum_health: float)
signal damage_received(event: DamageEvent, applied_amount: float)
signal died(final_event: DamageEvent)

@export_range(0.01, 100000.0, 0.01) var maximum_health: float = 1.0

var current_health: float = -1.0


func _ready() -> void:
	if current_health < 0.0:
		current_health = maximum_health
	else:
		current_health = clampf(current_health, 0.0, maximum_health)


func configure(new_maximum_health: float) -> void:
	maximum_health = maxf(new_maximum_health, 0.01)
	current_health = maximum_health
	health_changed.emit(current_health, maximum_health)


func apply_damage(event: DamageEvent) -> float:
	if not is_alive() or event == null or not event.is_valid():
		return 0.0

	var applied_amount := minf(event.amount, current_health)
	current_health = maxf(current_health - applied_amount, 0.0)
	damage_received.emit(event, applied_amount)
	_report_damage_event(event, applied_amount)
	health_changed.emit(current_health, maximum_health)
	if is_zero_approx(current_health):
		died.emit(event)
	return applied_amount


func heal(amount: float) -> float:
	if not is_alive() or amount <= 0.0:
		return 0.0

	var applied_amount := minf(amount, maximum_health - current_health)
	current_health += applied_amount
	health_changed.emit(current_health, maximum_health)
	return applied_amount


func is_alive() -> bool:
	return current_health > 0.0


func health_ratio() -> float:
	return current_health / maximum_health


func _report_damage_event(event: DamageEvent, applied_amount: float) -> void:
	## Direct --script unit tests deliberately omit autoloads. Resolve the shared
	## event surface dynamically so HealthComponent remains independently usable.
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree == null or tree.root == null:
		return
	var events := tree.root.get_node_or_null(^"GameplayEvents")
	if events != null and events.has_method(&"report_damage"):
		events.call(&"report_damage", get_parent(), event, applied_amount)
