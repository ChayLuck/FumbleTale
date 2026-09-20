class_name SaveSlotMenu
extends Node2D

signal slot_selected(index: int)
signal cancelled

const COLS := 3
const ROWS := 2
const SLOT_COUNT := COLS * ROWS
const TILE_SIZE := Vector2(190, 175)
const THUMB_SIZE := Vector2(160, 120)
const GRID_ORIGIN := Vector2(25, 55)
const GRID_GAP := Vector2(10, 15)

var active := false
var _save_mode := true
var _index := 0
var _slots: Array[Dictionary] = []

func open(save_mode: bool) -> void:
	_save_mode = save_mode
	_index = 0
	_refresh_slots()
	if not _save_mode and not _slots[_index]["has_data"]:
		_jump_to_first_occupied()
	active = true
	visible = true
	queue_redraw()

func close() -> void:
	active = false
	visible = false

func _refresh_slots() -> void:
	_slots.clear()
	for i in SLOT_COUNT:
		_slots.append(SaveSystem.get_manual_slot_info(i))

func _jump_to_first_occupied() -> void:
	for i in SLOT_COUNT:
		if _slots[i]["has_data"]:
			_index = i
			return

func _is_enabled(idx: int) -> bool:
	return _save_mode or _slots[idx]["has_data"]

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancelled.emit()
		return
	var col: int = _index % COLS
	var row: int = _index / COLS
	if event.is_action_pressed("ui_left"):
		col = (col - 1 + COLS) % COLS
	elif event.is_action_pressed("ui_right"):
		col = (col + 1) % COLS
	elif event.is_action_pressed("ui_up"):
		row = (row - 1 + ROWS) % ROWS
	elif event.is_action_pressed("ui_down"):
		row = (row + 1) % ROWS
	elif event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _is_enabled(_index):
			slot_selected.emit(_index)
		return
	else:
		return
	get_viewport().set_input_as_handled()
	_index = row * COLS + col
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.9))
	var font := ThemeDB.fallback_font
	var title: String = "Select a slot to save into" if _save_mode else "Select a save to load"
	draw_string(font, Vector2(0, 30), title, HORIZONTAL_ALIGNMENT_CENTER, 640, 20, Color(1, 1, 1))
	for i in SLOT_COUNT:
		_draw_tile(font, i)

func _draw_tile(font: Font, i: int) -> void:
	var col: int = i % COLS
	var row: int = i / COLS
	var pos: Vector2 = GRID_ORIGIN + Vector2(col * (TILE_SIZE.x + GRID_GAP.x), row * (TILE_SIZE.y + GRID_GAP.y))
	var tile_rect := Rect2(pos, TILE_SIZE)
	var info: Dictionary = _slots[i]
	var enabled: bool = _is_enabled(i)
	var border_color: Color
	if i == _index:
		border_color = Color(1, 1, 0) if enabled else Color(0.6, 0.6, 0)
	else:
		border_color = Color(1, 1, 1) if enabled else Color(0.35, 0.35, 0.35)
	draw_rect(tile_rect, Color(0.08, 0.08, 0.08))
	draw_rect(tile_rect, border_color, false, 2.0)
	var thumb_pos: Vector2 = pos + Vector2((TILE_SIZE.x - THUMB_SIZE.x) / 2.0, 10)
	if info["has_data"] and info["texture"]:
		draw_texture_rect(info["texture"], Rect2(thumb_pos, THUMB_SIZE), false)
	else:
		draw_rect(Rect2(thumb_pos, THUMB_SIZE), Color(0.18, 0.18, 0.18))
		draw_string(font, thumb_pos, "Empty", HORIZONTAL_ALIGNMENT_CENTER, THUMB_SIZE.x, 14, Color(0.5, 0.5, 0.5))
	var label_color: Color = Color(1, 1, 1) if enabled else Color(0.5, 0.5, 0.5)
	draw_string(font, pos + Vector2(0, TILE_SIZE.y - 32), "Slot %d" % (i + 1), HORIZONTAL_ALIGNMENT_CENTER, TILE_SIZE.x, 15, label_color)
	if info["has_data"]:
		draw_string(font, pos + Vector2(0, TILE_SIZE.y - 14), str(info["timestamp"]), HORIZONTAL_ALIGNMENT_CENTER, TILE_SIZE.x, 11, label_color)
