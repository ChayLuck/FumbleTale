extends SidescrollerPlayer

const DASH_SPEED := 420.0
const DASH_DURATION := 0.2
const DASH_COOLDOWN := 0.5

var is_dashing := false
var _dash_timer := 0.0
var _dash_cooldown_timer := 0.0
var _shift_was_pressed := false

func _ready() -> void:
	add_to_group("platformer_player")

func _handle_special_movement(delta: float) -> bool:
	if _dash_cooldown_timer > 0.0:
		_dash_cooldown_timer -= delta

	var shift_pressed: bool = Input.is_key_pressed(KEY_SHIFT)
	var shift_just_pressed: bool = shift_pressed and not _shift_was_pressed
	_shift_was_pressed = shift_pressed

	if _dash_timer > 0.0:
		_dash_timer -= delta
		is_dashing = _dash_timer > 0.0
		return true
	is_dashing = false

	if shift_just_pressed and _dash_cooldown_timer <= 0.0:
		_dash_timer = DASH_DURATION
		_dash_cooldown_timer = DASH_COOLDOWN
		is_dashing = true
		velocity = Vector2(facing * DASH_SPEED, 0.0)
		return true

	return false

func _after_move() -> void:
	_update_animation()

func _update_animation() -> void:
	if not is_on_floor():
		sprite.play("jump_rise" if velocity.y < 0.0 else "jump_fall")
	elif velocity.x != 0.0:
		sprite.play("walk")
	else:
		sprite.play("idle")
