extends BaseEncounter

const ICE_SPIKE_SCENE := preload("res://components/ice_spike.tscn")
const ICE_SHARD_SCENE := preload("res://components/ice_shard.tscn")
const HISAME_FURIOUS_FRAMES := preload("res://overworld/assets/hisame_portraits/hisame_furious_frames.tres")
const HISAME_SLAP_FRAMES := preload("res://overworld/assets/hisame_portraits/hisame_slap_frames.tres")
const HISAME_KNEEL_FRAMES := preload("res://overworld/assets/hisame_portraits/hisame_kneel_frames.tres")

const NEXT_STOP := "res://overworld/hisame_camp.tscn"
const MAX_TURNS := 5
const PHASE_DURATION := 10.0
const SPIKE_MARGIN := 24.0
const SPIKE_DAMAGE := 1
const SHARD_DAMAGE := 1

const GAP_HEIGHTS := [34.0, 30.0, 30.0, 30.0, 27.0]
const SPIKE_SPEEDS := [200.0, 220.0, 220.0, 220.0, 245.0]
const SPAWN_INTERVALS := [0.6, 0.52, 0.52, 0.52, 0.45]
const SHARD_INTERVALS := [2.6, 2.2, 2.2, 2.2, 1.9]
const SHARD_SPEEDS := [150.0, 170.0, 170.0, 170.0, 190.0]

const FIGHT_LINES := [
	"Your strike shatters harmlessly against her ice.",
	"The cold barely notices you.",
	"Your fist meets solid ice and nothing more.",
	"She doesn't even flinch.",
	"Ice, not skin. It was never going to work.",
]
const PLEAD_LINES := [
	"\"Please — I didn't mean it,\" you say.",
	"\"I'm sorry, really,\" you try again.",
	"\"Please, stop,\" you say.",
	"\"I get it, I get it — please,\" you plead.",
	"\"Enough, please,\" you say, voice cracking.",
]

@onready var spawner: BulletSpawner = %BulletSpawner

var turn_index := 0
var _pleaded_this_turn := false
var _in_phase := false
var _phase_timer := 0.0
var _spawn_timer := 0.0
var _shard_timer := 0.0
var _pending_choice: Callable = Callable()

