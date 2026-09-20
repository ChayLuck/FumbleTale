class_name RhythmSync
extends RefCounted

static func _loop_period(bpm: float, beats_per_loop: float) -> float:
	return beats_per_loop * 60.0 / bpm

static func sync_sprite_to_bpm(sprite: AnimatedSprite2D, anim_name: StringName, frame_count: int, bpm: float, beats_per_loop: float = 1.0) -> void:
	var loop_period: float = _loop_period(bpm, beats_per_loop)
	sprite.sprite_frames.set_animation_speed(anim_name, frame_count / loop_period)
	sprite.stop()
	sprite.frame = 0
	sprite.play(anim_name)

static func resync_if_needed(sprite: AnimatedSprite2D, anim_name: StringName, frame_count: int, bpm: float, beats_per_loop: float = 1.0) -> void:
	if sprite.animation != anim_name or not sprite.is_playing():
		return
	var loop_period: float = _loop_period(bpm, beats_per_loop)
	var phase: float = fmod(MusicPlayer.get_playback_position(), loop_period)
	var target_frame: int = int(floor(phase / loop_period * frame_count)) % frame_count
	if sprite.frame != target_frame:
		sprite.frame = target_frame
