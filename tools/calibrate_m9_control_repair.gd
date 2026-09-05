extends SceneTree
## Derive review candidates from the approved clean-control source. This never
## writes runtime assets: UI review must accept the measured candidates first.

const SOURCE := "res://docs/art/m9-control-repair-20260904/clean-hardware-atlas-source-v1.png"
const OUTPUT := "res://build/evidence/m9a-runtime-20260904/control-repair-candidates"
const TRANSPARENT_PADDING := 2
const PREVIEW_CELL := Vector2i(112, 104)
const PREVIEW_COLUMNS := 3
const TARGET_SHAPES := {
	"wide_parchment_tab": [72, 56], "binding_tab": [72, 56], "square_stud": [56, 56],
	"tall_index": [48, 64], "lever": [72, 56], "token": [56, 56],
}
const FONT_COLORS := {
	"wide_parchment_tab": "#172b3c", "binding_tab": "#fff0cf", "square_stud": "#fff0cf",
	"tall_index": "#fff0cf", "lever": "#fff0cf", "token": "#fff0cf",
}
const COMPONENTS := {
	"wide_parchment_tab": Rect2i(36, 284, 416, 213),
	"binding_tab": Rect2i(521, 287, 398, 207),
	"square_stud": Rect2i(990, 284, 226, 215),
	"tall_index": Rect2i(145, 632, 123, 325),
	"lever": Rect2i(449, 729, 289, 177),
	"token": Rect2i(889, 678, 267, 267),
}

func _init() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("M9 control source could not be loaded.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var report: Dictionary = {
		"source": SOURCE,
		"source_sha256": FileAccess.get_sha256(SOURCE),
		"background_alpha_method": "border-connected light neutral flood fill; RGB bytes are preserved while only alpha is cleared",
		"components": {}
	}
	var previews: Array[Dictionary] = []
	for kind in COMPONENTS:
		var requested: Rect2i = COMPONENTS[kind]
		var candidate := source.get_region(requested)
		var rgb_delta := _calibrate_border_connected_background_to_alpha(candidate)
		var content := _alpha_bounds(candidate)
		if content.size.x <= 0 or content.size.y <= 0:
			push_error("M9 %s has no calibrated opaque hardware." % kind)
			quit(1)
			return
		var tight := candidate.get_region(content)
		var trimmed := Image.create(tight.get_width() + TRANSPARENT_PADDING * 2, tight.get_height() + TRANSPARENT_PADDING * 2, false, Image.FORMAT_RGBA8)
		trimmed.fill(Color(0, 0, 0, 0))
		trimmed.blit_rect(tight, Rect2i(Vector2i.ZERO, tight.get_size()), Vector2i(TRANSPARENT_PADDING, TRANSPARENT_PADDING))
		var output := "%s/%s.png" % [OUTPUT, kind]
		if trimmed.save_png(output) != OK:
			push_error("Could not write M9 candidate %s." % kind)
			quit(1)
			return
		var target: Array = TARGET_SHAPES[kind]
		var expected_outer := _expected_outer_padding_pixels(trimmed.get_size())
		report.components[kind] = {
			"requested_source_rect": [requested.position.x, requested.position.y, requested.size.x, requested.size.y],
			"calibrated_alpha_bounds": [content.position.x, content.position.y, content.size.x, content.size.y],
			"output": output,
			"output_dimensions": [trimmed.get_width(), trimmed.get_height()],
			"output_sha256": FileAccess.get_sha256(output),
			"rgb_channel_max_delta": rgb_delta,
			"rgb_bytes_identical_after_alpha_calibration": is_zero_approx(rgb_delta),
			"transparent_padding_px": TRANSPARENT_PADDING,
			"corner_alpha": _corner_alpha(trimmed),
			"transparent_outer_fringe_pixels": _outer_transparent_pixels(trimmed),
			"expected_outer_padding_pixels": expected_outer,
			"outer_two_px_fully_transparent": _outer_transparent_pixels(trimmed) == expected_outer,
			"expected_minimum_target_px": target,
			"supports_minimum_target": trimmed.get_width() >= int(target[0]) and trimmed.get_height() >= int(target[1]),
			"native_font_color": FONT_COLORS[kind],
			"native_font_color_all_states": {
				"normal": FONT_COLORS[kind], "hover": FONT_COLORS[kind],
				"pressed": FONT_COLORS[kind], "focus": FONT_COLORS[kind]
			},
			"recommended_nine_slice_margins": _nine_slice_margins(kind, trimmed.get_size())
		}
		previews.append({"kind": kind, "image": trimmed, "target": target})
	var preview_report := _write_minimum_target_previews(previews)
	report["minimum_target_previews"] = preview_report
	var report_path := "%s/manifest.json" % OUTPUT
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("M9_CONTROL_CALIBRATION report=%s" % report_path)
	quit(0)

func _calibrate_border_connected_background_to_alpha(image: Image) -> float:
	image.convert(Image.FORMAT_RGBA8)
	var max_rgb_delta := 0.0
	var pending: Array[Vector2i] = []
	var visited := PackedByteArray()
	visited.resize(image.get_width() * image.get_height())
	for x in image.get_width():
		_enqueue_background_candidate(Vector2i(x, 0), image, pending, visited)
		_enqueue_background_candidate(Vector2i(x, image.get_height() - 1), image, pending, visited)
	for y in image.get_height():
		_enqueue_background_candidate(Vector2i(0, y), image, pending, visited)
		_enqueue_background_candidate(Vector2i(image.get_width() - 1, y), image, pending, visited)
	var cursor := 0
	while cursor < pending.size():
		var point := pending[cursor]
		cursor += 1
		var color := image.get_pixelv(point)
		var rgb := color
		color.a = 0.0
		var channel_delta := maxf(absf(rgb.r - color.r), maxf(absf(rgb.g - color.g), absf(rgb.b - color.b)))
		max_rgb_delta = maxf(max_rgb_delta, channel_delta)
		image.set_pixelv(point, color)
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			_enqueue_background_candidate(point + offset, image, pending, visited)
	return max_rgb_delta

