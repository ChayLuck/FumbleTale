extends Node2D

@export var floor_rect: Rect2 = Rect2(60, 60, 520, 360)

func _draw() -> void:
	draw_rect(floor_rect, Color(0.4, 0.4, 0.5), false, 3.0)
	var corners := [Vector2(0, 0), Vector2(640, 0), Vector2(0, 480), Vector2(640, 480)]
	for corner in corners:
		draw_circle(corner, 280.0, Color(0, 0, 0, 0.28))
