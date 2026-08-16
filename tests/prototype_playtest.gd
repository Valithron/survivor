class_name PrototypePlaytest
extends Node2D

signal run_finished(outcome: StringName, elapsed_seconds: float, level: int, total_xp: int)

## The approved Prototype combat scene now also serves as the focused P2
## Sterling-kit playtest. Full First Playable run content remains separate.
const STERLING: CharacterDefinition = preload("res://data/characters/sterling.tres")
const FIRST_PLAYABLE_PROFILE: RunProfile = preload("res://data/run_profiles/first_playable_12_min.tres")
const MUTANT_BOSS_SCENE: PackedScene = preload("res://game/boss/mutant_boss.tscn")
const PROGRESSION_DEFINITION: ProgressionDefinition = preload("res://data/progression/prototype_progression.tres")
const THROWING_KNIVES: WeaponDefinition = preload("res://data/weapons/throwing_knives.tres")
const KATANA: WeaponDefinition = preload("res://data/weapons/katana.tres")
const AUTO_TURRET: WeaponDefinition = preload("res://data/weapons/auto_turret.tres")
const MOLOTOV: WeaponDefinition = preload("res://data/weapons/molotov.tres")
const CHAIN_LIGHTNING: WeaponDefinition = preload("res://data/weapons/chain_lightning.tres")
const GRENADE_LAUNCHER: WeaponDefinition = preload("res://data/weapons/grenade_launcher.tres")

@onready var world: Node2D = $World
@onready var arena: ShoppingCenterArena = $World/Arena
@onready var player: SterlingPlayer = $World/SterlingPlayer
@onready var enemy_spawner: EnemySpawner = $World/EnemySpawner
@onready var fast_spawner: EnemySpawner = $World/FastSpawner
@onready var tank_spawner: EnemySpawner = $World/TankSpawner
@onready var run_director: RunDirector = $World/RunDirector
@onready var inventory: WeaponInventory = $World/WeaponInventory
@onready var progression: ProgressionController = $World/ProgressionController
@onready var core_hud: CoreHud = $CanvasLayer/CoreHud
@onready var outcome_label: Label = $CanvasLayer/Outcome
@onready var boss_bar: ColorRect = $CanvasLayer/BossBar
@onready var boss_bar_title: Label = $CanvasLayer/BossBar/Title
@onready var boss_bar_gauge: ProgressBar = $CanvasLayer/BossBar/Gauge
@onready var choice_panel: ColorRect = $CanvasLayer/UpgradeChoices
@onready var choice_title: Label = $CanvasLayer/UpgradeChoices/Title
@onready var choice_buttons: Array[Button] = [
	$CanvasLayer/UpgradeChoices/Choices/Choice0,
	$CanvasLayer/UpgradeChoices/Choices/Choice1,
	$CanvasLayer/UpgradeChoices/Choices/Choice2,
]
@onready var pause_panel: ColorRect = $CanvasLayer/PausePanel
@onready var outcome_actions: HBoxContainer = $CanvasLayer/OutcomeActions
@onready var resume_button: Button = $CanvasLayer/PausePanel/ResumeButton
@onready var pause_restart_button: Button = $CanvasLayer/PausePanel/RestartButton
@onready var pause_select_button: Button = $CanvasLayer/PausePanel/SelectButton
@onready var outcome_restart_button: Button = $CanvasLayer/OutcomeActions/RestartButton
@onready var outcome_select_button: Button = $CanvasLayer/OutcomeActions/SelectButton

var _last_event := "Combat online. Clear zombies, collect XP, and choose weapons."
var _xp_awards_seen := 0
var _run_outcome: StringName
var _active_boss: MutantBoss


func _ready() -> void:
	## This root and the choice UI must remain interactive during a full gameplay
	## pause; player, enemies, projectiles, and effects inherit the tree pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory.configure_runtime(player, world)
	progression.configure(PROGRESSION_DEFINITION, [THROWING_KNIVES, KATANA, AUTO_TURRET, MOLOTOV, CHAIN_LIGHTNING, GRENADE_LAUNCHER], inventory)
	progression.set_pickup_target(player, world)
	core_hud.configure(player, progression, inventory)
	progression.upgrade_choices_ready.connect(_on_upgrade_choices_ready)
	progression.upgrade_selected.connect(_on_upgrade_selected)
	progression.level_advanced_without_upgrade.connect(_on_level_advanced_without_upgrade)
	progression.level_changed.connect(player.set_character_level)
	player.died.connect(_on_player_died)
	player.tactical_activated.connect(_on_tactical_activated)
	player.ultimate_activated.connect(_on_ultimate_activated)
	player.ability_milestone_unlocked.connect(_on_ability_milestone_unlocked)
	RunController.run_time_elapsed.connect(_on_run_time_elapsed)
	RunController.run_state_changed.connect(_on_run_state_changed)
	DevTools.xp_award_requested.connect(_on_dev_xp_award_requested)
	DevTools.timer_jump_requested.connect(_on_dev_timer_jump_requested)
	for index in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	resume_button.pressed.connect(_resume_from_pause)
	pause_restart_button.pressed.connect(_restart_run)
	pause_select_button.pressed.connect(_return_to_selection)
	outcome_restart_button.pressed.connect(_restart_run)
	outcome_select_button.pressed.connect(_return_to_selection)

	arena.configure_pickups(player, player.health_component)
	arena.health_pickup_collected.connect(_on_health_pickup_collected)
	run_director.phase_started.connect(_on_run_phase_started)
	run_director.boss_arrival_requested.connect(_on_boss_arrival_requested)
	RunController.begin_run(STERLING, FIRST_PLAYABLE_PROFILE)
	run_director.start(player, player.health_component, 16.0)
	player.set_character_level(progression.current_level)
	choice_panel.visible = false
	pause_panel.visible = false
	outcome_label.visible = false
	outcome_actions.visible = false


