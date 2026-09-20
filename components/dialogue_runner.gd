class_name DialogueRunner
extends RefCounted

signal node_entered(node: DialogueNode)
signal finished

var _dialog_box: DialogBox
var _menu: EncounterMenu
var _tree: DialogueTree
var _current: DialogueNode

func _init(dialog_box: DialogBox, menu: EncounterMenu = null) -> void:
	_dialog_box = dialog_box
	_menu = menu
	_dialog_box.finished.connect(_on_dialog_finished)
	if _menu != null:
		_menu.option_selected.connect(_on_option_selected)

func start(tree: DialogueTree, start_id: String = "") -> void:
	_tree = tree
	_goto(start_id if start_id != "" else tree.start_id)

func _goto(id: String) -> void:
	if id == "":
		_current = null
		finished.emit()
		return
	var node := _tree.find_node(id)
	if node == null:
		push_error("DialogueRunner: unknown node id '%s'" % id)
		_current = null
		finished.emit()
		return
	_current = node
	node_entered.emit(node)
	_dialog_box.show_lines(node.lines)

func _on_dialog_finished() -> void:
	if _current == null:
		return
	if _current.options.is_empty():
		_goto(_current.next_id)
		return
	if _menu == null:
		push_error("DialogueRunner: node '%s' has options but no EncounterMenu was given" % _current.id)
		return
	var labels: Array[String] = []
	for option in _current.options:
		labels.append(option.label)
	_menu.set_options(labels)
	_menu.show_menu()

func _on_option_selected(index: int) -> void:
	if _current == null:
		return
	_menu.hide_menu()
	_goto(_current.options[index].next_id)
