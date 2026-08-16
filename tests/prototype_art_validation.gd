extends Node

## Verifies the A1 art gate is backed by real imported raster assets and that
## their frame contracts are present in the runtime scenes.
const PLAYER_SCENE: PackedScene = preload("res://game/player/sterling_player.tscn")
const RYAN_PLAYER_SCENE: PackedScene = preload("res://game/player/ryan_player.tscn")
const COOPER_PLAYER_SCENE: PackedScene = preload("res://game/player/cooper_player.tscn")
const ENEMY_SCENE: PackedScene = preload("res://game/enemies/swarm_zombie.tscn")
const STERLING: CharacterDefinition = preload("res://data/characters/sterling.tres")
const RYAN: CharacterDefinition = preload("res://data/characters/ryan.tres")
const COOPER: CharacterDefinition = preload("res://data/characters/cooper.tres")
const SWARM: EnemyDefinition = preload("res://data/enemies/swarm_zombie.tres")
const CELL_SIZE := 64
const DIRECTION_COUNT := 8


func _ready() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
	var errors: Array[String] = []
	if STERLING.sprite_scene == null:
		errors.append("Sterling CharacterDefinition has no production sprite scene.")
	if RYAN.sprite_scene == null:
		errors.append("Ryan CharacterDefinition has no production sprite scene.")
	if COOPER.sprite_scene == null:
		errors.append("Cooper CharacterDefinition has no production sprite scene.")
	if SWARM.visual_scene == null:
		errors.append("Swarm EnemyDefinition has no production visual scene.")
	if not FileAccess.file_exists("res://art/source/sterling_concept_sheet_v1.png"):
		errors.append("Sterling art-bible concept sheet is missing.")
	if not FileAccess.file_exists("res://art/characters/sterling/sterling_sheet.png"):
		errors.append("Sterling raster sheet is missing.")
	if not FileAccess.file_exists("res://art/characters/ryan/ryan_sheet_v2.png"):
		errors.append("Ryan raster sheet is missing.")
	if not FileAccess.file_exists("res://art/characters/cooper/cooper_sheet_v2.png"):
		errors.append("Cooper raster sheet is missing.")
	if not FileAccess.file_exists("res://art/enemies/swarm_zombie/swarm_zombie_sheet.png"):
		errors.append("Swarm zombie raster sheet is missing.")

	var root_node := Node2D.new()
	get_tree().root.add_child(root_node)
	var player := PLAYER_SCENE.instantiate() as SterlingPlayer
	root_node.add_child(player)
	var ryan := RYAN_PLAYER_SCENE.instantiate() as RyanPlayer
	ryan.position = Vector2(256, 1024)
	root_node.add_child(ryan)
	var cooper := COOPER_PLAYER_SCENE.instantiate() as CooperPlayer
	cooper.position = Vector2(768, 1024)
	root_node.add_child(cooper)
	var enemy := ENEMY_SCENE.instantiate() as ZombieEnemy
	enemy.configure(SWARM)
	root_node.add_child(enemy)
	await get_tree().process_frame

	_validate_visual(player.get_node_or_null(^"Visual"), Vector2(512, 1024), "Sterling", errors)
	_validate_visual(ryan.get_node_or_null(^"Visual"), Vector2(512, 1024), "Ryan", errors)
	_validate_visual(cooper.get_node_or_null(^"Visual"), Vector2(512, 1024), "Cooper", errors)
	_validate_visual(enemy.get_node_or_null(^"Visual"), Vector2(512, 576), "Swarm zombie", errors)
	_validate_player_sheet(ryan.get_node_or_null(^"Visual"), "Ryan", errors)
	_validate_player_sheet(cooper.get_node_or_null(^"Visual"), "Cooper", errors)

	var sterling_visual := player.get_node_or_null(^"Visual")
	if sterling_visual != null and sterling_visual.has_method(&"set_animation_state"):
		sterling_visual.call(&"set_animation_state", &"basic_n")
		var sprite := sterling_visual.get_node_or_null(^"Sprite") as Sprite2D
		if sprite != null and sprite.region_rect.position.y not in [576.0, 640.0]:
			errors.append("Sterling basic animation did not resolve to either documented recoil row of the raster sheet.")
		if sterling_visual.has_method(&"play_basic_shot") and sprite != null:
			sterling_visual.call(&"play_basic_shot", 1)
			if sprite.region_rect.position.y != 576.0:
				errors.append("Sterling's right-pistol recoil did not select basic frame 0.")
			sterling_visual.call(&"play_basic_shot", -1)
			if sprite.region_rect.position.y != 640.0:
				errors.append("Sterling's left-pistol recoil did not select basic frame 1.")
			_validate_sterling_animation_cells(sprite.texture.get_image(), errors)

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
	if not sprite.region_enabled or sprite.region_rect.size != Vector2(CELL_SIZE, CELL_SIZE):
		errors.append("%s Visual is not using the canonical 64 px atlas region." % label)
	var image := sprite.texture.get_image()
	if image.get_pixel(0, 0).a > 0.0:
		errors.append("%s raster sheet does not have a transparent corner." % label)
	if image.get_pixel(image.get_width() - 1, image.get_height() - 1).a > 0.0:
		errors.append("%s raster sheet does not preserve transparent sheet padding." % label)
	if _has_chroma_backdrop(image):
		errors.append("%s raster sheet still contains a substantial chroma-key backdrop." % label)


