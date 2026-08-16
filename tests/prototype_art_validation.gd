extends Node

## Verifies the A1 art gate is backed by real imported raster assets and that
## their frame contracts are present in the runtime scenes.
const PLAYER_SCENE: PackedScene = preload("res://game/player/sterling_player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://game/enemies/swarm_zombie.tscn")
const STERLING: CharacterDefinition = preload("res://data/characters/sterling.tres")
const SWARM: EnemyDefinition = preload("res://data/enemies/swarm_zombie.tres")


func _ready() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	if STERLING.sprite_scene == null:
		errors.append("Sterling CharacterDefinition has no production sprite scene.")
	if SWARM.visual_scene == null:
		errors.append("Swarm EnemyDefinition has no production visual scene.")
	if not FileAccess.file_exists("res://art/source/sterling_concept_sheet_v1.png"):
		errors.append("Sterling art-bible concept sheet is missing.")
	if not FileAccess.file_exists("res://art/characters/sterling/sterling_sheet.png"):
		errors.append("Sterling raster sheet is missing.")
	if not FileAccess.file_exists("res://art/enemies/swarm_zombie/swarm_zombie_sheet.png"):
		errors.append("Swarm zombie raster sheet is missing.")

	var root_node := Node2D.new()
	get_tree().root.add_child(root_node)
	var player := PLAYER_SCENE.instantiate() as SterlingPlayer
	root_node.add_child(player)
	var enemy := ENEMY_SCENE.instantiate() as ZombieEnemy
	enemy.configure(SWARM)
	root_node.add_child(enemy)
	await get_tree().process_frame

	_validate_visual(player.get_node_or_null(^"Visual"), Vector2(512, 1024), "Sterling", errors)
	_validate_visual(enemy.get_node_or_null(^"Visual"), Vector2(512, 576), "Swarm zombie", errors)

	var sterling_visual := player.get_node_or_null(^"Visual")
	if sterling_visual != null and sterling_visual.has_method(&"set_animation_state"):
		sterling_visual.call(&"set_animation_state", &"basic_n")
		var sprite := sterling_visual.get_node_or_null(^"Sprite") as Sprite2D
		if sprite != null and sprite.region_rect.position.y != 576.0:
			errors.append("Sterling basic animation did not resolve to row 9 of the raster sheet.")

	var zombie_visual := enemy.get_node_or_null(^"Visual")
	if zombie_visual != null and zombie_visual.has_method(&"set_motion_state"):
		zombie_visual.call(&"set_motion_state", &"attack", Vector2.RIGHT)
		var sprite := zombie_visual.get_node_or_null(^"Sprite") as Sprite2D
		if sprite != null and sprite.region_rect.position.y != 256.0:
			errors.append("Swarm zombie attack animation did not resolve to row 4 of the raster sheet.")

	root_node.queue_free()
	if errors.is_empty():
		print("PROTOTYPE ART TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("PROTOTYPE ART TEST: " + error_text)
	get_tree().quit(1)


func _validate_visual(visual: Node, expected_size: Vector2, label: String, errors: Array[String]) -> void:
	if visual == null:
		errors.append("%s runtime did not instantiate a Visual child." % label)
		return
	var sprite := visual.get_node_or_null(^"Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		errors.append("%s Visual is missing a raster Sprite2D." % label)
		return
	if sprite.texture.get_size() != expected_size:
		errors.append("%s raster sheet size is %s, expected %s." % [label, sprite.texture.get_size(), expected_size])
	if not sprite.region_enabled or sprite.region_rect.size != Vector2(64, 64):
		errors.append("%s Visual is not using the canonical 64 px atlas region." % label)
	var image := sprite.texture.get_image()
	if image.get_pixel(0, 0).a > 0.0:
		errors.append("%s raster sheet does not have a transparent corner." % label)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0 and pixel.r > 0.82 and pixel.b > 0.58 and pixel.g < 0.46:
				errors.append("%s raster sheet still contains chroma-key magenta at (%d, %d)." % [label, x, y])
			return
