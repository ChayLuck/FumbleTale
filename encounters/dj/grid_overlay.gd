extends Node2D

@export var col_edges: Array[float] = []
@export var row_edges: Array[float] = []
@export var player_row_index: int = -1

func _draw() -> void:
	if col_edges.is_empty() or row_edges.is_empty():
		return
	var line_color := Color(1, 1, 1, 0.28)
	var left: float = col_edges[0]
	var right: float = col_edges[col_edges.size() - 1]
	var top: float = row_edges[0]
	var bottom: float = row_edges[row_edges.size() - 1]
	for x in col_edges:
		draw_line(Vector2(x, top), Vector2(x, bottom), line_color, 1.0)
	for y in row_edges:
		draw_line(Vector2(left, y), Vector2(right, y), line_color, 1.0)
	if player_row_index >= 0 and player_row_index < row_edges.size() - 1:
		var rect := Rect2(left, row_edges[player_row_index], right - left, row_edges[player_row_index + 1] - row_edges[player_row_index])
		draw_rect(rect, Color(1, 1, 1, 0.1))
