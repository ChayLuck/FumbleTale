class_name PauseMenu
extends Node2D

signal resume_requested
signal save_requested
signal load_requested
signal exit_requested

const BOX := Rect2(200, 140, 240, 200)
const OPTIONS := ["Resume", "Save", "Load", "Exit"]

var active := false
var _can_save := true
var _index := 0
var _message := ""

func open(can_save: bool = true) -> void:
	_can_save = can_save
	_index = 0
	_message = ""
	active = true
	visible = true
	queue_redraw()

func close() -> void:
	active = false
	visible = false

func show_message(text: String) -> void:
	_message = text
	queue_redraw()

func _is_enabled(idx: int) -> bool:
	return _can_save or OPTIONS[idx] != "Save"

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()
		return
	if event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_accept"):
		if _is_enabled(_index):
			get_viewport().set_input_as_handled()
			_select(_index)

func _move(step: int) -> void:
	var count: int = OPTIONS.size()
	for _i in count:
		_index = (_index + step + count) % count
		if _is_enabled(_index):
			break
	queue_redraw()

func _select(idx: int) -> void:
	match OPTIONS[idx]:
		"Resume": resume_requested.emit()
		"Save": save_requested.emit()
		"Load": load_requested.emit()
		"Exit": exit_requested.emit()

func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.7))
	draw_rect(BOX, Color(0, 0, 0, 1))
	draw_rect(BOX, Color(1, 1, 1), false, 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, BOX.position + Vector2(16, 30), "Menu", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1))
	for i in OPTIONS.size():
		var color: Color
		if not _is_enabled(i):
			color = Color(0.4, 0.4, 0.4)
		elif i == _index:
			color = Color(1, 1, 0)
		else:
			color = Color(1, 1, 1)
		var label: String = OPTIONS[i]
		if not _is_enabled(i):
			label += " (unavailable)"
		draw_string(font, BOX.position + Vector2(16, 70 + i * 32), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
	if _message != "":
		draw_string(font, BOX.position + Vector2(16, BOX.size.y - 16), _message, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.7, 1, 0.7))
