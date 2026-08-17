extends Node
## Four-page, renderer-backed proof that every roster master uses the same
## shader path: no-Core, Standard, Arcane, and Legendary.

const ROSTER := preload("res://scripts/ui/tiered_armor_roster.gd")
const PREVIEW := preload("res://scripts/ui/tiered_armor_palette_preview.gd")

const PAGES := [
	{"tag":"armor_roster_no_core", "title":"No-Core • Neutral Gem", "tier":"standard", "core":""},
	{"tag":"armor_roster_standard", "title":"Standard • Ember Core", "tier":"standard", "core":"ember"},
	{"tag":"armor_roster_arcane", "title":"Arcane • Arcane Core", "tier":"arcane", "core":"arcane"},
	{"tag":"armor_roster_legendary", "title":"Legendary • Storm Core", "tier":"legendary", "core":"storm"}
]

func _ready() -> void:
	for dimensions in [Vector2i(576, 1024), Vector2i(1280, 720)]:
		for page in PAGES:
			await _capture(dimensions, page)
	print("CAPTURED 24-creature no-Core, Standard, Arcane, and Legendary contact sheets")
	get_tree().quit()

func _capture(dimensions: Vector2i, page: Dictionary) -> void:
	get_window().size = dimensions
	var sheet := _build_sheet(dimensions, page)
	add_child(sheet)
	await get_tree().process_frame
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("Roster contact capture requires a non-dummy renderer.")
		get_tree().quit(1)
		return
	image.save_png("user://%s_%dx%d.png" % [str(page.tag), dimensions.x, dimensions.y])
	sheet.queue_free()
	await get_tree().process_frame

func _build_sheet(dimensions: Vector2i, page: Dictionary) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backdrop := ColorRect.new()
	backdrop.color = Color("07111f")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var body := VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	body.add_theme_constant_override("separation", 3)
	root.add_child(body)
	var heading := Label.new()
	heading.text = "PrintForge Legends • 24-Creature Armor Roster"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 20 if dimensions.x > dimensions.y else 18)
	heading.add_theme_color_override("font_color", Color("ffd36c"))
	body.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "%s — one master per creature; tier and Core are shader-only." % str(page.title)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13 if dimensions.x > dimensions.y else 12)
	subtitle.add_theme_color_override("font_color", Color("b9d3e8"))
	body.add_child(subtitle)
	var grid := GridContainer.new()
	grid.columns = 6 if dimensions.x > dimensions.y else 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	body.add_child(grid)
	for creature_id in ROSTER.creature_ids():
		grid.add_child(_card(creature_id, page, dimensions))
	return root

func _card(creature_id: String, page: Dictionary, dimensions: Vector2i) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102238e8")
	style.border_color = Color(PREVIEW.PALETTES[str(page.tier)].highlight)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	card.add_child(column)
	var label := Label.new()
	label.text = creature_id.capitalize()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10 if dimensions.x > dimensions.y else 9)
	label.add_theme_color_override("font_color", Color("dce8f4"))
	column.add_child(label)
	var preview := PREVIEW.new()
	preview.custom_minimum_size = Vector2(0, 0)
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.configure_creature(creature_id)
	preview.configure_tier(str(page.tier))
	preview.configure_core(str(page.core))
	column.add_child(preview)
	return card
