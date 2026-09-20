extends CanvasLayer

enum _Origin { PAUSE_MENU, EXTERNAL }

const EXCLUDED_SCENES := [
	"res://menu/main_menu.tscn",
]

const PAUSE_MENU_SCENE := preload("res://components/pause_menu.tscn")
const STATUS_MENU_SCENE := preload("res://components/status_menu.tscn")
const SAVE_SLOT_MENU_SCENE := preload("res://components/save_slot_menu.tscn")

var _pause_menu: PauseMenu
var _status_menu: StatusMenu
var _save_slot_menu: SaveSlotMenu
var _slot_menu_origin: int = _Origin.EXTERNAL
var _slot_menu_is_save := true
var _pending_screenshot: Image = null

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	_status_menu = STATUS_MENU_SCENE.instantiate()
	_save_slot_menu = SAVE_SLOT_MENU_SCENE.instantiate()
	_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_status_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	_save_slot_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_menu)
	add_child(_status_menu)
	add_child(_save_slot_menu)
	_pause_menu.resume_requested.connect(_close_pause)
	_pause_menu.save_requested.connect(_on_save_requested)
	_pause_menu.load_requested.connect(_on_load_requested)
	_pause_menu.exit_requested.connect(_on_exit_requested)
	_status_menu.closed.connect(_close_status)
	_save_slot_menu.slot_selected.connect(_on_slot_selected)
	_save_slot_menu.cancelled.connect(_on_slot_menu_cancelled)

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var keycode: Key = (event as InputEventKey).keycode
	if keycode == KEY_ESCAPE:
		_toggle_pause()
	elif keycode == KEY_TAB:
		_toggle_status()

func _is_excluded() -> bool:
	var current := get_tree().current_scene
	return current == null or current.scene_file_path in EXCLUDED_SCENES

func _can_save_now() -> bool:
	return not (get_tree().current_scene is BaseEncounter)

func _resync_current_scene() -> void:
	var current := get_tree().current_scene
	if current and current.has_method("resync_rhythm"):
		current.resync_rhythm()

func _toggle_pause() -> void:
	if _status_menu.active or _save_slot_menu.active:
		return
	if _pause_menu.active:
		_close_pause()
		get_viewport().set_input_as_handled()
	elif not _is_excluded():
		_pending_screenshot = get_viewport().get_texture().get_image()
		_pause_menu.open(_can_save_now())
		get_tree().paused = true
		MusicPlayer.set_ducked(true)
		get_viewport().set_input_as_handled()

func _close_pause() -> void:
	_pause_menu.close()
	get_tree().paused = false
	MusicPlayer.set_ducked(false)
	_resync_current_scene()

func _toggle_status() -> void:
	if _pause_menu.active or _save_slot_menu.active:
		return
	if _status_menu.active:
		_close_status()
		get_viewport().set_input_as_handled()
	elif not _is_excluded():
		_status_menu.open()
		get_tree().paused = true
		MusicPlayer.set_ducked(true)
		get_viewport().set_input_as_handled()

func _close_status() -> void:
	_status_menu.close()
	get_tree().paused = false
	MusicPlayer.set_ducked(false)
	_resync_current_scene()

func _on_save_requested() -> void:
	_pause_menu.close()
	_slot_menu_origin = _Origin.PAUSE_MENU
	_slot_menu_is_save = true
	_save_slot_menu.open(true)

func _on_load_requested() -> void:
	_pause_menu.close()
	_slot_menu_origin = _Origin.PAUSE_MENU
	_slot_menu_is_save = false
	_save_slot_menu.open(false)

func _on_exit_requested() -> void:
	_close_pause()
	get_tree().change_scene_to_file("res://menu/main_menu.tscn")

func open_load_menu() -> void:
	_slot_menu_origin = _Origin.EXTERNAL
	_slot_menu_is_save = false
	get_tree().paused = true
	MusicPlayer.set_ducked(true)
	_save_slot_menu.open(false)

func _on_slot_menu_cancelled() -> void:
	_save_slot_menu.close()
	if _slot_menu_origin == _Origin.PAUSE_MENU:
		_pause_menu.open(_can_save_now())
	else:
		get_tree().paused = false
		MusicPlayer.set_ducked(false)
		_resync_current_scene()

func _on_slot_selected(index: int) -> void:
	_save_slot_menu.close()
	get_tree().paused = false
	MusicPlayer.set_ducked(false)
	if _slot_menu_is_save:
		SaveSystem.save_manual_slot(index, _pending_screenshot)
	else:
		SaveSystem.load_manual_slot(index)
