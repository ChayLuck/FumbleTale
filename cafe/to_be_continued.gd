extends Node2D

const MAIN_MENU_SCENE := "res://menu/main_menu.tscn"

var _alpha := 0.0

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "_alpha", 1.0, 2.0)
	tween.tween_callback(queue_redraw)

func _process(_delta: float) -> void:
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	elif event is InputEventMouseButton and event.pressed:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 1))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, 230), "This is it for now", HORIZONTAL_ALIGNMENT_CENTER, 640, 28, Color(1, 1, 1, _alpha))
	draw_string(font, Vector2(0, 420), "press anything to continue", HORIZONTAL_ALIGNMENT_CENTER, 640, 14, Color(0.6, 0.6, 0.6, _alpha))
