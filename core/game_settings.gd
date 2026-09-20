extends Node

const SETTINGS_PATH := "user://settings.cfg"
const MASTER_BUS := "Master"
const BASE_WINDOW_SIZE := Vector2i(640, 480)

var subwoofer_defeated := false
var cyclops_defeated := false
var carrotina_defeated := false
var door_opened := false
var aphrodite_greeting_done := false
var goddess_room_door_unlocked := false
var goddess_room_door_closed := false
var mushroom_girl_cleared := false
var strawberry_girl_cleared := false
var ivy_cleared := false
var mushroom_item_collected := false
var strawberry_item_collected := false
var forest_dog_passed := false
var dj_defeated := false
var master_volume := 1.0
var fullscreen := false
var window_scale := 1

func _ready() -> void:
	_load()
	_apply_volume()
	_apply_display()

func reset_progress_for_new_game() -> void:
	subwoofer_defeated = false
	cyclops_defeated = false
	carrotina_defeated = false
	door_opened = false
	aphrodite_greeting_done = false
	goddess_room_door_unlocked = false
	goddess_room_door_closed = false
	mushroom_girl_cleared = false
	strawberry_girl_cleared = false
	ivy_cleared = false
	mushroom_item_collected = false
	strawberry_item_collected = false
	forest_dog_passed = false
	dj_defeated = false
	_save()

func mark_subwoofer_defeated() -> void:
	if subwoofer_defeated:
		return
	subwoofer_defeated = true
	_save()

func mark_cyclops_defeated() -> void:
	if cyclops_defeated:
		return
	cyclops_defeated = true
	_save()

func mark_carrotina_defeated() -> void:
	if carrotina_defeated:
		return
	carrotina_defeated = true
	_save()

func mark_door_opened() -> void:
	if door_opened:
		return
	door_opened = true
	_save()

func mark_aphrodite_greeting_done() -> void:
	if aphrodite_greeting_done:
		return
	aphrodite_greeting_done = true
	_save()

func mark_goddess_room_door_unlocked() -> void:
	if goddess_room_door_unlocked:
		return
	goddess_room_door_unlocked = true
	_save()

func mark_goddess_room_door_closed() -> void:
	if goddess_room_door_closed:
		return
	goddess_room_door_closed = true
	_save()

func mark_mushroom_girl_cleared() -> void:
	if mushroom_girl_cleared:
		return
	mushroom_girl_cleared = true
	_save()

func mark_strawberry_girl_cleared() -> void:
	if strawberry_girl_cleared:
		return
	strawberry_girl_cleared = true
	_save()

func mark_ivy_cleared() -> void:
	if ivy_cleared:
		return
	ivy_cleared = true
	_save()

func mark_mushroom_item_collected() -> void:
	if mushroom_item_collected:
		return
	mushroom_item_collected = true
	_save()

func mark_strawberry_item_collected() -> void:
	if strawberry_item_collected:
		return
	strawberry_item_collected = true
	_save()

func mark_forest_dog_passed() -> void:
	if forest_dog_passed:
		return
	forest_dog_passed = true
	_save()

func mark_dj_defeated() -> void:
	if dj_defeated:
		return
	dj_defeated = true
	_save()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	_save()

func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_display()
	_save()

func set_window_scale(value: int) -> void:
	window_scale = clampi(value, 1, 4)
	_apply_display()
	_save()

func _apply_volume() -> void:
	var bus_index := AudioServer.get_bus_index(MASTER_BUS)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(master_volume, 0.0001)))

func _apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(BASE_WINDOW_SIZE * window_scale)

func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "window_scale", window_scale)
	config.set_value("progress", "subwoofer_defeated", subwoofer_defeated)
	config.set_value("progress", "cyclops_defeated", cyclops_defeated)
	config.set_value("progress", "carrotina_defeated", carrotina_defeated)
	config.set_value("progress", "door_opened", door_opened)
	config.set_value("progress", "aphrodite_greeting_done", aphrodite_greeting_done)
	config.set_value("progress", "goddess_room_door_unlocked", goddess_room_door_unlocked)
	config.set_value("progress", "goddess_room_door_closed", goddess_room_door_closed)
	config.set_value("progress", "mushroom_girl_cleared", mushroom_girl_cleared)
	config.set_value("progress", "strawberry_girl_cleared", strawberry_girl_cleared)
	config.set_value("progress", "ivy_cleared", ivy_cleared)
	config.set_value("progress", "mushroom_item_collected", mushroom_item_collected)
	config.set_value("progress", "strawberry_item_collected", strawberry_item_collected)
	config.set_value("progress", "forest_dog_passed", forest_dog_passed)
	config.set_value("progress", "dj_defeated", dj_defeated)
	config.save(SETTINGS_PATH)

func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = config.get_value("audio", "master_volume", 1.0)
	fullscreen = config.get_value("display", "fullscreen", false)
	window_scale = config.get_value("display", "window_scale", 1)
	subwoofer_defeated = config.get_value("progress", "subwoofer_defeated", false)
	cyclops_defeated = config.get_value("progress", "cyclops_defeated", false)
	carrotina_defeated = config.get_value("progress", "carrotina_defeated", false)
	door_opened = config.get_value("progress", "door_opened", false)
	aphrodite_greeting_done = config.get_value("progress", "aphrodite_greeting_done", false)
	goddess_room_door_unlocked = config.get_value("progress", "goddess_room_door_unlocked", false)
	goddess_room_door_closed = config.get_value("progress", "goddess_room_door_closed", false)
	mushroom_girl_cleared = config.get_value("progress", "mushroom_girl_cleared", false)
	strawberry_girl_cleared = config.get_value("progress", "strawberry_girl_cleared", false)
	ivy_cleared = config.get_value("progress", "ivy_cleared", false)
	mushroom_item_collected = config.get_value("progress", "mushroom_item_collected", false)
	strawberry_item_collected = config.get_value("progress", "strawberry_item_collected", false)
	forest_dog_passed = config.get_value("progress", "forest_dog_passed", false)
	dj_defeated = config.get_value("progress", "dj_defeated", false)
