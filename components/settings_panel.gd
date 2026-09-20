class_name SettingsPanel
extends Node2D

signal closed

const BOX := Rect2(110, 70, 420, 330)

enum Row { AUDIO_VOLUME, DISPLAY_MODE, DISPLAY_SCALE }

var active := false
var _rows: Array[Row] = [Row.AUDIO_VOLUME, Row.DISPLAY_MODE, Row.DISPLAY_SCALE]
var _index := 0
var _volume_percent := 100

func open() -> void:
	_volume_percent = int(round(GameSettings.master_volume * 100.0))
	_index = 0
	active = true
	visible = true
	queue_redraw()

func close() -> void:
	active = false
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		closed.emit()
		return
	if event.is_action_pressed("ui_up"):
		_index = (_index - 1 + _rows.size()) % _rows.size()
		queue_redraw()
	elif event.is_action_pressed("ui_down"):
		_index = (_index + 1) % _rows.size()
		queue_redraw()
	elif event.is_action_pressed("ui_left"):
		_adjust(-1)
	elif event.is_action_pressed("ui_right"):
		_adjust(1)
	elif event.is_action_pressed("ui_accept") and _rows[_index] == Row.DISPLAY_MODE:
		_adjust(1)

func _adjust(direction: int) -> void:
	match _rows[_index]:
		Row.AUDIO_VOLUME:
			_volume_percent = clampi(_volume_percent + direction * 10, 0, 100)
			GameSettings.set_master_volume(_volume_percent / 100.0)
		Row.DISPLAY_MODE:
			GameSettings.set_fullscreen(not GameSettings.fullscreen)
		Row.DISPLAY_SCALE:
			GameSettings.set_window_scale(GameSettings.window_scale + direction)
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.85))
	draw_rect(BOX, Color(0, 0, 0, 1))
	draw_rect(BOX, Color(1, 1, 1), false, 3.0)
	var font := ThemeDB.fallback_font
	var pos := BOX.position
	draw_string(font, pos + Vector2(16, 34), "Settings", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1))

	var y := 90.0
	_draw_row(font, pos, y, "Volume: %d%%" % _volume_percent, Row.AUDIO_VOLUME)
	y += 40.0

	y += 20.0

	var mode_text: String = "Fullscreen" if GameSettings.fullscreen else "Windowed"
	_draw_row(font, pos, y, "Display Mode: %s" % mode_text, Row.DISPLAY_MODE)
	y += 40.0
	_draw_row(font, pos, y, "Window Scale: %dx" % GameSettings.window_scale, Row.DISPLAY_SCALE)
	y += 40.0

	y += 20.0

	draw_string(font, pos + Vector2(16, y), "ESC to go back, arrows to adjust", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.6, 0.6))

func _draw_row(font: Font, box_pos: Vector2, y: float, text: String, row: Row) -> void:
	var idx: int = _rows.find(row)
	var color: Color = Color(1, 1, 0) if idx == _index else Color(1, 1, 1)
	draw_string(font, box_pos + Vector2(16, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
