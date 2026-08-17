class_name FirstPlayableShell
extends Control

## Entry shell. Roster selection is data-backed; a character only becomes
## launchable when both its real persistent unlock and final sprite scene are
## present. Combat-complete but art-pending roster entries stay explicit.
const PLAYTEST_SCENE: PackedScene = preload("res://tests/prototype_playtest.tscn")

@onready var title_panel: Control = $TitlePanel
@onready var character_select: Control = $CharacterSelect
@onready var start_button: Button = $TitlePanel/StartButton
@onready var sterling_button: Button = $CharacterSelect/SterlingButton
@onready var ryan_button: Button = $CharacterSelect/RyanButton
@onready var cooper_button: Button = $CharacterSelect/CooperButton
@onready var back_button: Button = $CharacterSelect/BackButton
@onready var unlock_status: Label = $CharacterSelect/UnlockStatus


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_button.pressed.connect(show_character_select)
	sterling_button.pressed.connect(start_sterling_run)
	ryan_button.pressed.connect(start_character_run.bind(&"ryan"))
	cooper_button.pressed.connect(start_character_run.bind(&"cooper"))
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
	start_character_run(&"sterling")


func start_character_run(character_id: StringName) -> void:
	if not _can_start_character(character_id):
		return
	if CharacterSelection.select_character(character_id):
		get_tree().change_scene_to_packed(PLAYTEST_SCENE)


func _on_profile_changed(_completed_natural_runs: int, _newly_unlocked_character_ids: PackedStringArray) -> void:
	_refresh_unlock_status()


func _refresh_unlock_status() -> void:
	var completed_runs := MetaProgression.completed_natural_runs
	sterling_button.disabled = not _can_start_character(&"sterling")
	ryan_button.disabled = not _can_start_character(&"ryan")
	cooper_button.disabled = not _can_start_character(&"cooper")
	unlock_status.text = _unlock_status_line(&"sterling", "STERLING", 0, completed_runs)
	unlock_status.text += "\n"
	unlock_status.text += _unlock_status_line(&"ryan", "RYAN", 1, completed_runs)
	unlock_status.text += "\n"
	unlock_status.text += _unlock_status_line(&"cooper", "COOPER", 3, completed_runs)


func _unlock_status_line(character_id: StringName, display_name: String, required_runs: int, completed_runs: int) -> String:
	var entry := CharacterSelection.ROSTER.get_entry(character_id)
	if MetaProgression.is_character_unlocked(character_id):
		if entry != null and entry.character != null and entry.character.sprite_scene != null:
			return "%s // UNLOCKED - READY" % display_name
		return "%s // UNLOCKED - COMBAT READY, FINAL ART PENDING" % display_name
	return "%s // LOCKED - %d natural run%s remaining" % [
		display_name,
		maxi(required_runs - completed_runs, 0),
		"" if required_runs - completed_runs == 1 else "s",
	]


func _can_start_character(character_id: StringName) -> bool:
	var entry := CharacterSelection.ROSTER.get_entry(character_id)
	return (
		MetaProgression.is_character_unlocked(character_id)
		and entry != null
		and entry.character != null
		and entry.character.sprite_scene != null
	)
