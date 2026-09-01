class_name PhysicalCatalogImprint
extends RefCounted
## Creates passive clipped artifact art. Supports transparent creature sprites and
## opaque card art using the same native aperture ownership contract.

const INK_SHADER := preload("res://scripts/ui/physical_catalog_imprint.gdshader")

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
	aperture.add_child(art)
	return art

static func blueprint_texture(definition: Dictionary) -> Texture2D:
	if str(definition.get("type", "creature")) != "creature":
		return null
	var blueprint_path := blueprint_path_for(definition)
	# UnifiedRules/V3 catalog cards intentionally retain gameplay-only payloads.
	# Resolve their stable creature ID through the presentation catalog rather than
	# assuming that every route already carries the optional art field.
	if not blueprint_path.is_empty():
		var approved := _load_png_texture(blueprint_path)
		if approved != null: return approved
	# A future/unrecognized creature remains inspectable without changing save or
	# rules data.  It must never borrow another creature, a raw model, or an
	# animated battlefield sprite as an identity fallback.
	return _load_png_texture("res://assets/creatures/2d/blueprints/unknown_blueprint_card_v1.png")

static func blueprint_path_for(definition: Dictionary) -> String:
	if str(definition.get("type", "creature")) != "creature": return ""
	var blueprint_path := str(definition.get("blueprint_art", ""))
	if blueprint_path.is_empty():
		var presentation_definition: Dictionary = Catalog.creature(str(definition.get("id", "")))
		blueprint_path = str(presentation_definition.get("blueprint_art", ""))
	return blueprint_path

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
