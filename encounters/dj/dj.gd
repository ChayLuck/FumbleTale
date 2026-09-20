extends BaseEncounter

const CELL_SIZE := 44.0
const GRID_COL_X: Array[float] = [232.0, 276.0, 320.0, 364.0, 408.0]
const ROW_Y: Array[float] = [210.0, 254.0, 298.0, 342.0, 386.0, 430.0]
const PLAYER_ROW_INDEX := 5
const PLAYER_Y := 430.0
const COL_EDGES: Array[float] = [210.0, 254.0, 298.0, 342.0, 386.0, 430.0]
const ROW_EDGES: Array[float] = [188.0, 232.0, 276.0, 320.0, 364.0, 408.0, 452.0]
const BASE_BOUNDS := Rect2(210.0, 188.0, 220.0, 264.0)
const SNAP_DURATION := 0.07

const PUNCHABLE_DAMAGE := 5
const PUNCHABLE_CHANCE := 0.35
const REGULAR_DAMAGE := 2
const IDLE_FRAME_COUNT := 20
const BEATS_PER_LOOP := 2.0

@onready var rhythm: RhythmTracker = %RhythmTracker
@onready var beat_kick: BeatKick = %BeatKick
@onready var grid_overlay: Node2D = %GridOverlay

var _note_scene := preload("res://encounters/dj/assets/note.tscn")
var _punchable_texture := preload("res://encounters/dj/assets/note_punchable.png")
var _dodge_avatar_frames := preload("res://encounters/dj/assets/player_dodge_frames.tres")
var _beat_count := 0
var _player_col := 2
var _snap_tween: Tween

func _ready() -> void:
	super._ready()
	MusicPlayer.ensure_playing_for_dev_test()
	won.connect(_on_won)
	player_hp_changed.connect(_on_player_hp_changed)
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(enemy_sprite, &"idle", IDLE_FRAME_COUNT, MusicPlayer.get_bpm(MusicPlayer.current_track_id), BEATS_PER_LOOP)
	rhythm.bpm = MusicPlayer.get_bpm(MusicPlayer.current_track_id) if MusicPlayer.is_playing() else 120.0
	rhythm.beat.connect(_on_beat)
	arena.bounds = BASE_BOUNDS
	arena.soul.grid_locked = true
	arena.soul.get_node("AnimatedSprite2D").sprite_frames = _dodge_avatar_frames
	grid_overlay.col_edges = COL_EDGES
	grid_overlay.row_edges = ROW_EDGES
	grid_overlay.player_row_index = PLAYER_ROW_INDEX
	grid_overlay.visible = false

func resync_rhythm() -> void:
	if MusicPlayer.is_playing():
		RhythmSync.resync_if_needed(enemy_sprite, &"idle", IDLE_FRAME_COUNT, MusicPlayer.get_bpm(MusicPlayer.current_track_id), BEATS_PER_LOOP)

func _start_player_turn() -> void:
	_past_intro = true
	hud.set_enemy_hp_visible(true)
	_refresh_screen_mode()
	arena.bounds = BASE_BOUNDS
	start_enemy_phase()
	_player_col = 2
	arena.soul.position = Vector2(GRID_COL_X[_player_col], PLAYER_Y)
	_beat_count = 0
	grid_overlay.visible = true
	grid_overlay.queue_redraw()
	rhythm.start()

func _unhandled_input(event: InputEvent) -> void:
	if state != State.ENEMY_PHASE:
		return
	if event.is_action_pressed("ui_accept"):
		_try_punch()
	elif event.is_action_pressed("ui_right"):
		_move_col(1)
	elif event.is_action_pressed("ui_left"):
		_move_col(-1)

func _move_col(delta: int) -> void:
	_player_col = clampi(_player_col + delta, 0, GRID_COL_X.size() - 1)
	var target := Vector2(GRID_COL_X[_player_col], PLAYER_Y)
	if _snap_tween:
		_snap_tween.kill()
	_snap_tween = create_tween()
	_snap_tween.tween_property(arena.soul, "position", target, SNAP_DURATION)

func _try_punch() -> void:
	var target_x: float = GRID_COL_X[_player_col]
	for child in arena.bullets.get_children():
		if child is Projectile and child.punchable and absf(child.position.x - target_x) < 1.0 and _row_index(child.position.y) == PLAYER_ROW_INDEX - 1:
			child.queue_free()
			deal_damage_to_enemy(PUNCHABLE_DAMAGE)
			if enemy_hp <= 0:
				_finish(true)
			return

func _row_index(y: float) -> int:
	return int(round((y - ROW_Y[0]) / CELL_SIZE))

func _on_player_hp_changed(current: int, _max_hp: int) -> void:
	if current <= 0 and state == State.ENEMY_PHASE:
		_finish(false)

func _finish(did_win: bool) -> void:
	rhythm.stop()
	arena.end_phase()
	if did_win:
		_win()
	else:
		_lose()

func _on_won() -> void:
	GameSettings.mark_dj_defeated()
	SaveSystem.mark_pending_dj_victory_teleport()

func _on_beat() -> void:
	if state != State.ENEMY_PHASE:
		return
	_beat_count += 1
	if _beat_count % 2 == 1:
		beat_kick.kick()
	else:
		beat_kick.tick()
	_advance_bullets()
	_spawn_note(randf() < PUNCHABLE_CHANCE)

func _advance_bullets() -> void:
	for child in arena.bullets.get_children():
		if child is Projectile:
			child.position.y += CELL_SIZE
			if child.position.y > ROW_Y[PLAYER_ROW_INDEX] + 1.0:
				child.queue_free()

func _spawn_note(punchable: bool) -> void:
	var col: int = randi() % GRID_COL_X.size()
	var spawn_pos := Vector2(GRID_COL_X[col], ROW_Y[0])
	var bullet := arena.spawn_bullet(_note_scene, spawn_pos, Vector2.ZERO, REGULAR_DAMAGE, false, punchable)
	if punchable:
		bullet.get_node("Sprite2D").texture = _punchable_texture
