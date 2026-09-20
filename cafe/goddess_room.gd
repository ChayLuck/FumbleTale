extends Node2D

const DIALOGUE_JSON := "res://cafe/goddess_room_dialogue.json"
const FOLLOWUP_DELAY := 30.0
const BORING_ROOM_SCENE := "res://cafe/boring_room.tscn"
const APHRODITE_TEXT_COLOR := Color(1.0, 0.6, 0.85)
const PLAYER_TEXT_COLOR := Color(0.95, 0.95, 0.98)

@onready var player: OverworldPlayer = %Player
@onready var aphrodite_trigger: EncounterTrigger = %AphroditeTrigger
@onready var dialog_box: DialogBox = %DialogBox
@onready var menu: EncounterMenu = %EncounterMenu
@onready var aphrodite_bust: AnimatedSprite2D = %AphroditeBust
@onready var aphrodite_sprite: AnimatedSprite2D = %AphroditeSprite
@onready var name_label: NameLabel = %NameLabel
@onready var door_sprite: Sprite2D = %DoorSprite
@onready var door: RoomDoor = %BoringRoomDoor

var _runner: DialogueRunner
var _last_node_id: String = ""
var _dialogue_tree: DialogueTree
var _followup_timer: Timer

func _ready() -> void:
	_dialogue_tree = DialogueTree.load_from_json(DIALOGUE_JSON)
	MusicPlayer.ensure_playing_for_dev_test()
	aphrodite_trigger.triggered.connect(_on_aphrodite_triggered)
	door_sprite.visible = false
	door.monitoring = false
	if MusicPlayer.is_playing():
		var bpm: float = MusicPlayer.get_bpm(MusicPlayer.current_track_id)
		RhythmSync.sync_sprite_to_bpm(aphrodite_bust, &"idle", 5, bpm)
		RhythmSync.sync_sprite_to_bpm(aphrodite_sprite, &"idle", 5, bpm)
	if GameSettings.goddess_room_door_unlocked and not GameSettings.goddess_room_door_closed:
		_reveal_door()
	if SaveSystem.consume_pending_aphrodite_teleport():
		aphrodite_trigger.monitoring = false
		GameSettings.mark_goddess_room_door_closed()
		door_sprite.visible = false
		door.monitoring = false
		player.position = aphrodite_trigger.position + Vector2(0, 40)
		_begin_dialogue()
		_run_dialogue("task_offer")
	elif SaveSystem.consume_pending_dj_victory_teleport():
		aphrodite_trigger.monitoring = false
		player.position = aphrodite_trigger.position + Vector2(0, 40)
		_begin_dialogue()
		_run_dialogue("carrot_delivered")

func resync_rhythm() -> void:
	if not MusicPlayer.is_playing():
		return
	var bpm: float = MusicPlayer.get_bpm(MusicPlayer.current_track_id)
	RhythmSync.resync_if_needed(aphrodite_bust, &"idle", 5, bpm)
	RhythmSync.resync_if_needed(aphrodite_sprite, &"idle", 5, bpm)

func _begin_dialogue() -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	aphrodite_bust.visible = true
	name_label.set_character_name("Aphrodite")

func _end_dialogue() -> void:
	aphrodite_bust.visible = false
	name_label.set_character_name("")
	player.set_physics_process(true)

func _on_dialogue_node(node: DialogueNode) -> void:
	_last_node_id = node.id
	match node.event:
		"say_aphrodite":
			dialog_box.text_color = APHRODITE_TEXT_COLOR
		"say_player":
			dialog_box.text_color = PLAYER_TEXT_COLOR

func _run_dialogue(start_id: String) -> void:
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.node_entered.connect(_on_dialogue_node)
	_runner.finished.connect(_on_dialogue_finished)
	_runner.start(_dialogue_tree, start_id)

func _on_dialogue_finished() -> void:
	match _last_node_id:
		"thanks_ending":
			GameSettings.mark_aphrodite_greeting_done()
			_end_dialogue()
			_start_followup_timer()
		"task_forest_teleport":
			GameSettings.mark_aphrodite_greeting_done()
			get_tree().change_scene_to_file("res://forest/forest.tscn")
		"followup_end":
			_end_dialogue()
			GameSettings.mark_goddess_room_door_unlocked()
			_reveal_door()
		"carrot_delivered_end":
			get_tree().change_scene_to_file("res://school/classroom.tscn")
		_:
			_end_dialogue()

func _on_aphrodite_triggered() -> void:
	_begin_dialogue()
	_run_dialogue("greeting_repeat" if GameSettings.aphrodite_greeting_done else "greeting")

func _start_followup_timer() -> void:
	if GameSettings.goddess_room_door_unlocked:
		return
	_followup_timer = Timer.new()
	_followup_timer.wait_time = FOLLOWUP_DELAY
	_followup_timer.one_shot = true
	add_child(_followup_timer)
	_followup_timer.timeout.connect(_on_followup_timer_timeout)
	_followup_timer.start()

func _on_followup_timer_timeout() -> void:
	if dialog_box.active or GameSettings.goddess_room_door_unlocked:
		return
	_begin_dialogue()
	_run_dialogue("followup_start")

func _reveal_door() -> void:
	door_sprite.visible = true
	door.monitoring = true

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.08, 0.04, 0.06))
