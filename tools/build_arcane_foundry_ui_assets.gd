extends SceneTree

## Deterministic post-processing for the Arcane Foundry generated UI kit.
## Sources retain ImageGen provenance under art-source/source/ui/arcane-foundry-v2.

const SOURCE_DIR := "res://art-source/source/ui/arcane-foundry-v2/"
const OUTPUT_DIR := "res://assets/ui/arcane_foundry/"
const KEY := Color8(255, 0, 255, 255)

func _init() -> void:
	# Approved no-text ImageGen plates stay in docs as provenance. This builder
	# deterministically makes only the compact runtime assets so `all_resources`
	# cannot ship raw or rejected intermediates.
	_compact_source("outer_panel_chroma_v1.png", "foundry_panel_compact_v1.png", 0.55)
	_compact_source("keycap_primary_chroma_v1.png", "foundry_keycap_compact_v1.png", 0.50)
	_compact_source("blueprint_cartridge_chroma_v2.png", "foundry_blueprint_cartridge_compact_v2.png", 0.48)
	_compact_source("inset_well_chroma_v1.png", "foundry_inset_well_compact_v1.png", 0.50)
	_variant("foundry_keycap_compact_v1.png", "foundry_keycap_hover_compact_v1.png", Color(1.10, 1.20, 1.24, 1.0), 0.02)
	_variant("foundry_keycap_compact_v1.png", "foundry_keycap_pressed_compact_v1.png", Color(0.92, 0.78, 0.61, 1.0), -0.08)
	_variant("foundry_keycap_compact_v1.png", "foundry_keycap_disabled_compact_v1.png", Color(0.45, 0.45, 0.43, 1.0), -0.12)
	print("Arcane Foundry UI assets built.")
	quit()

func _compact_source(source_name: String, target_name: String, scale: float) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE_DIR + source_name))
	if image == null or image.is_empty():
		push_error("Missing approved source: " + source_name)
		return
	image.convert(Image.FORMAT_RGBA8)
	_key_to_alpha(image)
	var rect := _content_rect(image, true)
	if rect.size.x < 4 or rect.size.y < 4:
		push_error("Could not find content in: " + source_name)
		return
	image = image.get_region(rect)
	var compact_size := Vector2i(maxi(4, roundi(image.get_width() * scale)), maxi(4, roundi(image.get_height() * scale)))
	image.resize(compact_size.x, compact_size.y, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + target_name))

func _key_to_alpha(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var distance := absf(pixel.r - KEY.r) + absf(pixel.g - KEY.g) + absf(pixel.b - KEY.b)
			if distance < 0.18:
				pixel.a = 0.0
			elif distance < 0.38:
				pixel.a *= clampf((distance - 0.18) / 0.20, 0.0, 1.0)
			image.set_pixel(x, y, pixel)

func _content_rect(image: Image, alpha_only: bool) -> Rect2i:
	var left := image.get_width()
	var right := -1
	var top := image.get_height()
	var bottom := -1
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			# ImageGen's soft chroma fringe leaves fractional alpha across the
			# original square canvas.  Only the opaque plate defines the crop; a
			# small deterministic padding below retains its antialiased edge.
			var content := pixel.a > 0.90 if alpha_only else (pixel.r + pixel.g + pixel.b) > 0.10
			if not content: continue
			left = mini(left, x); right = maxi(right, x); top = mini(top, y); bottom = maxi(bottom, y)
	if right < left or bottom < top: return Rect2i()
	var padding := 4
	left = maxi(0, left - padding)
	top = maxi(0, top - padding)
	right = mini(image.get_width() - 1, right + padding)
	bottom = mini(image.get_height() - 1, bottom + padding)
	return Rect2i(left, top, right - left + 1, bottom - top + 1)

func _variant(source_name: String, target_name: String, tint: Color, brightness: float) -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT_DIR + source_name))
	if image == null or image.is_empty(): return
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.01: continue
			pixel.r = clampf(pixel.r * tint.r + brightness, 0.0, 1.0)
			pixel.g = clampf(pixel.g * tint.g + brightness, 0.0, 1.0)
			pixel.b = clampf(pixel.b * tint.b + brightness, 0.0, 1.0)
			image.set_pixel(x, y, pixel)
	image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + target_name))
