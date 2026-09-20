class_name AnimPacing
extends RefCounted

static func apply(sprite: AnimatedSprite2D, also_continuous: Array[SpriteFrames] = [], min_pause: float = 1.2, max_pause: float = 3.0) -> void:
	var continuous_frames: Array[SpriteFrames] = [sprite.sprite_frames]
	continuous_frames.append_array(also_continuous)
	sprite.animation_looped.connect(func() -> void:
		if not is_instance_valid(sprite):
			return
		if continuous_frames.has(sprite.sprite_frames):
			return
		var anim := sprite.animation
		sprite.stop()
		sprite.frame = 0
		var tree := sprite.get_tree()
		if tree:
			await tree.create_timer(randf_range(min_pause, max_pause)).timeout
		if is_instance_valid(sprite):
			sprite.play(anim)
	)
