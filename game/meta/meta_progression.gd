extends Node

## The entire persistent layer for the locked lightweight unlock track. Active
## run data never enters this file, and only death/victory can advance it.
signal profile_loaded(completed_natural_runs: int)
signal profile_changed(completed_natural_runs: int, newly_unlocked_character_ids: PackedStringArray)

const DEFINITION: UnlockProgressionDefinition = preload("res://data/meta/character_unlocks.tres")
const DEFAULT_STORAGE_PATH := "user://survivor_progression_v1.json"
const NATURAL_OUTCOMES: Array[StringName] = [&"death", &"victory"]

var completed_natural_runs := 0
var _unlocked_character_ids: Dictionary = {}
var _storage_path := DEFAULT_STORAGE_PATH


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_profile()
	RunController.run_ended.connect(_on_run_ended)


func _exit_tree() -> void:
	if RunController.run_ended.is_connected(_on_run_ended):
		RunController.run_ended.disconnect(_on_run_ended)


func is_character_unlocked(character_id: StringName) -> bool:
	return _unlocked_character_ids.has(character_id)


func get_unlocked_character_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for rule in DEFINITION.character_unlock_rules:
		if rule != null and is_character_unlocked(rule.character_id):
			ids.append(String(rule.character_id))
	return ids


func record_natural_run_end(outcome: StringName) -> PackedStringArray:
	if not NATURAL_OUTCOMES.has(outcome):
		return PackedStringArray()
	var previously_unlocked := get_unlocked_character_ids()
	completed_natural_runs += 1
	_refresh_rule_unlocks()
	var newly_unlocked := PackedStringArray()
	for character_id in get_unlocked_character_ids():
		if not previously_unlocked.has(character_id):
			newly_unlocked.append(character_id)
	_write_profile()
	profile_changed.emit(completed_natural_runs, newly_unlocked)
	return newly_unlocked


func reload_from_storage() -> void:
	_load_profile()


## Test-only storage routing keeps headless tests out of a player's profile.
func set_storage_path_for_testing(path: String) -> void:
	_storage_path = path
	_load_profile()


func get_storage_path() -> String:
	return _storage_path


func reset_profile_for_testing() -> void:
	completed_natural_runs = 0
	_unlocked_character_ids.clear()
	_refresh_rule_unlocks()
	_write_profile()
	profile_changed.emit(completed_natural_runs, PackedStringArray())


func _on_run_ended(outcome: StringName, _elapsed_seconds: float) -> void:
	record_natural_run_end(outcome)


func _load_profile() -> void:
	completed_natural_runs = 0
	_unlocked_character_ids.clear()
	if FileAccess.file_exists(_storage_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_storage_path))
		if parsed is Dictionary:
			var save_data: Dictionary = parsed
			completed_natural_runs = maxi(int(save_data.get("completed_natural_runs", 0)), 0)
			var saved_ids: Variant = save_data.get("unlocked_character_ids", [])
			if saved_ids is Array:
				for saved_id in saved_ids:
					if saved_id is String and not saved_id.is_empty():
						_unlocked_character_ids[StringName(saved_id)] = true
	_refresh_rule_unlocks()
	if not FileAccess.file_exists(_storage_path):
		_write_profile()
	profile_loaded.emit(completed_natural_runs)


func _refresh_rule_unlocks() -> void:
	for rule in DEFINITION.character_unlock_rules:
		if rule != null and rule.is_unlocked_at(completed_natural_runs):
			_unlocked_character_ids[rule.character_id] = true


func _write_profile() -> void:
	var file := FileAccess.open(_storage_path, FileAccess.WRITE)
	if file == null:
		push_warning("MetaProgression could not write local save %s." % _storage_path)
		return
	var serialized_ids: Array[String] = []
	for character_id in get_unlocked_character_ids():
		serialized_ids.append(character_id)
	file.store_string(JSON.stringify({
		"version": DEFINITION.save_version,
		"completed_natural_runs": completed_natural_runs,
		"unlocked_character_ids": serialized_ids,
	}))
