class_name CreatureAssetValidator
extends RefCounted
## Source-PNG validator for the catalog creature presentation contract.

const SHEET_SIZE := Vector2i(1536, 1024)
const CELL_SIZE := Vector2i(384, 512)
const ALPHA_THRESHOLD := 0.04
const MIN_CELL_ALPHA_SAMPLES := 12
const SAMPLE_STEP := 8

static func validate_catalog() -> Array[String]:
	var errors: Array[String] = []
	for definition in Catalog.CREATURES:
		errors.append_array(validate_definition(definition))
	return errors

static func validate_definition(definition: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var creature_id: String = str(definition.get("id", "unknown"))
	var living_path: String = str(definition.get("sprite_sheet", ""))
	var raw_path: String = str(definition.get("raw_print", ""))
	var living: Image = _load_source(living_path, creature_id, "living sheet", errors)
	if living != null:
		if living.get_size() != SHEET_SIZE:
			errors.append("%s living sheet must be 1536x1024, found %dx%d: %s" % [creature_id, living.get_width(), living.get_height(), living_path])
		else:
			_validate_living_alpha(living, creature_id, errors)
	var raw: Image = _load_source(raw_path, creature_id, "raw print", errors)
	if raw != null:
		_validate_raw_alpha(raw, creature_id, errors)
	return errors

static func _load_source(path: String, creature_id: String, label: String, errors: Array[String]) -> Image:
	if path.is_empty():
		errors.append("%s has no catalog %s path" % [creature_id, label])
		return null
	var absolute: String = ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute):
		errors.append("%s %s is missing: %s" % [creature_id, label, path])
		return null
	var image: Image = Image.load_from_file(absolute)
	if image == null or image.is_empty():
		errors.append("%s %s could not be read as a PNG: %s" % [creature_id, label, path])
		return null
	# Image does not expose a has_alpha() API in Godot 4.  Sampling for an actual
	# transparent pixel verifies the alpha requirement and catches an opaque PNG
	# even when it has been converted to an RGBA image by the decoder.
	if not _has_transparent_pixel(image):
		errors.append("%s %s has no transparent alpha coverage: %s" % [creature_id, label, path])
	return image

static func _has_transparent_pixel(image: Image) -> bool:
	for y in range(0, image.get_height(), SAMPLE_STEP):
		for x in range(0, image.get_width(), SAMPLE_STEP):
			if image.get_pixel(x, y).a <= ALPHA_THRESHOLD:
				return true
	return image.get_pixel(0, 0).a <= ALPHA_THRESHOLD

static func _validate_living_alpha(image: Image, creature_id: String, errors: Array[String]) -> void:
	for cell_index in 8:
		var opaque_samples: int = 0
		var origin_x: int = (cell_index % 4) * CELL_SIZE.x
		var origin_y: int = (cell_index / 4) * CELL_SIZE.y
		for y in range(origin_y, origin_y + CELL_SIZE.y, SAMPLE_STEP):
			for x in range(origin_x, origin_x + CELL_SIZE.x, SAMPLE_STEP):
				if image.get_pixel(x, y).a > ALPHA_THRESHOLD:
					opaque_samples += 1
		if opaque_samples < MIN_CELL_ALPHA_SAMPLES:
			errors.append("%s living sheet cell %d has too little visible alpha coverage (%d samples)" % [creature_id, cell_index, opaque_samples])

static func _validate_raw_alpha(image: Image, creature_id: String, errors: Array[String]) -> void:
	var width: int = image.get_width()
	var height: int = image.get_height()
	if width < 32 or height < 32:
		errors.append("%s raw print is implausibly small (%dx%d)" % [creature_id, width, height])
		return
	var corners: Array[Vector2i] = [Vector2i(0, 0), Vector2i(width - 1, 0), Vector2i(0, height - 1), Vector2i(width - 1, height - 1)]
	for corner in corners:
		if image.get_pixelv(corner).a > ALPHA_THRESHOLD:
			errors.append("%s raw print corner must remain transparent: %s" % [creature_id, corner])
			break
	var visible_samples: int = 0
	var transparent_samples: int = 0
	for y in range(0, height, SAMPLE_STEP):
		for x in range(0, width, SAMPLE_STEP):
			if image.get_pixel(x, y).a > ALPHA_THRESHOLD:
				visible_samples += 1
			else:
				transparent_samples += 1
	if visible_samples < MIN_CELL_ALPHA_SAMPLES or transparent_samples < MIN_CELL_ALPHA_SAMPLES:
		errors.append("%s raw print needs both visible form and transparent surround (%d opaque, %d transparent samples)" % [creature_id, visible_samples, transparent_samples])
