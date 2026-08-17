class_name CreatureArtGallery
extends Control
## Deterministic two-page contact sheet for reviewing the 20 new catalog assets.

const REFERENCE_TEXTURE := preload("res://assets/ui/workshop/workshop-theme-reference-fallback.jpg")
const PAGE_SIZE := 10
# Keep a two-pixel gutter inside the 384x512 atlas cell.  Linear sampling at an
# exact cell edge can otherwise bleed opaque pixels from the next animation frame
# into this idle-only gallery preview.
const LIVING_CELL := Rect2(2, 2, 380, 508)

var page: int = 1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func set_page(value: int) -> void:
	page = clampi(value, 1, 2)
	if is_inside_tree():
		for child in get_children():
			child.queue_free()
		_build()

func _build() -> void:
	var background := TextureRect.new()
	background.texture = REFERENCE_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.modulate = Color(0.21, 0.34, 0.50, 0.38)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color("071321cc")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var header := PanelContainer.new()
	header.name = "WorkshopHeader"
	header.custom_minimum_size = Vector2(0, 92)
	header.add_theme_stylebox_override("panel", _panel_style(Color("122d45ef"), Color("f1be69"), 2))
	content.add_child(header)
	var header_rows := VBoxContainer.new()
	header.add_child(header_rows)
	header_rows.add_child(_label("PRINTFORGE LEGENDS", 25, Color("ffd36c")))
	header_rows.add_child(_label("Makers Guild - Creature Art Gallery - Page %d of 2" % page, 16, Color("a9ecff")))
	header_rows.add_child(_label("Living idle frame beside raw dormant print - batch additions %d-%d of 20" % [((page - 1) * PAGE_SIZE) + 1, mini(page * PAGE_SIZE, 20)], 13, Color("dce8f4")))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	var additions: Array = Catalog.CREATURES.slice(4)
	var start: int = (page - 1) * PAGE_SIZE
	var page_definitions: Array = additions.slice(start, start + PAGE_SIZE)
	for index in page_definitions.size():
		var card := _art_card(page_definitions[index])
		card.name = "GalleryLastCard" if index == page_definitions.size() - 1 else "GalleryCard%d" % index
		grid.add_child(card)

func _art_card(definition: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 236)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rarity: Dictionary = Catalog.rarity(str(definition.get("rarity", "common")))
	card.add_theme_stylebox_override("panel", _panel_style(Color("10243ce8"), Color(str(rarity.get("color", "6bd6ed"))), 2))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 3)
	card.add_child(rows)
	rows.add_child(_label(str(definition.get("name", "Unknown print")), 17, Color("ffffff")))
	rows.add_child(_label("%s - %s" % [str(definition.get("element", "Unknown")), str(rarity.get("name", "Common"))], 12, Color("b8dcef")))
	var forms := HBoxContainer.new()
	forms.alignment = BoxContainer.ALIGNMENT_CENTER
	forms.add_theme_constant_override("separation", 6)
	rows.add_child(forms)
	forms.add_child(_form_column("Living idle", str(definition.get("sprite_sheet", "")), true))
	forms.add_child(_form_column("Raw print", str(definition.get("raw_print", "")), false))
	return card

func _form_column(caption: String, path: String, living: bool) -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(94, 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(88, 146)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = _load_preview(path, living)
	if preview.texture == null:
		preview.modulate = Color("71859d")
	column.add_child(preview)
	column.add_child(_label(caption if preview.texture != null else "Awaiting art", 11, Color("dce8f4")))
	return column

func _load_preview(path: String, living: bool) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		return null
	var texture := ResourceLoader.load(path) as Texture2D
	if texture == null:
		return null
	if not living:
		return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = LIVING_CELL
	return atlas

func _label(value: String, size_px: int, tint: Color) -> Label:
	var result := Label.new()
	result.text = value
	result.add_theme_font_size_override("font_size", size_px)
	result.add_theme_color_override("font_color", tint)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return result

func _panel_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
