class_name BeatKick
extends AudioStreamPlayer

const MIX_RATE := 44100.0

var _playback: AudioStreamGeneratorPlayback

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.3
	stream = generator
	play()
	_playback = get_stream_playback()

func kick() -> void:
	_pulse(90.0, 0.12, 0.6)

func tick() -> void:
	_pulse(440.0, 0.05, 0.25)

func _pulse(freq: float, duration: float, volume: float) -> void:
	var frame_count: int = int(MIX_RATE * duration)
	for i in frame_count:
		if _playback.get_frames_available() <= 0:
			break
		var t: float = float(i) / MIX_RATE
		var envelope: float = pow(1.0 - float(i) / frame_count, 2.0)
		var sample: float = sin(TAU * freq * t) * envelope * volume
		_playback.push_frame(Vector2(sample, sample))
