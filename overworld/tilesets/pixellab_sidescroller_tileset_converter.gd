extends SceneTree

var output_path = "combined_sidescroller_terrain.tres"
var tile_size = 0
var terrains = {}
var tiles = []
var atlas_cols = 5

var corner_layout = [
	"ss/sw", "ss/ww", "ss/ws", "ww/ws", "ww/sw",
	"sw/sw", "ww/ww", "ws/ws", "ws/ww", "sw/ww",
	"sw/ss", "ww/ss", "ws/ss", "ws/sw", "sw/ws",
	"ww/ww", "ss/ss", "", "", ""
]

func _init():
	var args = OS.get_cmdline_args()
	var json_path = ""
	var png_path = ""
	for i in range(args.size()):
		if args[i].ends_with(".json"):
			json_path = args[i]
		elif args[i].ends_with(".png"):
			png_path = args[i]
		elif args[i].ends_with(".tres"):
			output_path = args[i]

	if json_path == "" or png_path == "":
		print("Usage: godot --headless -s pixellab_sidescroller_tileset_converter.gd metadata.json image.png [output.tres]")
		quit()
		return

	load_tileset_pair(json_path, png_path)
	if tiles.is_empty():
		print("No tiles loaded")
		quit()
		return

	create_tileset()
	add_collision_polygons_via_api(output_path)
	print("Created: %s (terrains: %s)" % [output_path, ", ".join(terrains.values())])
	quit()

func load_tileset_pair(json_path: String, png_path: String):
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("Invalid JSON")
		return
	file.close()
	var metadata = json.data

	var sprite_sheet = Image.new()
	if sprite_sheet.load(png_path) != OK:
		print("Failed to load PNG")
		return

	if tile_size == 0:
		var size = metadata.tileset_data.tile_size
		tile_size = size.width

	var lower_name = metadata.metadata.terrain_prompts.lower
	var upper_name = metadata.metadata.terrain_prompts.upper

	var upper_id = get_terrain_id(upper_name)
	var lower_id = get_terrain_id(lower_name)

	var wang_tiles = {}
	for i in range(metadata.tileset_data.tiles.size()):
		var tile = metadata.tileset_data.tiles[i]
		var corners = tile.corners
		var box = tile.bounding_box
		var width = int(box.width)
		var height = int(box.height)
		var x = int(box.x)
		var y = int(box.y)

		var tile_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
		tile_image.blit_rect(sprite_sheet, Rect2i(x, y, width, height), Vector2i.ZERO)

		var nw = 1 if corners.NW == "upper" else 0
		var ne = 1 if corners.NE == "upper" else 0
		var sw = 1 if corners.SW == "upper" else 0
		var se = 1 if corners.SE == "upper" else 0
		var wang_idx = nw * 8 + ne * 4 + sw * 2 + se

		wang_tiles[wang_idx] = {
			"image": tile_image,
			"corners": [
				upper_id if nw == 1 else lower_id,
				upper_id if ne == 1 else lower_id,
				upper_id if sw == 1 else lower_id,
				upper_id if se == 1 else lower_id
			]
		}

	for pattern in corner_layout:
		if pattern == "":
			tiles.append(null)
		else:
			var parts = pattern.split("/")
			var top = parts[0]
			var bottom = parts[1]
			var nw = 1 if top[0] == "s" else 0
			var ne = 1 if top[1] == "s" else 0
			var sw = 1 if bottom[0] == "s" else 0
			var se = 1 if bottom[1] == "s" else 0
			var wang_idx = nw * 8 + ne * 4 + sw * 2 + se
			if wang_tiles.has(wang_idx):
				tiles.append(wang_tiles[wang_idx])
			else:
				tiles.append(null)

func get_terrain_id(name: String) -> int:
	for id in terrains:
		if terrains[id] == name:
			return id
	var id = terrains.size()
	terrains[id] = name
	return id

