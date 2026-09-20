extends SidescrollerPlayer

signal died
signal stomped_enemy

const STOMP_BOUNCE := -220.0

func _after_move() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider is Node and (collider as Node).is_in_group("mushroom_enemy"):
			if collision.get_normal().y < -0.5:
				collider.call("stomp")
				velocity.y = STOMP_BOUNCE
				stomped_enemy.emit()
			else:
				died.emit()
	_update_animation()

func _update_animation() -> void:
	if not is_on_floor():
		sprite.play("jump_rise" if velocity.y < 0.0 else "jump_fall")
	elif velocity.x != 0.0:
		sprite.play("walk")
	else:
		sprite.play("idle")