func _exit_tree() -> void:
	if RunController.run_time_elapsed.is_connected(_on_run_time_elapsed):
		RunController.run_time_elapsed.disconnect(_on_run_time_elapsed)
	if RunController.run_state_changed.is_connected(_on_run_state_changed):
		RunController.run_state_changed.disconnect(_on_run_state_changed)
	if DevTools.xp_award_requested.is_connected(_on_dev_xp_award_requested):
		DevTools.xp_award_requested.disconnect(_on_dev_xp_award_requested)
	if DevTools.timer_jump_requested.is_connected(_on_dev_timer_jump_requested):
		DevTools.timer_jump_requested.disconnect(_on_dev_timer_jump_requested)
	if arena.health_pickup_collected.is_connected(_on_health_pickup_collected):
		arena.health_pickup_collected.disconnect(_on_health_pickup_collected)
	if run_director.phase_started.is_connected(_on_run_phase_started):
		run_director.phase_started.disconnect(_on_run_phase_started)
	if run_director.boss_arrival_requested.is_connected(_on_boss_arrival_requested):
		run_director.boss_arrival_requested.disconnect(_on_boss_arrival_requested)
	if RunController.state != RunController.RunState.IDLE:
		RunController.reset_to_idle()


func _process(_delta: float) -> void:
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and RunController.state != RunController.RunState.UPGRADE_PAUSED:
		if RunController.toggle_user_pause():
			_last_event = "Run %s." % ("paused" if RunController.state == RunController.RunState.USER_PAUSED else "resumed")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_award_xp"):
		DevTools.request_xp_award(15)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_spawn_swarm"):
		DevTools.request_enemy_spawn(&"swarm_zombie", 16)
		_last_event = "Developer spawn request: 16 swarm zombies."
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_jump_timer"):
		DevTools.request_timer_jump(minf(RunController.elapsed_seconds + 240.0, 720.0))
		get_viewport().set_input_as_handled()


func _on_upgrade_choices_ready(level: int, choices: Array[WeaponUpgradeChoice]) -> void:
	choice_panel.visible = true
	choice_title.text = "LEVEL %d // CHOOSE ONE" % level
	for index in range(choice_buttons.size()):
		var button := choice_buttons[index]
		if index < choices.size():
			button.text = choices[index].display_label()
			button.disabled = false
		else:
			button.text = "No legal upgrade"
			button.disabled = true
	_last_event = "Gameplay fully paused for three server-validated upgrade choices."


func _on_upgrade_selected(choice: WeaponUpgradeChoice) -> void:
	choice_panel.visible = false
	_last_event = "%s selected. Combat resumed." % choice.display_label()


func _on_level_advanced_without_upgrade(level: int) -> void:
	_last_event = "Level %d reached; all equipped weapons are Rank 5, so no illegal card was shown." % level


func _on_tactical_activated(_direction: Vector2, _start: Vector2, _end: Vector2, buff_seconds: float) -> void:
	_last_event = "Reposition Burst: dash complete; pistol cadence buffed for %.1fs." % buff_seconds


func _on_ultimate_activated(burst_count: int, projectiles_per_burst: int) -> void:
	_last_event = "Radial Bullet Storm: %d bursts of %d shots while movement stays active." % [burst_count, projectiles_per_burst]


func _on_ability_milestone_unlocked(ability_id: StringName, level: int) -> void:
	var readable_name := ability_id.replace("sterling_", "").replace("_", " ").capitalize()
	_last_event = "Level %d milestone: %s upgraded automatically." % [level, readable_name]


func _on_run_phase_started(phase: RunPhaseDefinition) -> void:
	_last_event = "Run surge: %s." % phase.event_id.replace("_", " ").capitalize()


