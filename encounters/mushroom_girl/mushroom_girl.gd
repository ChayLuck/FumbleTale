extends Node2D

const SPAWN_POSITION := Vector2(60, 420)
const RETURN_SCENE := "res://forest/forest.tscn"

@onready var player: CharacterBody2D = %Player
@onready var fall_death_zone: Area2D = %FallDeathZone
@onready var flag_zone: Area2D = %FlagZone
@onready var end_screen: EndScreen = %EndScreen

func _ready() -> void:
	MusicPlayer.ensure_playing_for_dev_test()
	player.died.connect(_on_player_died)
	fall_death_zone.body_entered.connect(_on_fall_death)
	flag_zone.body_entered.connect(_on_flag_reached)

func _on_player_died() -> void:
	_respawn_player()

func _on_fall_death(body: Node2D) -> void:
	if body == player:
		_respawn_player()

func _respawn_player() -> void:
	player.position = SPAWN_POSITION
	player.velocity = Vector2.ZERO

func _on_flag_reached(body: Node2D) -> void:
	if body != player:
		return
	GameSettings.mark_mushroom_girl_cleared()
	player.set_physics_process(false)
	end_screen.option_selected.connect(_on_end_screen_continue, CONNECT_ONE_SHOT)
	end_screen.show_screen("LEVEL CLEAR!", ["Continue"], [true])

func _on_end_screen_continue(_index: int) -> void:
	get_tree().change_scene_to_file(RETURN_SCENE)
