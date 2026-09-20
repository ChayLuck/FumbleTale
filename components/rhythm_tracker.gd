class_name RhythmTracker
extends Node

signal beat

@export var bpm: float = 128.0
var running := false

var _accumulator := 0.0

func start() -> void:
	running = true
	_accumulator = 0.0

func stop() -> void:
	running = false

func _process(delta: float) -> void:
	if not running:
		return
	_accumulator += delta
	var interval: float = 60.0 / bpm
	while _accumulator >= interval:
		_accumulator -= interval
		beat.emit()
