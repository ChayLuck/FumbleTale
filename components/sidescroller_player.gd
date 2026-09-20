class_name SidescrollerPlayer
extends CharacterBody2D

signal jumped(from_x: float)

@export var gravity: float = 900.0
@export var move_speed: float = 120.0
@export var jump_velocity: float = -320.0
@export var jump_action: StringName = "ui_accept"
@export var run_multiplier: float = 1.0

@onready var sprite: AnimatedSprite2D = %Sprite

var facing: float = 1.0

func _physics_process(delta: float) -> void:
	if _handle_special_movement(delta):
		move_and_slide()
		_after_move()
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	var dir := 0.0
	if Input.is_action_pressed("ui_left"):
		dir -= 1.0
	if Input.is_action_pressed("ui_right"):
		dir += 1.0
	var speed: float = move_speed
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= run_multiplier
	velocity.x = dir * speed
	if dir != 0.0:
		facing = dir
		sprite.flip_h = dir < 0.0

	if is_on_floor() and Input.is_action_just_pressed(jump_action):
		velocity.y = jump_velocity
		jumped.emit(global_position.x)

	move_and_slide()
	_after_move()

func _handle_special_movement(_delta: float) -> bool:
	return false

func _after_move() -> void:
	pass
