class_name EncounterHud
extends Node2D

@export var enemy_name_color := Color(1, 1, 1)
@export var enemy_bar_color := Color(0.8, 0.1, 0.1)

@export var enemy_name_pos := Vector2(40, 60)
@export var enemy_bar_pos := Vector2(40, 75)
@export var enemy_bar_size := Vector2(200, 12)
@export var player_hp_pos := Vector2(400, 60)

var _enemy_name := ""
var _player_hp := 0
var _player_max_hp := 1
var _enemy_hp := 0
var _enemy_max_hp := 1
var _show_enemy_hp := false

func set_enemy_name(new_name: String) -> void:
	_enemy_name = new_name
	queue_redraw()

func set_player_hp(current: int, max_hp: int) -> void:
	_player_hp = current
	_player_max_hp = max_hp
	queue_redraw()

func set_enemy_hp(current: int, max_hp: int) -> void:
	_enemy_hp = current
	_enemy_max_hp = max_hp
	queue_redraw()

func set_enemy_hp_visible(shown: bool) -> void:
	_show_enemy_hp = shown
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, enemy_name_pos, _enemy_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, enemy_name_color)
	if _show_enemy_hp:
		draw_rect(Rect2(enemy_bar_pos, enemy_bar_size), Color(0.3, 0.3, 0.3))
		if _enemy_max_hp > 0:
			var ratio: float = float(_enemy_hp) / float(_enemy_max_hp)
			draw_rect(Rect2(enemy_bar_pos, Vector2(enemy_bar_size.x * ratio, enemy_bar_size.y)), enemy_bar_color)
	draw_string(font, player_hp_pos, "LV 1  HP %d/%d" % [_player_hp, _player_max_hp], HORIZONTAL_ALIGNMENT_RIGHT, 200, 16, Color(1, 1, 0))
