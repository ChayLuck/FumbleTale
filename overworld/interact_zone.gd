class_name InteractZone
extends Area2D

var is_player_inside := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(_body: Node2D) -> void:
	is_player_inside = true

func _on_body_exited(_body: Node2D) -> void:
	is_player_inside = false
