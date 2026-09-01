class_name PhysicalCatalogImprint
extends RefCounted
## Creates passive clipped artifact art. Supports transparent creature sprites and
## opaque card art using the same native aperture ownership contract.

const INK_SHADER := preload("res://scripts/ui/physical_catalog_imprint.gdshader")
const APPROVED_V2_PREFIX := "res://assets/creatures/2d/blueprints/v2/"
static var _neutral_placeholder: Texture2D

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
		var approved := _load_png_texture(blueprint_path)
		if approved != null and _transparent_ink_texture(approved): return approved
	# The approval gate is deliberately identity-neutral: no raw print, sprite,
	# card back, legacy card, or substitute creature is allowed before full v2 art.
	return neutral_placeholder_texture()

static func blueprint_path_for(definition: Dictionary) -> String:
	if str(definition.get("type", "creature")) != "creature": return ""
	var creature_id := str(definition.get("id", ""))
	var candidate := str(definition.get("blueprint_art", ""))
	if candidate.is_empty():
		var presentation_definition: Dictionary = Catalog.creature(creature_id)
		candidate = str(presentation_definition.get("blueprint_art", ""))
	var expected := APPROVED_V2_PREFIX + creature_id + "_blueprint_ink_v2.png"
	if creature_id.is_empty() or candidate != expected or not candidate.begins_with(APPROVED_V2_PREFIX): return ""
	return candidate if FileAccess.file_exists(candidate) else ""

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
	if image == null or image.is_empty() or image.get_width() < 2 or image.get_height() < 2: return false
	return image.get_pixel(0, 0).a <= 0.05 and image.get_pixel(image.get_width() - 1, 0).a <= 0.05 and image.get_pixel(0, image.get_height() - 1).a <= 0.05 and image.get_pixel(image.get_width() - 1, image.get_height() - 1).a <= 0.05

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
