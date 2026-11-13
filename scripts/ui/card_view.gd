class_name CardView
extends Control
## One card, laid out at 300x420. Scale the node to show it at other sizes.

const W := 300.0
const H := 420.0
const COST_BLUE := Color("2f9bff")
const ATK_AMBER := Color("f59f1c")
const HP_RED := Color("e5484d")

static var _gradients: Dictionary = {}
static var _lines_mat: ShaderMaterial

var card_id := ""
## The card's Blueprint: {tier, mod, paint}. Empty means the plain card.
var build: Dictionary = {}
## Show a creature as its raw, unpainted print (used for cards not yet owned).
var raw := false
var _glow: Panel
var _glow_color: Variant = null
var _glow_k := 1.0
var _count: Label


static func make(id: String, card_scale: float = 1.0, card_build: Dictionary = {}) -> CardView:
	var c := CardView.new()
	c.build = card_build
	c.size = Vector2(W, H)
	c.custom_minimum_size = Vector2(W, H) * card_scale
	c.scale = Vector2(card_scale, card_scale)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	c.set_card(id)
	return c


static func _radial(inner: Color, outer: Color) -> GradientTexture2D:
	var key := inner.to_html() + outer.to_html()
	if not _gradients.has(key):
		var g := Gradient.new()
		g.set_color(0, inner)
		g.set_color(1, outer)
		var t := GradientTexture2D.new()
		t.gradient = g
		t.width = 64
		t.height = 64
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.6)
		t.fill_to = Vector2(1.05, 1.05)
		_gradients[key] = t
	return _gradients[key]


static func lines_material() -> ShaderMaterial:
	if _lines_mat == null:
		_lines_mat = ShaderMaterial.new()
		_lines_mat.shader = load("res://assets/shaders/layer_lines.gdshader")
	return _lines_mat


func set_card(id: String) -> void:
	card_id = id
	_glow = null
	_glow_color = null
	_count = null
	for ch in get_children():
		remove_child(ch)
		ch.queue_free()
	if GameData.has_card(id):
		_build_front(GameData.card(id))
	else:
		_build_back()


func set_build(new_build: Dictionary) -> void:
	build = new_build
	set_card(card_id)


func set_raw(on: bool) -> void:
	if raw != on:
		raw = on
		set_card(card_id)


func is_face_down() -> bool:
	return not GameData.has_card(card_id)


## Green outline for "you can play this", or any other colour; null to clear.
func set_glow(color: Variant) -> void:
	if _glow == null:
		_glow = Panel.new()
		_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_glow.position = Vector2(-7, -7)
		_glow.size = Vector2(W + 14, H + 14)
		add_child(_glow)
		move_child(_glow, 0)
		set_notify_transform(true)
	_glow.visible = color != null
	_glow_color = color
	_style_glow()


## The outline keeps the same thickness on screen whatever size the card is
## drawn at (a small hand card and a big preview used to look different).
func _style_glow() -> void:
	if _glow == null or _glow_color == null:
		return
	var k := 1.0 / maxf(absf(scale.x), 0.05)
	_glow_k = scale.x
	var pad := 5.0 * k
	_glow.position = Vector2(-pad, -pad)
	_glow.size = Vector2(W + pad * 2.0, H + pad * 2.0)
	var col: Color = _glow_color
	var s := UI.box(Color.TRANSPARENT, col, roundi(4.0 * k), roundi(22.0 * k))
	s.shadow_color = Color(col, 0.5)
	s.shadow_size = roundi(10.0 * k)
	_glow.add_theme_stylebox_override("panel", s)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and _glow != null and not is_equal_approx(_glow_k, scale.x):
		_style_glow()


func set_dimmed(on: bool) -> void:
	modulate = Color(0.62, 0.64, 0.7) if on else Color.WHITE


