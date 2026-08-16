extends Node

## Focused Vertical Slice validation for Ryan's data-driven Bruiser kit. It
## uses actual ZombieEnemy targets to prove the common damage/knockback seam,
## while leaving final Ryan sprite/VFX work to ART-ROSTER.
const RYAN_SCENE: PackedScene = preload("res://game/player/ryan_player.tscn")
const SWARM_SCENE: PackedScene = preload("res://game/enemies/swarm_zombie.tscn")
const SWARM_DEFINITION: EnemyDefinition = preload("res://data/enemies/swarm_zombie.tres")
const RYAN: CharacterDefinition = preload("res://data/characters/ryan.tres")
const BASIC_TUNING: RyanBasicTuning = preload("res://data/characters/ryan_basic_tuning.tres")
const KIT_TUNING: RyanKitTuning = preload("res://data/characters/ryan_kit_tuning.tres")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_validate")


func _validate() -> void:
	var errors: Array[String] = []
	errors.append_array(RYAN.validate_contract())
	errors.append_array(BASIC_TUNING.validate_contract())
	errors.append_array(KIT_TUNING.validate_contract())
	if RYAN.base_max_health <= 100.0 or RYAN.move_speed >= 260.0:
		errors.append("Ryan's resource does not preserve a durable, lower-tempo Bruiser stat profile.")

	var player := RYAN_SCENE.instantiate() as RyanPlayer
	get_tree().root.add_child(player)
	await get_tree().process_frame
	if player == null or player.health_component == null or not is_equal_approx(player.health_component.maximum_health, RYAN.base_max_health):
		errors.append("RyanPlayer did not configure its shared HealthComponent from CharacterDefinition.")
		_finish(errors)
		return

	var basic_enemy := _spawn_durable_enemy(player, Vector2(110.0, 0.0))
	await get_tree().process_frame
	player.set_manual_aim_enabled(true)
	player.set_manual_aim_direction(Vector2.RIGHT)
	var health_before_basic := basic_enemy.health_component.current_health if basic_enemy != null else 0.0
	player.fire_basic_once_for_test()
	await get_tree().physics_frame
	if basic_enemy == null or basic_enemy.health_component.current_health >= health_before_basic:
		errors.append("Ryan's combat shotgun did not damage a close target inside its aimed cone.")
	var level_one_damage := player.get_effective_basic_damage()
	player.set_character_level(5)
	if not player.basic_milestone_active or player.get_effective_basic_damage() <= level_one_damage:
		errors.append("Ryan Level 5 did not materially improve the locked shotgun basic.")

	var charge_enemy := _spawn_durable_enemy(player, player.global_position + Vector2(116.0, 0.0))
	await get_tree().process_frame
	player.set_character_level(10)
	var charge_events: Array[DamageEvent] = []
	if charge_enemy != null:
		charge_enemy.health_component.damage_received.connect(func(event: DamageEvent, _amount: float) -> void:
			if event.tag == &"ryan_armored_charge":
				charge_events.append(event)
		)
	var expected_charge_distance := player.get_tactical_total_distance()
	var charge_start := player.global_position
	if not player.try_activate_tactical(Vector2.RIGHT):
		errors.append("Ryan's Armored Charge did not activate while ready.")
	for _frame in range(48):
		await get_tree().physics_frame
	if player.is_charging() or player.global_position.distance_to(charge_start) < expected_charge_distance * 0.72:
		errors.append("Ryan's Armored Charge was not a sustained physical movement through space.")
	if charge_events.is_empty() or charge_events[0].knockback.length_squared() <= 0.0001:
		errors.append("Ryan's Armored Charge did not damage and shove an encountered enemy through DamageEvent.")
	if player.try_activate_tactical(Vector2.RIGHT):
		errors.append("Ryan's Armored Charge ignored its cooldown.")

	var impact_enemy := _spawn_durable_enemy(player, player.global_position + Vector2(180.0, 0.0))
	await get_tree().process_frame
	var health_before_ultimate := impact_enemy.health_component.current_health if impact_enemy != null else 0.0
	player.set_character_level(15)
	var impacts: Array[Dictionary] = []
	player.radial_impact_fired.connect(func(index: int, radius: float, damage: float, final_shockwave: bool, hit_count: int) -> void:
		impacts.append({"index": index, "radius": radius, "damage": damage, "final": final_shockwave, "hits": hit_count})
	)
	if not player.try_activate_ultimate():
		errors.append("Ryan's escalating radial-impact ultimate did not activate while ready.")
	for _frame in range(132):
		await get_tree().physics_frame
	var expected_impacts := KIT_TUNING.impact_count_for(true)
	if impacts.size() != expected_impacts:
		errors.append("Ryan's ultimate emitted %d impacts instead of its Level 15 value %d." % [impacts.size(), expected_impacts])
	elif not bool(impacts.back()["final"]) or float(impacts.back()["radius"]) <= float(impacts[0]["radius"]) or float(impacts.back()["damage"]) <= float(impacts[0]["damage"]):
		errors.append("Ryan's ultimate did not end in a visibly/mechanically larger final shockwave.")
	if impact_enemy == null or impact_enemy.health_component.current_health >= health_before_ultimate:
		errors.append("Ryan's radial impacts did not damage a target within the expanding crowd-reset radius.")
	if player.try_activate_ultimate():
		errors.append("Ryan's ultimate ignored its cooldown.")

	for enemy in [basic_enemy, charge_enemy, impact_enemy]:
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
	player.queue_free()
	await get_tree().process_frame
	_finish(errors)


func _spawn_durable_enemy(player: RyanPlayer, position: Vector2) -> ZombieEnemy:
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


func _finish(errors: Array[String]) -> void:
	if errors.is_empty():
		print("C-RYAN BRUISER KIT TEST: PASS")
		get_tree().quit(0)
		return
	for error_text in errors:
		printerr("C-RYAN BRUISER KIT TEST: " + error_text)
	get_tree().quit(1)
