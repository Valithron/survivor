extends Node2D

const STERLING: CharacterDefinition = preload("res://data/characters/sterling.tres")
const PROTOTYPE_PROFILE: RunProfile = preload("res://data/run_profiles/prototype_5_min.tres")
const PROGRESSION: ProgressionDefinition = preload("res://data/progression/prototype_progression.tres")
const KATANA: WeaponDefinition = preload("res://data/weapons/katana.tres")
const MOLOTOV: WeaponDefinition = preload("res://data/weapons/molotov.tres")

@onready var world: Node2D = $World
@onready var player_anchor: Node2D = $World/PlayerAnchor
@onready var inventory: WeaponInventory = $WeaponInventory
@onready var progression: ProgressionController = $ProgressionController
@onready var state_label: Label = $CanvasLayer/Panel/State
@onready var event_label: Label = $CanvasLayer/Panel/Event
@onready var choice_buttons: Array[Button] = [
	$CanvasLayer/Panel/Choices/Choice0,
	$CanvasLayer/Panel/Choices/Choice1,
	$CanvasLayer/Panel/Choices/Choice2,
]

var last_event := "Waiting for a dev XP award."


func _ready() -> void:
	## This test presentation must remain interactive while RunController pauses
	## the gameplay tree for a level-up choice.
	process_mode = Node.PROCESS_MODE_ALWAYS
	inventory.configure_runtime(player_anchor, world)
	progression.configure(PROGRESSION, [KATANA, MOLOTOV], inventory)
	progression.set_pickup_target(player_anchor, world)
	progression.set_choice_seed(13)
	progression.upgrade_choices_ready.connect(_on_upgrade_choices_ready)
	progression.upgrade_selected.connect(_on_upgrade_selected)
	RunController.run_state_changed.connect(_on_run_state_changed)
	for index in range(choice_buttons.size()):
		choice_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	RunController.begin_run(STERLING, PROTOTYPE_PROFILE)
	_refresh_presentation()
	queue_redraw()


func _exit_tree() -> void:
	if RunController.state != RunController.RunState.IDLE:
		RunController.reset_to_idle()


func _process(_delta: float) -> void:
	_refresh_presentation()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dev_award_xp") and RunController.state == RunController.RunState.RUNNING:
		var spawn_position := player_anchor.global_position + Vector2(180.0, 0.0)
		GameplayEvents.award_xp(XpAward.new(self, 15, spawn_position))
		last_event = "Spawned a 15 XP temporary pickup. It attracts to the player marker."
		get_viewport().set_input_as_handled()


func _draw() -> void:
	draw_circle(player_anchor.position, 22.0, Color("6ea8ff"))
	draw_circle(player_anchor.position, 8.0, Color("e9f3ff"))
	draw_arc(player_anchor.position, PROGRESSION.xp_attraction_radius, 0.0, TAU, 48, Color(0.25, 0.74, 0.55, 0.25), 1.0, true)


func _on_upgrade_choices_ready(_level: int, _choices: Array[WeaponUpgradeChoice]) -> void:
	last_event = "Gameplay paused: choose one of the server-validated weapon cards."


func _on_upgrade_selected(choice: WeaponUpgradeChoice) -> void:
	last_event = "%s selected; gameplay resumed." % choice.display_label()


func _on_run_state_changed(_previous: RunController.RunState, _current: RunController.RunState) -> void:
	_refresh_presentation()


func _on_choice_pressed(index: int) -> void:
	if progression.select_upgrade(index):
		last_event = "Applied selected card."
	else:
		last_event = "No selectable upgrade at that button."


func _refresh_presentation() -> void:
	var next_threshold := PROGRESSION.total_xp_required_for_level(progression.current_level + 1)
	state_label.text = "X1 DEV TEST // XP + WEAPON PROGRESSION\n\nRun state: %s\nLevel: %d\nXP: %d / %d\nActive XP pickups: %d\nLoadout: %s\n\n%s" % [
		_run_state_name(), progression.current_level, progression.total_xp, next_threshold,
		progression.active_pickup_count(), _loadout_text(), last_event,
	]
	var choices := progression.get_current_choices()
	for index in range(choice_buttons.size()):
		var button := choice_buttons[index]
		if index < choices.size():
			button.text = choices[index].display_label()
			button.disabled = false
		else:
			button.text = "No upgrade available"
			button.disabled = true


func _loadout_text() -> String:
	var labels: Array[String] = []
	for entry in inventory.get_entries():
		labels.append("%s R%d" % [entry.definition.display_name, entry.current_rank])
	return ", ".join(labels) if not labels.is_empty() else "(empty)"


func _run_state_name() -> String:
	match RunController.state:
		RunController.RunState.IDLE:
			return "IDLE"
		RunController.RunState.RUNNING:
			return "RUNNING"
		RunController.RunState.USER_PAUSED:
			return "USER PAUSED"
		RunController.RunState.UPGRADE_PAUSED:
			return "UPGRADE PAUSED"
		RunController.RunState.ENDED:
			return "ENDED"
	return "UNKNOWN"
