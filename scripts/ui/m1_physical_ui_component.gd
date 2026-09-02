class_name M1PhysicalUiComponent
extends RefCounted
## Static physical-plate geometry and chrome helpers for the M1 portrait routes.
## Main owns callbacks, profile state, and transactions; this class owns no gameplay.

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const FIRST_PRINT_EMPTY_BED := Rect2(64, 230, 690, 520)
const FIRST_PRINT_CARTRIDGE := Rect2(798, 387, 78, 230)
const BLUEPRINT_CARTRIDGE_PATH := "res://assets/ui/physical_ui/m1-r2/blueprint-cartridge-text-free-v1.png"
const BLUEPRINT_CARTRIDGE_CROP := Rect2i(96, 0, 584, 2172)

const ASSET_PATHS := {
	"title":"res://assets/ui/physical_ui/title-backplate-text-free-v2.png",
	"workshop":"res://assets/ui/physical_ui/workshop-backplate-text-free-v1.png",
	"starter_desk":"res://assets/ui/physical_ui/m1-r2/starter-blueprint-desk-v4.png",
	"starter_inspector":"res://assets/ui/physical_ui/m1-r2/starter-inspection-folio-v2.png",
	"first_print":"res://assets/ui/physical_ui/m1-r2/first-print-empty-printer-v2.png",
	"battle":"res://assets/ui/physical_ui/m1-r2/workshop-battle-dial-v2.png",
	"archive":"res://assets/ui/physical_ui/m1-r2/workshop-archive-folio-v2.png",
	"deck":"res://assets/ui/physical_ui/m1-r2/workshop-deck-drawer-v2.png",
	"supplies":"res://assets/ui/physical_ui/m1-r2/workshop-supplies-tray-v3.png",
	"settings":"res://assets/ui/physical_ui/m1-r2/workshop-settings-dial-v3.png"
}

static func place_design(control: Control, rect: Rect2, design_size := DESIGN_SIZE) -> void:
	control.anchor_left = rect.position.x / design_size.x
	control.anchor_top = rect.position.y / design_size.y
	control.anchor_right = rect.end.x / design_size.x
	control.anchor_bottom = rect.end.y / design_size.y
	control.offset_left = 0
	control.offset_top = 0
	control.offset_right = 0
	control.offset_bottom = 0

static func texture_for(key: String) -> Texture2D:
	var path := str(ASSET_PATHS.get(key, ""))
	return ResourceLoader.load(path) as Texture2D if not path.is_empty() else null