func _on_boss_arrival_requested() -> void:
	if is_instance_valid(_active_boss) or _run_outcome != &"":
		return
	var boss_node := MUTANT_BOSS_SCENE.instantiate()
	if not (boss_node is MutantBoss):
		push_error("M1/B1 playtest expected mutant_boss.tscn to instantiate MutantBoss.")
		boss_node.queue_free()
		return
	_active_boss = boss_node as MutantBoss
	world.add_child(_active_boss)
	var arrival_offset := Vector2(-1.0, 0.28).normalized() * 510.0
	_active_boss.global_position = arena.clamp_to_playable_area(player.global_position + arrival_offset)
	_active_boss.set_target(player, player.health_component, 16.0)
	_active_boss.health_changed.connect(_on_boss_health_changed)
	_active_boss.defeated.connect(_on_boss_defeated)
	_active_boss.attack_telegraph_started.connect(_on_boss_telegraph_started)
	_active_boss.attack_resolved.connect(_on_boss_attack_resolved)
	boss_bar_title.text = _active_boss.definition.display_name.to_upper()
	boss_bar_gauge.max_value = _active_boss.health_component.maximum_health
	boss_bar_gauge.value = _active_boss.health_component.current_health
	boss_bar.visible = true
	arena.spawn_guaranteed_health_pickup_near(player)
	_last_event = "BOSS ARRIVAL // Late-game horde remains at full pressure. A medical beacon appeared nearby."


func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_bar_gauge.max_value = maximum
	boss_bar_gauge.value = current


func _on_boss_telegraph_started(attack_id: StringName) -> void:
	_last_event = "BOSS TELEGRAPH // %s" % attack_id.replace("_", " ").to_upper()


func _on_boss_attack_resolved(attack_id: StringName) -> void:
	_last_event = "BOSS ATTACK // %s resolved." % attack_id.replace("_", " ")


func _on_boss_defeated(_boss: MutantBoss, _event: DamageEvent) -> void:
	if _run_outcome == &"":
		_finish_run(&"victory", "MUTANT COLOSSUS DEFEATED // Victory.")


func _on_health_pickup_collected(_pickup: HealthPickup, healed_amount: float) -> void:
	_last_event = "Medical cache collected: restored %d health. This location will respawn." % roundi(healed_amount)


func _on_choice_pressed(index: int) -> void:
	if not progression.select_upgrade(index):
		_last_event = "That card is no longer legal; the run remains paused."


func _on_run_state_changed(_previous: RunController.RunState, current: RunController.RunState) -> void:
	pause_panel.visible = current == RunController.RunState.USER_PAUSED


func _resume_from_pause() -> void:
	if RunController.state == RunController.RunState.USER_PAUSED:
		RunController.toggle_user_pause()


func _restart_run() -> void:
	get_tree().reload_current_scene()


func _return_to_selection() -> void:
	get_tree().change_scene_to_file("res://game/ui/first_playable_shell.tscn")


func _on_player_died(_event: DamageEvent) -> void:
	if _run_outcome.is_empty():
		_finish_run(&"death", "STERLING DOWN // First Playable run ended.")


func _on_run_time_elapsed(_profile: RunProfile) -> void:
	if _run_outcome.is_empty():
		_finish_run(&"timed_session_complete", "TIME // Timed session complete.")


func _on_dev_xp_award_requested(amount: int) -> void:
	if RunController.state == RunController.RunState.ENDED:
		return
	GameplayEvents.award_xp(XpAward.new(self, amount, player.global_position + Vector2(110.0, 0.0)))
	_last_event = "Developer XP award spawned as a collectable pickup."


func _on_dev_timer_jump_requested(target_seconds: float) -> void:
	RunController.set_elapsed_seconds(target_seconds)
	_last_event = "Developer timer jump: %s." % _format_time(target_seconds)


func _finish_run(outcome: StringName, message: String) -> void:
	_run_outcome = outcome
	run_director.stop()
	RunController.end_run(outcome)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	choice_panel.visible = false
	boss_bar.visible = false
	pause_panel.visible = false
	outcome_label.text = "%s\n\nTIME %s   LEVEL %d   XP %d\n\nChoose a run-flow action below." % [message, _format_time(RunController.elapsed_seconds), progression.current_level, progression.total_xp]
	outcome_label.visible = true
	outcome_actions.visible = true
	_last_event = message
	run_finished.emit(outcome, RunController.elapsed_seconds, progression.current_level, progression.total_xp)


func _refresh_hud() -> void:
	core_hud.set_message(_last_event)


func _horde_count() -> int:
	return enemy_spawner.get_active_enemy_count() + fast_spawner.get_active_enemy_count() + tank_spawner.get_active_enemy_count()


func _ability_status(cooldown_remaining: float, active: bool) -> String:
	if active:
		return "ACTIVE"
	if cooldown_remaining <= 0.0:
		return "READY"
	return "%.1fs" % cooldown_remaining


func _loadout_text() -> String:
	var labels: Array[String] = []
	for entry in inventory.get_entries():
		labels.append("%s R%d" % [entry.definition.display_name, entry.current_rank])
	return ", ".join(labels) if not labels.is_empty() else "(none)"


func _format_time(total_seconds: float) -> String:
	var whole_seconds := int(floor(total_seconds))
	return "%02d:%02d" % [whole_seconds / 60, whole_seconds % 60]
