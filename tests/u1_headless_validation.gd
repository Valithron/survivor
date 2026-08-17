extends Node

const PLAYTEST_SCENE: PackedScene = preload("res://tests/prototype_playtest.tscn")
const SHELL_SCENE: PackedScene = preload("res://game/ui/first_playable_shell.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_validate")


func _validate() -> void:
	var errors: Array[String] = []
	var playtest := PLAYTEST_SCENE.instantiate() as PrototypePlaytest
	get_tree().root.add_child(playtest)
	await get_tree().process_frame
	var player := playtest.get_node_or_null(^"World/PlayerAnchor/Player") as SterlingPlayer
	var core_hud := playtest.get_node_or_null(^"CanvasLayer/CoreHud") as CoreHud
	var number_layer := playtest.get_node_or_null(^"World/DamageNumbers") as DamageNumberLayer
	var pause_panel := playtest.get_node_or_null(^"CanvasLayer/PausePanel") as ColorRect
	var outcome_actions := playtest.get_node_or_null(^"CanvasLayer/OutcomeActions") as HBoxContainer
	if player == null or core_hud == null or number_layer == null or pause_panel == null or outcome_actions == null:
		errors.append("U1 assembled playtest is missing a required HUD, damage-number, or run-flow node.")
	else:
		player.apply_damage(DamageEvent.new(self, 4.0, &"u1_damage_number"))
		await get_tree().process_frame
		if number_layer.get_child_count() <= 0:
			errors.append("U1 shared health/damage event did not create visible damage-number presentation.")
		if not RunController.toggle_user_pause():
			errors.append("U1 could not enter user pause through the run lifecycle.")
		await get_tree().process_frame
		if not pause_panel.visible:
			errors.append("U1 pause panel did not appear while the run was paused.")
		RunController.toggle_user_pause()
		await get_tree().process_frame
		if pause_panel.visible:
			errors.append("U1 pause panel remained visible after the run resumed.")
		player.apply_damage(DamageEvent.new(self, player.health_component.current_health + 1.0, &"u1_finish"))
		await get_tree().process_frame
		if RunController.state != RunController.RunState.ENDED or not outcome_actions.visible:
			errors.append("U1 death flow did not end the run and expose restart/select actions.")

	playtest.queue_free()
	await get_tree().process_frame
	var shell := SHELL_SCENE.instantiate() as FirstPlayableShell
	get_tree().root.add_child(shell)
	await get_tree().process_frame
	if not shell.title_panel.visible or shell.character_select.visible:
		errors.append("U1 title shell did not begin on the title panel.")
	shell.show_character_select()
	if shell.title_panel.visible or not shell.character_select.visible:
		errors.append("U1 Sterling selection shell could not change between title and character-select states.")
	shell.queue_free()
	await get_tree().process_frame

	if errors.is_empty():
		print("U1 HUD / RUN FLOW TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("U1 HUD / RUN FLOW TEST: " + error_text)
	get_tree().quit(1)
