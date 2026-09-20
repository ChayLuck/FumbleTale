class_name AmbientDust
extends Node2D

@export var area: Rect2 = Rect2(0, 0, 640, 480)
@export var particle_count: int = 14
@export var speed_range: Vector2 = Vector2(6.0, 16.0)

var _positions: Array[Vector2] = []
var _velocities: Array[Vector2] = []
var _sizes: Array[float] = []

func _ready() -> void:
	for _i in particle_count:
		_positions.append(Vector2(
			randf_range(area.position.x, area.position.x + area.size.x),
			randf_range(area.position.y, area.position.y + area.size.y)
		))
		var angle: float = randf_range(0.0, TAU)
		var speed: float = randf_range(speed_range.x, speed_range.y)
		_velocities.append(Vector2(cos(angle), sin(angle)) * speed)
		_sizes.append(randf_range(1.0, 2.5))

func _process(delta: float) -> void:
	for i in _positions.size():
		var pos: Vector2 = _positions[i] + _velocities[i] * delta
		if pos.x < area.position.x:
			pos.x = area.position.x + area.size.x
		elif pos.x > area.position.x + area.size.x:
			pos.x = area.position.x
		if pos.y < area.position.y:
			pos.y = area.position.y + area.size.y
		elif pos.y > area.position.y + area.size.y:
			pos.y = area.position.y
		_positions[i] = pos
	queue_redraw()

func _draw() -> void:
	for i in _positions.size():
		draw_circle(_positions[i], _sizes[i], Color(1, 1, 1, 0.35))
