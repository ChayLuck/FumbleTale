extends BaseEncounter

const BASE_BOUNDS := Rect2(210, 344, 220, 120)
const PHASE_DURATION := 6.0
const BURST_INTERVAL := 0.9
const TEAR_HOLD := 0.15

@onready var spawner: BulletSpawner = %BulletSpawner

var _in_phase := false
var _phase_timer := 0.0
var _burst_timer := 0.0
var _tear_timer := 0.0
var _next_tear := 1.0
var _tear_hold := 0.0
var _tear_offset := Vector2.ZERO
var brightness: int = 1
var target: int = 1
var in_focus := false

func _ready() -> void:
	super._ready()
	MusicPlayer.ensure_playing_for_dev_test()
	won.connect(_on_cleared)
	spared.connect(_on_cleared)
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(enemy_sprite, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
	spawner.arena = arena
	spawner.projectile_scene = preload("res://encounters/cathode_cyclops/glitch_projectile.tscn")
	spawner.projectile_speed = 70.0
	spawner.projectile_damage = 2
	target = randi_range(1, 10)
	brightness = ((target + randi_range(3, 6) - 1) % 10) + 1

func resync_rhythm() -> void:
	if MusicPlayer.is_playing():
		RhythmSync.resync_if_needed(enemy_sprite, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

func _process(delta: float) -> void:
	if not _in_phase:
		return
	_phase_timer += delta
	_update_tear(delta)
	_burst_timer += delta
	if _burst_timer >= BURST_INTERVAL:
		_burst_timer = 0.0
		spawner.spawn_static_burst(randi_range(2, 3))
	if _phase_timer >= PHASE_DURATION:
		_end_phase()

func _update_tear(delta: float) -> void:
	if _tear_hold > 0.0:
		_tear_hold -= delta
		if _tear_hold <= 0.0:
			_tear_offset = Vector2.ZERO
	else:
		_tear_timer += delta
		if _tear_timer >= _next_tear:
			_tear_timer = 0.0
			_next_tear = randf_range(0.7, 1.6)
			_tear_offset = Vector2(randf_range(-16, 16), randf_range(-10, 10))
			_tear_hold = TEAR_HOLD
	arena.bounds = Rect2(BASE_BOUNDS.position + _tear_offset, BASE_BOUNDS.size)

func _handle_menu_option(index: int) -> void:
	match index:
		0: _do_smash()
		1: _do_adjust()
		2: _do_amplify()
		3: _do_calibrate()

func _do_smash() -> void:
	var dmg: int = randi_range(6, 11)
	deal_damage_to_enemy(dmg)
	if enemy_hp <= 0:
		say(["The screen sparks, flickers, and goes dark for good!"], _win)
	else:
		say(["You smack the casing! %d damage." % dmg], _begin_phase)

func _do_adjust() -> void:
	brightness = (brightness % 10) + 1
	if brightness == target:
		in_focus = true
		say(["You nudge the dial... the picture SNAPS into focus!"], _begin_phase)
	else:
		var hint: String = "closer" if abs(brightness - target) < 3 else "still fuzzy"
		say(["You nudge the dial... %s." % hint], _begin_phase)

func _do_amplify() -> void:
	open_item_menu(_on_item_used, _start_player_turn)

func _on_item_used(item: ItemData, healed: int) -> void:
	say(["You used %s. Healed %d HP." % [item.item_name, healed]], _begin_phase)

func _do_calibrate() -> void:
	if in_focus:
		say(["The screen settles into a calm, focused glow."], _spare)
	else:
		say(["The picture is still out of focus."], _begin_phase)

func _begin_phase() -> void:
	start_enemy_phase()
	_phase_timer = 0.0
	_burst_timer = 0.0
	_tear_timer = 0.0
	_tear_hold = 0.0
	_tear_offset = Vector2.ZERO
	_in_phase = true

func _end_phase() -> void:
	_in_phase = false
	end_enemy_phase(func() -> void:
		say(["The Cathode Cyclops's eye refocuses on you."], _start_player_turn))

func _on_cleared() -> void:
	GameSettings.mark_cyclops_defeated()
	Inventory.add_item(preload("res://items/key_fragment_display.tres"))
