class_name FirstPlayableShell
extends Control

## Entry shell. Sterling remains the only runnable character until the
## corresponding Vertical Slice kits are integrated, while META-1 exposes the
## real persistent unlock state instead of implying future progress.
const PLAYTEST_SCENE: PackedScene = preload("res://tests/prototype_playtest.tscn")

@onready var title_panel: Control = $TitlePanel
@onready var character_select: Control = $CharacterSelect
@onready var start_button: Button = $TitlePanel/StartButton
@onready var sterling_button: Button = $CharacterSelect/SterlingButton
@onready var back_button: Button = $CharacterSelect/BackButton
@onready var unlock_status: Label = $CharacterSelect/UnlockStatus


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_button.pressed.connect(show_character_select)
	sterling_button.pressed.connect(start_sterling_run)
	back_button.pressed.connect(show_title)
	MetaProgression.profile_changed.connect(_on_profile_changed)
	show_title()
	start_button.grab_focus()
	_refresh_unlock_status()


func _exit_tree() -> void:
	if MetaProgression.profile_changed.is_connected(_on_profile_changed):
		MetaProgression.profile_changed.disconnect(_on_profile_changed)


func show_title() -> void:
	title_panel.visible = true
	character_select.visible = false


func show_character_select() -> void:
	title_panel.visible = false
	character_select.visible = true
	sterling_button.grab_focus()


func start_sterling_run() -> void:
	get_tree().change_scene_to_packed(PLAYTEST_SCENE)


func _on_profile_changed(_completed_natural_runs: int, _newly_unlocked_character_ids: PackedStringArray) -> void:
	_refresh_unlock_status()


func _refresh_unlock_status() -> void:
	var completed_runs := MetaProgression.completed_natural_runs
	unlock_status.text = "STERLING // AVAILABLE\n"
	unlock_status.text += _unlock_status_line(&"ryan", "RYAN", 1, completed_runs)
	unlock_status.text += "\n"
	unlock_status.text += _unlock_status_line(&"cooper", "COOPER", 3, completed_runs)


func _unlock_status_line(character_id: StringName, display_name: String, required_runs: int, completed_runs: int) -> String:
	if MetaProgression.is_character_unlocked(character_id):
		return "%s // UNLOCKED - character kit in production" % display_name
	return "%s // LOCKED - %d natural run%s remaining" % [
		display_name,
		maxi(required_runs - completed_runs, 0),
		"" if required_runs - completed_runs == 1 else "s",
	]
