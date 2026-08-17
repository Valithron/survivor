extends Node2D

## Developer-only E1 integration scene. The blue player is a test marker;
## spawned swarm zombies use the integrated Prototype raster visual.
@onready var player_target: CharacterBody2D = $PlayerTarget
@onready var player_health: HealthComponent = $PlayerTarget/HealthComponent
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var status_label: Label = $CanvasLayer/Status

var _xp_awards_seen := 0


func _ready() -> void:
	enemy_spawner.set_target(player_target, player_health, 16.0)
	GameplayEvents.xp_awarded.connect(_on_xp_awarded)
	queue_redraw()


func _exit_tree() -> void:
	if GameplayEvents.xp_awarded.is_connected(_on_xp_awarded):
		GameplayEvents.xp_awarded.disconnect(_on_xp_awarded)


func _physics_process(_delta: float) -> void:
	var move_direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	player_target.velocity = move_direction * 260.0
	player_target.move_and_slide()
	player_target.global_position.x = clampf(player_target.global_position.x, 32.0, 1248.0)
	player_target.global_position.y = clampf(player_target.global_position.y, 32.0, 688.0)
	queue_redraw()


func _process(_delta: float) -> void:
	status_label.text = "E1 ENEMY / HORDE TEST\n\nWASD: move target\n2: request 12 more swarm zombies\n\nHealth: %.1f / %.1f\nActive swarm: %d\nXP awards observed: %d\n\nThe blue player body is a test marker. Swarm zombies use their Prototype pixel-art visual." % [
		player_health.current_health,
		player_health.maximum_health,
		enemy_spawner.get_active_enemy_count(),
		_xp_awards_seen,
	]


func _draw() -> void:
	draw_circle(player_target.global_position, 16.0, Color("69c8ff"))
	draw_line(player_target.global_position + Vector2(-10, 0), player_target.global_position + Vector2(10, 0), Color("173d5a"), 3.0)
	draw_line(player_target.global_position + Vector2(0, -10), player_target.global_position + Vector2(0, 10), Color("173d5a"), 3.0)


func _on_xp_awarded(_award: XpAward) -> void:
	_xp_awards_seen += 1
