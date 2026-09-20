class_name RelationshipPanel
extends Node2D

signal cancelled

const BOX := Rect2(120, 80, 400, 320)
const FILLED_HEART := "♥"
const EMPTY_HEART := "♡"

var active := false
var _characters: Array[String] = []

func open() -> void:
	_characters = Relationships.get_tracked_characters()
	active = true
	visible = true
	queue_redraw()

func close() -> void:
	active = false
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		cancelled.emit()

func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.6))
	draw_rect(BOX, Color(0, 0, 0, 1))
	draw_rect(BOX, Color(1, 1, 1), false, 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, BOX.position + Vector2(16, 30), "Relationships", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1))
	if _characters.is_empty():
		draw_string(font, BOX.position + Vector2(16, 70), "No one yet.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.7))
		return
	var max_hearts: int = Relationships.get_max_hearts()
	for i in _characters.size():
		var character: String = _characters[i]
		var y: float = 70.0 + i * 32.0
		draw_string(font, BOX.position + Vector2(16, y), character, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1))
		var hearts: int = Relationships.get_hearts(character)
		var heart_str := ""
		for h in max_hearts:
			heart_str += FILLED_HEART if h < hearts else EMPTY_HEART
		draw_string(font, BOX.position + Vector2(220, y), heart_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.45, 0.55))
