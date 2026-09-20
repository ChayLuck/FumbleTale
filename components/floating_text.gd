class_name FloatingText
extends Node2D

@export var rise_distance: float = 26.0
@export var duration: float = 0.7

var _text := ""
var _color := Color(1, 1, 1)

func setup(text: String, color: Color = Color(1, 1, 1)) -> void:
	_text = text
	_color = color

func _ready() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise_distance, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-40, 0), _text, HORIZONTAL_ALIGNMENT_CENTER, 80, 18, _color)
