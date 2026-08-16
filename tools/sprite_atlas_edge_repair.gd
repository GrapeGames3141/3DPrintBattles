class_name SpriteAtlasEdgeRepair
extends RefCounted
## Offline-only alpha-component repair for the shipped 4x2 creature sheets.
## Runtime never invokes this: use clean_sprite_atlas_edges.gd before import.

const CELL := Vector2i(384, 512)
const FRAMES := 8
const ALPHA_LIMIT := 10

static func repair_sheet(path: String) -> Dictionary:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty() or image.get_size() != CELL * Vector2i(4, 2):
		return {"path":path, "error":"expected 1536x1024 RGBA sheet"}
	var before := hash_path(path)
	var frames: Array = []
	var total_removed_pixels := 0
	var total_removed_components := 0
	for frame in FRAMES:
		var origin := frame_origin(frame)
		var repaired := repair_cell(image.get_region(Rect2i(origin, CELL)))
		image.blit_rect(repaired.get("cell") as Image, Rect2i(Vector2i.ZERO, CELL), origin)
		var report: Dictionary = repaired.get("audit", {})
		report["frame"] = frame
		frames.append(report)
		total_removed_pixels += int(report.get("removed_edge_pixels", 0))
		total_removed_components += int(report.get("removed_edge_components", 0))
	if total_removed_pixels > 0 and image.save_png(ProjectSettings.globalize_path(path)) != OK:
		return {"path":path, "error":"could not save repaired PNG"}
	return {"path":path, "before_sha256":before, "after_sha256":hash_path(path), "removed_edge_pixels":total_removed_pixels, "removed_edge_components":total_removed_components, "frames":frames}

static func audit_sheet(path: String) -> Dictionary:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	var result := audit_image(image)
	result["path"] = path
	result["sha256"] = hash_path(path) if not result.has("error") else ""
	return result

static func audit_image(image: Image) -> Dictionary:
	if image == null or image.is_empty() or image.get_size() != CELL * Vector2i(4, 2):
		return {"error":"expected 1536x1024 RGBA sheet"}
	var frames: Array = []
	for frame in FRAMES:
		var report := audit_cell(image.get_region(Rect2i(frame_origin(frame), CELL)))
		report["frame"] = frame
		frames.append(report)
	return {"frames":frames}

static func repair_cell(cell: Image) -> Dictionary:
	cell.convert(Image.FORMAT_RGBA8)
	var pixels := cell.get_data()
	var components := components_for_pixels(pixels)
	var largest_index := largest_component_index(components)
	var removed_components := 0
	var removed_pixels := 0
	for index in components.size():
		var component: Dictionary = components[index]
		if index == largest_index or not bool(component.get("touches_edge", false)): continue
		removed_components += 1
		var points: PackedInt32Array = component.get("points", PackedInt32Array())
		for point in points:
			pixels[point * 4 + 3] = 0
			removed_pixels += 1
	cell.set_data(CELL.x, CELL.y, false, Image.FORMAT_RGBA8, pixels)
	var audit := audit_components(components, largest_index, removed_components, removed_pixels)
	return {"cell":cell, "audit":audit}

static func audit_cell(cell: Image) -> Dictionary:
	cell.convert(Image.FORMAT_RGBA8)
	var components := components_for_pixels(cell.get_data())
	return audit_components(components, largest_component_index(components), 0, 0)

static func audit_components(components: Array, largest_index: int, removed_components := 0, removed_pixels := 0) -> Dictionary:
	var alpha_pixels := 0
	var largest_pixels := 0
	var secondary_edge_components := 0
	for index in components.size():
		var component: Dictionary = components[index]
		var count := int(component.get("size", 0))
		alpha_pixels += count
		if index == largest_index: largest_pixels = count
		elif bool(component.get("touches_edge", false)): secondary_edge_components += 1
	return {"alpha_pixels":alpha_pixels, "largest_component_pixels":largest_pixels, "secondary_edge_components":secondary_edge_components, "removed_edge_components":removed_components, "removed_edge_pixels":removed_pixels}

static func largest_component_index(components: Array) -> int:
	var largest_index := -1
	var largest_size := 0
	for index in components.size():
		var count := int((components[index] as Dictionary).get("size", 0))
		if count > largest_size:
			largest_size = count
			largest_index = index
	return largest_index

static func components_for_pixels(pixels: PackedByteArray) -> Array:
	var visited := PackedByteArray()
	visited.resize(CELL.x * CELL.y)
	var components: Array = []
	for start in CELL.x * CELL.y:
		if visited[start] != 0 or pixels[start * 4 + 3] <= ALPHA_LIMIT: continue
		visited[start] = 1
		var queue := PackedInt32Array([start])
		var points := PackedInt32Array()
		var cursor := 0
		var touches_edge := false
		while cursor < queue.size():
			var point := queue[cursor]
			cursor += 1
			var x := point % CELL.x
			var y := point / CELL.x
			points.append(point)
			touches_edge = touches_edge or x == 0 or y == 0 or x == CELL.x - 1 or y == CELL.y - 1
			if x > 0: _enqueue_alpha(point - 1, pixels, visited, queue)
			if x < CELL.x - 1: _enqueue_alpha(point + 1, pixels, visited, queue)
			if y > 0: _enqueue_alpha(point - CELL.x, pixels, visited, queue)
			if y < CELL.y - 1: _enqueue_alpha(point + CELL.x, pixels, visited, queue)
		components.append({"points":points, "size":points.size(), "touches_edge":touches_edge})
	return components

static func _enqueue_alpha(point: int, pixels: PackedByteArray, visited: PackedByteArray, queue: PackedInt32Array) -> void:
	if visited[point] == 0 and pixels[point * 4 + 3] > ALPHA_LIMIT:
		visited[point] = 1
		queue.append(point)

static func frame_origin(frame: int) -> Vector2i:
	return Vector2i((frame % 4) * CELL.x, (frame / 4) * CELL.y)

static func hash_path(path: String) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(path)))
	return context.finish().hex_encode()
