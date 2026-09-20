class_name NameLabel
extends Node2D

var character_name := ""

func set_character_name(new_name: String) -> void:
	character_name = new_name
	queue_redraw()

func _draw() -> void:
	if character_name != "":
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(40, 60), character_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 1, 1))
