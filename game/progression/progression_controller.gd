class_name ProgressionController
extends Node

## Owns run-local XP and choice state. It receives shared XP awards, pauses via
## RunController, and delegates only legal acquisition/rank changes to inventory.
signal xp_changed(total_xp: int, next_level_threshold: int)
signal level_changed(level: int)
signal xp_pickup_spawned(pickup: XpPickup)
signal upgrade_choices_ready(level: int, choices: Array[WeaponUpgradeChoice])
signal upgrade_selected(choice: WeaponUpgradeChoice)
signal level_advanced_without_upgrade(level: int)

@export var definition: ProgressionDefinition
@export var weapon_pool: Array[WeaponDefinition] = []
@export var inventory: WeaponInventory

var current_level: int = 1
var total_xp: int = 0
var pickup_target: Node2D
var pickup_parent: Node

var _choice_generator := UpgradeChoiceGenerator.new()
var _current_choices: Array[WeaponUpgradeChoice] = []
var _pending_awards: Array[XpAward] = []
var _active_pickups: Array[XpPickup] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameplayEvents.xp_awarded.connect(_on_xp_awarded)
	reset_progression(false)


func _exit_tree() -> void:
	if GameplayEvents.xp_awarded.is_connected(_on_xp_awarded):
		GameplayEvents.xp_awarded.disconnect(_on_xp_awarded)


func configure(progress_definition: ProgressionDefinition, available_weapons: Array[WeaponDefinition], weapon_inventory: WeaponInventory) -> void:
	definition = progress_definition
	weapon_pool = available_weapons.duplicate()
	inventory = weapon_inventory
	reset_progression(false)


func set_pickup_target(target: Node2D, parent_for_pickups: Node = null) -> void:
	pickup_target = target
	pickup_parent = parent_for_pickups if parent_for_pickups != null else self
	_flush_pending_awards()


func set_choice_seed(seed_value: int) -> void:
	_choice_generator.set_seed(seed_value)


func get_current_choices() -> Array[WeaponUpgradeChoice]:
	var copy: Array[WeaponUpgradeChoice] = []
	for choice in _current_choices:
		copy.append(choice.duplicate_choice())
	return copy


func active_pickup_count() -> int:
	return _active_pickups.size()


func receive_xp_award(award: XpAward) -> bool:
	if award == null or not award.is_valid():
		return false
	if pickup_target == null or not is_instance_valid(pickup_target):
		_pending_awards.append(XpAward.new(award.source, award.amount, award.world_position))
		return true
	_spawn_pickup(award)
	return true


func collect_xp(award: XpAward) -> bool:
	if award == null or not award.is_valid():
		return false
	total_xp += award.amount
	xp_changed.emit(total_xp, _next_level_threshold())
	_attempt_level_advance()
	return true


func select_upgrade(choice_index: int) -> bool:
	if choice_index < 0 or choice_index >= _current_choices.size() or inventory == null:
		return false
	var selected_choice := _current_choices[choice_index]
	if not inventory.apply_choice(selected_choice):
		## The only expected cause is a stale/misconfigured integration. Keep the
		## pause and options intact rather than silently granting an illegal rank.
		return false
	_current_choices.clear()
	upgrade_selected.emit(selected_choice)
	if RunController.state == RunController.RunState.UPGRADE_PAUSED:
		RunController.resume_after_upgrade()
	call_deferred("_attempt_level_advance")
	return true


func reset_progression(reset_inventory: bool = true) -> void:
	_current_choices.clear()
	_pending_awards.clear()
	for pickup in _active_pickups:
		if pickup != null and is_instance_valid(pickup):
			pickup.queue_free()
	_active_pickups.clear()
	if reset_inventory and inventory != null:
		inventory.reset_loadout()
	current_level = definition.starting_level if definition != null else 1
	total_xp = 0
	xp_changed.emit(total_xp, _next_level_threshold())
	level_changed.emit(current_level)


func _on_xp_awarded(award: XpAward) -> void:
	receive_xp_award(award)


func _spawn_pickup(award: XpAward) -> void:
	var pickup := XpPickup.new()
	var parent := pickup_parent if pickup_parent != null else self
	parent.add_child(pickup)
	pickup.global_position = award.world_position
	pickup.configure(award, pickup_target, _attraction_radius(), _attraction_speed(), _collection_radius())
	pickup.collected.connect(_on_pickup_collected.bind(pickup))
	_active_pickups.append(pickup)
	xp_pickup_spawned.emit(pickup)


func _flush_pending_awards() -> void:
	if pickup_target == null or not is_instance_valid(pickup_target):
		return
	var queued_awards := _pending_awards.duplicate()
	_pending_awards.clear()
	for award in queued_awards:
		_spawn_pickup(award)


func _on_pickup_collected(award: XpAward, pickup: XpPickup) -> void:
	_active_pickups.erase(pickup)
	collect_xp(award)


func _attempt_level_advance() -> void:
	if not _current_choices.is_empty() or definition == null or inventory == null:
		return
	var next_threshold := _next_level_threshold()
	if total_xp < next_threshold:
		return
	current_level += 1
	level_changed.emit(current_level)
	var generated_choices := _choice_generator.generate(inventory, weapon_pool, 3)
	if generated_choices.is_empty():
		## Once all equipped weapons reach Rank 5 there is no legal weapon card.
		## Advance cleanly instead of showing a fake Rank 6/no-op choice or leaving
		## the run permanently paused.
		level_advanced_without_upgrade.emit(current_level)
		call_deferred("_attempt_level_advance")
		return
	_current_choices = generated_choices
	if RunController.state == RunController.RunState.RUNNING:
		RunController.pause_for_upgrade()
	upgrade_choices_ready.emit(current_level, get_current_choices())


func _next_level_threshold() -> int:
	return definition.total_xp_required_for_level(current_level + 1) if definition != null else 1


func _attraction_radius() -> float:
	return definition.xp_attraction_radius if definition != null else 220.0


func _attraction_speed() -> float:
	return definition.xp_attraction_speed if definition != null else 720.0


func _collection_radius() -> float:
	return definition.xp_collect_radius if definition != null else 18.0
