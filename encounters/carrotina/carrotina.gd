extends BaseEncounter

const CARROT_PROJECTILE_SCENE := preload("res://encounters/carrotina/carrot_projectile.tscn")
const CARROT_BOMB_SCENE := preload("res://encounters/carrotina/carrot_bomb.tscn")
const CEILING_RABBIT_SCENE := preload("res://encounters/carrotina/ceiling_rabbit.tscn")
const CARROTINA_PORTRAIT_FRAMES := preload("res://overworld/assets/carrotina_portrait/carrotina_portrait_frames.tres")
const CARROT_ITEM := preload("res://items/carrot_of_sight.tres")

const PHASE_DURATION := 6.0

const SHOT_INTERVALS := [0.6, 0.45]
const SHOT_SPEEDS := [150.0, 190.0]
const BOMB_INTERVALS := [2.3, 1.9]
const BURST_INTERVALS := [0.0, 2.6]
const PHASE_END_LINES := [
	"Carrotina's roots dig in deeper, bracing for another wave.",
	"The burrow behind her rustles — she isn't done yet.",
]

@onready var spawner: BulletSpawner = %BulletSpawner

var phase_count := 0
var _rabbit_intro_shown := false
var _in_phase := false
var _phase_timer := 0.0
var _shot_timer := 0.0
var _bomb_timer := 0.0
var _burst_timer := 0.0
var _pending_choice: Callable = Callable()

func _ready() -> void:
	super._ready()
	MusicPlayer.ensure_playing_for_dev_test()
	won.connect(_on_cleared)
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(enemy_sprite, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
	spawner.arena = arena
	spawner.projectile_scene = CARROT_PROJECTILE_SCENE
	spawner.projectile_damage = 2

func resync_rhythm() -> void:
	if MusicPlayer.is_playing() and enemy_sprite.sprite_frames == data.enemy_frames:
		RhythmSync.resync_if_needed(enemy_sprite, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

func _current_tier() -> int:
	return mini(phase_count, 1)

func _process(delta: float) -> void:
	if not _in_phase:
		return
	_phase_timer += delta
	var tier: int = _current_tier()

	_shot_timer += delta
	if _shot_timer >= SHOT_INTERVALS[tier]:
		_shot_timer = 0.0
		spawner.projectile_speed = SHOT_SPEEDS[tier]
		if randi() % 2 == 0:
			spawner.spawn_from_top()
		else:
			spawner.spawn_from_side()

	if BOMB_INTERVALS[tier] > 0.0:
		_bomb_timer += delta
		if _bomb_timer >= BOMB_INTERVALS[tier]:
			_bomb_timer = 0.0
			_spawn_carrot_bomb()

	if BURST_INTERVALS[tier] > 0.0:
		_burst_timer += delta
		if _burst_timer >= BURST_INTERVALS[tier]:
			_burst_timer = 0.0
			spawner.projectile_speed = SHOT_SPEEDS[tier]
			spawner.spawn_ring_burst(randi_range(6, 8))

	if _phase_timer >= PHASE_DURATION:
		_end_phase()

func _spawn_carrot_bomb() -> void:
	var b: Rect2 = arena.bounds
	var margin := 18.0
	var bomb: CarrotBomb = CARROT_BOMB_SCENE.instantiate()
	bomb.position = Vector2(
		b.position.x + randf_range(margin, b.size.x - margin),
		b.position.y + randf_range(margin, b.size.y - margin)
	)
	bomb.damage = 3
	arena.bullets.add_child(bomb)

func _spawn_ceiling_rabbit() -> void:
	var b: Rect2 = arena.bounds
	var rabbit: CeilingRabbit = CEILING_RABBIT_SCENE.instantiate()
	rabbit.position = Vector2(b.position.x + b.size.x / 2.0, b.position.y + 14.0)
	rabbit.velocity = Vector2(80.0, 0)
	rabbit.damage = 2
	rabbit.bounds = b
	arena.bullets.add_child(rabbit)

func _start_intro_choices() -> void:
	_choose(["I honestly don't know that myself.", "All I know is that I need to fight you."], _on_first_choice)

func _on_first_choice(index: int) -> void:
	var line: String = "\"I honestly don't know that myself,\" you say." if index == 0 else "\"All I know is that I need to fight you,\" you say."
	say([line, "\"So you want to fight, huh!\" Carrotina snaps, leaves bristling with rage."], _show_second_choice)

func _show_second_choice() -> void:
	_choose(["I want to see beyond this land."], _on_second_choice)

func _on_second_choice(_index: int) -> void:
	say([
		"\"I want to see beyond this land,\" you say.",
		"\"Then earn that sight — you'll have to defeat me first,\" she says, roots tensing as she readies herself.",
	], _start_player_turn)

func _choose(options: Array[String], handler: Callable) -> void:
	_pending_choice = handler
	menu.set_options(options)
	menu.show_menu()

func _handle_menu_option(index: int) -> void:
	if _pending_choice.is_valid():
		var handler := _pending_choice
		_pending_choice = Callable()
		handler.call(index)
		return
	match index:
		0: _do_strike()
		1: _do_item()

func _do_strike() -> void:
	var dmg: int = randi_range(6, 11)
	deal_damage_to_enemy(dmg)
	if enemy_hp <= 0:
		say(["Carrotina staggers, roots buckling beneath her!"], _play_transform_ending)
	else:
		say(["You strike Carrotina! %d damage." % dmg], _begin_phase)

func _do_item() -> void:
	open_item_menu(_on_item_used, _start_player_turn)

func _on_item_used(item: ItemData, healed: int) -> void:
	say(["You used %s. Healed %d HP." % [item.item_name, healed]], _begin_phase)

func _begin_phase() -> void:
	start_enemy_phase()
	_phase_timer = 0.0
	_shot_timer = 0.0
	_bomb_timer = 0.0
	_burst_timer = 0.0
	_in_phase = true
	if _current_tier() == 1:
		_spawn_ceiling_rabbit()

func _end_phase() -> void:
	_in_phase = false
	end_enemy_phase(_on_phase_resolved)

func _on_phase_resolved() -> void:
	phase_count += 1
	if _current_tier() == 1 and not _rabbit_intro_shown:
		_rabbit_intro_shown = true
		_show_rabbit_intro()
	else:
		say([PHASE_END_LINES[_current_tier()]], _start_player_turn)

func _show_rabbit_intro() -> void:
	enemy_sprite.sprite_frames = CARROTINA_PORTRAIT_FRAMES
	enemy_sprite.play("rabbit_idle")
	say([
		"Carrotina reaches behind her into the burrow...",
		"...and pulls out a wriggling rabbit, cradling it gently for a moment.",
		"\"You've made her very cross,\" she mutters. \"She helps me clear out pests, you know.\"",
	], _end_rabbit_intro)

func _end_rabbit_intro() -> void:
	enemy_sprite.sprite_frames = data.enemy_frames
	enemy_sprite.play("idle")
	resync_rhythm()
	say(["Carrotina lets the rabbit bound off into the shadows above."], _start_player_turn)

func _play_transform_ending() -> void:
	await get_tree().create_timer(0.9).timeout
	enemy_sprite.play("transform")
	await enemy_sprite.animation_finished
	Inventory.add_item(CARROT_ITEM)
	say([
		"Carrotina's form softens, roots unwinding, her color draining into one bright shape...",
		"...until only a single, gleaming carrot remains where she stood.",
		"You pick it up. Somehow, it feels like it's watching you back.",
	], _win)

func _on_cleared() -> void:
	GameSettings.mark_carrotina_defeated()
