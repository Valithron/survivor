class_name UpgradeChoiceGenerator
extends RefCounted

## Chooses presentation order only. WeaponInventory remains the authority on
## validity, so UI cannot accidentally offer a fifth weapon or Rank 6.
var _random := RandomNumberGenerator.new()


func set_seed(seed_value: int) -> void:
	_random.seed = seed_value


func generate(inventory: WeaponInventory, weapon_pool: Array[WeaponDefinition], choice_count: int = 3) -> Array[WeaponUpgradeChoice]:
	if inventory == null or choice_count <= 0:
		return []
	var candidates := inventory.get_valid_choices(weapon_pool)
	if candidates.is_empty():
		return []
	_shuffle(candidates)
	var choices: Array[WeaponUpgradeChoice] = []
	for index in range(choice_count):
		## The initial Prototype pool has only Katana and Molotov. Repeating an
		## otherwise legal option is preferable to inventing an unimplemented
		## third weapon; each repeated card remains a valid acquisition/rank-up.
		choices.append(candidates[index % candidates.size()].duplicate_choice())
	return choices


func _shuffle(items: Array[WeaponUpgradeChoice]) -> void:
	for index in range(items.size() - 1, 0, -1):
		var swap_index := _random.randi_range(0, index)
		var held := items[index]
		items[index] = items[swap_index]
		items[swap_index] = held
