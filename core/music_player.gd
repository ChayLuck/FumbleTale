extends Node

const TRACKS: Dictionary[String, AudioStream] = {
	"beat1": preload("res://Musics/FumbleTale Beat1 90 BPM  Loop.wav"),
	"beat2": preload("res://Musics/FumbleTale Beat2 120 BPM Loop.wav"),
	"beat2_2": preload("res://Musics/FumbleTale Beat2.2 90 BPM  Loop.wav"),
	"beat4": preload("res://Musics/FumbleTale Beat4 90 BPM Loop.wav"),
	"beat4_2": preload("res://Musics/FumbleTale Beat4.2 90 BPM Loop.wav"),
	"beat9": preload("res://Musics/FumbleTale Beat9 60 BPM loop.wav"),
}
const TRACK_BPM: Dictionary[String, float] = {
	"beat1": 90.0,
	"beat2": 120.0,
	"beat2_2": 90.0,
	"beat4": 90.0,
	"beat4_2": 90.0,
	"beat9": 60.0,
}
const SILENT_DB := -80.0
const DUCK_DB := -12.04

var current_track_id: String = ""

var _players: Array[AudioStreamPlayer] = []
var _active_index := 0
var _fade_tween: Tween
var _ducked := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = SILENT_DB
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_players.append(p)
	for stream in TRACKS.values():
		if stream is AudioStreamWAV:
			var wav := stream as AudioStreamWAV
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(round(wav.get_length() * wav.mix_rate))

func play_track(track_id: String, fade_time: float = 1.5) -> void:
	if track_id == current_track_id:
		return
	if not TRACKS.has(track_id):
		push_warning("MusicPlayer: unknown track id '%s'" % track_id)
		return

	var outgoing := _players[_active_index]
	_active_index = 1 - _active_index
	var incoming := _players[_active_index]

	incoming.stream = TRACKS[track_id]
	incoming.volume_db = SILENT_DB
	incoming.play()
	current_track_id = track_id

	var target_db: float = DUCK_DB if _ducked else 0.0
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(incoming, "volume_db", target_db, fade_time)
	if outgoing.playing:
		_fade_tween.tween_property(outgoing, "volume_db", SILENT_DB, fade_time)
	_fade_tween.set_parallel(false)
	_fade_tween.tween_callback(outgoing.stop)

func set_ducked(ducked: bool, duck_time: float = 0.3) -> void:
	if ducked == _ducked:
		return
	_ducked = ducked
	if current_track_id == "":
		return
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_players[_active_index], "volume_db", DUCK_DB if ducked else 0.0, duck_time)

func stop(fade_time: float = 1.5) -> void:
	if current_track_id == "":
		return
	current_track_id = ""
	var outgoing := _players[_active_index]

	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(outgoing, "volume_db", SILENT_DB, fade_time)
	_fade_tween.tween_callback(outgoing.stop)

func is_playing() -> bool:
	return current_track_id != ""

func ensure_playing_for_dev_test() -> void:
	if not is_playing():
		play_track("beat2", 0.1)

func get_playback_position() -> float:
	if current_track_id == "":
		return 0.0
	return _players[_active_index].get_playback_position()

func get_bpm(track_id: String) -> float:
	return TRACK_BPM.get(track_id, 120.0)
