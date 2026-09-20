class_name SeamFog
extends Node2D

@export var seam_x_positions: Array[float] = []
@export var height: float = 480.0
@export var band_half_width: float = 190.0
@export var max_alpha: float = 0.5
@export var fog_color: Color = Color(0.06, 0.09, 0.14)

func _draw() -> void:
	for seam_x in seam_x_positions:
		_draw_gradient_quad(seam_x - band_half_width, seam_x, 0.0, max_alpha)
		_draw_gradient_quad(seam_x, seam_x + band_half_width, max_alpha, 0.0)

func _draw_gradient_quad(x_from: float, x_to: float, alpha_from: float, alpha_to: float) -> void:
	var c_from := Color(fog_color.r, fog_color.g, fog_color.b, alpha_from)
	var c_to := Color(fog_color.r, fog_color.g, fog_color.b, alpha_to)
	var points := PackedVector2Array([
		Vector2(x_from, 0), Vector2(x_to, 0), Vector2(x_to, height), Vector2(x_from, height),
	])
	var colors := PackedColorArray([c_from, c_to, c_to, c_from])
	draw_polygon(points, colors)
