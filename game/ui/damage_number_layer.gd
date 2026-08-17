class_name DamageNumberLayer
extends Node2D

const DAMAGE_NUMBER_SCRIPT: Script = preload("res://game/ui/damage_number.gd")


func _ready() -> void:
	var events := get_tree().root.get_node_or_null(^"GameplayEvents")
	if events != null and events.has_signal(&"damage_applied"):
		events.connect(&"damage_applied", _on_damage_applied)


func _exit_tree() -> void:
	if get_tree() == null or get_tree().root == null:
		return
	var events := get_tree().root.get_node_or_null(^"GameplayEvents")
	if events != null and events.is_connected(&"damage_applied", _on_damage_applied):
		events.disconnect(&"damage_applied", _on_damage_applied)


func _on_damage_applied(target: Node, event: DamageEvent, applied_amount: float) -> void:
	if not (target is Node2D) or event == null or applied_amount <= 0.0:
		return
	var number := DAMAGE_NUMBER_SCRIPT.new() as DamageNumber
	add_child(number)
	var color := Color(1.0, 0.83, 0.34, 1.0)
	if target.has_method(&"try_activate_tactical") and not target.is_in_group(WeaponTargeting.ENEMY_TARGET_GROUP):
		color = Color(1.0, 0.42, 0.40, 1.0)
	number.configure((target as Node2D).global_position + Vector2(0.0, -36.0), applied_amount, color)
