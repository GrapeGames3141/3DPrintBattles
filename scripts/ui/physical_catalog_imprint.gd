class_name PhysicalCatalogImprint
extends RefCounted
## Creates passive clipped artifact art. Supports transparent creature sprites and
## opaque card art using the same native aperture ownership contract.

const INK_SHADER := preload("res://scripts/ui/physical_catalog_imprint.gdshader")
const APPROVED_V2_PREFIX := "res://assets/creatures/2d/blueprints/v2/"
const RUNTIME_MANIFEST_PATH := APPROVED_V2_PREFIX + "manifest-v2.json"
static var _neutral_placeholder: Texture2D
static var _runtime_manifest_checked := false
static var _runtime_manifest_valid := false
static var _runtime_blueprints: Dictionary = {}
static var _runtime_texture_cache: Dictionary = {}
static var _manifest_warnings: Dictionary = {}

## The approved blueprint masters are already complete physical cards.  Keep them
## in their authored navy/cream color without the sepia support-art shader or a
## second runtime card face behind them.
static func add_blueprint_card(host: Control, node_name: String, texture: Texture2D, rect: Rect2) -> TextureRect:
	var aperture := _aperture(host, node_name, rect)
	var art := TextureRect.new()
	art.name = node_name
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.set_meta("m6_blueprint_placeholder", is_neutral_placeholder(texture))
	aperture.add_child(art)
	return art

static func blueprint_texture(definition: Dictionary) -> Texture2D:
	if str(definition.get("type", "creature")) != "creature":
		return null
	var blueprint_path := blueprint_path_for(definition)
	if not blueprint_path.is_empty():
		var creature_id := str(definition.get("id", ""))
		if _runtime_texture_cache.has(creature_id): return _runtime_texture_cache[creature_id] as Texture2D
		var approved := _load_png_texture(blueprint_path)
		if approved != null and _transparent_ink_texture(approved):
			_runtime_texture_cache[creature_id] = approved
			return approved
		_warn_manifest_once("texture:%s" % creature_id, "Approved M7 blueprint texture failed alpha validation: %s" % creature_id)
	# The approval gate is deliberately identity-neutral: no raw print, sprite,
	# card back, legacy card, or substitute creature is allowed before full v2 art.
	return neutral_placeholder_texture()

static func blueprint_path_for(definition: Dictionary) -> String:
	if str(definition.get("type", "creature")) != "creature": return ""
	var creature_id := str(definition.get("id", ""))
	if creature_id.is_empty() or not _ensure_runtime_manifest(): return ""
	var approved: Dictionary = _runtime_blueprints.get(creature_id, {})
	if approved.is_empty(): return ""
	var expected := str(approved.get("runtime_path", ""))
	var candidate := str(definition.get("blueprint_art", ""))
	# Absent presentation data resolves only through the approved runtime manifest.
	# Any explicit injection must exactly match the manifest entry; legacy/raw/sprite
	# paths are never accepted as a convenience fallback.
	if not candidate.is_empty() and candidate != expected:
		_warn_manifest_once("injection:%s:%s" % [creature_id, candidate], "Rejected non-manifest blueprint injection for %s." % creature_id)
		return ""
	# Export remapping can make the raw source path unavailable even though the
	# imported Texture2D is present.  Accept either export-safe loader discovery
	# or the raw-file fallback used by fresh headless project scans.
	return expected if ResourceLoader.exists(expected) or FileAccess.file_exists(expected) else ""

static func runtime_manifest_snapshot() -> Dictionary:
	_ensure_runtime_manifest()
	return _runtime_blueprints.duplicate(true)

static func runtime_texture_cache_count() -> int:
	return _runtime_texture_cache.size()

