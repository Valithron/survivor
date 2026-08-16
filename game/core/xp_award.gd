class_name XpAward
extends RefCounted

## Emitted after an enemy is defeated. Progression owns collection and leveling;
## enemy code only reports this award through GameplayEvents.
var source: Object
var amount: int
var world_position: Vector2


func _init(award_source: Object = null, award_amount: int = 0, position: Vector2 = Vector2.ZERO) -> void:
	source = award_source
	amount = maxi(award_amount, 0)
	world_position = position


func is_valid() -> bool:
	return amount > 0
