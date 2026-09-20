extends Node2D

const DIALOGUE_JSON := "res://overworld/overworld_room_dialogue.json"
const SUBWOOFER_SCENE := "res://encounters/melodic_subwoofer/melodic_subwoofer.tscn"
const CYCLOPS_SCENE := "res://encounters/cathode_cyclops/cathode_cyclops.tscn"
const NEXT_SCENE := "res://cafe/goddess_room.tscn"
const KEY_FRAGMENT_SOUND := preload("res://items/key_fragment_sound.tres")
const KEY_FRAGMENT_DISPLAY := preload("res://items/key_fragment_display.tres")

@onready var player: OverworldPlayer = %Player
@onready var subwoofer_trigger: EncounterTrigger = %SubwooferTrigger
@onready var subwoofer_sprite: AnimatedSprite2D = %SubwooferSprite
@onready var cyclops_trigger: EncounterTrigger = %CyclopsTrigger
@onready var cyclops_sprite: AnimatedSprite2D = %CyclopsSprite
@onready var door_trigger: EncounterTrigger = %DoorTrigger
@onready var door_sprite: Sprite2D = %DoorSprite
@onready var dialog_box: DialogBox = %DialogBox
@onready var cake_zone: InteractZone = %CakeTrigger
@onready var cake_bust: AnimatedSprite2D = %CakeBust

var _synced: Array[Dictionary] = []
var _runner: DialogueRunner
var _dialogue_tree: DialogueTree

func _ready() -> void:
	_dialogue_tree = DialogueTree.load_from_json(DIALOGUE_JSON)
	MusicPlayer.ensure_playing_for_dev_test()
	subwoofer_trigger.triggered.connect(_on_subwoofer_triggered)
	cyclops_trigger.triggered.connect(_on_cyclops_triggered)
	cake_bust.visible = false
	if GameSettings.subwoofer_defeated:
		subwoofer_sprite.stop()
		subwoofer_sprite.modulate = Color(0.5, 0.5, 0.5)
	elif MusicPlayer.is_playing():
		_sync_to_beat(subwoofer_sprite, &"idle", 5)
	if GameSettings.cyclops_defeated:
		cyclops_sprite.stop()
		cyclops_sprite.modulate = Color(0.5, 0.5, 0.5)
	elif MusicPlayer.is_playing():
		_sync_to_beat(cyclops_sprite, &"idle", 5)
	if MusicPlayer.is_playing():
		RhythmSync.sync_sprite_to_bpm(cake_bust, &"idle", 5, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
		_synced.append({"sprite": cake_bust, "anim_name": &"idle", "frame_count": 5})
	_reclaim_lost_key_fragments()
	door_trigger.monitoring = false
	door_sprite.visible = false
	if _has_both_key_fragments():
		door_trigger.monitoring = true
		door_sprite.visible = true
		door_trigger.triggered.connect(_on_door_triggered)
	if SaveSystem.has_pending_position():
		player.position = SaveSystem.consume_pending_position()

func _sync_to_beat(sprite: AnimatedSprite2D, anim_name: StringName, frame_count: int) -> void:
	sprite.sprite_frames = sprite.sprite_frames.duplicate(true)
	RhythmSync.sync_sprite_to_bpm(sprite, anim_name, frame_count, MusicPlayer.get_bpm(MusicPlayer.current_track_id))
	_synced.append({"sprite": sprite, "anim_name": anim_name, "frame_count": frame_count})

func resync_rhythm() -> void:
	if not MusicPlayer.is_playing():
		return
	var bpm: float = MusicPlayer.get_bpm(MusicPlayer.current_track_id)
	for entry in _synced:
		RhythmSync.resync_if_needed(entry["sprite"], entry["anim_name"], entry["frame_count"], bpm)

func _on_subwoofer_triggered() -> void:
	if GameSettings.subwoofer_defeated:
		_run("subwoofer_free", _on_free_dialogue_finished)
	else:
		_run("subwoofer_intro", _on_subwoofer_intro_finished)

func _on_subwoofer_intro_finished() -> void:
	get_tree().change_scene_to_file(SUBWOOFER_SCENE)

func _on_cyclops_triggered() -> void:
	if GameSettings.cyclops_defeated:
		_run("cyclops_free", _on_free_dialogue_finished)
	else:
		_run("cyclops_intro", _on_cyclops_intro_finished)

func _on_cyclops_intro_finished() -> void:
	get_tree().change_scene_to_file(CYCLOPS_SCENE)

func _on_free_dialogue_finished() -> void:
	player.set_physics_process(true)

func _unhandled_input(event: InputEvent) -> void:
	if dialog_box.active:
		return
	if cake_zone.is_player_inside and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_cake_triggered()

func _on_cake_triggered() -> void:
	cake_bust.visible = true
	_run("cake", _on_cake_dialogue_finished)

func _on_cake_dialogue_finished() -> void:
	cake_bust.visible = false
	player.set_physics_process(true)

func _has_both_key_fragments() -> bool:
	return Inventory.get_count(KEY_FRAGMENT_SOUND) > 0 and Inventory.get_count(KEY_FRAGMENT_DISPLAY) > 0

func _reclaim_lost_key_fragments() -> void:
	if GameSettings.door_opened:
		return
	if GameSettings.subwoofer_defeated and Inventory.get_count(KEY_FRAGMENT_SOUND) <= 0:
		Inventory.add_item(KEY_FRAGMENT_SOUND)
	if GameSettings.cyclops_defeated and Inventory.get_count(KEY_FRAGMENT_DISPLAY) <= 0:
		Inventory.add_item(KEY_FRAGMENT_DISPLAY)

func _on_door_triggered() -> void:
	GameSettings.mark_door_opened()
	Inventory.remove_item(KEY_FRAGMENT_SOUND)
	Inventory.remove_item(KEY_FRAGMENT_DISPLAY)
	_run("door_open", _on_door_dialogue_finished)

func _on_door_dialogue_finished() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE)

func _run(start_id: String, on_finished: Callable) -> void:
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	_runner = DialogueRunner.new(dialog_box)
	_runner.finished.connect(on_finished)
	_runner.start(_dialogue_tree, start_id)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0.05, 0.05, 0.08))