static func _ensure_runtime_manifest() -> bool:
	if _runtime_manifest_checked: return _runtime_manifest_valid
	_runtime_manifest_checked = true
	_runtime_manifest_valid = false
	_runtime_blueprints.clear()
	_runtime_texture_cache.clear()
	if not FileAccess.file_exists(RUNTIME_MANIFEST_PATH):
		_warn_manifest_once("missing", "M7 blueprint runtime manifest is unavailable; using neutral pre-print placeholder.")
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RUNTIME_MANIFEST_PATH))
	if not parsed is Dictionary:
		_warn_manifest_once("malformed", "M7 blueprint runtime manifest is malformed; using neutral pre-print placeholder.")
		return false
	var manifest: Dictionary = parsed
	if str(manifest.get("schema", "")) != "printforge.runtime-blueprints.v2" or int(manifest.get("version", 0)) != 2:
		_warn_manifest_once("schema", "M7 blueprint runtime manifest schema is invalid; using neutral pre-print placeholder.")
		return false
	var entries: Variant = manifest.get("entries", [])
	var order: Variant = manifest.get("catalog_order", [])
	if not entries is Array or not order is Array or entries.size() != 24 or order.size() != 24:
		_warn_manifest_once("membership", "M7 blueprint runtime manifest must contain exactly 24 entries.")
		return false
	var seen := {}
	for index in range(entries.size()):
		var raw: Variant = entries[index]
		if not raw is Dictionary:
			_warn_manifest_once("entry", "M7 blueprint runtime manifest contains an invalid entry.")
			return false
		var entry: Dictionary = raw
		var creature_id := str(entry.get("id", ""))
		var expected_path := APPROVED_V2_PREFIX + creature_id + "_blueprint_ink_v2.png"
		if creature_id.is_empty() or seen.has(creature_id) or str(order[index]) != creature_id or str(entry.get("runtime_path", "")) != expected_path:
			_warn_manifest_once("identity", "M7 blueprint runtime manifest identity/order validation failed.")
			return false
		# PNG bytes/hashes are build-time package integrity gates.  Do not read or
		# decode the complete 24-asset family here: mobile/export startup validates
		# manifest structure only, then validates the requested Texture2D on demand.
		var expected_sha := str(entry.get("runtime_sha256", ""))
		if int(entry.get("runtime_bytes", -1)) <= 0 or expected_sha.length() != 64 or not expected_sha.is_valid_hex_number():
			_warn_manifest_once("asset_metadata:%s" % creature_id, "M7 blueprint runtime manifest metadata failed: %s." % creature_id)
			return false
		seen[creature_id] = true
		_runtime_blueprints[creature_id] = {"runtime_path": expected_path, "runtime_sha256": str(entry.get("runtime_sha256", "")), "runtime_bytes": int(entry.get("runtime_bytes", -1))}
	_runtime_manifest_valid = seen.size() == 24
	return _runtime_manifest_valid

static func _corner_alpha_max(image: Image) -> int:
	var right := image.get_width() - 1
	var bottom := image.get_height() - 1
	var maximum := 0
	for point in [Vector2i(0, 0), Vector2i(right, 0), Vector2i(0, bottom), Vector2i(right, bottom)]:
		maximum = max(maximum, int(round(image.get_pixelv(point).a * 255.0)))
	return maximum

static func _warn_manifest_once(key: String, message: String) -> void:
	if _manifest_warnings.has(key): return
	_manifest_warnings[key] = true
	push_warning(message)

static func neutral_placeholder_texture() -> Texture2D:
	if _neutral_placeholder != null: return _neutral_placeholder
	var image := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var ivory := Color("f4dfadcc")
	var cyan := Color("8deeffcc")
	for value in range(18, 79):
		image.set_pixel(value, 48, cyan)
		if value % 4 == 0: image.set_pixel(48, value, ivory)
	for corner in [Vector2i(20,20), Vector2i(76,20), Vector2i(20,76), Vector2i(76,76)]:
		for offset in range(-4, 5):
			image.set_pixel(corner.x + offset, corner.y, ivory)
			image.set_pixel(corner.x, corner.y + offset, ivory)
	_neutral_placeholder = ImageTexture.create_from_image(image)
	return _neutral_placeholder

static func is_neutral_placeholder(texture: Texture2D) -> bool:
	return texture != null and texture == neutral_placeholder_texture()

static func _transparent_ink_texture(texture: Texture2D) -> bool:
	var image := texture.get_image()
	if image == null or image.is_empty() or image.get_width() != 1254 or image.get_height() != 1254: return false
	return _corner_alpha_max(image) <= 1

static func add(host: Control, node_name: String, texture: Texture2D, rect: Rect2, remove_dark_matte := false) -> TextureRect:
	var aperture := _aperture(host, node_name, rect)
	var art := TextureRect.new(); art.name = node_name; art.texture = texture; art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.mouse_filter = Control.MOUSE_FILTER_IGNORE; art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); art.material = ShaderMaterial.new(); (art.material as ShaderMaterial).shader = INK_SHADER; (art.material as ShaderMaterial).set_shader_parameter("remove_dark_matte", remove_dark_matte); aperture.add_child(art)
	return art

static func add_catalog_art(host: Control, node_name: String, definition: Dictionary, rect: Rect2, support_texture: Texture2D) -> TextureRect:
	if str(definition.get("type", "")) == "creature":
		return add_blueprint_card(host, node_name, blueprint_texture(definition), rect)
	return add(host, node_name, support_texture, rect, true)

static func _aperture(host: Control, node_name: String, rect: Rect2) -> Control:
	var aperture := Control.new()
	aperture.name = node_name + "Aperture"
	aperture.clip_contents = true
	aperture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aperture.anchor_left = rect.position.x
	aperture.anchor_top = rect.position.y
	aperture.anchor_right = rect.end.x
	aperture.anchor_bottom = rect.end.y
	host.add_child(aperture)
	return aperture

static func _load_png_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := ResourceLoader.load(path) as Texture2D
		if imported != null: return imported
	# Headless regression runs can exercise freshly promoted PNGs before the editor
	# scan has generated import metadata. Decode the durable asset rather than
	# selecting raw-print or animated substitute artwork.
	if not FileAccess.file_exists(path): return null
	var image := Image.new()
	if image.load(path) != OK: return null
	return ImageTexture.create_from_image(image)