func _ready() -> void:
	super._ready()
	MusicPlayer.ensure_playing_for_dev_test()
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(enemy_sprite, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
	spawner.arena = arena
	spawner.projectile_scene = ICE_SHARD_SCENE
	spawner.projectile_damage = SHARD_DAMAGE
	_update_boss_intensity()

func resync_rhythm() -> void:
	if MusicPlayer.is_playing() and enemy_sprite.sprite_frames == HISAME_FURIOUS_FRAMES:
		RhythmSync.resync_if_needed(enemy_sprite, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

func _process(delta: float) -> void:
	if not _in_phase:
		return
	_phase_timer += delta
	_spawn_timer += delta
	_shard_timer += delta
	if _spawn_timer >= SPAWN_INTERVALS[turn_index]:
		_spawn_timer = 0.0
		_spawn_ice_gap_pair()
	if _shard_timer >= SHARD_INTERVALS[turn_index]:
		_shard_timer = 0.0
		spawner.projectile_speed = SHARD_SPEEDS[turn_index]
		spawner.spawn_from_top()
	if _phase_timer >= PHASE_DURATION:
		_end_phase()

func _spawn_ice_gap_pair() -> void:
	var b: Rect2 = arena.bounds
	var gap_h: float = GAP_HEIGHTS[turn_index]
	var lo: float = b.position.y + SPIKE_MARGIN + gap_h / 2.0
	var hi: float = b.position.y + b.size.y - SPIKE_MARGIN - gap_h / 2.0
	var gap_center: float = randf_range(min(lo, hi), max(lo, hi))
	spawner.spawn_ice_gap(ICE_SPIKE_SCENE, ICE_SPIKE_SCENE, gap_center - gap_h / 2.0, gap_center + gap_h / 2.0, SPIKE_SPEEDS[turn_index], SPIKE_DAMAGE)

func _handle_menu_option(index: int) -> void:
	if _pending_choice.is_valid():
		var handler := _pending_choice
		_pending_choice = Callable()
		handler.call(index)
		return
	match index:
		0: _do_plead()
		1: _do_fight()
		2: _do_item()

func _choose(options: Array[String], handler: Callable) -> void:
	_pending_choice = handler
	menu.set_options(options)
	menu.show_menu()

func _do_plead() -> void:
	_pleaded_this_turn = true
	say([PLEAD_LINES[turn_index]], _begin_phase)

func _do_fight() -> void:
	_pleaded_this_turn = false
	say([FIGHT_LINES[turn_index]], _begin_phase)

func _do_item() -> void:
	open_item_menu(_on_item_used, _start_player_turn)

func _on_item_used(item: ItemData, healed: int) -> void:
	_pleaded_this_turn = false
	say(["You used %s. Healed %d HP." % [item.item_name, healed]], _begin_phase)

func _begin_phase() -> void:
	arena.set_soul_frozen(not _pleaded_this_turn)
	start_enemy_phase()
	_phase_timer = 0.0
	_spawn_timer = 0.0
	_shard_timer = 0.0
	_in_phase = true

func _end_phase() -> void:
	_in_phase = false
	end_enemy_phase(_on_phase_survived)

func _on_phase_survived() -> void:
	turn_index += 1
	if turn_index >= MAX_TURNS:
		_resolve_fight()
	elif turn_index == MAX_TURNS - 1:
		_show_kneel_ultimatum()
	else:
		_update_boss_intensity()
		say(["Hisame's glare sharpens further, ice creeping further up her arms."], _start_player_turn)

func _show_kneel_ultimatum() -> void:
	enemy_sprite.sprite_frames = HISAME_KNEEL_FRAMES
	enemy_sprite.play("idle")
	say(["\"Beg or die,\" she says."], _show_kneel_choice)

func _show_kneel_choice() -> void:
	_choose(["Say sorry", "Refuse"], _on_kneel_choice)

func _on_kneel_choice(index: int) -> void:
	if index == 0:
		_beg_ending()
	else:
		_refuse_kneel_and_continue()

func _beg_ending() -> void:
	Relationships.add_heart("Hisame", 1)
	say([
		"\"I'm sorry, I'm sorry — please,\" you say,.",
		"\"Good.\"",
	], _finish_encounter)

func _refuse_kneel_and_continue() -> void:
	enemy_sprite.sprite_frames = HISAME_FURIOUS_FRAMES
	enemy_sprite.play("idle")
	resync_rhythm()
	_update_boss_intensity()
	say(["\"Die, then,\" she says, and the temperature plummets."], _start_player_turn)

func _update_boss_intensity() -> void:
	var t: float = float(turn_index) / float(MAX_TURNS - 1)
	enemy_sprite.modulate = Color(1, 1, 1).lerp(Color(1.5, 1.6, 2.2), t)

func _resolve_fight() -> void:
	_change_state(State.RESOLVE)
	say([
		"Hisame straightens, and the cold finally eases from her shoulders.",
		"\"...I hope you've learned your lesson,\" she says.",
	], _show_post_fight_choice)

func _show_post_fight_choice() -> void:
	_choose([
		"Okay, I'm very sorry.",
		"What was that? What are you doing?",
		"(wait silently)",
	], _on_post_fight_choice)

func _on_post_fight_choice(index: int) -> void:
	match index:
		0:
			Relationships.add_heart("Hisame", 1)
			say(["\"Okay, I'm very sorry,\" you say."], _show_final_order_line)
		1:
			enemy_sprite.sprite_frames = HISAME_SLAP_FRAMES
			enemy_sprite.play("idle")
			say([
				"\"What was that? What are you doing?\" you ask.",
				"The second slap answers before you finish.",
			], _restore_furious_then_final)
		_:
			Relationships.add_heart("Hisame", 1)
			say(["You stay quiet and wait for her to speak."], _show_final_order_line)

func _restore_furious_then_final() -> void:
	enemy_sprite.sprite_frames = HISAME_FURIOUS_FRAMES
	enemy_sprite.play("idle")
	resync_rhythm()
	_show_final_order_line()

func _show_final_order_line() -> void:
	say([
		"\"I don't want your unnecessary talk,\" she says. \"I give an order, you follow it. That's all.\"",
		"\"If I want you to speak, I'll tell you to. Understood?\"",
	], _show_understood_choice)

func _show_understood_choice() -> void:
	_choose(["Yes", "(stay silent)"], _on_understood_choice)

func _on_understood_choice(_index: int) -> void:
	say(["\"Good.\""], _show_closing_line)

func _show_closing_line() -> void:
	say(["\"Now let's find somewhere to rest, so I can tell you why you're here.\""], _finish_encounter)

func _finish_encounter() -> void:
	get_tree().change_scene_to_file(NEXT_STOP)
