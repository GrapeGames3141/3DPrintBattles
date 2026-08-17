class_name CorePowerShowcase
extends Control
## Peak-state presentation of every core over the shared full-suit master.

const PREVIEW := preload("res://scripts/ui/tiered_armor_palette_preview.gd")
const CORES := preload("res://scripts/core/armor_core_definitions.gd")
const CORE_VFX := preload("res://scripts/ui/core_power_vfx.gd")
const SHOWCASE_IDS := ["", "ember", "tide", "verdant", "storm", "arcane"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	body.add_theme_constant_override("separation", 7)
	add_child(body)
	var title := Label.new()
	title.text = "Image-Authored Helmet Gems"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("ffd36c"))
	body.add_child(title)
	var note := Label.new()
	note.text = "One shared full-suit master, baked bezel and gem, plus one tinted grayscale activation atlas."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", Color("b9d3e8"))
	body.add_child(note)
	var portrait := size.y > size.x
	var grid := GridContainer.new()
	grid.name = "CorePowerGrid"
	grid.columns = 2 if portrait else 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if portrait else Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for core_id in SHOWCASE_IDS:
		grid.add_child(_make_core_card(core_id, portrait))

func _make_core_card(core_id: String, portrait: bool) -> PanelContainer:
	var data: Dictionary = CORES.definition(core_id) if not core_id.is_empty() else {"name":"Unpowered Gem", "effect":"Dull authored gem - no Core installed", "color":Color("93a4b1")}
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 370 if portrait else 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if portrait else Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d1b2ccc")
	style.border_color = Color(data.color)
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
	name_label.add_theme_color_override("font_color", Color(data.color))
	column.add_child(name_label)
	var effect := Label.new()
	effect.text = str(data.effect)
	effect.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.add_theme_font_size_override("font_size", 12)
	effect.add_theme_color_override("font_color", Color("dce8f4"))
	column.add_child(effect)
	var visual := Control.new()
	visual.custom_minimum_size = Vector2(0, 260 if portrait else 0)
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(visual)
	var armor := PREVIEW.new()
	armor.name = "%sSharedArmorMaster" % (core_id.capitalize() if not core_id.is_empty() else "EmptySocket")
	armor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	armor.configure_tier("standard")
	armor.configure_core(core_id)
	visual.add_child(armor)
	var vfx := CORE_VFX.new()
	vfx.name = "%sCorePeakVFX" % (core_id.capitalize() if not core_id.is_empty() else "EmptySocket")
	vfx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vfx.configure_core(core_id)
	if core_id.is_empty():
		vfx.show_idle()
	else:
		vfx.show_peak()
	visual.add_child(vfx)
	return card

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111f"), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color("315778"), false, 2.0)
