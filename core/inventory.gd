extends Node

signal inventory_changed

var _counts: Dictionary = {}

func _ready() -> void:
	reset_to_starting_kit()

func reset_to_starting_kit() -> void:
	_counts.clear()
	add_item(preload("res://items/sandwich.tres"), 2)

func add_item(item: ItemData, amount: int = 1) -> void:
	_counts[item] = get_count(item) + amount
	inventory_changed.emit()

func remove_item(item: ItemData, amount: int = 1) -> bool:
	var current: int = get_count(item)
	if current < amount:
		return false
	current -= amount
	if current <= 0:
		_counts.erase(item)
	else:
		_counts[item] = current
	inventory_changed.emit()
	return true

func get_count(item: ItemData) -> int:
	return _counts.get(item, 0)

func clear() -> void:
	_counts.clear()
	inventory_changed.emit()

func get_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in _counts:
		result.append(item)
	return result
