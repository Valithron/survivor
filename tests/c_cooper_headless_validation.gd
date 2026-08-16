extends Node

## Focused Vertical Slice validation for Cooper's Glass Cannon kit. It proves
## actual projectiles and commitment-state multipliers without assigning any
## final art responsibility to this mechanical packet.
const COOPER_SCENE: PackedScene = preload("res://game/player/cooper_player.tscn")
const SWARM_SCENE: PackedScene = preload("res://game/enemies/swarm_zombie.tscn")
const SWARM_DEFINITION: EnemyDefinition = preload("res://data/enemies/swarm_zombie.tres")
const COOPER: CharacterDefinition = preload("res://data/characters/cooper.tres")
const BASIC_TUNING: CooperBasicTuning = preload("res://data/characters/cooper_basic_tuning.tres")
const KIT_TUNING: CooperKitTuning = preload("res://data/characters/cooper_kit_tuning.tres")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_validate")


func _validate() -> void:
	var errors: Array[String] = []
	errors.append_array(COOPER.validate_contract())
	errors.append_array(BASIC_TUNING.validate_contract())
	errors.append_array(KIT_TUNING.validate_contract())
	if COOPER.base_max_health >= 100.0 or COOPER.move_speed <= 0.0:
		errors.append("Cooper's resource does not preserve a clearly vulnerable Glass Cannon profile.")

	var player := COOPER_SCENE.instantiate() as CooperPlayer
	get_tree().root.add_child(player)
	await get_tree().process_frame
	if player == null or player.health_component == null or not is_equal_approx(player.health_component.maximum_health, COOPER.base_max_health):
		errors.append("CooperPlayer did not configure its shared HealthComponent from CharacterDefinition.")
		_finish(errors)
		return

	var target := _spawn_durable_enemy(player, Vector2(150.0, 0.0))
	await get_tree().process_frame
	player.set_manual_aim_enabled(true)
	player.set_manual_aim_direction(Vector2.RIGHT)
	var health_before_basic := target.health_component.current_health if target != null else 0.0
	player.fire_basic_once_for_test()
	await get_tree().process_frame
	var rifle_projectile := _first_rifle_projectile(get_tree().root)
	if rifle_projectile == null:
		errors.append("Cooper basic did not create its rifle projectile presentation.")
	else:
		var tracer_sprite := _first_sprite(rifle_projectile)
		if tracer_sprite == null or tracer_sprite.texture == null:
			errors.append("Cooper rifle projectile is missing its production raster tracer.")
		elif tracer_sprite.texture.get_size() != Vector2(128.0, 64.0):
			errors.append("Cooper rifle tracer atlas has the wrong raster dimensions.")
	for _frame in range(24):
		await get_tree().physics_frame
	if target == null or target.health_component.current_health >= health_before_basic:
		errors.append("Cooper's automatic rifle projectile did not damage a target through the shared DamageEvent seam.")
	var level_one_damage := player.get_effective_basic_damage()
	var level_one_rate := player.get_current_fire_rate()
	player.set_character_level(5)
	if not player.basic_milestone_active or player.get_effective_basic_damage() <= level_one_damage or player.get_current_fire_rate() <= level_one_rate:
		errors.append("Cooper Level 5 did not visibly/mechanically improve automatic rifle sustained fire.")

	player.set_character_level(10)
	var damage_before_overclock := player.get_effective_basic_damage()
	var speed_before_overclock := player.get_effective_move_speed()
	if not player.try_activate_tactical():
		errors.append("Cooper Damage Overclock did not activate while ready.")
	if not player.is_overclock_active() or player.get_effective_basic_damage() <= damage_before_overclock or player.get_effective_move_speed() >= speed_before_overclock:
		errors.append("Cooper Damage Overclock did not create the locked damage-for-mobility tradeoff.")
	if player.try_activate_tactical():
		errors.append("Cooper Damage Overclock ignored its active/cooldown state.")

	player.set_character_level(15)
	var damage_before_ultimate := player.get_effective_basic_damage()
	var rate_before_ultimate := player.get_current_fire_rate()
	var rifle_events: Array[Dictionary] = []
	player.basic_fired.connect(func(_direction: Vector2, _muzzle: Vector2, rate: float, damage: float) -> void:
		rifle_events.append({"rate": rate, "damage": damage})
	)
	if not player.try_activate_ultimate():
		errors.append("Cooper Anchored Sustained Fire did not activate while ready.")
	if not player.is_ultimate_active() or player.get_effective_basic_damage() <= damage_before_ultimate or player.get_current_fire_rate() <= rate_before_ultimate:
		errors.append("Cooper ultimate did not create extreme sustained rifle damage.")
	if player.get_effective_move_speed() >= COOPER.move_speed * 0.2:
		errors.append("Cooper ultimate did not nearly root player movement.")
	if player.try_activate_ultimate():
		errors.append("Cooper Anchored Sustained Fire ignored its active/cooldown state.")
	for _frame in range(30):
		await get_tree().physics_frame
	if rifle_events.size() < 4:
		errors.append("Cooper ultimate did not maintain a rapid automatic-rifle stream while anchored.")
	elif float(rifle_events.back()["rate"]) <= rate_before_ultimate or float(rifle_events.back()["damage"]) <= damage_before_ultimate:
		errors.append("Cooper ultimate rifle shots did not carry its sustained-fire multipliers.")

	if target != null and is_instance_valid(target):
		target.queue_free()
	player.queue_free()
	await get_tree().process_frame
	_finish(errors)


func _spawn_durable_enemy(player: CooperPlayer, position: Vector2) -> ZombieEnemy:
	var enemy := SWARM_SCENE.instantiate() as ZombieEnemy
	if enemy == null:
		return null
	var durable_definition := SWARM_DEFINITION.duplicate(true) as EnemyDefinition
	durable_definition.base_max_health = 10000.0
	enemy.configure(durable_definition)
	enemy.set_target(player, player.health_component, 16.0)
	enemy.global_position = position
	get_tree().root.add_child(enemy)
	return enemy


func _first_rifle_projectile(parent: Node) -> CooperRifleProjectile:
	for child in parent.get_children():
		if child is CooperRifleProjectile:
			return child as CooperRifleProjectile
	return null


func _first_sprite(parent: Node) -> Sprite2D:
	for child in parent.get_children():
		if child is Sprite2D:
			return child as Sprite2D
	return null


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("C-COOPER GLASS CANNON KIT TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("C-COOPER GLASS CANNON KIT TEST: " + error_text)
	get_tree().quit(1)