static func atlas_texture(source: Texture2D, crop: Rect2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = crop
	return atlas

static func physical_workshop_hotspots() -> Array:
	return [
		{"m1_physical":true, "id":"printer", "name":"Printer", "description":"Choose a blueprint and prepare an empty print bed.", "target":"printer", "rect":Rect2(128.0 / 576.0, 102.0 / 928.0, 320.0 / 576.0, 404.0 / 928.0)},
		{"m1_physical":true, "id":"battle_arena", "name":"Battle Dais", "description":"Open a challenge.", "target":"proving", "rect":Rect2(16.0 / 576.0, 258.0 / 928.0, 120.0 / 576.0, 184.0 / 928.0)},
		{"m1_physical":true, "id":"card_archive", "name":"Archive Folio", "description":"Browse blueprints.", "target":"unified_library", "rect":Rect2(440.0 / 576.0, 258.0 / 928.0, 120.0 / 576.0, 184.0 / 928.0)},
		{"m1_physical":true, "id":"deck", "name":"Deck Clipboard", "description":"Edit the active deck.", "target":"unified_deck", "rect":Rect2(16.0 / 576.0, 516.0 / 928.0, 250.0 / 576.0, 176.0 / 928.0)},
		{"m1_physical":true, "id":"supplies", "name":"Supply Cabinet", "description":"Review offers.", "target":"unified_market", "rect":Rect2(310.0 / 576.0, 516.0 / 928.0, 250.0 / 576.0, 176.0 / 928.0)},
		{"m1_physical":true, "id":"settings", "name":"Settings Instrument", "description":"Adjust accessibility and audio.", "target":"settings", "rect":Rect2(166.0 / 576.0, 732.0 / 928.0, 244.0 / 576.0, 168.0 / 928.0)}
	]

static func transparent_plate_style(border: Color, width := 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	return style

static func workshop_prop_specs(textures: Dictionary = {}) -> Array:
	return [
		# Label faces are individually fitted to the pictured ivory/paper plaques.
		# Manual line breaks prevent orphaned syllables at 150% text scale.
		{"id":"battle_arena", "label":"BATTLE\nDAIS", "label_rect":Rect2(31.0 / 576.0, 344.0 / 928.0, 90.0 / 576.0, 38.0 / 928.0), "label_font_size":9, "label_color":Color("1a2a30"), "label_outline":Color("f5e5bd"), "texture":textures.battle, "crop":Rect2i(82, 7, 1090, 1205), "rect":Rect2(16.0 / 576.0, 258.0 / 928.0, 120.0 / 576.0, 184.0 / 928.0)},
		{"id":"card_archive", "label":"ARCHIVE\nFOLIO", "label_rect":Rect2(456.0 / 576.0, 347.0 / 928.0, 88.0 / 576.0, 38.0 / 928.0), "label_font_size":9, "label_color":Color("362317"), "label_outline":Color("fff0c9"), "texture":textures.archive, "crop":Rect2i(101, 6, 1056, 1185), "rect":Rect2(440.0 / 576.0, 258.0 / 928.0, 120.0 / 576.0, 184.0 / 928.0)},
		{"id":"deck", "label":"DECK\nCLIPBOARD", "label_rect":Rect2(73.0 / 576.0, 575.0 / 928.0, 136.0 / 576.0, 42.0 / 928.0), "label_font_size":9, "label_color":Color("47331f"), "label_outline":Color("fff0c9"), "texture":textures.deck, "crop":Rect2i(112, 37, 1030, 1128), "rect":Rect2(16.0 / 576.0, 516.0 / 928.0, 250.0 / 576.0, 176.0 / 928.0)},
		{"id":"supplies", "label":"SUPPLY\nCABINET", "label_rect":Rect2(399.0 / 576.0, 582.0 / 928.0, 118.0 / 576.0, 38.0 / 928.0), "label_font_size":9, "label_color":Color("f7e5bd"), "label_outline":Color("152832"), "texture":textures.supplies, "crop":Rect2i(38, 145, 1184, 950), "rect":Rect2(310.0 / 576.0, 516.0 / 928.0, 250.0 / 576.0, 176.0 / 928.0)},
		{"id":"settings", "label":"SETTINGS", "label_rect":Rect2(228.0 / 576.0, 807.0 / 928.0, 120.0 / 576.0, 36.0 / 928.0), "label_font_size":10, "label_color":Color("172c35"), "label_outline":Color("f5e5bd"), "texture":textures.settings, "crop":Rect2i(107, 107, 1040, 1045), "rect":Rect2(166.0 / 576.0, 732.0 / 928.0, 244.0 / 576.0, 168.0 / 928.0)}
	]

static func workshop_label_rect(prop: Dictionary) -> Rect2:
	return prop.get("label_rect", Rect2()) as Rect2

static func apply_cream_action(button: Button) -> void:
	# The art supplies the cream face. Native states add only restrained dark
	# treatment, never unreadable white-on-cream copy.
	var navy := Color("071a25")
	button.add_theme_color_override("font_color", navy)
	button.add_theme_color_override("font_hover_color", Color("000000"))
	button.add_theme_color_override("font_pressed_color", Color("000000"))
	button.add_theme_color_override("font_focus_color", navy)
	button.add_theme_color_override("font_hover_pressed_color", Color("000000"))
	button.add_theme_stylebox_override("normal", transparent_plate_style(Color(0, 0, 0, 0), 0))
	button.add_theme_stylebox_override("hover", transparent_plate_style(Color("234c5e"), 2))
	button.add_theme_stylebox_override("pressed", transparent_plate_style(Color("10283a"), 3))
	button.add_theme_stylebox_override("focus", transparent_plate_style(Color("10283a"), 3))

static func add_inset_button_focus_ring(button: Button, high_contrast: bool) -> Panel:
	# Compact authored plaques need a complete focus affordance of their own. The
	# ring remains inside the transparent hit owner, so it neither covers the
	# baked hardware nor turns a Back key into a generic full-screen rectangle.
	var ring := Panel.new()
	ring.name = "PhysicalInsetFocusRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ring.offset_left = 4; ring.offset_top = 4; ring.offset_right = -4; ring.offset_bottom = -4
	ring.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var width := 4 if high_contrast else 3
	var ink := Color("ffffff") if high_contrast else Color("6defff")
	for edge in ["Top", "Right", "Bottom", "Left"]:
		var line := ColorRect.new()
		line.name = "PhysicalInsetFocus%s" % edge
		line.color = ink
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match edge:
			"Top": line.anchor_right = 1.0; line.offset_bottom = width
			"Right": line.anchor_left = 1.0; line.anchor_bottom = 1.0; line.offset_left = -width
			"Bottom": line.anchor_top = 1.0; line.anchor_right = 1.0; line.anchor_bottom = 1.0; line.offset_top = -width
			"Left": line.anchor_bottom = 1.0; line.offset_right = width
		ring.add_child(line)
	ring.hide()
	button.add_child(ring)
	button.focus_entered.connect(ring.show)
	button.focus_exited.connect(ring.hide)
	return ring

static func workshop_focus_rect(hotspot_id: String) -> Rect2:
	# Hit regions intentionally span the full authored object. Focus instead marks
	# a small physical latch/medallion inside it, so keyboard focus never reads as
	# a generic rectangle drawn over scenery or a station label.
	match hotspot_id:
		"printer": return Rect2(0.28, 0.58, 0.44, 0.17)
		"battle_arena", "card_archive": return Rect2(0.17, 0.12, 0.66, 0.33)
		"deck", "supplies": return Rect2(0.34, 0.16, 0.32, 0.38)
		"settings": return Rect2(0.35, 0.16, 0.30, 0.36)
	return Rect2(0.25, 0.25, 0.50, 0.50)

static func add_complete_focus_ring(button: Button, hotspot_id: String, high_contrast: bool, _style_factory: Callable) -> Panel:
	var stroke := 4 if high_contrast else 3
	var ring := Panel.new()
	ring.name = "WorkshopHotspotTightFocusRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.z_index = 16
	ring.set_meta("hotspot_id", hotspot_id)
	ring.set_meta("focus_stroke_width", stroke)
	var focus_rect := workshop_focus_rect(hotspot_id)
	ring.anchor_left = focus_rect.position.x; ring.anchor_top = focus_rect.position.y
	ring.anchor_right = focus_rect.end.x; ring.anchor_bottom = focus_rect.end.y
	ring.offset_left = 0; ring.offset_top = 0; ring.offset_right = 0; ring.offset_bottom = 0
	ring.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var stroke_color := Color("ffffff") if high_contrast else Color("6defff")
	for edge in ["Top", "Right", "Bottom", "Left"]:
		var line := ColorRect.new()
		line.name = "WorkshopHotspotTightFocusStroke%s" % edge
		line.color = stroke_color
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		match edge:
			"Top": line.anchor_right = 1.0; line.offset_bottom = stroke
			"Right": line.anchor_left = 1.0; line.anchor_top = 0.0; line.anchor_bottom = 1.0; line.offset_left = -stroke
			"Bottom": line.anchor_top = 1.0; line.anchor_right = 1.0; line.anchor_bottom = 1.0; line.offset_top = -stroke
			"Left": line.anchor_bottom = 1.0; line.offset_right = stroke
		ring.add_child(line)
	ring.visible = false
	button.add_child(ring)
	button.focus_entered.connect(ring.show)
	button.focus_exited.connect(ring.hide)
	button.mouse_entered.connect(ring.show)
	button.mouse_exited.connect(func():
		if not button.has_focus(): ring.hide())
	return ring
