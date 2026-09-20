extends Node2D

const DIALOGUE_JSON := "res://jungle/jungle_dialogue.json"
const CARROTINA_SCENE := "res://encounters/carrotina/carrotina.tscn"
const DJ_FIGHT_SCENE := "res://encounters/dj/dj.tscn"
const IDLE_FRAME_COUNT := 20
const BEATS_PER_LOOP := 2.0
const CARROTINA_SPRITE_FRAME_COUNT := 4
const CARROTINA_BUST_FRAME_COUNT := 5

@onready var player: OverworldPlayer = %Player
@onready var dj_trigger: EncounterTrigger = %DjTrigger
@onready var dj_sprite: AnimatedSprite2D = %DjSprite
@onready var bust: AnimatedSprite2D = %Bust
@onready var carrotina_trigger: EncounterTrigger = %CarrotinaTrigger
@onready var carrotina_sprite: AnimatedSprite2D = %CarrotinaSprite
@onready var carrotina_bust: AnimatedSprite2D = %CarrotinaBust
@onready var dialog_box: DialogBox = %DialogBox
@onready var menu: EncounterMenu = %EncounterMenu

var _runner: DialogueRunner
var _dialogue_tree: DialogueTree

func _ready() -> void:
	_dialogue_tree = DialogueTree.load_from_json(DIALOGUE_JSON)
	MusicPlayer.ensure_playing_for_dev_test()
	dj_trigger.triggered.connect(_on_dj_triggered)
	carrotina_trigger.triggered.connect(_on_carrotina_triggered)
	bust.visible = false
	carrotina_bust.visible = false
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(dj_sprite, &"idle", IDLE_FRAME_COUNT, MusicPlayer.get_bpm(MusicPlayer.current_track_id), BEATS_PER_LOOP)
	if GameSettings.carrotina_defeated:
		carrotina_sprite.stop()
		carrotina_sprite.modulate = Color(0.5, 0.5, 0.5)
	elif MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(carrotina_sprite, &"idle_south", CARROTINA_SPRITE_FRAME_COUNT, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

func resync_rhythm() -> void:
	if not MusicPlayer.is_playing():
		return
	var bpm: float = MusicPlayer.get_bpm(MusicPlayer.current_track_id)
	RhythmSync.resync_if_needed(dj_sprite, &"idle", IDLE_FRAME_COUNT, bpm, BEATS_PER_LOOP)
	if bust.visible:
		RhythmSync.resync_if_needed(bust, &"idle", IDLE_FRAME_COUNT, bpm, BEATS_PER_LOOP)
	RhythmSync.resync_if_needed(carrotina_sprite, &"idle_south", CARROTINA_SPRITE_FRAME_COUNT, bpm)
	if carrotina_bust.visible:
		RhythmSync.resync_if_needed(carrotina_bust, &"idle", CARROTINA_BUST_FRAME_COUNT, bpm)

func _on_dj_triggered() -> void:
	bust.visible = true
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(bust, &"idle", IDLE_FRAME_COUNT, MusicPlayer.get_bpm(MusicPlayer.current_track_id), BEATS_PER_LOOP)
	else:
		bust.play("idle")
	if not GameSettings.carrotina_defeated:
		_run("dj_carrot_block", _on_dj_free_finished)
	elif GameSettings.dj_defeated:
		_run("dj_free", _on_dj_free_finished)
	else:
		_run("dj_intro", _on_dj_dialogue_finished)

func _on_dj_dialogue_finished() -> void:
	bust.visible = false
	get_tree().change_scene_to_file(DJ_FIGHT_SCENE)

func _on_dj_free_finished() -> void:
	bust.visible = false
	player.set_physics_process(true)

func _on_carrotina_triggered() -> void:
	carrotina_bust.visible = true
	if GameSettings.carrotina_defeated:
		_run("carrotina_free", _on_carrotina_free_finished)
	else:
		_run("carrotina_intro", _on_carrotina_intro_finished)

func _on_carrotina_intro_finished() -> void:
	get_tree().change_scene_to_file(CARROTINA_SCENE)

func _on_carrotina_free_finished() -> void:
	carrotina_bust.visible = false
	player.set_physics_process(true)

func _run(start_id: String, on_finished: Callable) -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.finished.connect(on_finished)
	_runner.start(_dialogue_tree, start_id)
