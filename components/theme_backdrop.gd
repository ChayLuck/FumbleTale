class_name ThemeBackdrop
extends TextureRect

@export var theme_color: Color = Color(0.8, 0.8, 0.85):
	set(value):
		theme_color = value
		if is_inside_tree():
			_rebuild()
@export var combat_mode: bool = true:
	set(value):
		combat_mode = value
		if is_inside_tree():
			_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	var gradient := Gradient.new()
	if combat_mode:
		gradient.set_color(0, Color(theme_color.r * 0.4, theme_color.g * 0.4, theme_color.b * 0.4, 1.0))
		gradient.set_color(1, Color(0.02, 0.02, 0.035, 1.0))
	else:
		gradient.set_color(0, Color(0.015, 0.015, 0.02, 1.0))
		gradient.set_color(1, Color(0.015, 0.015, 0.02, 1.0))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.38)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 640
	tex.height = 480
	texture = tex
