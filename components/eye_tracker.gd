class_name EyeTracker
extends Node2D

@export var pupil_radius: float = 2.2
@export var iris_radius: float = 4.0
@export var pupil_color: Color = Color(0.15, 0.09, 0.07)
@export var iris_color: Color = Color(0.85, 0.35, 0.55)
@export var highlight_color: Color = Color(1.0, 1.0, 1.0, 0.85)
@export var max_offset: Vector2 = Vector2(2.3, 1.5)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var offset := _clamped_offset_to_mouse()
	draw_circle(offset, iris_radius, iris_color)
	draw_circle(offset, pupil_radius, pupil_color)
	draw_circle(offset + Vector2(-pupil_radius * 0.35, -pupil_radius * 0.35), pupil_radius * 0.3, highlight_color)

func _clamped_offset_to_mouse() -> Vector2:
	var to_mouse := get_global_mouse_position() - global_position
	if max_offset.x <= 0.0 or max_offset.y <= 0.0:
		return Vector2.ZERO
	var normalized := Vector2(to_mouse.x / max_offset.x, to_mouse.y / max_offset.y)
	if normalized.length() > 1.0:
		normalized = normalized.normalized()
	return Vector2(normalized.x * max_offset.x, normalized.y * max_offset.y)
