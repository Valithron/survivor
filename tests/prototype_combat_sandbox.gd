class_name PrototypeCombatSandbox
extends Node2D

## Developer-only P1 + E1 convergence sandbox. It intentionally exercises the
## published SterlingPlayer, EnemySpawner, HealthComponent, DamageEvent, and XP
## event contracts without becoming a player-facing arena, HUD, progression, or
## shared-weapon implementation. Sterling and swarm-zombie body rendering comes
## from the integrated A1 raster scenes; the sandbox grid/HUD stays developer UI.

@export_category("Developer spawn pressure")
@export_range(0, 240, 1) var initial_spawn_burst := 12
@export_range(1, 100, 1) var enemies_per_batch := 3
@export_range(0.05, 10.0, 0.05) var spawn_interval_seconds := 0.4
@export_range(1, 500, 1) var maximum_active_enemies := 240
@export_range(1, 100, 1) var manual_spawn_burst := 12
@export_range(32.0, 300.0, 1.0) var player_contact_radius := 16.0

@onready var player: SterlingPlayer = $SterlingPlayer
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var status_label: Label = $CanvasLayer/Panel/Status

var basic_shots_fired := 0
var xp_awards_seen := 0
var last_event := "Booting Sterling + swarm-zombie contract sandbox."


func _ready() -> void:
	_apply_developer_spawn_pressure()
	enemy_spawner.set_target(player, player.health_component, player_contact_radius)
	player.basic_fired.connect(_on_basic_fired)
	player.aim_mode_changed.connect(_on_aim_mode_changed)
	player.damage_received.connect(_on_player_damage_received)
	player.died.connect(_on_player_died)
	enemy_spawner.active_enemy_count_changed.connect(_on_active_enemy_count_changed)
	GameplayEvents.xp_awarded.connect(_on_xp_awarded)
	if not enemy_spawner.start_spawning():
		last_event = "Spawner did not start; check the E1 spawn configuration."
		push_error(last_event)
		return
	var spawned := enemy_spawner.spawn_burst(initial_spawn_burst)
	last_event = "Started tunable swarm pressure with %d immediate swarm zombies." % spawned
	queue_redraw()


func _exit_tree() -> void:
	if GameplayEvents.xp_awarded.is_connected(_on_xp_awarded):
		GameplayEvents.xp_awarded.disconnect(_on_xp_awarded)


func _process(_delta: float) -> void:
	status_label.text = "P1 + E1 DEV COMBAT SANDBOX\n\nAim: %s\nVector: (%.2f, %.2f)\nFire rate: %.2f shots/sec\nHealth: %.0f / %.0f\nSwarm active: %d / %d\nBasic shots: %d\nXP awards observed: %d\n\n%s\n\nWASD: move Sterling\nMouse: Manual Aim direction\nT: persistent Auto / Manual basic aim\n2: add %d swarm zombies\n\nDeveloper primitives only — final Sterling and zombie art remain external A1 dependencies." % [
		"Manual Aim" if player.manual_aim_enabled else "Auto Aim",
		player.get_basic_aim_direction().x,
		player.get_basic_aim_direction().y,
		player.get_current_fire_rate(),
		player.health_component.current_health,
		player.health_component.maximum_health,
		enemy_spawner.get_active_enemy_count(),
		maximum_active_enemies,
		basic_shots_fired,
		xp_awards_seen,
		last_event,
		manual_spawn_burst,
	]
	var presentation_note := "\n\nSterling and swarm-zombie pixel art are integrated. The grid and HUD remain developer presentation."
	var stale_note_start := status_label.text.rfind("\n\nDeveloper primitives")
	if stale_note_start >= 0:
		status_label.text = status_label.text.left(stale_note_start) + presentation_note
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_spawn_swarm") and not event.is_echo():
		var spawned := enemy_spawner.spawn_burst(manual_spawn_burst)
		last_event = "Developer burst requested %d; spawned %d within the active cap." % [manual_spawn_burst, spawned]
		get_viewport().set_input_as_handled()


func _draw() -> void:
	## Simple field markings are developer readability aids, not environment art.
	for x in range(0, 1281, 80):
		draw_line(Vector2(x, 0), Vector2(x, 720), Color(0.25, 0.34, 0.31, 0.14), 1.0)
	for y in range(0, 721, 80):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.25, 0.34, 0.31, 0.14), 1.0)
	draw_arc(player.global_position, 80.0, 0.0, TAU, 48, Color(0.34, 0.67, 1.0, 0.24), 1.0, true)


func _apply_developer_spawn_pressure() -> void:
	## Duplicate the E1 resource at runtime so sandbox inspection/tuning never
	## mutates its shared editable asset.
	var base_configuration := enemy_spawner.spawn_configuration
	if base_configuration == null:
		push_error("PrototypeCombatSandbox requires EnemySpawner.spawn_configuration.")
		return
	var runtime_configuration := base_configuration.duplicate(true) as EnemySpawnConfiguration
	if runtime_configuration == null:
		push_error("PrototypeCombatSandbox could not duplicate EnemySpawnConfiguration.")
		return
	runtime_configuration.initial_delay_seconds = 0.0
	runtime_configuration.enemies_per_batch = enemies_per_batch
	runtime_configuration.spawn_interval_seconds = spawn_interval_seconds
	runtime_configuration.maximum_active_enemies = maximum_active_enemies
	enemy_spawner.spawn_configuration = runtime_configuration


func _on_basic_fired(_direction: Vector2, _muzzle_position: Vector2, _muzzle_side: int, _fire_rate: float) -> void:
	basic_shots_fired += 1


func _on_aim_mode_changed(manual_aim_enabled: bool) -> void:
	last_event = "Persistent basic aim switched to %s without stopping fire." % ("Manual Aim" if manual_aim_enabled else "Auto Aim")


func _on_player_damage_received(_event: DamageEvent, amount: float) -> void:
	last_event = "Swarm contact delivered %.1f damage through HealthComponent." % amount


func _on_player_died(_event: DamageEvent) -> void:
	enemy_spawner.stop_spawning()
	last_event = "Sterling health reached zero; spawning stopped. Reload this developer scene to reset."


func _on_active_enemy_count_changed(active_enemy_count: int) -> void:
	if active_enemy_count >= maximum_active_enemies:
		last_event = "Swarm reached the temporary active-enemy cap (%d)." % maximum_active_enemies


func _on_xp_awarded(_award: XpAward) -> void:
	xp_awards_seen += 1
