class_name DialogBox
extends Node2D

signal finished

const CHAR_INTERVAL := 0.025

@export var box_rect: Rect2 = Rect2(20, 320, 600, 140)
@export var text_color := Color(0.95, 0.95, 0.98)

var _lines: Array[String] = []
var _line_index := 0
var _full_text := ""
var _shown_text := ""
var _char_index := 0
var _timer := 0.0
var active := false

func show_lines(lines: Array[String]) -> void:
	if lines.is_empty():
		finished.emit()
		return
	_lines = lines
	_line_index = 0
	active = true
	visible = true
	_start_line()

func _start_line() -> void:
	_full_text = _lines[_line_index]
	_shown_text = ""
	_char_index = 0
	_timer = 0.0

func _process(delta: float) -> void:
	if not active:
		return
	if _char_index < _full_text.length():
		_timer += delta
		while _timer >= CHAR_INTERVAL and _char_index < _full_text.length():
			_char_index += 1
			_timer -= CHAR_INTERVAL
		_shown_text = _full_text.substr(0, _char_index)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance()

func _advance() -> void:
	if _char_index < _full_text.length():
		_char_index = _full_text.length()
		_shown_text = _full_text
		return
	_line_index += 1
	if _line_index < _lines.size():
		_start_line()
	else:
		active = false
		visible = false
		finished.emit()

func _draw() -> void:
	if not active:
		return
	draw_rect(box_rect, Color(0, 0, 0, 1))
	draw_rect(box_rect, Color(1, 1, 1), false, 2.0)
	var font := ThemeDB.fallback_font
	draw_multiline_string(font, box_rect.position + Vector2(16, 30), _shown_text, HORIZONTAL_ALIGNMENT_LEFT, box_rect.size.x - 32, 18, -1, text_color)