## A small tag in the top-right corner, e.g. "x2". Empty hides it.
func set_count(text: String, color := UI.CREAM) -> void:
	if _count == null:
		var bg := UI.panel(self, Rect2(W - 156, 6, 150, 44), UI.box(Color("0b1220"), UI.BRASS, 3, 16))
		bg.z_index = 2
		_count = UI.label("", 25, color)
		_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_count.size = bg.size
		bg.add_child(_count)
	_count.get_parent().visible = text != ""
	_count.text = text
	_count.add_theme_color_override("font_color", color)


func _add_lines(rect: Rect2, strength := 0.16) -> void:
	var lines := ColorRect.new()
	lines.material = lines_material()
	lines.position = rect.position
	lines.size = rect.size
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.modulate.a = strength / 0.1
	add_child(lines)


func _build_back() -> void:
	UI.panel(self, Rect2(0, 0, W, H), UI.box(Color("16233f"), UI.BRASS, 7, 20, 6))
	UI.panel(self, Rect2(22, 22, W - 44, H - 44), UI.box(Color("0f1a30"), UI.BRASS_DARK, 3, 12))
	_add_lines(Rect2(10, 10, W - 20, H - 20), 0.2)
	var emblem := IconView.make("spool", 150, UI.CYAN)
	emblem.position = Vector2(W * 0.5 - 75, H * 0.5 - 75)
	add_child(emblem)
	var nut := IconView.make("hex", 46, UI.BRASS)
	nut.position = Vector2(W * 0.5 - 23, H * 0.5 - 23)
	add_child(nut)
	for corner in [Vector2(40, 40), Vector2(W - 40, 40), Vector2(40, H - 40), Vector2(W - 40, H - 40)]:
		var bolt := IconView.make("hex", 22, UI.BRASS_DARK)
		bolt.position = corner - Vector2(11, 11)
		add_child(bolt)


