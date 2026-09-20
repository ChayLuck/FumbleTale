class_name OverworldPlayer
extends CharacterBody2D

@export var speed: float = 120.0

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D

var _facing := "south"

func _ready() -> void:
	add_to_group("player")
	sprite.play("idle_south")

func _physics_process(_delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		dir.x += 1
	if Input.is_action_pressed("ui_up"):
		dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		dir.y += 1

	if dir != Vector2.ZERO:
		velocity = dir.normalized() * speed
		_facing = DirectionUtils.from_vector(dir)
		sprite.play("walk_%s" % _facing)
	else:
		velocity = Vector2.ZERO
		sprite.play("idle_%s" % _facing)
	move_and_slide()
