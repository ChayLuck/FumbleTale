extends Node2D

const DIALOGUE_JSON := "res://origin_room/origin_room_dialogue.json"

@onready var player: OverworldPlayer = %Player
@onready var dialog_box: DialogBox = %DialogBox
@onready var player_bust: AnimatedSprite2D = %PlayerBust
@onready var desk_zone: InteractZone = %DeskZone

var _runner: DialogueRunner
var _dialogue_tree: DialogueTree
var _desk_dialogue_started := false

func _ready() -> void:
	_dialogue_tree = DialogueTree.load_from_json(DIALOGUE_JSON)

func _unhandled_input(event: InputEvent) -> void:
	if _desk_dialogue_started or not desk_zone.is_player_inside or dialog_box.active:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_on_desk_triggered()

func _on_desk_triggered() -> void:
	_desk_dialogue_started = true
	player.set_physics_process(false)
	player.velocity = Vector2.ZERO
	player_bust.visible = true
	_runner = DialogueRunner.new(dialog_box)
	_runner.node_entered.connect(_on_dialogue_node)
	_runner.finished.connect(_on_dialogue_finished)
	_runner.start(_dialogue_tree)

func _on_dialogue_node(node: DialogueNode) -> void:
	if node.event == "candy_eaten":
		MusicPlayer.play_track("beat2")
		RhythmSync.sync_sprite_to_bpm(player_bust, &"idle", 8, MusicPlayer.get_bpm("beat2"))

func _on_dialogue_finished() -> void:
	_start_hallucination()

func _start_hallucination() -> void:
	player_bust.animation_finished.connect(_on_hallucination_finished, CONNECT_ONE_SHOT)
	player_bust.play("hallucinate")

func _on_hallucination_finished() -> void:
	_play_puff_transition()

func _play_puff_transition() -> void:
	_screen_shake(10.0, 0.4)
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_property(self, "modulate", Color(0.05, 0.0, 0.08), 0.8)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://overworld/overworld_room.tscn")
	)

func _screen_shake(strength: float = 6.0, duration: float = 0.2) -> void:
	var tween := create_tween()
	var steps := 5
	for _i in steps:
		var offset := Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(self, "position", offset, duration / steps)
	tween.tween_property(self, "position", Vector2.ZERO, duration / steps)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0))
