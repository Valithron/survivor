extends Node

## Small shared event surface. It keeps enemy, progression, and run work from
## depending on one another's private implementation details.
signal enemy_defeated(enemy: Node, award: XpAward)
signal xp_awarded(award: XpAward)
signal run_event(event_id: StringName, payload: Dictionary)
signal damage_applied(target: Node, event: DamageEvent, applied_amount: float)


func report_enemy_defeated(enemy: Node, award: XpAward) -> void:
	if award == null or not award.is_valid():
		push_warning("Ignored enemy defeat with an invalid XP award.")
		return
	enemy_defeated.emit(enemy, award)
	xp_awarded.emit(award)


func award_xp(award: XpAward) -> void:
	if award == null or not award.is_valid():
		push_warning("Ignored invalid XP award.")
		return
	xp_awarded.emit(award)


func publish_run_event(event_id: StringName, payload: Dictionary = {}) -> void:
	run_event.emit(event_id, payload.duplicate(true))


func report_damage(target: Node, event: DamageEvent, applied_amount: float) -> void:
	if target == null or event == null or applied_amount <= 0.0:
		return
	damage_applied.emit(target, event, applied_amount)
