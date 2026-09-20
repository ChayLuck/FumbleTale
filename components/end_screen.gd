class_name EndScreen
extends Node2D

signal option_selected(index: int)

var title := ""
var options: Array[String] = []
var enabled_flags: Array[bool] = []
var index := 0
var active := false

func show_screen(new_title: String, new_options: Array[String], new_enabled: Array[bool] = []) -> void:
	title = new_title
	options = new_options
	enabled_flags = new_enabled
	if enabled_flags.size() != options.size():
		enabled_flags.clear()
		for _i in options.size():
			enabled_flags.append(true)
	index = 0
	while index < enabled_flags.size() - 1 and not enabled_flags[index]:
		index += 1
	active = true
	visible = true
	queue_redraw()

func hide_screen() -> void:
	active = false
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not active or options.is_empty():
		return
	if event.is_action_pressed("ui_up"):
		_move(-1)
	elif event.is_action_pressed("ui_down"):
		_move(1)
	elif event.is_action_pressed("ui_accept"):
		if enabled_flags[index]:
			option_selected.emit(index)

func _move(step: int) -> void:
	var count: int = options.size()
	for _i in count:
		index = (index + step + count) % count
		if enabled_flags[index]:
			break
	queue_redraw()

func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 480)), Color(0, 0, 0, 0.85))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 190), title, HORIZONTAL_ALIGNMENT_CENTER, 640, 34, Color(1, 1, 1))
	for i in options.size():
		var color: Color
		if not enabled_flags[i]:
			color = Color(0.4, 0.4, 0.4)
		elif i == index:
			color = Color(1, 1, 0)
		else:
			color = Color(1, 1, 1)
		var label: String = options[i]
		if not enabled_flags[i]:
			label += " (unavailable)"
		draw_string(font, Vector2(0, 250 + i * 38), label, HORIZONTAL_ALIGNMENT_CENTER, 640, 22, color)
