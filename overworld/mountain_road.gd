extends Node2D

const DIALOGUE_JSON := "res://overworld/mountain_road_dialogue.json"
const NEXT_SCENE := "res://cafe/to_be_continued.tscn"
const ICE_ENCOUNTER := "res://encounters/hisame_ice/hisame_ice.tscn"
const LEVEL_WIDTH := 2560
const OBEDIENT_DOG_TAG := "obedient_dog"

const HISAME_IDLE_FRAMES := preload("res://school/assets/hisame_frames.tres")
const HISAME_ANGRY_FRAMES := preload("res://overworld/assets/hisame_portraits/hisame_angry_frames.tres")
const HISAME_SLAP_FRAMES := preload("res://overworld/assets/hisame_portraits/hisame_slap_frames.tres")

@onready var player: SidescrollerPlayer = %Player
@onready var hisame_companion: SidescrollerCompanion = $YSortEntities/HisameCompanion
@onready var exit_trigger: EncounterTrigger = %ExitTrigger
@onready var trigger_1: EncounterTrigger = %Trigger1
@onready var trigger_2: EncounterTrigger = %Trigger2
@onready var trigger_3: EncounterTrigger = %Trigger3
@onready var dialog_box: DialogBox = %DialogBox
@onready var menu: EncounterMenu = %EncounterMenu
@onready var hisame_bust: AnimatedSprite2D = %HisameBust

var _runner: DialogueRunner
var _dialogue_tree: DialogueTree
var _last_node_id: String = ""

func _ready() -> void:
	_dialogue_tree = DialogueTree.load_from_json(DIALOGUE_JSON)
	MusicPlayer.ensure_playing_for_dev_test()
	hisame_companion.track(player)
	exit_trigger.triggered.connect(_on_exit_triggered)
	trigger_1.triggered.connect(_on_trigger_1)
	trigger_2.triggered.connect(_on_trigger_2)
	trigger_3.triggered.connect(_on_trigger_3)
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
	player.resume_input()

func resync_rhythm() -> void:
	if not MusicPlayer.is_playing() or hisame_bust.sprite_frames != HISAME_IDLE_FRAMES:
		return
	RhythmSync.resync_if_needed(hisame_bust, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))

func _on_dialogue_node(node: DialogueNode) -> void:
	_last_node_id = node.id
	match node.event:
		"bust_idle":
			hisame_bust.sprite_frames = HISAME_IDLE_FRAMES
			hisame_bust.play("idle")
			if MusicPlayer.is_playing():
				RhythmSync.resync_if_needed(hisame_bust, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
		"bust_angry":
			hisame_bust.sprite_frames = HISAME_ANGRY_FRAMES
			hisame_bust.play("idle")
		"bust_slap":
			hisame_bust.sprite_frames = HISAME_SLAP_FRAMES
			hisame_bust.play("idle")
		"obedient_ending":
			Relationships.add_heart("Hisame", 1)
			Relationships.add_tag("Hisame", OBEDIENT_DOG_TAG)
		"apologize_ending":
			Relationships.add_heart("Hisame", 1)

func _run_road_dialogue(start_id: String, on_finished: Callable) -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	hisame_bust.visible = true
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.node_entered.connect(_on_dialogue_node)
	_runner.finished.connect(on_finished)
	_runner.start(_dialogue_tree, start_id)

func _on_trigger_1() -> void:
	_run_road_dialogue("trigger_1", _end_road_dialogue)

func _on_trigger_2() -> void:
	_run_road_dialogue("trigger_2", _end_road_dialogue)

func _on_trigger_3() -> void:
	_run_road_dialogue("trigger_3", _on_trigger_3_finished)

func _on_trigger_3_finished() -> void:
	if _last_node_id == "t3_defiant":
		_go_to_ice_encounter()
	else:
		_end_road_dialogue()

func _go_to_ice_encounter() -> void:
	get_tree().change_scene_to_file(ICE_ENCOUNTER)

func _end_road_dialogue() -> void:
	hisame_bust.visible = false
	player.resume_input()

func _on_exit_triggered() -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.finished.connect(_on_exit_dialogue_finished)
	_runner.start(_dialogue_tree, "exit_line")

func _on_exit_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)
