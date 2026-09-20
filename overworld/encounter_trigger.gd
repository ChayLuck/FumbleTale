class_name EncounterTrigger
extends Area2D

signal triggered

var _consumed := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(_body: Node2D) -> void:
	if _consumed:
		return
	_consumed = true
	triggered.emit()