func _validate_sterling_animation_cells(image: Image, errors: Array[String]) -> void:
	## These checks deliberately inspect visible raster output, not tool constants:
	## every documented cell must be present, live frames keep the shared foot line,
	## and the authored poses materially change from frame to frame.
	for row in range(16):
		for direction in range(DIRECTION_COUNT):
			var cell := image.get_region(Rect2i(direction * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE))
			if cell.get_used_rect().size == Vector2i.ZERO:
				errors.append("Sterling sheet has an empty animation cell at row %d, direction %d." % [row, direction])
	for row in range(12):
		for direction in range(DIRECTION_COUNT):
			if not _has_ground_contact(image, row, direction):
				errors.append("Sterling live animation lost the shared feet anchor at row %d, direction %d." % [row, direction])
	for direction in range(DIRECTION_COUNT):
		for row in range(3, 8):
			if _visible_pixel_difference(image, row, row + 1, direction) < 48:
				errors.append("Sterling run frames %d/%d are not materially distinct in direction %d." % [row - 3, row - 2, direction])
		var basic_difference := _visible_pixel_difference(image, 9, 10, direction)
		if basic_difference < 24:
			errors.append("Sterling alternating basic frames are not materially distinct in direction %d." % direction)
		var hurt_difference := _alpha_difference(image, 0, 11, direction)
		if hurt_difference < 6:
			errors.append("Sterling hurt frame has no silhouette reaction in direction %d." % direction)
		for row in range(12, 15):
			if _visible_pixel_difference(image, row, row + 1, direction) < 48:
				errors.append("Sterling death stages %d/%d are not materially distinct in direction %d." % [row - 12, row - 11, direction])


func _validate_player_sheet(visual: Node, label: String, errors: Array[String]) -> void:
	if visual == null:
		return
	var sprite := visual.get_node_or_null(^"Sprite") as Sprite2D
	if sprite == null or sprite.texture == null:
		return
	var image := sprite.texture.get_image()
	for row in range(16):
		for direction in range(DIRECTION_COUNT):
			var cell := image.get_region(Rect2i(direction * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE))
			if cell.get_used_rect().size == Vector2i.ZERO:
				errors.append("%s sheet has an empty animation cell at row %d, direction %d." % [label, row, direction])
	for row in range(12):
		for direction in range(DIRECTION_COUNT):
			if not _has_ground_contact(image, row, direction):
				errors.append("%s live animation lost the shared feet anchor at row %d, direction %d." % [label, row, direction])
	for direction in range(DIRECTION_COUNT):
		for row in range(3, 8):
			if _visible_pixel_difference(image, row, row + 1, direction) < 8:
				errors.append("%s run frames %d/%d are not materially distinct in direction %d." % [label, row - 3, row - 2, direction])
		if _visible_pixel_difference(image, 9, 10, direction) < 8:
			errors.append("%s basic frames are not materially distinct in direction %d." % [label, direction])


func _has_ground_contact(image: Image, row: int, direction: int) -> bool:
	for y in range(CELL_SIZE - 4, CELL_SIZE):
		for x in range(CELL_SIZE):
			if image.get_pixel(direction * CELL_SIZE + x, row * CELL_SIZE + y).a > 0.0:
				return true
	return false


func _visible_pixel_difference(image: Image, first_row: int, second_row: int, direction: int) -> int:
	var changed := 0
	for y in range(CELL_SIZE):
		for x in range(CELL_SIZE):
			var first := image.get_pixel(direction * CELL_SIZE + x, first_row * CELL_SIZE + y)
			var second := image.get_pixel(direction * CELL_SIZE + x, second_row * CELL_SIZE + y)
			if first.to_rgba32() != second.to_rgba32():
				changed += 1
	return changed


func _alpha_difference(image: Image, first_row: int, second_row: int, direction: int) -> int:
	var changed := 0
	for y in range(CELL_SIZE):
		for x in range(CELL_SIZE):
			var first_alpha := int(round(image.get_pixel(direction * CELL_SIZE + x, first_row * CELL_SIZE + y).a * 255.0))
			var second_alpha := int(round(image.get_pixel(direction * CELL_SIZE + x, second_row * CELL_SIZE + y).a * 255.0))
			if first_alpha != second_alpha:
				changed += 1
	return changed


func _has_chroma_backdrop(image: Image) -> bool:
	## A few intentional dark crimson/purple pixels are valid art. A chroma-key
	## failure, in contrast, leaves hundreds or thousands of bright magenta pixels.
	var chroma_pixels := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.0 and pixel.r > 0.94 and pixel.b > 0.94 and pixel.g < 0.15:
				chroma_pixels += 1
				if chroma_pixels > 64:
					return true
	return false
