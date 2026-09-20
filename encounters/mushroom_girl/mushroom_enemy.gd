extends CharacterBody2D

@export var move_speed: float = 40.0
@export var patrol_range: float = 60.0

const GRAVITY := 900.0

@onready var sprite: AnimatedSprite2D = %Sprite

var _direction := 1.0
var _spawn_x: float
var _alive := true

func _ready() -> void:
	add_to_group("mushroom_enemy")
	_spawn_x = position.x
	sprite.flip_h = _direction > 0.0

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	velocity.x = _direction * move_speed
	move_and_slide()
	if absf(position.x - _spawn_x) > patrol_range:
		_direction *= -1.0
		sprite.flip_h = _direction > 0.0

func stomp() -> void:
	if not _alive:
		return
	_alive = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	sprite.play("die")
	await sprite.animation_finished
	queue_free()
