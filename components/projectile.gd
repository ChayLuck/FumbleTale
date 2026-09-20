class_name Projectile
extends Area2D

@export var velocity: Vector2 = Vector2.ZERO
@export var damage: int = 1
@export var lifetime: float = 6.0
@export var glitch_mode: bool = false
@export var glitch_interval: float = 0.12
@export var punchable: bool = false

var hit_soul := false

var _glitch_timer := 0.0

const ICE_SPIKE_PROFILE: Array[Vector2] = [
	Vector2(0.00, 3.0), Vector2(0.06, 2.0), Vector2(0.15, 4.5), Vector2(0.24, 5.5),
	Vector2(0.33, 6.5), Vector2(0.42, 8.5), Vector2(0.51, 10.5), Vector2(0.60, 13.0),
	Vector2(0.69, 10.5), Vector2(0.78, 7.5), Vector2(0.87, 4.0), Vector2(0.96, 2.0),
	Vector2(1.00, 1.0),
]

func configure_span(length: float, anchor_top: bool) -> void:
	var sign_mult: float = 1.0 if anchor_top else -1.0
	var half: float = length / 2.0
	var poly := get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly:
		var points := PackedVector2Array()
		for p in ICE_SPIKE_PROFILE:
			points.append(Vector2(-p.y, sign_mult * p.x * length))
		for i in range(ICE_SPIKE_PROFILE.size() - 1, -1, -1):
			var p: Vector2 = ICE_SPIKE_PROFILE[i]
			points.append(Vector2(p.y, sign_mult * p.x * length))
		poly.polygon = points
	else:
		var collision := $CollisionShape2D as CollisionShape2D
		var rect := collision.shape as RectangleShape2D
		rect.size.y = length
		collision.position.y = sign_mult * half
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.flip_v = not anchor_top
		var base_height: float = sprite.region_rect.size.y if sprite.region_enabled else (sprite.texture.get_height() if sprite.texture else length)
		sprite.scale.y = length / base_height
		sprite.position.y = sign_mult * half

func _process(delta: float) -> void:
	if glitch_mode:
		_glitch_timer += delta
		if _glitch_timer >= glitch_interval:
			_glitch_timer -= glitch_interval
			position += velocity * glitch_interval
	else:
		position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
