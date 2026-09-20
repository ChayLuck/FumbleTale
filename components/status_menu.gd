class_name StatusMenu
extends Node2D

signal closed

enum Tab { INVENTORY, RELATIONSHIPS }

@onready var inventory_menu: InventoryMenu = %InventoryMenu
@onready var relationship_panel: RelationshipPanel = %RelationshipPanel

var active := false
var _tab: Tab = Tab.INVENTORY

func _ready() -> void:
	inventory_menu.cancelled.connect(_on_child_cancelled)
	relationship_panel.cancelled.connect(_on_child_cancelled)

func open() -> void:
	active = true
	visible = true
	_tab = Tab.INVENTORY
	_show_tab()

func close() -> void:
	active = false
	visible = false
	inventory_menu.close()
	relationship_panel.close()

func _show_tab() -> void:
	if _tab == Tab.INVENTORY:
		relationship_panel.close()
		inventory_menu.open(true)
	else:
		inventory_menu.close()
		relationship_panel.open()
	queue_redraw()

func _on_child_cancelled() -> void:
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_TAB:
		closed.emit()
		return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		_tab = Tab.RELATIONSHIPS if _tab == Tab.INVENTORY else Tab.INVENTORY
		_show_tab()

func _draw() -> void:
	if not active:
		return
	var font := ThemeDB.fallback_font
	var label: String = "[Inventory] | Relationships" if _tab == Tab.INVENTORY else "Inventory | [Relationships]"
	draw_string(font, Vector2(120, 410), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.6, 0.6))
