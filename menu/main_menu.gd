extends Node2D

const PLAY_SCENE := "res://origin_room/origin_room.tscn"
const FOCUSED_TINT := Color(1.3, 1.3, 1.0)
const NORMAL_TINT := Color(1, 1, 1)
const DISABLED_TINT := Color(0.55, 0.55, 0.55, 0.7)

@onready var settings_button: TextureButton = %SettingsButton
@onready var continue_button: TextureButton = %ContinueButton
@onready var new_game_button: TextureButton = %NewGameButton
@onready var exit_button: TextureButton = %ExitButton
@onready var settings_panel: SettingsPanel = %SettingsPanel

func _ready() -> void:
	var has_save := SaveSystem.has_save()
	_setup_focus_tint(settings_button, NORMAL_TINT)
	_setup_focus_tint(continue_button, NORMAL_TINT if has_save else DISABLED_TINT)
	_setup_focus_tint(new_game_button, NORMAL_TINT)
	_setup_focus_tint(exit_button, NORMAL_TINT)

	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	settings_panel.closed.connect(_on_settings_closed)

	if has_save:
		continue_button.grab_focus()
	else:
		continue_button.disabled = true
		continue_button.focus_mode = Control.FOCUS_NONE
		settings_button.focus_neighbor_bottom = settings_button.get_path_to(new_game_button)
		settings_button.focus_next = settings_button.get_path_to(new_game_button)
		new_game_button.focus_neighbor_top = new_game_button.get_path_to(settings_button)
		new_game_button.focus_previous = new_game_button.get_path_to(settings_button)
		new_game_button.grab_focus()

func _setup_focus_tint(button: TextureButton, normal: Color) -> void:
	button.modulate = normal
	button.focus_entered.connect(func() -> void: button.modulate = FOCUSED_TINT)
	button.focus_exited.connect(func() -> void: button.modulate = normal)

func _on_continue_pressed() -> void:
	SaveSystem.load_most_recent()

func _on_new_game_pressed() -> void:
	Inventory.reset_to_starting_kit()
	Relationships.clear()
	GameSettings.reset_progress_for_new_game()
	MusicPlayer.stop(0.3)
	get_tree().change_scene_to_file(PLAY_SCENE)

func _on_settings_pressed() -> void:
	settings_button.release_focus()
	settings_panel.open()

func _on_settings_closed() -> void:
	settings_button.grab_focus()

func _on_exit_pressed() -> void:
	get_tree().quit()
