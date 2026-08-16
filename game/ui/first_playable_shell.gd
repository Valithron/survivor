class_name FirstPlayableShell
extends Control

## U1 entry shell. The First Playable intentionally offers Sterling only;
## character unlock persistence belongs to the later documented progression
## milestone and is not implied here.
const PLAYTEST_SCENE: PackedScene = preload("res://tests/prototype_playtest.tscn")

@onready var title_panel: Control = $TitlePanel
@onready var character_select: Control = $CharacterSelect
@onready var start_button: Button = $TitlePanel/StartButton
@onready var sterling_button: Button = $CharacterSelect/SterlingButton
@onready var back_button: Button = $CharacterSelect/BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	start_button.pressed.connect(show_character_select)
	sterling_button.pressed.connect(start_sterling_run)
	back_button.pressed.connect(show_title)
	show_title()
	start_button.grab_focus()


func show_title() -> void:
	title_panel.visible = true
	character_select.visible = false


func show_character_select() -> void:
	title_panel.visible = false
	character_select.visible = true
	sterling_button.grab_focus()


func start_sterling_run() -> void:
	get_tree().change_scene_to_packed(PLAYTEST_SCENE)
