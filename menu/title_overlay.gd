extends Node2D

const PANEL_RECT := Rect2(0, 0, 250, 480)
const PANEL_COLOR := Color(0.15, 0.05, 0.15, 0.35)
const TITLE_POS := Vector2(46, 305)
const TITLE_COLOR := Color(1, 0.9, 0.85)
const TITLE_OUTLINE := Color(0.25, 0.05, 0.15, 0.9)

func _draw() -> void:
	draw_rect(PANEL_RECT, PANEL_COLOR)
	var font := ThemeDB.fallback_font
	for offset in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		draw_string(font, TITLE_POS + offset, "FumbleTale", HORIZONTAL_ALIGNMENT_LEFT, 210, 30, TITLE_OUTLINE)
	draw_string(font, TITLE_POS, "FumbleTale", HORIZONTAL_ALIGNMENT_LEFT, 210, 30, TITLE_COLOR)
