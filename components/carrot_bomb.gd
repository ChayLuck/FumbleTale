class_name CarrotBomb
extends Projectile

const GrazeSparkScene := preload("res://components/graze_spark.tscn")

@export var grow_duration: float = 0.9
@export var telegraph_duration: float = 0.5
@export var explode_duration: float = 0.25

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var _t := 0.0
var _state := 0

func _ready() -> void:
	monitoring = false
	monitorable = true
	collision.disabled = true
	scale = Vector2(0.05, 0.05)

func _process(delta: float) -> void:
	_t += delta
	match _state:
		0:
			var p: float = clampf(_t / grow_duration, 0.0, 1.0)
			scale = Vector2.ONE * lerpf(0.05, 1.0, p)
			if _t >= grow_duration:
				_state = 1
				_t = 0.0
		1:
			sprite.modulate = Color(1, 1, 1).lerp(Color(3, 1.6, 1.6), fmod(_t * 6.0, 1.0))
			if _t >= telegraph_duration:
				_state = 2
				_t = 0.0
				collision.disabled = false
				sprite.modulate = Color(1, 0.35, 0.35)
				_spawn_boom()
		2:
			if _t >= explode_duration:
				queue_free()

func _spawn_boom() -> void:
	var boom: GrazeSpark = GrazeSparkScene.instantiate()
	boom.max_radius = 22.0
	boom.duration = 0.3
	boom.color = Color(1, 0.5, 0.2)
	boom.position = position
	get_parent().add_child(boom)
