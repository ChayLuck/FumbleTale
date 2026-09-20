extends SidescrollerPlayer

var _ignore_next_attack := false

func resume_input() -> void:
	set_physics_process(true)
	_ignore_next_attack = true

const ATTACK_DURATION := 0.35

var is_attacking := false
var is_parrying := false

var _attack_timer := 0.0

func _after_move() -> void:
	var delta := get_physics_process_delta_time()
	if _attack_timer > 0.0:
		_attack_timer -= delta
		is_attacking = _attack_timer > 0.0

	is_parrying = Input.is_action_pressed("parry")
	if _ignore_next_attack:
		_ignore_next_attack = false
	elif not is_parrying and Input.is_action_just_pressed("attack"):
		is_attacking = true
		_attack_timer = ATTACK_DURATION

	_update_animation()

func _update_animation() -> void:
	if is_attacking:
		sprite.play("attack")
	elif is_parrying:
		sprite.play("parry")
	elif not is_on_floor():
		sprite.play("jump_rise" if velocity.y < 0.0 else "jump_fall")
	elif velocity.x != 0.0:
		sprite.play("run" if Input.is_key_pressed(KEY_SHIFT) else "walk")
	else:
		sprite.play("idle")
