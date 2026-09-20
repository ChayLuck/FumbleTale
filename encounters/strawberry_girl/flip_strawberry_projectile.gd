extends Projectile

@export var flip_min_delay: float = 0.6
@export var flip_max_delay: float = 2.4
@export var flip_duration: float = 0.3
@export var flip_scale_mult: float = 1.9

var _flip_timer := 0.0
var _next_flip := 0.0
var _flipping := false
var _base_shape_scale := Vector2.ONE

func _ready() -> void:
	_next_flip = randf_range(flip_min_delay, flip_max_delay)
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		_base_shape_scale = shape.scale

func _process(delta: float) -> void:
	super._process(delta)
	_flip_timer += delta
	if not _flipping and _flip_timer >= _next_flip:
		_start_flip()
	elif _flipping and _flip_timer >= _next_flip + flip_duration:
		_end_flip()

func _start_flip() -> void:
	_flipping = true
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.scale = _base_shape_scale * flip_scale_mult
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.scale = Vector2.ONE * flip_scale_mult
		sprite.modulate = Color(1.5, 1.5, 1.0)

func _end_flip() -> void:
	_flipping = false
	_flip_timer = 0.0
	_next_flip = randf_range(flip_min_delay, flip_max_delay)
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape:
		shape.scale = _base_shape_scale
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.scale = Vector2.ONE
		sprite.modulate = Color(1, 1, 1)
