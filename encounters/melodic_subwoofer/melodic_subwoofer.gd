extends BaseEncounter

const BASE_BOUNDS := Rect2(255, 330, 130, 130)
const PHASE_DURATION := 6.0
const BEAT_BPM := 128.0

@onready var rhythm: RhythmTracker = %RhythmTracker
@onready var spawner: BulletSpawner = %BulletSpawner
@onready var beat_kick: BeatKick = %BeatKick

var _in_phase := false
var _phase_timer := 0.0
var _beat_count := 0
var dial: int = 1
var target: int = 1
var in_tune := false

func _ready() -> void:
	super._ready()
	MusicPlayer.ensure_playing_for_dev_test()
	won.connect(_on_cleared)
	spared.connect(_on_cleared)
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(enemy_sprite, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
	rhythm.bpm = BEAT_BPM
	rhythm.beat.connect(_on_beat)
	spawner.arena = arena
	spawner.projectile_scene = preload("res://components/projectile.tscn")
	spawner.projectile_speed = 90.0
	spawner.projectile_damage = 2
	target = randi_range(1, 10)
	dial = ((target + randi_range(3, 6) - 1) % 10) + 1

func resync_rhythm() -> void:
	if MusicPlayer.is_playing():
		RhythmSync.resync_if_needed(enemy_sprite, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

func _process(delta: float) -> void:
	if not _in_phase:
		return
	_phase_timer += delta
	var pulse: float = sin(_phase_timer * BEAT_BPM / 60.0 * TAU) * 10.0
	arena.bounds = BASE_BOUNDS.grow(pulse)
	if _phase_timer >= PHASE_DURATION:
		_end_phase()

func _handle_menu_option(index: int) -> void:
	match index:
		0: _do_strike()
		1: _do_tune()
		2: _do_amplify()
		3: _do_harmonize()

func _do_strike() -> void:
	var dmg: int = randi_range(6, 11)
	deal_damage_to_enemy(dmg)
	if enemy_hp <= 0:
		say(["The cabinet rattles, sparks, and powers down for good!"], _win)
	else:
		say(["You slam the cabinet! %d damage." % dmg], _begin_phase)

func _do_tune() -> void:
	dial = (dial % 10) + 1
	if dial == target:
		in_tune = true
		say(["You nudge the dial... it CLICKS into place. Perfectly in tune!"], _begin_phase)
	else:
		var hint: String = "warmer" if abs(dial - target) < 3 else "colder"
		say(["You nudge the dial... still sounds %s." % hint], _begin_phase)

func _do_amplify() -> void:
	open_item_menu(_on_item_used, _start_player_turn)

func _on_item_used(item: ItemData, healed: int) -> void:
	say(["You used %s. Healed %d HP." % [item.item_name, healed]], _begin_phase)

func _do_harmonize() -> void:
	if in_tune:
		say(["The subwoofer hums contentedly and powers down peacefully."], _spare)
	else:
		say(["The frequencies still clash. It's not ready to be harmonized."], _begin_phase)

func _begin_phase() -> void:
	start_enemy_phase()
	_phase_timer = 0.0
	_beat_count = 0
	_in_phase = true
	rhythm.start()

func _end_phase() -> void:
	_in_phase = false
	rhythm.stop()
	end_enemy_phase(func() -> void:
		say(["The Melodic Subwoofer winds up for another track."], _start_player_turn))

func _on_cleared() -> void:
	GameSettings.mark_subwoofer_defeated()
	Inventory.add_item(preload("res://items/key_fragment_sound.tres"))

func _on_beat() -> void:
	if not _in_phase:
		return
	_beat_count += 1
	if _beat_count % 2 == 1:
		beat_kick.kick()
	else:
		beat_kick.tick()
	spawner.spawn_from_rim()
