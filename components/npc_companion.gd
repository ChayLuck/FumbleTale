class_name NpcCompanion
extends Node2D

@export var follow_distance: float = 26.0
@export var speed: float = 130.0

@onready var sprite: AnimatedSprite2D = %AnimatedSprite2D

var _target: Node2D
var _facing := "south"

func _ready() -> void:
	sprite.play("idle_south")

func _physics_process(delta: float) -> void:
	if _target == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.is_empty():
			return
		_target = players[0]
	var to_target: Vector2 = _target.global_position - global_position
	var dist: float = to_target.length()
	if dist > follow_distance:
		var dir: Vector2 = to_target.normalized()
		var move_amount: float = min(speed * delta, dist - follow_distance)
		global_position += dir * move_amount
		_facing = DirectionUtils.from_vector(dir)
		sprite.play("walk_%s" % _facing)
	else:
		sprite.play("idle_%s" % _facing)