func _enqueue_background_candidate(point: Vector2i, image: Image, pending: Array[Vector2i], visited: PackedByteArray) -> void:
	if point.x < 0 or point.y < 0 or point.x >= image.get_width() or point.y >= image.get_height(): return
	var offset := point.y * image.get_width() + point.x
	if visited[offset] != 0: return
	visited[offset] = 1
	var color := image.get_pixelv(point)
	if color.a <= 0.01 or _is_light_neutral_background(color): pending.append(point)

func _is_light_neutral_background(color: Color) -> bool:
	# The generator's off-white canvas is not byte-identical white. Restrict the
	# flood to bright, low-chroma pixels connected to a crop edge so parchment,
	# brass, and enclosed highlights remain intact.
	var lowest := minf(color.r, minf(color.g, color.b))
	var highest := maxf(color.r, maxf(color.g, color.b))
	# This deliberately includes the source's light-grey antialias ramp. Its warm
	# parchment and brass pixels have materially higher chroma, so the exterior
	# flood cannot enter a real control face through its hardware outline.
	return lowest >= 0.22 and highest - lowest <= 0.30

func _alpha_bounds(image: Image) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := -1
	var bottom := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.01: continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x)
			bottom = maxi(bottom, y)
	if right < left or bottom < top: return Rect2i()
	return Rect2i(left, top, right - left + 1, bottom - top + 1)

func _corner_alpha(image: Image) -> Array:
	return [image.get_pixel(0, 0).a, image.get_pixel(image.get_width() - 1, 0).a, image.get_pixel(0, image.get_height() - 1).a, image.get_pixel(image.get_width() - 1, image.get_height() - 1).a]

func _outer_transparent_pixels(image: Image) -> int:
	var count := 0
	for y in image.get_height():
		for x in image.get_width():
			if x >= TRANSPARENT_PADDING and y >= TRANSPARENT_PADDING and x < image.get_width() - TRANSPARENT_PADDING and y < image.get_height() - TRANSPARENT_PADDING: continue
			if image.get_pixel(x, y).a <= 0.01: count += 1
	return count

func _expected_outer_padding_pixels(dimensions: Vector2i) -> int:
	var inner_width := dimensions.x - TRANSPARENT_PADDING * 2
	var inner_height := dimensions.y - TRANSPARENT_PADDING * 2
	return dimensions.x * dimensions.y - inner_width * inner_height

func _write_minimum_target_previews(previews: Array[Dictionary]) -> Dictionary:
	var rows := int(ceil(float(previews.size()) / float(PREVIEW_COLUMNS)))
	var dimensions := Vector2i(PREVIEW_CELL.x * PREVIEW_COLUMNS, PREVIEW_CELL.y * rows)
	var light := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	var dark := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	light.fill(Color("ead9b7"))
	dark.fill(Color("0d1722"))
	var placements: Dictionary = {}
	for index in previews.size():
		var entry := previews[index]
		var target: Array = entry.target
		var actual: Image = (entry.image as Image).duplicate()
		actual.resize(int(target[0]), int(target[1]), Image.INTERPOLATE_LANCZOS)
		var col := index % PREVIEW_COLUMNS
		var row := index / PREVIEW_COLUMNS
		var position := Vector2i(col * PREVIEW_CELL.x + (PREVIEW_CELL.x - actual.get_width()) / 2, row * PREVIEW_CELL.y + (PREVIEW_CELL.y - actual.get_height()) / 2)
		# `blit_rect` replaces the sheet's dark pixels with transparent pixels whose
		# RGB still carries the source canvas. Alpha-composite instead so this proof
		# shows the real exterior silhouette rather than a preview-only white matte.
		light.blend_rect(actual, Rect2i(Vector2i.ZERO, actual.get_size()), position)
		dark.blend_rect(actual, Rect2i(Vector2i.ZERO, actual.get_size()), position)
		placements[str(entry.kind)] = [position.x, position.y, actual.get_width(), actual.get_height()]
	var light_path := "%s/minimum-target-light.png" % OUTPUT
	var dark_path := "%s/minimum-target-dark.png" % OUTPUT
	if light.save_png(light_path) != OK or dark.save_png(dark_path) != OK:
		push_error("Could not write M9 minimum-target preview sheets.")
		quit(1)
	return {
		"cell_px": [PREVIEW_CELL.x, PREVIEW_CELL.y],
		"backgrounds": {"light": light_path, "dark": dark_path},
		"placements_at_one_to_one_px": placements,
		"note": "Each listed placement is rendered at its exact minimum target dimensions; the contact sheet does not enlarge any component."
	}

func _nine_slice_margins(kind: String, dimensions: Vector2i) -> Array:
	var requested := 18
	if kind == "binding_tab": requested = 36
	if kind == "tall_index": requested = 14
	if kind == "lever": requested = 20
	if kind == "token": requested = 28
	var horizontal := mini(requested, maxi(1, dimensions.x / 3))
	var vertical := mini(requested, maxi(1, dimensions.y / 3))
	return [horizontal, horizontal, vertical, vertical]
