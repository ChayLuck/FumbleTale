class_name GrazeSpark
extends Node2D

@export var duration: float = 0.25
@export var max_radius: float = 14.0
@export var color: Color = Color(1, 1, 1)

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	if _t >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress: float = _t / duration
	var radius: float = lerp(4.0, max_radius, progress)
	var alpha: float = 1.0 - progress
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(color.r, color.g, color.b, alpha), 2.0)