func _build_front(def: Dictionary) -> void:
	# What is printed on the card is the card with its Blueprint applied.
	var base_def := def
	def = GameData.built(def["id"], build)
	var paint_id := str(build.get("paint", "original"))
	var rar := GameData.rarity_color(def["rarity"])
	var body: Color
	var accent: Color
	var kind_text: String
	match def["type"]:
		"creature":
			body = GameData.element_dark(def["element"])
			accent = GameData.element_color(def["element"])
			kind_text = "%s Print" % def["element"] if def["element"] != "Neutral" else "Print"
		"upgrade":
			body = Color("3d2c1c")
			accent = Color("e0a45a")
			kind_text = "Upgrade"
		_:
			body = Color("22324a")
			accent = Color("7fb2e6")
			kind_text = "Tool"

	UI.panel(self, Rect2(0, 0, W, H), UI.box(body, rar, 7, 20, 6))
	_add_lines(Rect2(10, 10, W - 20, H - 20))

	var art := Control.new()
	art.clip_contents = true
	art.position = Vector2(16, 16)
	art.size = Vector2(268, 190)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var path := GameData.art_path(def)
	if def["type"] == "tool":
		var tool_img := UI.image(path, Rect2(Vector2.ZERO, art.size), true)
		tool_img.material = UI.paint_material(paint_id)
		art.add_child(tool_img)
	else:
		var bg := TextureRect.new()
		bg.texture = _radial(accent.lerp(Color.WHITE, 0.15), body.darkened(0.45))
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.size = art.size
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(bg)
		# A little round print bed for the figure to stand on.
		var bed := Control.new()
		bed.mouse_filter = Control.MOUSE_FILTER_IGNORE
		art.add_child(bed)
		bed.draw.connect(func():
			bed.draw_set_transform(Vector2(134, 166), 0.0, Vector2(1.0, 0.26))
			bed.draw_circle(Vector2.ZERO, 104, Color(0, 0, 0, 0.5))
			bed.draw_circle(Vector2.ZERO, 96, body.darkened(0.2))
			bed.draw_arc(Vector2.ZERO, 96, 0, TAU, 48, accent.darkened(0.2), 5.0, true))
		var tex := UI.sprite(path, 0) if def["type"] == "creature" else UI.tex(path)
		var raw_path: String = GameData.RAW % def["id"]
		var show_raw: bool = raw and def["type"] == "creature" and ResourceLoader.exists(raw_path)
		if show_raw:
			tex = UI.tex(raw_path)
		var fig := TextureRect.new()
		fig.texture = tex
		fig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fig.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if show_raw:
			fig.position = Vector2(36, -8)
			fig.size = Vector2(196, 196)
		elif def["type"] == "creature":
			fig.position = Vector2(24, -14)
			fig.size = Vector2(220, 212)
		else:
			fig.position = Vector2(44, 4)
			fig.size = Vector2(180, 182)
		fig.material = UI.paint_material(paint_id)
		art.add_child(fig)
	UI.panel(self, Rect2(13, 13, 274, 196), UI.box(Color.TRANSPARENT, body.darkened(0.55), 4, 10))

	var bar := UI.panel(self, Rect2(8, 202, 284, 44), UI.box(Color(0.04, 0.06, 0.1, 0.94), rar, 2, 9))
	var name: String = def["name"]
	var title := UI.label(name, 23 if name.length() <= 14 else 19, UI.CREAM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size = bar.size
	bar.add_child(title)

	var rules := RichTextLabel.new()
	rules.bbcode_enabled = true
	rules.scroll_active = false
	rules.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rules.position = Vector2(22, 250)
	rules.size = Vector2(256, 122)
	rules.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var rules_plain := GameData.rules_text(def)
	var rules_size := 20 if rules_plain.length() <= 64 else (17 if rules_plain.length() <= 100 else 15)
	rules.add_theme_font_size_override("normal_font_size", rules_size)
	rules.add_theme_font_size_override("bold_font_size", rules_size)
	rules.add_theme_constant_override("line_separation", 2)
	rules.text = "[center]%s[/center]" % rules_plain
	add_child(rules)

	var mod_names: Array = []
	for key in ["mod", "mod2"]:
		if str(def.get(key, "")) != "":
			mod_names.append(str(GameData.card_mod(def[key])["name"]))
	if mod_names.size() == 1:
		kind_text += "  -  " + mod_names[0]
	elif mod_names.size() > 1:
		kind_text = " + ".join(mod_names)  # no room for the kind as well
	var kind := UI.label(kind_text, 14, accent.lerp(Color.WHITE, 0.35), false)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kind.position = Vector2(0, 388)
	kind.size = Vector2(W, 20)
	add_child(kind)

	if int(def.get("mk", 1)) > 1:
		_tier_tag(int(def["mk"]))
	var cost := Badge.make("spool", COST_BLUE, 68)
	cost.position = Vector2(-12, -12)
	cost.set_value(int(def["cost"]), _vs(int(def["cost"]), int(base_def["cost"]), true))
	add_child(cost)
	if def["type"] == "creature":
		var atk := Badge.make("burst", ATK_AMBER, 66)
		atk.position = Vector2(-10, 364)
		atk.set_value(int(def["atk"]), _vs(int(def["atk"]), int(base_def["atk"]), false))
		add_child(atk)
		var hp := Badge.make("hex", HP_RED, 66)
		hp.position = Vector2(244, 364)
		hp.set_value(int(def["hp"]), _vs(int(def["hp"]), int(base_def["hp"]), false))
		hp.z_index = 1
		add_child(hp)


## Number colour against the plain card: green is better, red is worse.
## (For a cost, lower is better.)
func _vs(now: int, base: int, lower_is_better: bool) -> Color:
	if now == base:
		return Color.WHITE
	return UI.GOOD if (now < base) == lower_is_better else Color("ff8a8a")


## "Mk II" marker for a built-up card (a gold tag under the cost badge).
func _tier_tag(tier: int) -> void:
	var names := ["", "", "Mk II", "Mk III"]
	var tag := UI.panel(self, Rect2(56, 8, 72, 28), UI.box(Color("0b1220"), UI.GOLD, 2, 14))
	tag.z_index = 3
	var l := UI.label(names[tier], 16, UI.GOLD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = tag.size
	tag.add_child(l)
