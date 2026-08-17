class_name WeaponInventory
extends Node

## Run-local shared-weapon loadout. It contains exactly the rules that must not
## drift between progression, HUD, and weapon implementations.
const MAX_SHARED_WEAPON_SLOTS := 4

signal weapon_acquired(entry: WeaponLoadoutEntry)
signal weapon_rank_changed(entry: WeaponLoadoutEntry, previous_rank: int)
signal loadout_reset

@export_range(1, MAX_SHARED_WEAPON_SLOTS, 1) var max_slots: int = MAX_SHARED_WEAPON_SLOTS

var weapon_owner: Node
var runtime_parent: Node
var _entries: Array[WeaponLoadoutEntry] = []


func configure_runtime(owner: Node, parent_for_runtimes: Node = null) -> void:
	weapon_owner = owner
	runtime_parent = parent_for_runtimes if parent_for_runtimes != null else self


func get_entries() -> Array[WeaponLoadoutEntry]:
	return _entries.duplicate()


func equipped_count() -> int:
	return _entries.size()


func is_full() -> bool:
	return equipped_count() >= max_slots


func is_equipped(definition: WeaponDefinition) -> bool:
	return _find_entry(definition) != null


func get_current_rank(definition: WeaponDefinition) -> int:
	var entry := _find_entry(definition)
	return entry.current_rank if entry != null else 0


func can_acquire(definition: WeaponDefinition) -> bool:
	return definition != null and definition.validate_contract().is_empty() and not is_equipped(definition) and not is_full()


func can_rank_up(definition: WeaponDefinition) -> bool:
	var entry := _find_entry(definition)
	return entry != null and entry.current_rank < WeaponDefinition.MAX_RANK


func get_valid_choices(weapon_pool: Array[WeaponDefinition]) -> Array[WeaponUpgradeChoice]:
	var choices: Array[WeaponUpgradeChoice] = []
	var seen_weapon_ids: Dictionary = {}
	for definition in weapon_pool:
		if definition == null or seen_weapon_ids.has(definition.weapon_id):
			continue
		seen_weapon_ids[definition.weapon_id] = true
		var entry := _find_entry(definition)
		if entry != null:
			if entry.current_rank < WeaponDefinition.MAX_RANK:
				choices.append(WeaponUpgradeChoice.new(definition, entry.current_rank + 1))
		elif can_acquire(definition):
			choices.append(WeaponUpgradeChoice.new(definition, 1))
	return choices


func apply_choice(choice: WeaponUpgradeChoice) -> bool:
	if choice == null or not choice.is_valid_shape():
		return false
	var definition := choice.weapon
	if choice.is_acquisition():
		return _acquire(definition)
	var entry := _find_entry(definition)
	if entry == null or choice.target_rank != entry.current_rank + 1:
		return false
	return _rank_up(entry, choice.target_rank)


func reset_loadout() -> void:
	for entry in _entries:
		if entry.runtime != null and is_instance_valid(entry.runtime):
			entry.runtime.shutdown()
	_entries.clear()
	loadout_reset.emit()


func _acquire(definition: WeaponDefinition) -> bool:
	if not can_acquire(definition):
		return false
	var runtime := _create_runtime(definition)
	if runtime == null:
		return false
	var rank_definition := definition.get_rank_definition(1)
	if not runtime.apply_rank(1, rank_definition):
		runtime.shutdown()
		return false
	var entry := WeaponLoadoutEntry.new(definition, 1, runtime)
	_entries.append(entry)
	weapon_acquired.emit(entry)
	return true


func _rank_up(entry: WeaponLoadoutEntry, target_rank: int) -> bool:
	if entry.runtime == null or not is_instance_valid(entry.runtime):
		return false
	var rank_definition := entry.definition.get_rank_definition(target_rank)
	if not entry.runtime.apply_rank(target_rank, rank_definition):
		return false
	var previous_rank := entry.current_rank
	entry.current_rank = target_rank
	weapon_rank_changed.emit(entry, previous_rank)
	return true


func _create_runtime(definition: WeaponDefinition) -> SharedWeaponRuntime:
	var runtime: SharedWeaponRuntime
	if definition.runtime_scene != null:
		var instance := definition.runtime_scene.instantiate()
		if not (instance is SharedWeaponRuntime):
			push_error("Weapon runtime scene for %s must extend SharedWeaponRuntime." % definition.weapon_id)
			instance.queue_free()
			return null
		runtime = instance as SharedWeaponRuntime
	else:
		runtime = SharedWeaponRuntime.new()
	var parent := runtime_parent if runtime_parent != null else self
	parent.add_child(runtime)
	runtime.configure(definition, weapon_owner)
	return runtime


func _find_entry(definition: WeaponDefinition) -> WeaponLoadoutEntry:
	if definition == null:
		return null
	for entry in _entries:
		if entry.definition == definition or entry.definition.weapon_id == definition.weapon_id:
			return entry
	return null
