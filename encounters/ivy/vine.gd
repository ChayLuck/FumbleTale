extends Node2D

signal caught_player

@export_enum("ceiling", "ground") var origin: String = "ceiling"
@export var reach: float = 300.0
@export var trigger_height: float = 380.0
@export var trigger_width: float = 130.0
@export var width: float = 20.0
@export var extend_duration: float = 0.2
@export var hold_duration: float = 0.35
@export var retract_duration: float = 0.35
@export var trigger_cooldown: float = 0.6

enum State { IDLE, EXTENDING, HOLDING, RETRACTING }

@onready var trigger_zone: Area2D = %TriggerZone
@onready var trigger_shape: CollisionShape2D = %TriggerShape
@onready var grab_zone: Area2D = %GrabZone
@onready var grab_shape: CollisionShape2D = %GrabShape
@onready var visual: Control = %Visual

var _state: int = State.IDLE
var _timer := 0.0
var _cooldown_timer := 0.0
var _sign := 1.0

func _ready() -> void:
	add_to_group("ivy_vine")
	_sign = 1.0 if origin == "ceiling" else -1.0
	trigger_shape.shape = trigger_shape.shape.duplicate()
	grab_shape.shape = grab_shape.shape.duplicate()

	(trigger_shape.shape as RectangleShape2D).size = Vector2(trigger_width, trigger_height)
	trigger_zone.position.y = _sign * trigger_height / 2.0
	trigger_zone.body_entered.connect(_on_trigger_entered)
	grab_zone.body_entered.connect(_on_grab_entered)
	_set_length(0.0)

func _on_trigger_entered(body: Node2D) -> void:
	if _state == State.IDLE and _cooldown_timer <= 0.0 and body.is_in_group("platformer_player"):
		_state = State.EXTENDING
		_timer = 0.0

func _on_grab_entered(body: Node2D) -> void:
	if _state != State.EXTENDING and _state != State.HOLDING:
		return
	if not body.is_in_group("platformer_player"):
		return
	if "is_dashing" in body and body.is_dashing:
		return
	caught_player.emit()

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta
	match _state:
		State.EXTENDING:
			_timer += delta
			var t: float = clampf(_timer / extend_duration, 0.0, 1.0)
			_set_length(reach * t)
			if t >= 1.0:
				_state = State.HOLDING
				_timer = 0.0
		State.HOLDING:
			_timer += delta
			if _timer >= hold_duration:
				_state = State.RETRACTING
				_timer = 0.0
		State.RETRACTING:
			_timer += delta
			var t: float = clampf(_timer / retract_duration, 0.0, 1.0)
			_set_length(reach * (1.0 - t))
			if t >= 1.0:
				_state = State.IDLE
				_cooldown_timer = trigger_cooldown

func _set_length(length: float) -> void:
	var safe_length: float = maxf(length, 0.5)
	visual.size = Vector2(width, safe_length)
	visual.position = Vector2(-width / 2.0, 0.0 if _sign > 0.0 else -safe_length)
	(grab_shape.shape as RectangleShape2D).size = Vector2(width, safe_length)
	grab_zone.position.y = _sign * safe_length / 2.0
