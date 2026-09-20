class_name Classroom
extends Node2D

const NEXT_STOP := "res://cafe/to_be_continued.tscn"
const HISAME_ROAD_STOP := "res://overworld/mountain_road.tscn"
const HISAME_DOG_TAG := "hisame_dog"
const NAZUNA_FRIEND_TAG := "nazuna_friend"
const CHERRY_TAG := "cherry_bound"
const CHILLS_TAG := "chills"
const BORING_TAG := "boring"
const RUDE_TAG := "rude"
const KIND_TAG := "kind"
const CHAD_TAG := "chad"

const DIALOGUE_JSON := "res://school/classroom_dialogue.json"
const HISAME_IDLE_FRAMES := preload("res://school/assets/hisame_frames.tres")
const HISAME_DISTANT_FRAMES := preload("res://school/assets/hisame_distant_frames.tres")
const HISAME_NAILS_FRAMES := preload("res://school/assets/hisame_nails_frames.tres")
const HISAME_LAUGH_FRAMES := preload("res://school/assets/hisame_laugh_frames.tres")

@onready var dialog_box: DialogBox = %DialogBox
@onready var menu: EncounterMenu = %EncounterMenu
@onready var hisame_sprite: AnimatedSprite2D = %HisameSprite
@onready var nazuna_sprite: AnimatedSprite2D = %NazunaSprite
@onready var cherry_sprite: AnimatedSprite2D = %CherrySprite
@onready var name_label: NameLabel = %NameLabel

var _runner: DialogueRunner
var _last_node_id: String = ""
var _dialogue_tree: DialogueTree

func _ready() -> void:
	_dialogue_tree = DialogueTree.load_from_json(DIALOGUE_JSON)
	MusicPlayer.ensure_playing_for_dev_test()
	hisame_sprite.visible = false
	nazuna_sprite.visible = false
	cherry_sprite.visible = false
	AnimPacing.apply(hisame_sprite)
	AnimPacing.apply(nazuna_sprite)
	AnimPacing.apply(cherry_sprite)
	if MusicPlayer.is_playing():
		var bpm: float = MusicPlayer.get_bpm(MusicPlayer.current_track_id)
		RhythmSync.sync_sprite_to_bpm(hisame_sprite, &"idle", 5, bpm)
		RhythmSync.sync_sprite_to_bpm(nazuna_sprite, &"idle", 5, bpm)
		RhythmSync.sync_sprite_to_bpm(cherry_sprite, &"idle", 5, bpm)
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.node_entered.connect(_on_dialogue_node)
	_runner.finished.connect(_on_dialogue_finished)
	_runner.start(_dialogue_tree)

func resync_rhythm() -> void:
	if not MusicPlayer.is_playing():
		return
	var bpm: float = MusicPlayer.get_bpm(MusicPlayer.current_track_id)
	if hisame_sprite.sprite_frames == HISAME_IDLE_FRAMES:
		RhythmSync.resync_if_needed(hisame_sprite, &"idle", 5, bpm)
	RhythmSync.resync_if_needed(nazuna_sprite, &"idle", 5, bpm)
	RhythmSync.resync_if_needed(cherry_sprite, &"idle", 5, bpm)

func _on_dialogue_node(node: DialogueNode) -> void:
	_last_node_id = node.id
	if node.speaker != "":
		name_label.set_character_name(node.speaker)
	match node.event:
		"show_hisame":
			hisame_sprite.visible = true
		"hisame_distant":
			hisame_sprite.sprite_frames = HISAME_DISTANT_FRAMES
			hisame_sprite.play("idle")
		"hisame_nails":
			hisame_sprite.sprite_frames = HISAME_NAILS_FRAMES
			hisame_sprite.play("idle")
		"nails_chills_reaction":
			Relationships.add_tag("Hisame", CHILLS_TAG)
			hisame_sprite.sprite_frames = HISAME_LAUGH_FRAMES
			hisame_sprite.play("idle")
		"nails_boring_reaction":
			Relationships.add_tag("Hisame", BORING_TAG)
		"end_monologue":
			hisame_sprite.sprite_frames = HISAME_IDLE_FRAMES
			hisame_sprite.play("idle")
			if MusicPlayer.is_playing():
				RhythmSync.resync_if_needed(hisame_sprite, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
		"become_dog":
			Relationships.add_heart("Hisame", 1)
			Relationships.add_tag("Hisame", HISAME_DOG_TAG)
		"show_nazuna":
			hisame_sprite.visible = false
			nazuna_sprite.visible = true
		"tag_rude":
			Relationships.add_tag("Nazuna", RUDE_TAG)
		"tag_kind":
			Relationships.add_tag("Nazuna", KIND_TAG)
		"tag_chad":
			Relationships.add_tag("Nazuna", CHAD_TAG)
		"nazuna_success":
			Relationships.add_heart("Nazuna", 1)
			Relationships.add_tag("Nazuna", NAZUNA_FRIEND_TAG)
		"show_cherry":
			nazuna_sprite.visible = false
			cherry_sprite.visible = true
		"cherry_end":
			Relationships.add_heart("Cherry", 1)
			Relationships.add_tag("Cherry", CHERRY_TAG)

func _on_dialogue_finished() -> void:
	if _last_node_id == "work_accept":
		get_tree().change_scene_to_file(HISAME_ROAD_STOP)
	else:
		get_tree().change_scene_to_file(NEXT_STOP)
