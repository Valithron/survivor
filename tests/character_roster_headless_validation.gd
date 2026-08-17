extends Node

## Roster convergence validates that all three independent player scenes enter
## one shared First Playable runtime without character-id conditionals.
const ROSTER: CharacterRosterDefinition = preload("res://data/characters/roster.tres")
const PLAYTEST_SCENE: PackedScene = preload("res://tests/prototype_playtest.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_validate")


func _validate() -> void:
	var errors: Array[String] = []
	errors.append_array(ROSTER.validate_contract())
	var previous_id := CharacterSelection.selected_character_id
	for character_id in [&"sterling", &"ryan", &"cooper"]:
		var entry := ROSTER.get_entry(character_id)
		if entry == null:
			errors.append("Roster omitted %s." % character_id)
			continue
		if not CharacterSelection.select_character(character_id):
			errors.append("CharacterSelection rejected a valid %s roster entry." % character_id)
			continue
		var playtest := PLAYTEST_SCENE.instantiate() as PrototypePlaytest
		get_tree().root.add_child(playtest)
		await get_tree().process_frame
		var runtime_player := playtest.get_node_or_null(^"World/PlayerAnchor/Player") as Node2D
		var expected_player := entry.player_scene.instantiate()
		var expected_script: Script = expected_player.get_script() as Script
		expected_player.free()
		if runtime_player == null or runtime_player.get_script() != expected_script:
			errors.append("Selected %s runtime did not instantiate through the shared playtest path." % character_id)
		if RunController.active_character != entry.character:
			errors.append("Selected %s did not become the active CharacterDefinition for the run." % character_id)
		var inventory := playtest.get_node_or_null(^"World/WeaponInventory") as WeaponInventory
		if inventory == null or inventory.weapon_owner != runtime_player:
			errors.append("Selected %s did not receive the shared WeaponInventory owner contract." % character_id)
		playtest.queue_free()
		await get_tree().process_frame
	if not CharacterSelection.select_character(previous_id):
		CharacterSelection.select_character(&"sterling")
	_finish(errors)


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("CHARACTER ROSTER CONVERGENCE TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("CHARACTER ROSTER CONVERGENCE TEST: " + error_text)
	get_tree().quit(1)
