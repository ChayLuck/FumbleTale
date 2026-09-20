extends Node2D

const SPAWN_POSITION := Vector2(60, 420)
const RETURN_SCENE := "res://forest/forest.tscn"

@onready var player: CharacterBody2D = %Player
@onready var flag_zone: Area2D = %FlagZone
@onready var end_screen: EndScreen = %EndScreen
@onready var vines: Array = get_tree().get_nodes_in_group("ivy_vine")

func _ready() -> void:
	MusicPlayer.ensure_playing_for_dev_test()
	flag_zone.body_entered.connect(_on_flag_reached)
	for vine in vines:
		vine.caught_player.connect(_on_player_caught)

func _on_player_caught() -> void:
	_respawn_player()

func _respawn_player() -> void:
	player.position = SPAWN_POSITION
	player.velocity = Vector2.ZERO

func _on_flag_reached(body: Node2D) -> void:
	if body != player:
		return
	GameSettings.mark_ivy_cleared()
	player.set_physics_process(false)
	end_screen.option_selected.connect(_on_end_screen_continue, CONNECT_ONE_SHOT)
	end_screen.show_screen("LEVEL CLEAR!", ["Continue"], [true])

func _on_end_screen_continue(_index: int) -> void:
	get_tree().change_scene_to_file(RETURN_SCENE)
