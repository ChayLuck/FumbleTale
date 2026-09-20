extends Node2D

const DIALOGUE_JSON := "res://overworld/hisame_camp_dialogue.json"
const HISAME_IDLE_FRAMES := preload("res://school/assets/hisame_frames.tres")
const NEXT_SCENE := "res://cafe/to_be_continued.tscn"

@onready var player: OverworldPlayer = %Player
@onready var fireplace_trigger: EncounterTrigger = %FireplaceTrigger
@onready var fire_sprite: AnimatedSprite2D = %FireSprite
@onready var dialog_box: DialogBox = %DialogBox
@onready var menu: EncounterMenu = %EncounterMenu
@onready var hisame_bust: AnimatedSprite2D = %HisameBust

var _runner: DialogueRunner
var _dialogue_tree: DialogueTree

func _ready() -> void:
	_dialogue_tree = DialogueTree.load_from_json(DIALOGUE_JSON)
	MusicPlayer.ensure_playing_for_dev_test()
	fireplace_trigger.triggered.connect(_on_fireplace_triggered)
	hisame_bust.visible = false
	AnimPacing.apply(hisame_bust)
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(hisame_bust, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.finished.connect(_on_intro_finished)
	_runner.start(_dialogue_tree, "intro")

func _on_intro_finished() -> void:
	player.set_physics_process(true)

func resync_rhythm() -> void:
	if MusicPlayer.is_playing():
		RhythmSync.resync_if_needed(hisame_bust, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

func _on_fireplace_triggered() -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.node_entered.connect(_on_dialogue_node)
	_runner.finished.connect(_on_fireplace_dialogue_finished)
	_runner.start(_dialogue_tree, "fireplace_line")

func _on_fireplace_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)

func _on_dialogue_node(node: DialogueNode) -> void:
	match node.event:
		"fire_lit":
			fire_sprite.visible = true
			fire_sprite.play("idle")
		"show_hisame_bust":
			hisame_bust.sprite_frames = HISAME_IDLE_FRAMES
			hisame_bust.play("idle")
			hisame_bust.visible = true
