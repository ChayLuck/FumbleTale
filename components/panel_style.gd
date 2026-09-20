class_name PanelStyle
extends RefCounted

const GLOW_LAYERS := 3
const GLOW_STEP := 3.0

static func fill_color(theme_color: Color) -> Color:
	return Color(theme_color.r * 0.16, theme_color.g * 0.16, theme_color.b * 0.16, 0.82)

static func draw_rect_panel(canvas: CanvasItem, rect: Rect2, theme_color: Color) -> void:
	canvas.draw_rect(rect, fill_color(theme_color))
	for i in range(GLOW_LAYERS, 0, -1):
		var alpha: float = 0.12 * (1.0 - float(i - 1) / float(GLOW_LAYERS))
		canvas.draw_rect(rect.grow(i * GLOW_STEP), Color(theme_color.r, theme_color.g, theme_color.b, alpha), false, 2.0)
	canvas.draw_rect(rect, Color(theme_color.r, theme_color.g, theme_color.b, 0.95), false, 2.0)

static func draw_circle_panel(canvas: CanvasItem, center: Vector2, radius: float, theme_color: Color) -> void:
	canvas.draw_circle(center, radius, fill_color(theme_color))
	for i in range(GLOW_LAYERS, 0, -1):
		var alpha: float = 0.12 * (1.0 - float(i - 1) / float(GLOW_LAYERS))
		canvas.draw_arc(center, radius + i * GLOW_STEP, 0.0, TAU, 48, Color(theme_color.r, theme_color.g, theme_color.b, alpha), 2.0)
	canvas.draw_arc(center, radius, 0.0, TAU, 48, Color(theme_color.r, theme_color.g, theme_color.b, 0.95), 2.0)

const TEARDROP_SEGMENTS := 16

static func teardrop_half_width(t: float) -> float:
	t = clamp(t, 0.0, 1.0)
	if t < 0.12:
		return lerp(0.82, 1.0, t / 0.12)
	var u: float = (t - 0.12) / 0.88
	return pow(cos(u * PI / 2.0), 0.65)

static func _teardrop_polygon(bounds: Rect2) -> PackedVector2Array:
	var cx: float = bounds.position.x + bounds.size.x / 2.0
	var top: float = bounds.position.y
	var height: float = bounds.size.y
	var half_w: float = bounds.size.x / 2.0
	var pts := PackedVector2Array()
	for i in range(TEARDROP_SEGMENTS + 1):
		var t: float = float(i) / float(TEARDROP_SEGMENTS)
		var w: float = teardrop_half_width(t) * half_w
		pts.append(Vector2(cx - w, top + t * height))
	for i in range(TEARDROP_SEGMENTS, -1, -1):
		var t: float = float(i) / float(TEARDROP_SEGMENTS)
		var w: float = teardrop_half_width(t) * half_w
		pts.append(Vector2(cx + w, top + t * height))
	return pts

static func draw_teardrop_panel(canvas: CanvasItem, bounds: Rect2, theme_color: Color) -> void:
	var points := _teardrop_polygon(bounds)
	var closed := points.duplicate()
	closed.append(points[0])
	canvas.draw_colored_polygon(points, fill_color(theme_color))
	for i in range(GLOW_LAYERS, 0, -1):
		var alpha: float = 0.12 * (1.0 - float(i - 1) / float(GLOW_LAYERS))
		var grown := _teardrop_polygon(bounds.grow(i * GLOW_STEP))
		grown.append(grown[0])
		canvas.draw_polyline(grown, Color(theme_color.r, theme_color.g, theme_color.b, alpha), 2.0)
	canvas.draw_polyline(closed, Color(theme_color.r, theme_color.g, theme_color.b, 0.95), 2.0)

static func draw_cursor_icon(canvas: CanvasItem, tip: Vector2, icon: Texture2D, theme_color: Color) -> void:
	var center: Vector2 = tip + Vector2(-12, 0)
	canvas.draw_circle(center, 10.0, Color(theme_color.r, theme_color.g, theme_color.b, 0.35))
	var size := Vector2(16, 16)
	canvas.draw_texture_rect(icon, Rect2(center - size / 2.0, size), false)
