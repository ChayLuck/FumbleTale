class_name SidescrollerCompanion
extends CharacterBody2D

@export var gravity: float = 900.0
@export var move_speed: float = 190.0
@export var jump_velocity: float = -420.0
@export var follow_distance: float = 50.0
@export var follow_distance_stop: float = 20.0
var _is_following := false
@export var ledge_probe_ahead: float = 6.0
@export var ledge_probe_depth: float = 40.0

@onready var sprite: AnimatedSprite2D = %Sprite

var _target: Node2D
var _jump_queue: Array[float] = []

func _ready() -> void:
	add_to_group("companion")
	sprite.play("idle")

func track(player: Node2D) -> void:
	_target = player
	if player.has_signal("jumped"):
		player.jumped.connect(_on_player_jumped)

func _on_player_jumped(from_x: float) -> void:
	_jump_queue.append(from_x)

func _physics_process(delta: float) -> void:
	if _target == null:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	var to_target_x: float = _target.global_position.x - global_position.x
	var dist := absf(to_target_x)
	if dist > follow_distance:
		_is_following = true
	elif dist < follow_distance_stop:
		_is_following = false
	var dir := 0.0
	if _is_following:
		dir = signf(to_target_x)
	velocity.x = dir * move_speed
	if dir != 0.0:
		sprite.flip_h = dir < 0.0

	if not is_on_floor():
		sprite.play("jump_rise" if velocity.y < 0.0 else "jump_fall")
	elif dir != 0.0:
		sprite.play("walk")
	else:
		sprite.play("idle")

	if is_on_floor():
		if not _jump_queue.is_empty() and global_position.x >= _jump_queue[0] - 2.0:
			_jump_queue.pop_front()
			if not _has_floor_ahead():
				velocity.y = jump_velocity
		elif dir > 0.0 and not _has_floor_ahead():
			velocity.y = jump_velocity

	move_and_slide()

func _has_floor_ahead() -> bool:
	var probe_x: float = global_position.x + (ledge_probe_ahead if not sprite.flip_h else -ledge_probe_ahead)
	var from := Vector2(probe_x, global_position.y)
	var to := from + Vector2(0, ledge_probe_depth)
	var params := PhysicsRayQueryParameters2D.create(from, to)
	params.collision_mask = 1
	var result := get_world_2d().direct_space_state.intersect_ray(params)
	return not result.is_empty()