func create_tileset():
	atlas_cols = 5
	var cols = atlas_cols
	var rows = (tiles.size() + cols - 1) / cols
	var atlas = Image.create(cols * tile_size, rows * tile_size, false, Image.FORMAT_RGBA8)

	for i in range(tiles.size()):
		if tiles[i] == null:
			continue
		var img = tiles[i].image
		var x = (i % cols) * tile_size
		var y = (i / cols) * tile_size
		atlas.blit_rect(img, Rect2i(0, 0, tile_size, tile_size), Vector2i(x, y))

	atlas.save_png(output_path.replace(".tres", "_atlas.png"))

	var tile_defs = []
	for i in range(tiles.size()):
		if tiles[i] == null:
			continue
		var x = i % cols
		var y = i / cols
		var corners = tiles[i].corners
		tile_defs.append("%d:%d/0 = 0" % [x, y])
		tile_defs.append("%d:%d/0/terrain_set = 0" % [x, y])
		tile_defs.append("%d:%d/0/terrains_peering_bit/top_left_corner = %d" % [x, y, corners[0]])
		tile_defs.append("%d:%d/0/terrains_peering_bit/top_right_corner = %d" % [x, y, corners[1]])
		tile_defs.append("%d:%d/0/terrains_peering_bit/bottom_left_corner = %d" % [x, y, corners[2]])
		tile_defs.append("%d:%d/0/terrains_peering_bit/bottom_right_corner = %d" % [x, y, corners[3]])

	var terrain_defs = []
	var terrain_colors = {}
	for i in range(tiles.size()):
		if tiles[i] == null:
			continue
		var corners = tiles[i].corners
		if corners[0] == corners[1] and corners[1] == corners[2] and corners[2] == corners[3]:
			var terrain_id = corners[0]
			if not terrain_colors.has(terrain_id):
				var img = tiles[i].image
				terrain_colors[terrain_id] = img.get_pixel(img.get_width() / 2, img.get_height() / 2)

	for id in terrains:
		var name = terrains[id]
		var color = terrain_colors.get(id, Color(0.5, 0.5, 0.5))
		terrain_defs.append('terrain_set_0/terrain_%d/name = "%s"' % [id, name])
		terrain_defs.append('terrain_set_0/terrain_%d/color = Color(%f, %f, %f, 1)' % [id, color.r, color.g, color.b])

	var bytes = []
	for b in atlas.get_data():
		bytes.append(str(b))

	var tres = '[gd_resource type="TileSet" load_steps=4 format=3]\n\n'
	tres += '[sub_resource type="Image" id="Image_1"]\n'
	tres += 'data = {\n'
	tres += '"data": PackedByteArray(%s),\n' % ", ".join(bytes)
	tres += '"format": "RGBA8",\n'
	tres += '"height": %d,\n' % atlas.get_height()
	tres += '"mipmaps": false,\n'
	tres += '"width": %d\n' % atlas.get_width()
	tres += '}\n\n'
	tres += '[sub_resource type="ImageTexture" id="ImageTexture_1"]\n'
	tres += 'image = SubResource("Image_1")\n\n'
	tres += '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_1"]\n'
	tres += 'texture = SubResource("ImageTexture_1")\n'
	tres += 'texture_region_size = Vector2i(%d, %d)\n' % [tile_size, tile_size]
	tres += "\n".join(tile_defs) + '\n\n'
	tres += '[resource]\n'
	tres += 'tile_size = Vector2i(%d, %d)\n' % [tile_size, tile_size]
	tres += 'physics_layer_0/collision_layer = 1\n'
	tres += 'physics_layer_0/collision_mask = 1\n'
	tres += 'terrain_set_0/mode = 0\n'
	tres += "\n".join(terrain_defs) + '\n'
	tres += 'sources/0 = SubResource("TileSetAtlasSource_1")\n'

	var file = FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(tres)
	file.close()

func add_collision_polygons_via_api(path: String):
	var ts: TileSet = load(path)
	if ts == null:
		print("Could not reload %s to add collision" % path)
		return
	if ts.get_physics_layers_count() == 0:
		ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 1)

	var source: TileSetAtlasSource = ts.get_source(0)
	var half = tile_size / 2.0
	var quadrant_points = [
		PackedVector2Array([Vector2(-half, -half), Vector2(-half, 0), Vector2(0, 0), Vector2(0, -half)]),
		PackedVector2Array([Vector2(0, -half), Vector2(0, 0), Vector2(half, 0), Vector2(half, -half)]),
		PackedVector2Array([Vector2(-half, 0), Vector2(-half, half), Vector2(0, half), Vector2(0, 0)]),
		PackedVector2Array([Vector2(0, 0), Vector2(0, half), Vector2(half, half), Vector2(half, 0)]),
	]

	for i in range(tiles.size()):
		if tiles[i] == null:
			continue
		var x = i % atlas_cols
		var y = i / atlas_cols
		var corners = tiles[i].corners
		var td: TileData = source.get_tile_data(Vector2i(x, y), 0)
		if td == null:
			continue
		var poly_idx = 0
		for corner_i in range(4):
			if corners[corner_i] >= 1:
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, poly_idx, quadrant_points[corner_i])
				poly_idx += 1

	var err = ResourceSaver.save(ts, path)
	if err != OK:
		print("Failed to re-save %s with collision, error %d" % [path, err])
