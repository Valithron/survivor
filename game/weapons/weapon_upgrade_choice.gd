class_name WeaponUpgradeChoice
extends RefCounted

## Immutable description of one legal level-up option. Presentation reads this
## payload but never determines whether it is legal.
var weapon: WeaponDefinition
var target_rank: int


func _init(weapon_definition: WeaponDefinition = null, requested_rank: int = 0) -> void:
	weapon = weapon_definition
	target_rank = requested_rank


func is_acquisition() -> bool:
	return target_rank == 1


func is_valid_shape() -> bool:
	return weapon != null and target_rank >= 1 and target_rank <= WeaponDefinition.MAX_RANK


func display_label() -> String:
	if weapon == null:
		return "Invalid weapon choice"
	var action := "Acquire" if is_acquisition() else "Rank up"
	return "%s %s (Rank %d)" % [action, weapon.display_name, target_rank]


func duplicate_choice() -> WeaponUpgradeChoice:
	return WeaponUpgradeChoice.new(weapon, target_rank)
