extends Node

signal changed(character: String)

const MAX_HEARTS := 5

var _hearts: Dictionary = {}
var _tags: Dictionary = {}

func add_heart(character: String, amount: int = 1) -> void:
	var current: int = _hearts.get(character, 0)
	_hearts[character] = clampi(current + amount, 0, MAX_HEARTS)
	changed.emit(character)

func get_hearts(character: String) -> int:
	return _hearts.get(character, 0)

func get_max_hearts() -> int:
	return MAX_HEARTS

func add_tag(character: String, tag: String) -> void:
	var tags: Array = _tags.get(character, [])
	if tag not in tags:
		tags.append(tag)
		_tags[character] = tags
		changed.emit(character)

func has_tag(character: String, tag: String) -> bool:
	var tags: Array = _tags.get(character, [])
	return tag in tags

func get_tracked_characters() -> Array[String]:
	var names: Array[String] = []
	for key in _hearts:
		if key not in names:
			names.append(key)
	for key in _tags:
		if key not in names:
			names.append(key)
	return names

func serialize() -> Dictionary:
	return {"hearts": _hearts.duplicate(true), "tags": _tags.duplicate(true)}

func deserialize(data: Dictionary) -> void:
	_hearts = (data.get("hearts", {}) as Dictionary).duplicate(true)
	_tags = (data.get("tags", {}) as Dictionary).duplicate(true)

func clear() -> void:
	_hearts.clear()
	_tags.clear()
