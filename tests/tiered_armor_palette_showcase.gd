class_name TieredArmorPaletteShowcase
extends Control
## Capture-only presentation: all variants reference the identical alpha master.

const PREVIEW := preload("res://scripts/ui/tiered_armor_palette_preview.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	body.add_theme_constant_override("separation", 7)
	add_child(body)
	var title := Label.new()
	title.text = "Cinderpaw Armor Palette Forge"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("ffd36c"))
	body.add_child(title)
	var note := Label.new()
	note.text = "Five shader palettes, one transparent master texture. Only saturated blue armor plates are recolored."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", Color("b9d3e8"))
	body.add_child(note)
	var portrait := size.y > size.x
	var grid := GridContainer.new()
	grid.name = "TierPaletteGrid"
	grid.columns = 2 if portrait else 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if portrait else Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	var tier_ids := PREVIEW.tier_ids()
	var grid_tiers := tier_ids.slice(0, 4) if portrait else tier_ids
	for tier_id in grid_tiers:
		grid.add_child(_make_tier_card(tier_id, portrait))
	if portrait:
		# Keep the odd fifth tier as a deliberate centered final row rather than
		# leaving a visibly empty half-card beside it.
		var final_row := CenterContainer.new()
		final_row.name = "LegendaryCenteredRow"
		final_row.custom_minimum_size = Vector2(0, 370)
		final_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		final_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		body.add_child(final_row)
		var legendary_card := _make_tier_card("legendary", true)
		legendary_card.custom_minimum_size.x = 265
		final_row.add_child(legendary_card)

func _make_tier_card(tier_id: String, portrait: bool) -> PanelContainer:
	var data: Dictionary = PREVIEW.PALETTES[tier_id]
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 370 if portrait else 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if portrait else Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d1b2ccc")
	style.border_color = Color(data.highlight)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	card.add_child(column)
	var name_label := Label.new()
	name_label.text = str(data.name)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(data.highlight))
	column.add_child(name_label)
	var subtitle := Label.new()
	subtitle.text = str(data.subtitle)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("dce8f4"))
	column.add_child(subtitle)
	var preview := PREVIEW.new()
	preview.name = "%sTierPreview" % str(tier_id).capitalize()
	# Landscape cards fill the remaining height after the title/note; portrait
	# retains a concrete minimum so all five tiers stay visible in two columns.
	preview.custom_minimum_size = Vector2(0, 260 if portrait else 0)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.configure_tier(tier_id)
	column.add_child(preview)
	return card

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111f"), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color("315778"), false, 2.0)
