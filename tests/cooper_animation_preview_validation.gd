extends Node

const PREVIEW_SCENE: PackedScene = preload("res://tests/cooper_animation_preview.tscn")


func _ready() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var preview := PREVIEW_SCENE.instantiate()
	get_tree().root.add_child(preview)
	await get_tree().process_frame
	var errors: Array[String] = []
	if preview.get_node_or_null(^"Hero") == null or preview.get_node_or_null(^"GameplayScale") == null:
		errors.append("Cooper animation preview is missing its large or gameplay-scale visual.")
	var directional_visuals := 0
	for child in preview.get_children():
		if child is RosterSpriteVisual:
			directional_visuals += 1
	if directional_visuals != 10:
		errors.append("Cooper animation preview did not create its eight-direction review strip.")
	preview.queue_free()
	if errors.is_empty():
		print("COOPER ANIMATION PREVIEW TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("COOPER ANIMATION PREVIEW TEST: " + error_text)
	get_tree().quit(1)
