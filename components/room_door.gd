class_name RoomDoor
extends Area2D

@export var target_scene: String = ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D) -> void:
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
