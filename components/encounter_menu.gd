class_name EncounterMenu
extends Node2D

signal option_selected(index: int)

const CURSOR_ICON := preload("res://assets/anim/soul_wisp_0.png")

@export var box_rect: Rect2 = Rect2(20, 320, 600, 140)
@export var theme_color := Color(0.8, 0.8, 0.85)
@export var combat_mode := false

var options: Array[String] = []
var index := 0
var active := false

func set_options(new_options: Array[String]) -> void:
	options = new_options
	index = 0

func show_menu() -> void:
	active = true
	visible = true
	queue_redraw()

func hide_menu() -> void:
	active = false
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not active or options.is_empty():
		return
	if event.is_action_pressed("ui_left"):
		index = (index - 1 + options.size()) % options.size()
		queue_redraw()
	elif event.is_action_pressed("ui_right"):
		index = (index + 1) % options.size()
		queue_redraw()
	elif event.is_action_pressed("ui_accept"):
		option_selected.emit(index)

func _draw() -> void:
	if not active:
		return
	if combat_mode:
		PanelStyle.draw_rect_panel(self, box_rect, theme_color)
	else:
		draw_rect(box_rect, Color(0, 0, 0, 1))
		draw_rect(box_rect, Color(1, 1, 1), false, 2.0)
	var font := ThemeDB.fallback_font
	var font_size := 20
	var padding := 32.0
	var left: float = box_rect.position.x + 40.0
	var right_limit: float = box_rect.position.x + box_rect.size.x - 20.0
	var row_height := 34.0
	var x := left
	var y: float = box_rect.position.y + 55.0
	var selected_color := theme_color.lightened(0.35) if combat_mode else Color(1, 1, 0)
	var cursor_glow := theme_color if combat_mode else Color(1, 1, 1, 0.5)
	for i in options.size():
		var w: float = font.get_string_size(options[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if x + w > right_limit and x > left:
			x = left
			y += row_height
		var color := selected_color if i == index else Color(0.95, 0.95, 0.98)
		var pos := Vector2(x, y)
		draw_string(font, pos, options[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		if i == index:
			PanelStyle.draw_cursor_icon(self, pos + Vector2(-4, 4), CURSOR_ICON, cursor_glow)
		x += w + padding
