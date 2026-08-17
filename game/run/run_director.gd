class_name RunDirector
extends Node

## R1's hand-authored run coordinator. It only selects documented composition
## beats; each EnemySpawner continues to own actual spawning and active caps.
signal phase_started(phase: RunPhaseDefinition)
signal boss_arrival_requested

@export var run_profile: RunProfile
@export var tuning: RunDirectorTuning
@export var swarm_spawner_path: NodePath
@export var fast_spawner_path: NodePath
@export var tank_spawner_path: NodePath

var _swarm_spawner: EnemySpawner
var _fast_spawner: EnemySpawner
var _tank_spawner: EnemySpawner
var _next_phase_index := 0
var _started := false


func _ready() -> void:
	_swarm_spawner = get_node_or_null(swarm_spawner_path) as EnemySpawner
	_fast_spawner = get_node_or_null(fast_spawner_path) as EnemySpawner
	_tank_spawner = get_node_or_null(tank_spawner_path) as EnemySpawner


func start(target: Node2D, target_health: HealthComponent, contact_radius: float = 16.0) -> bool:
	if run_profile == null or tuning == null or _swarm_spawner == null or _fast_spawner == null or _tank_spawner == null:
		push_error("RunDirector requires profile, tuning, and three configured EnemySpawners.")
		return false
	_next_phase_index = 0
	_started = true
	for spawner in [_swarm_spawner, _fast_spawner, _tank_spawner]:
		spawner.set_target(target, target_health, contact_radius)
		spawner.start_spawning()
	_set_intensities(tuning.baseline_swarm_intensity, tuning.baseline_fast_intensity, tuning.baseline_tank_intensity)
	return true


func stop() -> void:
	_started = false
	for spawner in [_swarm_spawner, _fast_spawner, _tank_spawner]:
		if spawner != null:
			spawner.stop_spawning()


func _process(_delta: float) -> void:
	if not _started or RunController.state != RunController.RunState.RUNNING or run_profile == null:
		return
	while _next_phase_index < run_profile.scheduled_phases.size():
		var phase := run_profile.scheduled_phases[_next_phase_index]
		if phase == null or RunController.elapsed_seconds < phase.at_seconds:
			break
		_next_phase_index += 1
		_apply_phase(phase)


func _apply_phase(phase: RunPhaseDefinition) -> void:
	match phase.event_id:
		&"swarm_surge":
			_set_intensities(tuning.swarm_surge_swarm_intensity, 0.0, 0.0)
		&"fast_surge":
			_set_intensities(tuning.fast_surge_swarm_intensity, tuning.fast_surge_fast_intensity, 0.0)
		&"tank_surge":
			_set_intensities(tuning.tank_surge_swarm_intensity, tuning.tank_surge_fast_intensity, tuning.tank_surge_tank_intensity)
		&"combined_surge", &"boss_arrival":
			_set_intensities(tuning.combined_swarm_intensity, tuning.combined_fast_intensity, tuning.combined_tank_intensity)
	if phase.event_id == &"boss_arrival":
		boss_arrival_requested.emit()
	GameplayEvents.publish_run_event(phase.event_id, {"at_seconds": phase.at_seconds, "composition_tags": phase.composition_tags})
	phase_started.emit(phase)


func _set_intensities(swarm: float, fast: float, tank: float) -> void:
	_swarm_spawner.set_spawn_intensity(swarm)
	_fast_spawner.set_spawn_intensity(fast)
	_tank_spawner.set_spawn_intensity(tank)
