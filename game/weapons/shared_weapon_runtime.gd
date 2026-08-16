class_name SharedWeaponRuntime
extends Node

## W0 integration point. A weapon scene extends this node and overrides
## _on_rank_applied() to start or retune its automatic behavior. Inventory owns
## acquisition legality and rank order; weapon scenes own behavior and cleanup.
signal rank_applied(definition: WeaponDefinition, current_rank: int, rank_definition: WeaponRankDefinition)

var definition: WeaponDefinition
var weapon_owner: Node
var current_rank: int = 0


func configure(weapon_definition: WeaponDefinition, owner: Node) -> void:
	definition = weapon_definition
	weapon_owner = owner


func apply_rank(target_rank: int, rank_definition: WeaponRankDefinition) -> bool:
	if definition == null or rank_definition == null:
		push_error("SharedWeaponRuntime requires a definition and rank data before rank application.")
		return false
	if target_rank != current_rank + 1 or target_rank > WeaponDefinition.MAX_RANK:
		push_warning("Ignored non-sequential weapon rank application for %s." % definition.weapon_id)
		return false
	current_rank = target_rank
	_on_rank_applied(rank_definition)
	rank_applied.emit(definition, current_rank, rank_definition)
	return true


func shutdown() -> void:
	## W0 runtime scenes may stop timers, remove spawned effects, or detach hooks.
	queue_free()


func _on_rank_applied(_rank_definition: WeaponRankDefinition) -> void:
	## Intentionally inert fallback for contract tests. W0 supplies behavior.
	pass
