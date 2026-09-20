class_name CeilingRabbit
extends Projectile

@export var bounds: Rect2 = Rect2()
@export var hop_height: float = 20.0
@export var hop_duration: float = 0.45

var _dir: float = 1.0
var _hop_t := 0.0
var _base_y := 0.0

func _ready() -> void:
	_base_y = position.y
	_dir = 1.0 if randi() % 2 == 0 else -1.0

func _process(delta: float) -> void:
	position.x += velocity.x * _dir * delta
	if bounds.size.x > 0.0:
		var min_x: float = bounds.position.x + 12.0
		var max_x: float = bounds.position.x + bounds.size.x - 12.0
		if position.x < min_x:
			position.x = min_x
			_dir = 1.0
		elif position.x > max_x:
			position.x = max_x
			_dir = -1.0
	_hop_t = fmod(_hop_t + delta, hop_duration)
	var phase: float = _hop_t / hop_duration
	position.y = _base_y + absf(sin(phase * PI)) * hop_height
