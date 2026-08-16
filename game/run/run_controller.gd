extends Node

## Owns only one run's lifecycle. Combat, spawning, and UI stay outside this
## controller and communicate through their own contracts/events.
enum RunState {
	IDLE,
	RUNNING,
	USER_PAUSED,
	UPGRADE_PAUSED,
	ENDED,
}

signal run_started(character: CharacterDefinition, profile: RunProfile)
signal run_state_changed(previous_state: RunState, current_state: RunState)
signal elapsed_time_changed(elapsed_seconds: float)
signal run_time_elapsed(profile: RunProfile)
signal run_ended(outcome: StringName, elapsed_seconds: float)

var state: RunState = RunState.IDLE
var active_character: CharacterDefinition
var active_profile: RunProfile
var elapsed_seconds: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if state != RunState.RUNNING:
		return
	elapsed_seconds += delta
	elapsed_time_changed.emit(elapsed_seconds)
	if active_profile != null and active_profile.end_run_at_duration and elapsed_seconds >= active_profile.survival_duration_seconds:
		run_time_elapsed.emit(active_profile)


func begin_run(character: CharacterDefinition, profile: RunProfile) -> bool:
	if character == null or profile == null:
		push_error("RunController.begin_run requires a character and run profile.")
		return false
	active_character = character
	active_profile = profile
	elapsed_seconds = 0.0
	_set_tree_paused(false)
	_set_state(RunState.RUNNING)
	run_started.emit(active_character, active_profile)
	return true


func toggle_user_pause() -> bool:
	if state == RunState.RUNNING:
		_set_tree_paused(true)
		_set_state(RunState.USER_PAUSED)
		return true
	if state == RunState.USER_PAUSED:
		_set_tree_paused(false)
		_set_state(RunState.RUNNING)
		return true
	return false


func pause_for_upgrade() -> bool:
	if state != RunState.RUNNING:
		return false
	_set_tree_paused(true)
	_set_state(RunState.UPGRADE_PAUSED)
	return true


func resume_after_upgrade() -> bool:
	if state != RunState.UPGRADE_PAUSED:
		return false
	_set_tree_paused(false)
	_set_state(RunState.RUNNING)
	return true


func set_elapsed_seconds(value: float) -> void:
	elapsed_seconds = maxf(value, 0.0)
	elapsed_time_changed.emit(elapsed_seconds)


func end_run(outcome: StringName) -> void:
	if state == RunState.IDLE or state == RunState.ENDED:
		return
	_set_tree_paused(false)
	_set_state(RunState.ENDED)
	run_ended.emit(outcome, elapsed_seconds)


func reset_to_idle() -> void:
	_set_tree_paused(false)
	active_character = null
	active_profile = null
	elapsed_seconds = 0.0
	_set_state(RunState.IDLE)


func _set_state(next_state: RunState) -> void:
	var previous_state := state
	state = next_state
	if previous_state != state:
		run_state_changed.emit(previous_state, state)


func _set_tree_paused(should_pause: bool) -> void:
	if get_tree() != null:
		get_tree().paused = should_pause
