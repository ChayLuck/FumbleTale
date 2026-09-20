extends Node2D

const DIALOGUE_JSON := "res://cafe/boring_room_dialogue.json"
const GODDESS_ROOM_SCENE := "res://cafe/goddess_room.tscn"
const LAMP_OFF_TINT := Color(0.35, 0.35, 0.4, 1)
const LAMP_ON_TINT := Color(1, 1, 1, 1)
const APHRODITE_TEXT_COLOR := Color(1.0, 0.6, 0.85)
const PLAYER_TEXT_COLOR := Color(0.95, 0.95, 0.98)

@onready var player: OverworldPlayer = %Player
@onready var dialog_box: DialogBox = %DialogBox
@onready var menu: EncounterMenu = %EncounterMenu
@onready var name_label: NameLabel = %NameLabel
@onready var aphrodite_bust: AnimatedSprite2D = %AphroditeBust
@onready var light_switch_zone: InteractZone = %LightSwitchZone
@onready var couch_zone: InteractZone = %CouchZone
@onready var phone_zone: InteractZone = %PhoneZone
@onready var lamp_sprite: Sprite2D = %LampSprite
@onready var couch_empty_sprite: Sprite2D = %CouchEmptySprite
@onready var couch_sitting_sprite: Sprite2D = %CouchSittingSprite
@onready var tv_sprite: Sprite2D = %TVSprite
@onready var phone_sprite: Sprite2D = %PhoneSprite
@onready var tv_collider_shape: CollisionShape2D = %TVColliderShape
@onready var couch_collider_shape: CollisionShape2D = %CouchColliderShape
@onready var phone_collider_shape: CollisionShape2D = %PhoneColliderShape

var _runner: DialogueRunner
var _last_node_id: String = ""
var _dialogue_tree: DialogueTree
var _light_on := false
var _sitting := false

func _ready() -> void:
	_dialogue_tree = DialogueTree.load_from_json(DIALOGUE_JSON)
	couch_empty_sprite.visible = false
	couch_sitting_sprite.visible = false
	tv_sprite.visible = false
	phone_sprite.visible = false
	aphrodite_bust.visible = false
	tv_collider_shape.disabled = true
	couch_collider_shape.disabled = true
	phone_collider_shape.disabled = true

func _unhandled_input(event: InputEvent) -> void:
	if dialog_box.active:
		return
	if not event.is_action_pressed("ui_accept"):
		return
	if _sitting:
		get_viewport().set_input_as_handled()
		_toggle_sitting()
		return
	if light_switch_zone.is_player_inside:
		get_viewport().set_input_as_handled()
		_toggle_light()
	elif _light_on and couch_zone.is_player_inside:
		get_viewport().set_input_as_handled()
		_toggle_sitting()
	elif _light_on and phone_zone.is_player_inside:
		get_viewport().set_input_as_handled()
		_start_phone_call()

func _toggle_light() -> void:
	_light_on = not _light_on
	couch_empty_sprite.visible = _light_on and not _sitting
	couch_sitting_sprite.visible = _light_on and _sitting
	tv_sprite.visible = _light_on
	phone_sprite.visible = _light_on
	tv_collider_shape.disabled = not _light_on
	couch_collider_shape.disabled = not _light_on
	phone_collider_shape.disabled = not _light_on
	lamp_sprite.modulate = LAMP_ON_TINT if _light_on else LAMP_OFF_TINT

func _toggle_sitting() -> void:
	_sitting = not _sitting
	player.set_physics_process(not _sitting)
	player.velocity = Vector2.ZERO
	player.visible = not _sitting
	couch_empty_sprite.visible = _light_on and not _sitting
	couch_sitting_sprite.visible = _light_on and _sitting

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

func _on_dialogue_finished() -> void:
	if _last_node_id == "teleport_line":
		SaveSystem.mark_pending_aphrodite_teleport()
		get_tree().change_scene_to_file(GODDESS_ROOM_SCENE)
	else:
		_end_dialogue()

func _start_phone_call() -> void:
	_begin_dialogue()
	_runner = DialogueRunner.new(dialog_box, menu)
	_runner.node_entered.connect(_on_dialogue_node)
	_runner.finished.connect(_on_dialogue_finished)
	_runner.start(_dialogue_tree)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 1))
