extends BaseEncounter

const BASE_BOUNDS := Rect2(200, 260, 240, 160)
const LEFT_HALF := Rect2(200, 260, 118, 160)
const RIGHT_HALF := Rect2(322, 260, 118, 160)
const PHASE_DURATION := 7.0
const SEED_INTERVAL := 0.18
const BERRY_INTERVAL := 1.4
const TIER2_TURN := 2
const TIER3_TURN := 4
const SPLIT_DURATION := 0.5

const SEED_SCENE := preload("res://encounters/strawberry_girl/seed_dust.tscn")
const BERRY_SCENE := preload("res://encounters/strawberry_girl/flip_strawberry.tscn")

@onready var spawner: BulletSpawner = %BulletSpawner

var _in_phase := false
var _phase_timer := 0.0
var _seed_timer := 0.0
var _berry_timer := 0.0
var _turn_count := 0
var _tier := 1
var _split_side := ""

func _ready() -> void:
	super._ready()
	MusicPlayer.ensure_playing_for_dev_test()
	won.connect(_on_cleared)
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(enemy_sprite, &"idle", 9, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
	spawner.arena = arena

func resync_rhythm() -> void:
	if MusicPlayer.is_playing():
		RhythmSync.resync_if_needed(enemy_sprite, &"idle", 9, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

func _process(delta: float) -> void:
	if not _in_phase:
		return
	_phase_timer += delta
	_seed_timer += delta
	if _seed_timer >= SEED_INTERVAL:
		_seed_timer = 0.0
		_spawn_seed()
	if _tier >= 2:
		_berry_timer += delta
		if _berry_timer >= BERRY_INTERVAL:
			_berry_timer = 0.0
			_spawn_berry()
	if _phase_timer >= PHASE_DURATION:
		_end_phase()
	queue_redraw()

func _spawn_seed() -> void:
	spawner.projectile_scene = SEED_SCENE
	spawner.projectile_speed = randf_range(40.0, 70.0)
	spawner.projectile_damage = 1
	if randi() % 2 == 0:
		spawner.spawn_from_top()
	else:
		spawner.spawn_from_side()

func _spawn_berry() -> void:
	spawner.projectile_scene = BERRY_SCENE
	spawner.projectile_speed = randf_range(50.0, 80.0)
	spawner.projectile_damage = 2
	if randi() % 2 == 0:
		spawner.spawn_from_top()
	else:
		spawner.spawn_from_side()

func _handle_menu_option(index: int) -> void:
	match index:
		0: _do_strike()
		1: _do_item()

func _do_strike() -> void:
	var dmg: int = randi_range(6, 11)
	deal_damage_to_enemy(dmg)
	if enemy_hp <= 0:
		say(["Strawberry Girl bursts into seeds and scatters."], _win)
	else:
		_turn_count += 1
		_update_tier()
		say(["You struck the strawberry! %d damage." % dmg], _begin_phase)

func _update_tier() -> void:
	if _turn_count >= TIER3_TURN:
		_tier = max(_tier, 3)
	elif _turn_count >= TIER2_TURN:
		_tier = max(_tier, 2)

func _do_item() -> void:
	open_item_menu(_on_item_used, _start_player_turn)

func _on_item_used(item: ItemData, healed: int) -> void:
	say(["You used %s. Healed %d HP." % [item.item_name, healed]], _begin_phase)

func _begin_phase() -> void:
	start_enemy_phase()
	_phase_timer = 0.0
	_seed_timer = 0.0
	_berry_timer = 0.0
	_in_phase = true
	if _tier >= 3:
		_split_side = "left" if randi() % 2 == 0 else "right"
		_animate_split()
	else:
		_split_side = ""
		arena.shape = "teardrop"
		arena.bounds = BASE_BOUNDS

func _animate_split() -> void:
	arena.shape = "rect"
	arena.bounds = BASE_BOUNDS
	_screen_shake(8.0, 0.25)
	var target: Rect2 = LEFT_HALF if _split_side == "left" else RIGHT_HALF
	var tween := create_tween()
	tween.tween_property(arena, "bounds", target, SPLIT_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _end_phase() -> void:
	_in_phase = false
	queue_redraw()
	end_enemy_phase(func() -> void:
		say(["Strawberry Girl regathers herself."], _start_player_turn))

func _draw() -> void:
	if _in_phase and _split_side != "":
		var divider_x: float = (LEFT_HALF.position.x + LEFT_HALF.size.x + RIGHT_HALF.position.x) / 2.0
		draw_line(Vector2(divider_x, BASE_BOUNDS.position.y - 10), Vector2(divider_x, BASE_BOUNDS.position.y + BASE_BOUNDS.size.y + 10), Color(1, 1, 1, 0.85), 3.0)

func _on_cleared() -> void:
	GameSettings.mark_strawberry_girl_cleared()
