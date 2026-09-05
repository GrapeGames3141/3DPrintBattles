extends SceneTree
## Deterministically separates the approved transparent carriage atlas into its
## disconnected guide and head components. RGB bytes are copied untouched; only
## source-alpha-connected pixels are selected and surrounded by transparent guard.

const ATLAS := "res://docs/art/m9-forge-continuity-20260904/enclosed-forge-carriage-atlas-source-v1.png"
const STATIC := "res://docs/art/m9-forge-continuity-20260904/enclosed-forge-static-master-v1.png"
const OUTPUT := "res://build/evidence/m9a-runtime-20260904/forge-continuity-alpha"
const PADDING := 4
# Measured against the 941×1672 enclosed plate: the rail endpoints sit inside
# the fixed cyan-lit posts; the head remains over the chamber and above the bed.
const GUIDE_RECT := Rect2i(114, 280, 594, 168)
const HEAD_RECT := Rect2i(406, 294, 128, 266)

func _init() -> void:
	var atlas := Image.load_from_file(ATLAS)
	var static_master := Image.load_from_file(STATIC)
	if atlas.is_empty() or static_master.is_empty():
		push_error("Forge continuity source image could not load.")
		quit(1)
		return
	atlas.convert(Image.FORMAT_RGBA8)
	static_master.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var components := _connected_components(atlas)
	var guide := _component_near(components, Vector2i(768, 200))
	var head := _component_near(components, Vector2i(768, 700))
	if guide.is_empty() or head.is_empty() or guide == head:
		push_error("Forge carriage atlas did not expose separate guide/head alpha components.")
		quit(1)
		return
	var guide_image := _crop_component(atlas, guide.pixels)
	var head_image := _crop_component(atlas, head.pixels)
	var guide_path := "%s/carriage-guide-v1.png" % OUTPUT
	var head_path := "%s/carriage-head-v1.png" % OUTPUT
	guide_image.save_png(guide_path)
	head_image.save_png(head_path)
	_write_proofs(guide_image, head_image, static_master)
	var report := {
		"atlas": ATLAS,
		"atlas_sha256": FileAccess.get_sha256(ATLAS),
		"static_master": STATIC,
		"static_master_sha256": FileAccess.get_sha256(STATIC),
		"selection": "4-connected alpha>0 source components; original RGBA pixels copied unchanged into padded crops",
		"transparent_padding_px": PADDING,
		"components": _component_report(components),
		"guide": _output_report(guide, guide_image, guide_path),
		"head": _output_report(head, head_image, head_path),
		"registered_geometry": {"guide_rect":[GUIDE_RECT.position.x, GUIDE_RECT.position.y, GUIDE_RECT.size.x, GUIDE_RECT.size.y], "head_rect":[HEAD_RECT.position.x, HEAD_RECT.position.y, HEAD_RECT.size.x, HEAD_RECT.size.y]},
		"proofs": {"light":"%s/light-proof.png" % OUTPUT, "dark":"%s/dark-proof.png" % OUTPUT, "registered_composite":"%s/registered-composite.png" % OUTPUT}
	}
	var file := FileAccess.open("%s/manifest.json" % OUTPUT, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("FORGE_CONTINUITY_ALPHA report=%s/manifest.json components=%d" % [OUTPUT, components.size()])
	quit(0)

func _connected_components(image: Image) -> Array[Dictionary]:
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)
	var result: Array[Dictionary] = []
	for y in height:
		for x in width:
			var index := y * width + x
			if visited[index] != 0 or image.get_pixel(x, y).a <= 0.0: continue
			var queue: Array[Vector2i] = [Vector2i(x, y)]
			visited[index] = 1
			var pixels: Array[Vector2i] = []
			var bounds := Rect2i(x, y, 1, 1)
			var cursor := 0
			while cursor < queue.size():
				var point := queue[cursor]
				cursor += 1
				pixels.append(point)
				bounds = bounds.expand(point)
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbor: Vector2i = point + offset
					if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= width or neighbor.y >= height: continue
					var neighbor_index: int = neighbor.y * width + neighbor.x
					if visited[neighbor_index] != 0 or image.get_pixelv(neighbor).a <= 0.0: continue
					visited[neighbor_index] = 1
					queue.append(neighbor)
			result.append({"pixels":pixels, "bounds":bounds, "area":pixels.size(), "center":bounds.get_center()})
	result.sort_custom(func(a, b): return int(a.area) > int(b.area))
	return result

func _component_near(components: Array[Dictionary], point: Vector2i) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for component in components:
		if int(component.area) < 40: continue
		var bounds: Rect2i = component.bounds
		var distance := bounds.get_center().distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = component
	return best

func _crop_component(source: Image, pixels: Array[Vector2i]) -> Image:
	var bounds := Rect2i(pixels[0], Vector2i.ONE)
	for point in pixels: bounds = bounds.expand(point)
	var output := Image.create(bounds.size.x + PADDING * 2, bounds.size.y + PADDING * 2, false, Image.FORMAT_RGBA8)
	output.fill(Color(0, 0, 0, 0))
	for point in pixels:
		output.set_pixelv(point - bounds.position + Vector2i(PADDING, PADDING), source.get_pixelv(point))
	return output

func _write_proofs(guide: Image, head: Image, static_master: Image) -> void:
	var dimensions := Vector2i(maxi(guide.get_width(), head.get_width()) + 64, guide.get_height() + head.get_height() + 96)
	for proof in [{"name":"light", "color":Color("ead9b7")}, {"name":"dark", "color":Color("081725")}]:
		var image := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
		image.fill(proof.color)
		image.blend_rect(guide, Rect2i(Vector2i.ZERO, guide.get_size()), Vector2i(32, 24))
		image.blend_rect(head, Rect2i(Vector2i.ZERO, head.get_size()), Vector2i((dimensions.x - head.get_width()) / 2, guide.get_height() + 60))
		image.save_png("%s/%s-proof.png" % [OUTPUT, proof.name])
	var composite := static_master.duplicate()
	var registered_guide := guide.duplicate()
	var registered_head := head.duplicate()
	registered_guide.resize(GUIDE_RECT.size.x, GUIDE_RECT.size.y, Image.INTERPOLATE_LANCZOS)
	registered_head.resize(HEAD_RECT.size.x, HEAD_RECT.size.y, Image.INTERPOLATE_LANCZOS)
	composite.blend_rect(registered_guide, Rect2i(Vector2i.ZERO, registered_guide.get_size()), GUIDE_RECT.position)
	composite.blend_rect(registered_head, Rect2i(Vector2i.ZERO, registered_head.get_size()), HEAD_RECT.position)
	composite.save_png("%s/registered-composite.png" % OUTPUT)

func _component_report(components: Array[Dictionary]) -> Array:
	var report: Array = []
	for index in mini(components.size(), 10):
		var component: Dictionary = components[index]
		report.append({"index":index, "area":component.area, "bounds":[component.bounds.position.x, component.bounds.position.y, component.bounds.size.x, component.bounds.size.y]})
	return report

func _output_report(component: Dictionary, image: Image, path: String) -> Dictionary:
	var bounds: Rect2i = component.bounds
	return {"source_bounds":[bounds.position.x, bounds.position.y, bounds.size.x, bounds.size.y], "source_area":component.area, "output":path, "output_dimensions":[image.get_width(), image.get_height()], "output_sha256":FileAccess.get_sha256(path), "corner_alpha":[image.get_pixel(0,0).a, image.get_pixel(image.get_width()-1,0).a, image.get_pixel(0,image.get_height()-1).a, image.get_pixel(image.get_width()-1,image.get_height()-1).a]}
