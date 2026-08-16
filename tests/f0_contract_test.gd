extends Node2D

const STERLING: CharacterDefinition = preload("res://data/characters/sterling.tres")
const SWARM_ZOMBIE: EnemyDefinition = preload("res://data/enemies/swarm_zombie.tres")
const KATANA: WeaponDefinition = preload("res://data/weapons/katana.tres")
const MOLOTOV: WeaponDefinition = preload("res://data/weapons/molotov.tres")
const PROTOTYPE_PROFILE: RunProfile = preload("res://data/run_profiles/prototype_5_min.tres")

const REQUIRED_INPUTS: PackedStringArray = [
	"move_up", "move_down", "move_left", "move_right", "tactical", "ultimate", "toggle_aim_mode", "pause",
	"dev_award_xp", "dev_spawn_swarm", "dev_jump_timer",
]

@onready var state_label: Label = $CanvasLayer/Panel/State
@onready var event_label: Label = $CanvasLayer/Panel/Event
@onready var validation_label: Label = $CanvasLayer/Panel/Validation

var manual_aim_enabled := false
var last_event := "Waiting for input."
var xp_award_count := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameplayEvents.xp_awarded.connect(_on_xp_awarded)
	DevTools.xp_award_requested.connect(_on_xp_award_requested)
	DevTools.enemy_spawn_requested.connect(_on_enemy_spawn_requested)
	DevTools.timer_jump_requested.connect(_on_timer_jump_requested)

	var errors := _validate_foundation_contracts()
	if errors.is_empty():
		validation_label.text = "CONTRACT CHECK: PASS\nAll F0 Resource, Input Map, and health/damage checks passed."
	else:
		validation_label.text = "CONTRACT CHECK: FAIL\n" + "\n".join(errors)
		for error_text in errors:
			push_error(error_text)

	RunController.begin_run(STERLING, PROTOTYPE_PROFILE)
	queue_redraw()


func _exit_tree() -> void:
	if RunController.state != RunController.RunState.IDLE:
		RunController.reset_to_idle()


func _process(_delta: float) -> void:
	var aim_mode := "Manual Aim" if manual_aim_enabled else "Auto Aim"
	state_label.text = "F0 RUNTIME TEST\n\nState: %s\nTimer: %s / %s\nCharacter: %s\nAim contract: %s\nXP events observed: %d" % [
		_state_name(), _format_seconds(RunController.elapsed_seconds), _format_seconds(PROTOTYPE_PROFILE.survival_duration_seconds),
		STERLING.display_name, aim_mode, xp_award_count,
	]
	event_label.text = "LAST EVENT\n%s\n\nControls\nWASD: mapped movement concepts\nT: toggle basic aim mode contract\nEsc: lifecycle pause/resume\n1: dev XP award event\n2: dev swarm-spawn hook\n3: dev timer-jump hook" % last_event
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_aim_mode"):
		manual_aim_enabled = not manual_aim_enabled
		last_event = "Aim contract toggled to %s." % ("Manual Aim" if manual_aim_enabled else "Auto Aim")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"pause"):
		if RunController.toggle_user_pause():
			last_event = "Lifecycle pause toggled."
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_award_xp"):
		DevTools.request_xp_award(5)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_spawn_swarm"):
		DevTools.request_enemy_spawn(&"swarm_zombie", 12)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"dev_jump_timer"):
		DevTools.request_timer_jump(150.0)
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var indicator_color := Color("78d9ff") if RunController.state == RunController.RunState.RUNNING else Color("ffc857")
	draw_circle(Vector2(1020, 270), 70.0, Color("17213a"))
	draw_arc(Vector2(1020, 270), 70.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(RunController.elapsed_seconds / PROTOTYPE_PROFILE.survival_duration_seconds, 0.0, 1.0), 48, indicator_color, 8.0, true)
	draw_circle(Vector2(1020, 270), 6.0, indicator_color)


func _validate_foundation_contracts() -> Array[String]:
	var errors: Array[String] = []
	for input_action in REQUIRED_INPUTS:
		if not InputMap.has_action(input_action):
			errors.append("Missing Input Map action: %s" % input_action)
	errors.append_array(STERLING.validate_contract())
	errors.append_array(SWARM_ZOMBIE.validate_contract())
	errors.append_array(KATANA.validate_contract())
	errors.append_array(MOLOTOV.validate_contract())
	errors.append_array(PROTOTYPE_PROFILE.validate_contract())

	var health := HealthComponent.new()
	health.configure(10.0)
	var applied_damage := health.apply_damage(DamageEvent.new(self, 3.0, &"f0_contract_test"))
	if not is_equal_approx(applied_damage, 3.0) or not is_equal_approx(health.current_health, 7.0):
		errors.append("HealthComponent did not apply the shared DamageEvent correctly.")
	health.free()
	return errors


func _on_xp_award_requested(amount: int) -> void:
	GameplayEvents.award_xp(XpAward.new(self, amount, Vector2.ZERO))


func _on_enemy_spawn_requested(enemy_id: StringName, count: int) -> void:
	last_event = "Dev hook requested %d %s entities. No spawner exists in F0." % [count, enemy_id]


func _on_timer_jump_requested(target_seconds: float) -> void:
	RunController.set_elapsed_seconds(target_seconds)
	last_event = "Dev hook set the lifecycle timer to %s." % _format_seconds(target_seconds)


func _on_xp_awarded(award: XpAward) -> void:
	xp_award_count += 1
	last_event = "XP award event received: %d XP at %s." % [award.amount, award.world_position]


func _state_name() -> String:
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


func _format_seconds(total_seconds: float) -> String:
	var whole_seconds := int(floor(total_seconds))
	return "%02d:%02d" % [whole_seconds / 60, whole_seconds % 60]
