class_name DialogueTree
extends Resource

@export var start_id: String = ""
@export var nodes: Array[DialogueNode] = []

func find_node(id: String) -> DialogueNode:
	for node in nodes:
		if node.id == id:
			return node
	return null

func validate() -> Array[String]:
	var errors: Array[String] = []
	if start_id == "":
		errors.append("start_id is empty")
	elif find_node(start_id) == null:
		errors.append("start_id '%s' has no matching node" % start_id)
	var seen_ids: Dictionary = {}
	for node in nodes:
		if node.id == "":
			errors.append("a node has no id")
			continue
		if seen_ids.has(node.id):
			errors.append("duplicate node id '%s'" % node.id)
		seen_ids[node.id] = true
		if node.next_id != "" and find_node(node.next_id) == null:
			errors.append("node '%s' has next_id '%s' with no matching node" % [node.id, node.next_id])
		for option in node.options:
			if option.next_id != "" and find_node(option.next_id) == null:
				errors.append("node '%s' option '%s' has next_id '%s' with no matching node" % [node.id, option.label, option.next_id])
	return errors

static func load_from_json(path: String) -> DialogueTree:
	var tree := DialogueTree.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueTree.load_from_json: could not open '%s' (%s)" % [path, error_string(FileAccess.get_open_error())])
		return tree

	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not (parsed is Dictionary):
		push_error("DialogueTree.load_from_json: '%s' is not valid JSON" % path)
		return tree

	var data: Dictionary = parsed
	tree.start_id = data.get("start_id", "")

	var nodes: Array[DialogueNode] = []
	for raw_node in data.get("nodes", []):
		var node := DialogueNode.new()
		node.id = raw_node.get("id", "")
		node.speaker = raw_node.get("speaker", "")
		node.event = raw_node.get("event", "")
		node.next_id = raw_node.get("next", "")

		var lines: Array[String] = []
		for line in raw_node.get("lines", []):
			lines.append(str(line))
		node.lines = lines

		var options: Array[DialogueOption] = []
		for raw_option in raw_node.get("options", []):
			var option := DialogueOption.new()
			option.label = raw_option.get("label", "")
			option.next_id = raw_option.get("next", "")
			options.append(option)
		node.options = options

		nodes.append(node)
	tree.nodes = nodes

	var errors := tree.validate()
	for error in errors:
		push_error("DialogueTree.load_from_json: %s (%s)" % [error, path])

	return tree
