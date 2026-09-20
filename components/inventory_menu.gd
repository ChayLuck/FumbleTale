class_name InventoryMenu
extends Node2D

signal item_selected(item: ItemData)
signal cancelled

const BOX := Rect2(120, 80, 400, 320)

var items: Array[ItemData] = []
var index := 0
var active := false
var _selectable := true

func open(view_only: bool = false, only_consumable: bool = false) -> void:
	items = Inventory.get_items()
	if only_consumable:
		items = items.filter(func(item: ItemData) -> bool: return item.consumable)
	_selectable = not view_only
	index = 0
	active = true
	visible = true
	queue_redraw()

func close() -> void:
	active = false
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event.is_action_pressed("ui_cancel"):
		cancelled.emit()
		return
	if items.is_empty():
		if event.is_action_pressed("ui_accept"):
			cancelled.emit()
		return
	if event.is_action_pressed("ui_up"):
		index = (index - 1 + items.size()) % items.size()
		queue_redraw()
	elif event.is_action_pressed("ui_down"):
		index = (index + 1) % items.size()
		queue_redraw()
	elif event.is_action_pressed("ui_accept"):
		if _selectable:
			item_selected.emit(items[index])
		else:
			cancelled.emit()

func _draw() -> void:
	if not active:
		return
	draw_rect(Rect2(0, 0, 640, 480), Color(0, 0, 0, 0.6))
	draw_rect(BOX, Color(0, 0, 0, 1))
	draw_rect(BOX, Color(1, 1, 1), false, 3.0)
	var font := ThemeDB.fallback_font
	draw_string(font, BOX.position + Vector2(16, 30), "Inventory", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1))
	if items.is_empty():
		draw_string(font, BOX.position + Vector2(16, 70), "Empty.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.7, 0.7, 0.7))
		return
	for i in items.size():
		var item: ItemData = items[i]
		var color := Color(1, 1, 0) if i == index else Color(1, 1, 1)
		var row_y: float = 70 + i * 28
		var text_x := 16.0
		if item.icon:
			var icon_size := 22.0
			draw_texture_rect(item.icon, Rect2(BOX.position + Vector2(text_x, row_y - icon_size + 5), Vector2(icon_size, icon_size)), false)
			text_x += icon_size + 6.0
		var label := "%s x%d" % [item.item_name, Inventory.get_count(item)]
		draw_string(font, BOX.position + Vector2(text_x, row_y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
	var current: ItemData = items[index]
	draw_string(font, BOX.position + Vector2(16, BOX.size.y - 20), current.description, HORIZONTAL_ALIGNMENT_LEFT, BOX.size.x - 32, 14, Color(0.8, 0.8, 0.8))
