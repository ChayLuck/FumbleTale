extends Node

const DEFAULT_SCENE := "res://origin_room/origin_room.tscn"
const AUTOSAVE_PATH := "user://autosave.json"
const MANUAL_SLOT_COUNT := 6
const THUMB_SIZE := Vector2i(160, 120)

var _pending_position = null
var _pending_aphrodite_teleport := false
var _pending_dj_victory_teleport := false

func save_autosave() -> void:
	_write_json(AUTOSAVE_PATH, _capture_state())

func load_autosave() -> bool:
	return _load_from_path(AUTOSAVE_PATH)

func has_autosave() -> bool:
	return FileAccess.file_exists(AUTOSAVE_PATH)

func save_manual_slot(index: int, screenshot: Image) -> void:
	var data := _capture_state()
	data["timestamp"] = Time.get_datetime_string_from_system(false, true)
	_write_json(_manual_json_path(index), data)
	if screenshot:
		var thumb := screenshot.duplicate()
		thumb.resize(THUMB_SIZE.x, THUMB_SIZE.y, Image.INTERPOLATE_LANCZOS)
		thumb.save_png(_manual_png_path(index))

func load_manual_slot(index: int) -> bool:
	return _load_from_path(_manual_json_path(index))

func has_manual_slot(index: int) -> bool:
	return FileAccess.file_exists(_manual_json_path(index))

func has_any_manual_save() -> bool:
	for i in MANUAL_SLOT_COUNT:
		if has_manual_slot(i):
			return true
	return false

func get_manual_slot_info(index: int) -> Dictionary:
	if not has_manual_slot(index):
		return {"has_data": false, "texture": null, "timestamp": ""}
	var parsed: Variant = _read_json(_manual_json_path(index))
	var texture: ImageTexture = null
	var png_path := _manual_png_path(index)
	if FileAccess.file_exists(png_path):
		var img := Image.load_from_file(png_path)
		if img:
			texture = ImageTexture.create_from_image(img)
	return {
		"has_data": true,
		"texture": texture,
		"timestamp": parsed.get("timestamp", "") if typeof(parsed) == TYPE_DICTIONARY else "",
	}

func has_save() -> bool:
	return has_autosave() or has_any_manual_save()

func load_most_recent() -> bool:
	var best_path := ""
	var best_time := -1
	if has_autosave():
		best_path = AUTOSAVE_PATH
		best_time = FileAccess.get_modified_time(AUTOSAVE_PATH)
	for i in MANUAL_SLOT_COUNT:
		var path := _manual_json_path(i)
		if FileAccess.file_exists(path):
			var t := FileAccess.get_modified_time(path)
			if t > best_time:
				best_time = t
				best_path = path
	if best_path == "":
		return false
	return _load_from_path(best_path)

func mark_pending_position(pos: Vector2) -> void:
	_pending_position = {"x": pos.x, "y": pos.y}

func has_pending_position() -> bool:
	return _pending_position != null

func consume_pending_position() -> Vector2:
	var pos := Vector2(_pending_position["x"], _pending_position["y"])
	_pending_position = null
	return pos

func mark_pending_aphrodite_teleport() -> void:
	_pending_aphrodite_teleport = true

func consume_pending_aphrodite_teleport() -> bool:
	var flag := _pending_aphrodite_teleport
	_pending_aphrodite_teleport = false
	return flag

func mark_pending_dj_victory_teleport() -> void:
	_pending_dj_victory_teleport = true

func consume_pending_dj_victory_teleport() -> bool:
	var flag := _pending_dj_victory_teleport
	_pending_dj_victory_teleport = false
	return flag

func _capture_state() -> Dictionary:
	var data := {
		"scene_path": get_tree().current_scene.scene_file_path,
		"inventory": _serialize_inventory(),
		"relationships": Relationships.serialize(),
		"music_track": MusicPlayer.current_track_id,
	}
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var player: Node2D = players[0]
		data["player_position"] = {"x": player.position.x, "y": player.position.y}
	return data

func _load_from_path(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = _read_json(path)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	_restore_inventory(parsed.get("inventory", {}))
	Relationships.deserialize(parsed.get("relationships", {}))
	_pending_position = parsed.get("player_position", null)
	var track_id: String = parsed.get("music_track", "")
	if track_id != "":
		MusicPlayer.play_track(track_id, 0.5)
	get_tree().change_scene_to_file(parsed.get("scene_path", DEFAULT_SCENE))
	return true

func _write_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _read_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	return JSON.parse_string(text)

func _manual_json_path(index: int) -> String:
	return "user://manual_save_%d.json" % index

func _manual_png_path(index: int) -> String:
	return "user://manual_save_%d.png" % index

func _serialize_inventory() -> Dictionary:
	var result := {}
	for item in Inventory.get_items():
		result[item.resource_path] = Inventory.get_count(item)
	return result

func _restore_inventory(data: Dictionary) -> void:
	Inventory.clear()
	for path in data:
		var item := load(path) as ItemData
		if item:
			Inventory.add_item(item, int(data[path]))
