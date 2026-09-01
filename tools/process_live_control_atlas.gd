@tool
extends SceneTree
## Deterministically converts the approved reference-only state atlas into small
## runtime RGBA controls. The source's neutral checkerboard is never shipped.

const SOURCE := "res://docs/art/printforge-physical-ui-spike-20260830/live-correction-r1/physical-control-state-atlas-v1.png"
const OUTPUT := "res://assets/ui/physical_ui/live-correction-r1/controls"
const KINDS := ["wide_parchment_tab", "binding_tab", "square_stud", "tall_index", "lever", "token"]
const STATES := ["normal", "focused", "pressed", "disabled"]

func _init() -> void:
	var source := Image.new()
	if source.load(SOURCE) != OK:
		push_error("Could not load live control atlas: %s" % SOURCE)
		quit(1)
		return
	var cleaned := _remove_checkerboard(source)
	for row in KINDS.size():
		for column in STATES.size():
			var x0 := int(floor(float(column) * cleaned.get_width() / STATES.size()))
			var x1 := int(floor(float(column + 1) * cleaned.get_width() / STATES.size()))
			var y0 := int(floor(float(row) * cleaned.get_height() / KINDS.size()))
			var y1 := int(floor(float(row + 1) * cleaned.get_height() / KINDS.size()))
			var cell := cleaned.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
			cell.convert(Image.FORMAT_RGBA8)
			cell = _keep_center_component(cell)
			var directory := "%s/%s" % [OUTPUT, KINDS[row]]
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
			var path := "%s/%s.png" % [directory, STATES[column]]
			if cell.save_png(path) != OK:
				push_error("Could not save control slice: %s" % path)
				quit(1)
				return
	print("PASS: processed live control atlas %dx%d into %d RGBA slices" % [source.get_width(), source.get_height(), KINDS.size() * STATES.size()])
	quit(0)

func _remove_checkerboard(source: Image) -> Image:
	var output := source.duplicate()
	output.convert(Image.FORMAT_RGBA8)
	for y in output.get_height():
		for x in output.get_width():
			var color: Color = output.get_pixel(x, y)
			var high_luminance: bool = (color.r + color.g + color.b) / 3.0 >= 0.72
			var near_neutral: bool = maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b)) <= 0.045
			if high_luminance and near_neutral:
				output.set_pixel(x, y, Color(color.r, color.g, color.b, 0.0))
	# Feather only transparent checkerboard-adjacent pixels. This keeps opaque
	# parchment/brass pixels intact while removing hard matte stair-steps.
	var feathered := output.duplicate()
	for y in range(1, output.get_height() - 1):
		for x in range(1, output.get_width() - 1):
			if output.get_pixel(x, y).a > 0.0:
				continue
			var neighbors := [output.get_pixel(x - 1, y), output.get_pixel(x + 1, y), output.get_pixel(x, y - 1), output.get_pixel(x, y + 1)]
			var ink := Color(0, 0, 0, 0.0)
			var count := 0
			for sample in neighbors:
				if sample.a > 0.65:
					ink += sample
					count += 1
			if count > 0:
				ink /= float(count)
				ink.a = 0.22
				feathered.set_pixel(x, y, ink)
	return feathered

func _keep_center_component(cell: Image) -> Image:
	# The reference atlas has uneven editorial gutters. A rectangular row slice can
	# catch the next object's edge, so retain the opaque connected component nearest
	# the intended cell center and discard neighbor leakage before runtime export.
	var width := cell.get_width(); var height := cell.get_height()
	var start := Vector2i(-1, -1); var best_distance := INF
	var center := Vector2(float(width - 1) * 0.5, float(height - 1) * 0.5)
	for y in height:
		for x in width:
			if cell.get_pixel(x, y).a <= 0.50: continue
			var distance := Vector2(x, y).distance_squared_to(center)
			if distance < best_distance:
				best_distance = distance; start = Vector2i(x, y)
	if start.x < 0: return cell
	var keep := {}
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty():
		var current: Vector2i = pending.pop_back()
		var key := "%d:%d" % [current.x, current.y]
		if keep.has(key): continue
		if current.x < 0 or current.y < 0 or current.x >= width or current.y >= height: continue
		if cell.get_pixelv(current).a <= 0.50: continue
		keep[key] = true
		pending.append_array([current + Vector2i.LEFT, current + Vector2i.RIGHT, current + Vector2i.UP, current + Vector2i.DOWN])
	var output := cell.duplicate()
	for y in height:
		for x in width:
			var key := "%d:%d" % [x, y]
			if not keep.has(key):
				var color: Color = output.get_pixel(x, y); color.a = 0.0; output.set_pixel(x, y, color)
	return output
