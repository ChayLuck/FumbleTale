class_name EncounterData
extends Resource

@export var enemy_name: String = "Enemy"
@export var enemy_max_hp: int = 30
@export var player_max_hp: int = 20
@export var intro_lines: Array[String] = []
@export var intro_choices: Array[DialogueChoice] = []
@export var menu_labels: Array[String] = ["Strike", "Item"]
@export var theme_color: Color = Color(0.8, 0.8, 0.85)
@export var enemy_frames: SpriteFrames
@export var return_scene: String = "res://overworld/overworld_room.tscn"
