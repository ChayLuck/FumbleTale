class_name PlayerSoul
extends Area2D

signal hit(damage: int)
signal grazed
signal freeze_progress(count: int, required: int)
signal unfrozen

const HIT_SHAPE_INDEX := 0
const GRAZE_SHAPE_INDEX := 1

@export var active := false
@export var speed: float = 170.0
@export var dash_multiplier: float = 1.8
@export var invincible_duration: float = 1.0

@export var frozen := false
@export var frozen_speed_multiplier := 0.45
@export var freeze_break_presses := 20

@export var grid_locked := false

var bounds: Rect2 = Rect2(0, 0, 200, 120)
var bounds_shape: String = "rect"
var invincible := false

var _invincible_timer := 0.0
var _freeze_press_count := 0

func _ready() -> void:
	area_shape_entered.connect(_on_area_shape_entered)
	area_shape_exited.connect(_on_area_shape_exited)

func activate() -> void:
	active = true
	invincible = false
	visible = true
	_freeze_press_count = 0
	modulate = Color(0.55, 0.75, 1.0) if frozen else Color(1, 1, 1)

func deactivate() -> void:
	active = false
	invincible = false
	visible = false
	frozen = false
	modulate = Color(1, 1, 1)

func _process(delta: float) -> void:
	if not active:
		return
	if frozen and Input.is_action_just_pressed("ui_accept"):
		_freeze_press_count += 1
		freeze_progress.emit(_freeze_press_count, freeze_break_presses)
		if _freeze_press_count >= freeze_break_presses:
			frozen = false
			modulate = Color(1, 1, 1)
			unfrozen.emit()
	if not grid_locked:
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
			var current_speed: float = speed
			if Input.is_key_pressed(KEY_SHIFT):
				current_speed *= dash_multiplier
			if frozen:
				current_speed *= frozen_speed_multiplier
			position += dir.normalized() * current_speed * delta
		if bounds_shape == "circle":
			var center: Vector2 = bounds.get_center()
			var radius: float = min(bounds.size.x, bounds.size.y) / 2.0
			position = center + (position - center).limit_length(radius)
		elif bounds_shape == "teardrop":
			position.y = clamp(position.y, bounds.position.y, bounds.position.y + bounds.size.y)
			var t: float = (position.y - bounds.position.y) / bounds.size.y
			var half_w: float = PanelStyle.teardrop_half_width(t) * (bounds.size.x / 2.0)
			var cx: float = bounds.position.x + bounds.size.x / 2.0
			position.x = clamp(position.x, cx - half_w, cx + half_w)
		else:
			position.x = clamp(position.x, bounds.position.x, bounds.position.x + bounds.size.x)
			position.y = clamp(position.y, bounds.position.y, bounds.position.y + bounds.size.y)

	if invincible:
		_invincible_timer -= delta
		visible = fmod(_invincible_timer, 0.12) > 0.06
		if _invincible_timer <= 0.0:
			invincible = false
			visible = true

func _on_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, local_shape_index: int) -> void:
	if not active or invincible or local_shape_index != HIT_SHAPE_INDEX:
		return
	var damage := 1
	if area is Projectile:
		var projectile := area as Projectile
		damage = projectile.damage
		projectile.hit_soul = true
	flash_hit()
	_recoil_from(area.global_position)
	invincible = true
	_invincible_timer = invincible_duration
	hit.emit(damage)

func _on_area_shape_exited(_area_rid: RID, area: Area2D, _area_shape_index: int, local_shape_index: int) -> void:
	if not active or local_shape_index != GRAZE_SHAPE_INDEX:
		return
	if area is Projectile and not (area as Projectile).hit_soul:
		grazed.emit()

func flash_hit() -> void:
	var tween := create_tween()
	var base_color := Color(0.55, 0.75, 1.0) if frozen else Color(1, 1, 1)
	modulate = Color(4, 4, 4)
	tween.tween_property(self, "modulate", base_color, 0.3)

func _recoil_from(source_position: Vector2) -> void:
	var away: Vector2 = position - source_position
	away = away.normalized() if away.length() > 0.01 else Vector2.UP
	var base_pos: Vector2 = position
	var tween := create_tween()
	tween.tween_property(self, "position", base_pos + away * 8.0, 0.05)
	tween.tween_property(self, "position", base_pos, 0.1)
