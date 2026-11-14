class_name PrinterRig
extends TextureRect
## A Printer's picture with the mods it carries bolted on. Each mod has a small
## modelled part (assets/printer_mods/<id>.png, made by tools/render_mod_parts.gd)
## and a fixed spot on the machine, so what you fit is what you see, in the
## workshop and on the battlefield. A Printer carrying epic or legendary mods
## also glows in that rarity's colour.

const ART_SIZE := Vector2(656, 599)
const PART := "res://assets/printer_mods/%s.png"
## A part is drawn about this much bigger than its gadget, to cover its margin.
const PAD := 1.6

## Where each mod sits on the machine: [x, y, gadget width], all as fractions of
## the picture (the width is a fraction of the picture's width).
const LOOKS := {
	"stepper": [0.92, 0.43, 0.15],
	"spool": [0.07, 0.31, 0.20],
	"frame": [0.24, 0.17, 0.12],
	"bed": [0.50, 0.66, 0.34],
	"enclosure": [0.52, 0.47, 0.60],
	"sensor": [0.21, 0.50, 0.10],
	"preheater": [0.17, 0.80, 0.13],
	"quickstart": [0.63, 0.06, 0.10],
	"slicer": [0.54, 0.84, 0.14],
	"hot_end": [0.52, 0.40, 0.09],
	"mixer": [0.41, 0.28, 0.09],
	"sorter": [0.86, 0.90, 0.10],
	"cooling_duct": [0.64, 0.33, 0.10],
	"self_cleaning": [0.36, 0.57, 0.10],
	"spool_feeder": [0.21, 0.07, 0.11],
	"capacitor_bank": [0.94, 0.66, 0.12],
	"scrap_chute": [0.07, 0.72, 0.13],
	"quick_release": [0.72, 0.68, 0.10],
	"failsafe": [0.34, 0.88, 0.09],
	"plating": [0.74, 0.82, 0.12],
	"thermal_mass": [0.74, 0.14, 0.11],
	"prehensile_gantry": [0.39, 0.23, 0.10],
	"quantum_slicer": [0.45, 0.04, 0.12],
	"dual_extruder": [0.61, 0.43, 0.10],
	"direct_drive": [0.82, 0.28, 0.12],
	"spool_rack": [0.10, 0.09, 0.12],
	"twin_feed": [0.31, 0.05, 0.09],
	"titanium_frame": [0.88, 0.14, 0.12],
	"armor_panels": [0.10, 0.90, 0.12],
	"auto_leveler": [0.29, 0.63, 0.09],
	"runout_sensor": [0.15, 0.58, 0.08],
	"preheat_chamber": [0.28, 0.84, 0.12],
	"liquid_hot_end": [0.45, 0.45, 0.09],
	"overdrive_board": [0.78, 0.60, 0.11],
	"auto_sorter": [0.96, 0.78, 0.10],
	"guard_frame": [0.31, 0.40, 0.10],
	"overflow_hopper": [0.87, 0.55, 0.10],
	"tool_beacon": [0.88, 0.04, 0.09],
	"rush_springs": [0.60, 0.78, 0.10],
	"salvage_arm": [0.05, 0.47, 0.11],
	"twin_gantry": [0.52, 0.13, 0.16],
}

var printer_id := ""
var flipped := false
var mods: Array = []
var _parts: Array = []
var _aura: TextureRect


## `rect` is where the picture goes; `mod_ids` are the mods the Printer carries.
static func make(printer: String, mod_ids: Array, rect: Rect2, is_flipped := false) -> PrinterRig:
	var r := PrinterRig.new()
	r.printer_id = printer
	r.flipped = is_flipped
	r.texture = UI.tex("res://assets/printers/%s.png" % printer)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.flip_h = is_flipped
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	r.position = rect.position
	r.size = rect.size
	r.resized.connect(r._layout)
	r.set_mods(mod_ids)
	return r


## Shows these mods on the machine.
func set_mods(mod_ids: Array) -> void:
	mods = []
	for id in mod_ids:
		if LOOKS.has(id) and not mods.has(id):
			mods.append(str(id))
	for p in _parts:
		(p as Node).queue_free()
	_parts = []
	# Parts are drawn in catalog order so the look is the same everywhere.
	for m in GameData.PRINTER_MODS:
		var id: String = m["id"]
		if not mods.has(id):
			continue
		var t := UI.tex(PART % id)
		if t == null:
			continue
		var img := TextureRect.new()
		img.texture = t
		img.name = id
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_SCALE
		img.flip_h = flipped
		img.mouse_filter = Control.MOUSE_FILTER_IGNORE
		img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(img)
		_parts.append(img)
	_make_aura()
	_layout()


## The picture's rectangle inside this control (it is centred and keeps its shape).
func _art_rect() -> Rect2:
	var s := minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var sz := ART_SIZE * s
	return Rect2((size - sz) * 0.5, sz)


func _layout() -> void:
	var a := _art_rect()
	for img in _parts:
		var look: Array = LOOKS[(img as Node).name]
		var w: float = float(look[2]) * PAD * a.size.x
		var x: float = float(look[0])
		if flipped:
			x = 1.0 - x
		(img as Control).size = Vector2(w, w)
		(img as Control).position = a.position + Vector2(x * a.size.x, float(look[1]) * a.size.y) - Vector2(w, w) * 0.5
	if _aura != null:
		var c := a.position + a.size * Vector2(0.5, 0.5)
		var d := maxf(a.size.x, a.size.y) * 1.25
		_aura.size = Vector2(d, d)
		_aura.position = c - Vector2(d, d) * 0.5


## The strongest rarity among the mods: epic and legendary Printers glow.
func top_rarity() -> String:
	var best := -1
	for id in mods:
		best = maxi(best, GameData.RARITY_ORDER.find(str(GameData.mod(str(id)).get("rarity", "common"))))
	return GameData.RARITY_ORDER[best] if best >= 0 else ""


func _make_aura() -> void:
	if _aura != null:
		_aura.queue_free()
		_aura = null
	var top := top_rarity()
	if top != "epic" and top != "legendary":
		return
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	_aura = TextureRect.new()
	_aura.texture = gt
	_aura.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_aura.stretch_mode = TextureRect.STRETCH_SCALE
	_aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aura.show_behind_parent = true
	var col := GameData.rarity_color(top)
	_aura.modulate = Color(col.r, col.g, col.b, 0.5 if top == "legendary" else 0.36)
	add_child(_aura)
	move_child(_aura, 0)
	var tw := _aura.create_tween().set_loops()
	tw.tween_property(_aura, "modulate:a", 0.62 if top == "legendary" else 0.46, 1.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_aura, "modulate:a", 0.32 if top == "legendary" else 0.22, 1.4).set_trans(Tween.TRANS_SINE)
