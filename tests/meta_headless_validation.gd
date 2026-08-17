extends Node

const DEFINITION: UnlockProgressionDefinition = preload("res://data/meta/character_unlocks.tres")
const SHELL_SCENE: PackedScene = preload("res://game/ui/first_playable_shell.tscn")
const TEST_STORAGE_PATH := "user://survivor_meta_validation.json"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_validate")


func _validate() -> void:
	var errors: Array[String] = []
	errors.append_array(DEFINITION.validate_contract())
	var original_storage_path := MetaProgression.get_storage_path()
	MetaProgression.set_storage_path_for_testing(TEST_STORAGE_PATH)
	MetaProgression.reset_profile_for_testing()
	if MetaProgression.completed_natural_runs != 0:
		errors.append("META-1 fresh profile did not start with zero natural run ends.")
	if not MetaProgression.is_character_unlocked(&"sterling"):
		errors.append("META-1 fresh profile did not unlock Sterling.")
	if MetaProgression.is_character_unlocked(&"ryan") or MetaProgression.is_character_unlocked(&"cooper"):
		errors.append("META-1 fresh profile unlocked a future character too early.")

	var ignored := MetaProgression.record_natural_run_end(&"timed_session_complete")
	if not ignored.is_empty() or MetaProgression.completed_natural_runs != 0:
		errors.append("META-1 counted a non-natural run outcome.")
	var first_unlocks := MetaProgression.record_natural_run_end(&"death")
	if MetaProgression.completed_natural_runs != 1 or not first_unlocks.has("ryan") or not MetaProgression.is_character_unlocked(&"ryan"):
		errors.append("META-1 did not unlock Ryan after the first natural run end.")
	MetaProgression.record_natural_run_end(&"death")
	var third_unlocks := MetaProgression.record_natural_run_end(&"victory")
	if MetaProgression.completed_natural_runs != 3 or not third_unlocks.has("cooper") or not MetaProgression.is_character_unlocked(&"cooper"):
		errors.append("META-1 did not unlock Cooper after the third natural run end.")
	MetaProgression.reload_from_storage()
	if MetaProgression.completed_natural_runs != 3 or not MetaProgression.is_character_unlocked(&"ryan") or not MetaProgression.is_character_unlocked(&"cooper"):
		errors.append("META-1 did not persist the completed-run and unlock state.")

	var shell := SHELL_SCENE.instantiate() as FirstPlayableShell
	get_tree().root.add_child(shell)
	await get_tree().process_frame
	shell.show_character_select()
	var status := shell.get_node_or_null(^"CharacterSelect/UnlockStatus") as Label
	if status == null or not status.text.contains("RYAN // UNLOCKED") or not status.text.contains("COOPER // UNLOCKED"):
		errors.append("META-1 character select did not reflect persistent unlock state.")
	shell.queue_free()
	await get_tree().process_frame
	MetaProgression.set_storage_path_for_testing(original_storage_path)

	if errors.is_empty():
		print("META-1 UNLOCK PROGRESSION TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("META-1 UNLOCK PROGRESSION TEST: " + error_text)
	get_tree().quit(1)
