class_name CorePowerTimeline
extends Control
## Static snapshots document the finite Arcane Core activation without looping it.

const PREVIEW := preload("res://scripts/ui/tiered_armor_palette_preview.gd")
const CORE_VFX := preload("res://scripts/ui/core_power_vfx.gd")

const PHASES := [
	{"id":"idle", "title":"Idle", "note":"Static helmet gem"},
	{"id":"charging", "title":"Charging", "note":"Gem brightens"},
	{"id":"peak", "title":"Peak", "note":"Compact halo and motes"},
	{"id":"resolved", "title":"Resolved", "note":"Finite activation ends"}
]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body := VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 18)
	body.add_theme_constant_override("separation", 7)
	add_child(body)
	var title := Label.new()
	title.text = "Arcane Helmet Gem - Authored Atlas Timeline"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("f44cff"))
	body.add_child(title)
	var note := Label.new()
	note.text = "0.9 seconds: static tinted baked gem -> atlas charge -> atlas peak -> static gem."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", Color("b9d3e8"))
	body.add_child(note)
	var grid := GridContainer.new()
	grid.name = "CorePowerTimelineGrid"
	grid.columns = 2 if size.y > size.x else 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for phase in PHASES:
		grid.add_child(_make_phase_card(phase, size.y > size.x))

func _make_phase_card(phase: Dictionary, portrait: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 370 if portrait else 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if portrait else Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0d1b2ccc")
	style.border_color = Color("f44cff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	card.add_child(column)
	var label := Label.new()
	label.text = str(phase.title)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color("f44cff"))
	column.add_child(label)
	var note := Label.new()
	note.text = str(phase.note)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color("dce8f4"))
	column.add_child(note)
	var visual := Control.new()
	visual.custom_minimum_size = Vector2(0, 260 if portrait else 0)
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(visual)
	var armor := PREVIEW.new()
	armor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	armor.configure_tier("arcane")
	armor.configure_core("arcane")
	visual.add_child(armor)
	var vfx := CORE_VFX.new()
	vfx.name = "%sSnapshot" % str(phase.title)
	vfx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vfx.configure_core("arcane")
	vfx.show_snapshot(str(phase.id))
	visual.add_child(vfx)
	return card

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111f"), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color("315778"), false, 2.0)
