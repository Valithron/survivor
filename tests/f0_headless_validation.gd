extends SceneTree

const STERLING: CharacterDefinition = preload("res://data/characters/sterling.tres")
const SWARM_ZOMBIE: EnemyDefinition = preload("res://data/enemies/swarm_zombie.tres")
const KATANA: WeaponDefinition = preload("res://data/weapons/katana.tres")
const MOLOTOV: WeaponDefinition = preload("res://data/weapons/molotov.tres")
const PROTOTYPE_PROFILE: RunProfile = preload("res://data/run_profiles/prototype_5_min.tres")
const RUN_CONTROLLER_SCRIPT: Script = preload("res://game/run/run_controller.gd")
const REQUIRED_INPUTS: PackedStringArray = [
	"move_up", "move_down", "move_left", "move_right", "tactical", "ultimate", "toggle_aim_mode", "pause",
	"dev_award_xp", "dev_spawn_swarm", "dev_jump_timer",
]


func _init() -> void:
	call_deferred("_run_validation")


func _run_validation() -> void:
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
	if not is_equal_approx(health.apply_damage(DamageEvent.new(self, 3.0, &"f0_validation")), 3.0):
		errors.append("DamageEvent was not accepted by HealthComponent.")
	if not is_equal_approx(health.current_health, 7.0):
		errors.append("HealthComponent current health is not 7 after 3 damage.")
	health.free()
	if AnimationConvention.direction_id(Vector2.UP) != &"n" or AnimationConvention.direction_id(Vector2.RIGHT) != &"e":
		errors.append("AnimationConvention does not return canonical directions.")

	var lifecycle: Node = RUN_CONTROLLER_SCRIPT.new()
	root.add_child(lifecycle)
	if not lifecycle.begin_run(STERLING, PROTOTYPE_PROFILE):
		errors.append("RunController could not begin a run.")
	elif not lifecycle.pause_for_upgrade():
		errors.append("RunController could not enter full upgrade pause.")
	elif not lifecycle.resume_after_upgrade():
		errors.append("RunController could not resume after upgrade pause.")
	lifecycle.end_run(&"validation")
	lifecycle.queue_free()

	if errors.is_empty():
		print("F0 CONTRACT TEST: PASS")
		quit(0)
	else:
		for error_text in errors:
			printerr("F0 CONTRACT TEST: " + error_text)
		quit(1)
