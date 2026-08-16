extends SceneTree
## Deterministic local preprocessing for the supplied chroma atlas.
## Crops eight atlas cells, keys green without runtime masking, trims, and centers
## the seven authored armor parts on consistent transparent 512x512 canvases.

const SOURCE := "res://assets/armor/raw/armor_raw_print_atlas_v1.png"
const IDS := ["helm", "chest_plate", "leg_guards", "full_suit", "arcane_core", "shadow_cloak", "titan_plate"]
const CELL_W := 444
const CELL_ROWS := [Rect2i(0, 0, 1776, 444), Rect2i(0, 444, 1776, 443)]
const OUTPUT_SIZE := Vector2i(512, 512)

func _init() -> void:
	var atlas := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if atlas == null or atlas.is_empty():
		push_error("Armor atlas could not be loaded: %s" % SOURCE)
		quit(1)
		return
	for index in IDS.size():
		var row := index / 4
		var column := index % 4
		var row_rect: Rect2i = CELL_ROWS[row]
		var cell := atlas.get_region(Rect2i(column * CELL_W, row_rect.position.y, CELL_W, row_rect.size.y))
		cell.convert(Image.FORMAT_RGBA8)
		if cell.get_format() != Image.FORMAT_RGBA8:
			push_error("Armor source cell %s could not enter RGBA8 alpha processing." % IDS[index])
			quit(1)
			return
		key_green(cell)
		var bounds := alpha_bounds(cell)
		if bounds.size.x < 8 or bounds.size.y < 8:
			push_error("Armor atlas cell %s has no usable alpha content." % IDS[index])
			quit(1)
			return
		var trimmed := cell.get_region(bounds.grow(2).intersection(Rect2i(Vector2i.ZERO, cell.get_size())))
		var canvas := Image.create_empty(OUTPUT_SIZE.x, OUTPUT_SIZE.y, false, Image.FORMAT_RGBA8)
		var scale := minf(minf(440.0 / float(trimmed.get_width()), 440.0 / float(trimmed.get_height())), 1.0)
		if scale < 1.0: trimmed.resize(maxi(1, int(round(trimmed.get_width() * scale))), maxi(1, int(round(trimmed.get_height() * scale))), Image.INTERPOLATE_LANCZOS)
		canvas.blit_rect(trimmed, Rect2i(Vector2i.ZERO, trimmed.get_size()), Vector2i((OUTPUT_SIZE.x - trimmed.get_width()) / 2, OUTPUT_SIZE.y - 30 - trimmed.get_height()))
		if not _transparent_background_contract(canvas):
			push_error("Armor alpha contract failed for %s: matte survives in transparent probes." % IDS[index])
			quit(1)
			return
		# Runtime catalog mappings intentionally use versioned alpha assets, so a
		# regeneration writes those exact files instead of an unused intermediate.
		var output := "res://assets/armor/raw/%s_raw_print_alpha_v2.png" % IDS[index]
		var result := canvas.save_png(ProjectSettings.globalize_path(output))
		if result != OK:
			push_error("Could not save %s" % output)
			quit(1)
			return
		print("ARMOR_RAW %s %s" % [IDS[index], output])
	quit(0)

func key_green(image: Image) -> void:
	# The atlas is authored against a chroma matte. Remove only matte connected
	# to a cell edge, so dark seams inside an armor part remain opaque. Strong
	# green is also keyed globally for holes between printed plates.
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var queue: Array[Vector2i] = []
	for x in width:
		queue.append(Vector2i(x, 0)); queue.append(Vector2i(x, height - 1))
	for y in height:
		queue.append(Vector2i(0, y)); queue.append(Vector2i(width - 1, y))
	var cursor := 0
	while cursor < queue.size():
		var point := queue[cursor]; cursor += 1
		if point.x < 0 or point.y < 0 or point.x >= width or point.y >= height: continue
		var index := point.y * width + point.x
		if visited[index] != 0: continue
		visited[index] = 1
		var sample := image.get_pixel(point.x, point.y)
		if not _edge_matte_candidate(sample): continue
		image.set_pixel(point.x, point.y, _transparent_despill(sample))
		queue.append(point + Vector2i(1, 0)); queue.append(point + Vector2i(-1, 0))
		queue.append(point + Vector2i(0, 1)); queue.append(point + Vector2i(0, -1))
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if _strong_green(color): image.set_pixel(x, y, _transparent_despill(color))

func _edge_matte_candidate(color: Color) -> bool:
	var max_rgb := maxf(color.r, maxf(color.g, color.b))
	var dominance := color.g - maxf(color.r, color.b)
	# Neutral-black frame pixels are only removed when flood-connected to the edge.
	return (color.g > 0.08 and dominance > 0.025) or max_rgb < 0.14

func _strong_green(color: Color) -> bool:
	return color.g > 0.16 and color.g - maxf(color.r, color.b) > 0.09

func _transparent_despill(color: Color) -> Color:
	color.a = 0.0
	color.g = minf(color.g, maxf(color.r, color.b))
	return color

func alpha_bounds(image: Image) -> Rect2i:
	var min_x := image.get_width(); var min_y := image.get_height(); var max_x := -1; var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.03:
				min_x = mini(min_x, x); min_y = mini(min_y, y); max_x = maxi(max_x, x); max_y = maxi(max_y, y)
	if max_x < min_x: return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _transparent_background_contract(image: Image) -> bool:
	for probe in [Vector2i(0, 0), Vector2i(24, 24), Vector2i(256, 12), Vector2i(488, 24), Vector2i(16, 256), Vector2i(496, 256), Vector2i(128, 500), Vector2i(384, 500)]:
		if image.get_pixelv(probe).a > 0.03: return false
	return true
