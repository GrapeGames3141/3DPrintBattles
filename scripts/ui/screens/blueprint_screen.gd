extends GameScreen
## Blueprints: improve a card you own. Every copy you print afterwards has it.
## A card goes Mk I, Mk II, Mk III (spending coins and a spare copy each time),
## can carry one mod from Mk II, and can be painted any colour you own.

const FILTERS := [["All", ""], ["Prints", "creature"], ["Tools", "tool"], ["Armor", "upgrade"]]
const TIER_NAMES := ["", "Mk I", "Mk II", "Mk III"]

var _sel := ""
var _filter := ""
var _strip_scroll := 0.0
var _scroll: ScrollContainer
var _scroll_y := 0.0


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_terminal_closeup_v2.png", 0.8)
	top_bar("Blueprints")
	if _sel == "" and args.has("card"):
		_sel = str(args["card"])
	_scroll = null
	var owned := _owned()
	if _sel == "" or not owned.any(func(c): return c["id"] == _sel):
		_sel = owned[0]["id"] if not owned.is_empty() else ""
	_filters()
	_strip(owned)
	if _sel == "":
		var none := UI.label("You do not own any cards yet. Open some packs first.", 22, UI.MUTED, false)
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(self, none, Vector2(0, 360), Vector2(W, 40))
		return
	_editor()


func _owned() -> Array:
	var out: Array = []
	for c in GameData.collectible():
		if Profile.owned_count(c["id"]) > 0 and (_filter == "" or c["type"] == _filter):
			out.append(c)
	return out


func _filters() -> void:
	var fw := 96.0 if P else 112.0
	for i in FILTERS.size():
		var key: String = FILTERS[i][1]
		var b := UI.button(FILTERS[i][0], "primary" if _filter == key else "plain", Vector2(fw, 40), 17)
		b.pressed.connect(func():
			_filter = key
			_strip_scroll = 0.0
			relayout())
		UI.place(self, b, Vector2(14 + i * (fw + 6), 82))


## A row of small cards to pick from.
func _strip(owned: Array) -> void:
	var sc := ScrollContainer.new()
	sc.position = Vector2(0, 128)
	sc.size = Vector2(W, 136)
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(sc)
	var row := Control.new()
	var tile := 90.0
	row.custom_minimum_size = Vector2(maxf(owned.size() * (tile + 6.0) + 12.0, W), 130)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	sc.add_child(row)
	var s := tile / CardView.W
	for i in owned.size():
		var id: String = owned[i]["id"]
		var card := CardView.make(id, s, Profile.build_of(id))
		card.position = Vector2(8 + i * (tile + 6.0), 4)
		if id == _sel:
			card.set_glow(UI.GOLD)
		row.add_child(card)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		for stl in ["normal", "hover", "pressed", "focus"]:
			hit.add_theme_stylebox_override(stl, StyleBoxEmpty.new())
		hit.position = card.position
		hit.size = Vector2(tile, CardView.H * s)
		hit.pressed.connect(func():
			_strip_scroll = sc.scroll_horizontal
			_sel = id
			Audio.sfx("pick")
			relayout())
		row.add_child(hit)
	sc.scroll_horizontal = int(_strip_scroll)
	# Keep the selected card in view after a rebuild.
	if _sel != "":
		for i in owned.size():
			if owned[i]["id"] == _sel and sc.scroll_horizontal > i * (tile + 6.0) + 6.0:
				sc.scroll_horizontal = int(i * (tile + 6.0))


# ------------------------------------------------------------------- editor

func _editor() -> void:
	var def := GameData.card(_sel)
	var build := Profile.build_of(_sel)
	var top := 272.0
	var preview_scale := 0.78 if P else 1.0
	var card := CardView.make(_sel, preview_scale, build)
	var card_w := CardView.W * preview_scale
	var content: Control
	var w: float
	if P:
		card.position = Vector2(16, top + 6)
		# The controls scroll beside the card, so the card is always in view.
		var sc := ScrollContainer.new()
		sc.position = Vector2(card_w + 28, top)
		sc.size = Vector2(W - card_w - 40, H - top)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		add_child(sc)
		w = sc.size.x - 8
		content = Control.new()
		content.custom_minimum_size = Vector2(w, _content_height(w))
		content.mouse_filter = Control.MOUSE_FILTER_PASS
		sc.add_child(content)
		_scroll = sc
	else:
		card.position = Vector2(40, top + 6)
		var sc := ScrollContainer.new()
		sc.position = Vector2(card_w + 80, top)
		sc.size = Vector2(W - card_w - 100, H - top - 4)
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		add_child(sc)
		w = sc.size.x - 12
		content = Control.new()
		content.custom_minimum_size = Vector2(w, _content_height(w))
		content.mouse_filter = Control.MOUSE_FILTER_PASS
		sc.add_child(content)
		_scroll = sc
	add_child(card)
	_scroll.scroll_vertical = int(_scroll_y)
	_scroll.get_v_scroll_bar().value_changed.connect(func(v: float): _scroll_y = v)

	var y := 0.0
	var tier := int(build["tier"])
	var title := UI.label("%s   %s" % [def["name"], TIER_NAMES[tier]], 28 if not P else 22, UI.GOLD, true, 5)
	UI.place(content, title, Vector2(0, y), Vector2(w, 36))
	y += 40.0
	var spare := UI.label("Spare copies: %d    Maker Rank %d" % [Profile.spares(_sel), Profile.rank_level()], 16, UI.MUTED, false)
	UI.place(content, spare, Vector2(0, y), Vector2(w, 22))
	y += 32.0
	y = _tier_section(content, y, w, tier)
	y = _mod_section(content, y, w, tier, build)
	_paint_section(content, y, w, build)


func _content_height(w: float) -> float:
	var mods := 0
	for m in GameData.CARD_MODS:
		if GameData.mod_fits(m["id"], _sel):
			mods += 1
	var per_row := maxi(int((w + 8.0) / 76.0), 1)
	var paint_rows := ceili(float(GameData.PAINTS.size()) / per_row)
	return 40.0 + 32.0 + 250.0 + 70.0 + mods * 70.0 + 70.0 + paint_rows * 92.0 + 40.0


func _tier_section(content: Control, y: float, w: float, tier: int) -> float:
	UI.place(content, UI.label("Tier", 20, UI.CREAM), Vector2(0, y), Vector2(w, 26))
	y += 30.0
	for t in range(1, GameData.MAX_TIER + 1):
		var on := t <= tier
		UI.panel(content, Rect2(0, y, w, 46), UI.box(Color(0.04, 0.07, 0.14, 0.9), UI.GOLD if t == tier else (UI.BRASS_DARK if on else Color("2a3346")), 2, 12))
		UI.place(content, UI.label(TIER_NAMES[t], 19, UI.GOLD if on else UI.MUTED), Vector2(14, y + 10), Vector2(70, 26))
		var gain := _gain_text(t)
		var l := UI.label(gain, 15, UI.CREAM if on else UI.MUTED, false)
		l.clip_text = true
		UI.place(content, l, Vector2(86, y + 12), Vector2(w - 100, 24))
		y += 52.0
	if tier >= GameData.MAX_TIER:
		UI.place(content, UI.label("Fully built.", 18, UI.GOOD), Vector2(0, y + 4), Vector2(w, 26))
		y += 34.0
	else:
		var next := tier + 1
		var err := Profile.tier_error(_sel)
		var up := UI.button("Upgrade to %s" % TIER_NAMES[next], "primary", Vector2(minf(w, 300.0), 52), 20)
		up.disabled = err != ""
		up.pressed.connect(_upgrade)
		UI.place(content, up, Vector2(0, y + 4))
		var cost := "%d coins" % GameData.tier_coins(_sel, next)
		if int(GameData.TIER_SPARES[next]) > 0:
			cost += "  +  %d spare" % int(GameData.TIER_SPARES[next])
		var info := UI.label(err if err != "" else cost, 14, UI.AMBER if err != "" else UI.MUTED, false)
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(content, info, Vector2(0, y + 60), Vector2(w, 40))
		y += 92.0
	var craft_cost := Profile.craft_cost(_sel)
	var spare := UI.button("Print a spare  (%d)" % craft_cost, "plain", Vector2(minf(w, 300.0), 44), 17)
	spare.disabled = Profile.coins() < craft_cost or Profile.spares(_sel) >= GameData.MAX_SPARES
	spare.pressed.connect(func():
		var e := Profile.craft_spare(_sel)
		if e != "":
			_fail(e)
		else:
			Audio.sfx("print")
			relayout())
	UI.place(content, spare, Vector2(0, y))
	return y + 60.0


## What reaching a tier adds, in words.
func _gain_text(tier: int) -> String:
	if tier == 1:
		return "The card as found."
	var before := GameData.built(_sel, {"tier": tier - 1})
	var after := GameData.built(_sel, {"tier": tier})
	var bits: Array = []
	if after["type"] == "creature":
		if int(after["atk"]) != int(before["atk"]):
			bits.append("+%d Attack" % (int(after["atk"]) - int(before["atk"])))
		if int(after["hp"]) != int(before["hp"]):
			bits.append("+%d Health" % (int(after["hp"]) - int(before["hp"])))
	elif str(after["text"]) != str(before["text"]):
		bits.append("Effect +1")
	if int(after["cost"]) != int(before["cost"]):
		bits.append("Costs %d less" % (int(before["cost"]) - int(after["cost"])))
	if tier == 2:
		bits.append("Mod slot")
	return ",  ".join(bits)


func _mod_section(content: Control, y: float, w: float, tier: int, build: Dictionary) -> float:
	UI.place(content, UI.label("Mod", 20, UI.CREAM), Vector2(0, y), Vector2(w, 26))
	y += 30.0
	if tier < 2:
		var lock := UI.label("One mod fits a card from Mk II. Each mod gives something and takes something.", 15, UI.MUTED, false)
		lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(content, lock, Vector2(0, y), Vector2(w, 44))
		return y + 60.0
	var fitted := str(build["mod"])
	for m in GameData.CARD_MODS:
		var id: String = m["id"]
		if not GameData.mod_fits(id, _sel):
			continue
		var owned := Profile.owns_card_mod(id)
		var on := fitted == id
		UI.panel(content, Rect2(0, y, w, 62), UI.box(Color(0.04, 0.07, 0.14, 0.9), UI.GOOD if on else (UI.BRASS_DARK if owned else Color("2a3346")), 2, 12))
		var ic := IconView.make(m["icon"], 30, UI.AMBER if owned else Color("55607a"))
		ic.position = Vector2(12, y + 16)
		content.add_child(ic)
		UI.place(content, UI.label(m["name"], 17, UI.CREAM if owned else UI.MUTED), Vector2(52, y + 6), Vector2(w - 190, 24))
		var tx := UI.label(m["text"], 13, UI.MUTED, false)
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(content, tx, Vector2(52, y + 30), Vector2(w - 190, 30))
		var bw := 118.0
		if owned:
			var b := UI.button("Remove" if on else "Fit", "plain" if on else "go", Vector2(bw, 40), 17)
			b.pressed.connect(func(): _fit_mod("" if on else id))
			UI.place(content, b, Vector2(w - bw - 8, y + 11))
		elif Profile.rank_level() < int(m["rank"]):
			var l := UI.label("Rank %d" % int(m["rank"]), 16, UI.AMBER)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UI.place(content, l, Vector2(w - bw - 8, y + 18), Vector2(bw, 24))
		else:
			var b := UI.button("Unlock\n%d" % int(m["cost"]), "primary", Vector2(bw, 48), 14)
			b.disabled = Profile.coins() < int(m["cost"])
			b.pressed.connect(func(): _unlock_mod(id))
			UI.place(content, b, Vector2(w - bw - 8, y + 7))
		y += 68.0
	return y + 12.0


func _paint_section(content: Control, y: float, w: float, build: Dictionary) -> void:
	UI.place(content, UI.label("Paint", 20, UI.CREAM), Vector2(0, y), Vector2(w, 26))
	y += 32.0
	var per_row := maxi(int((w + 8.0) / 76.0), 1)
	var element := GameData.element_color(str(GameData.card(_sel).get("element", "Neutral")))
	for i in GameData.PAINTS.size():
		var p: Dictionary = GameData.PAINTS[i]
		var id: String = p["id"]
		var pos := Vector2((i % per_row) * 76.0, y + (i / per_row) * 92.0)
		var owned := Profile.owns_paint(id)
		var on := str(build["paint"]) == id
		var sw := Control.new()
		sw.position = pos
		sw.size = Vector2(68, 68)
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Swatches show the paint on a neutral red, so they read the same on every card;
		# the first one shows the card's own colour.
		var col := element if id == "original" else Color.from_hsv(fposmod(float(p["hue"]) / 360.0, 1.0), clampf(0.72 * float(p["sat"]), 0.0, 1.0), clampf(0.95 * float(p["val"]), 0.0, 1.0))
		sw.draw.connect(func():
			sw.draw_circle(Vector2(34, 34), 31.0, Color("0b1220"))
			sw.draw_circle(Vector2(34, 34), 27.0, col if owned else col.darkened(0.6))
			if on:
				sw.draw_arc(Vector2(34, 34), 32.0, 0, TAU, 40, UI.GOLD, 4.0, true)
			if not owned:
				UI.draw_icon(sw, "lock", Vector2(34, 34), 12.0, Color(1, 1, 1, 0.85)))
		content.add_child(sw)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		for stl in ["normal", "hover", "pressed", "focus"]:
			hit.add_theme_stylebox_override(stl, StyleBoxEmpty.new())
		hit.position = pos
		hit.size = Vector2(68, 88)
		hit.pressed.connect(func(): _paint(id))
		content.add_child(hit)
		var caption: String = p["name"] if owned or int(p["price"]) == 0 else ("%d" % int(p["price"]) if Profile.rank_level() >= int(p["rank"]) else "Rank %d" % int(p["rank"]))
		var l := UI.label(str(caption), 13, UI.MUTED if not on else UI.GOLD, false)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(content, l, pos + Vector2(-4, 68), Vector2(76, 18))


# ------------------------------------------------------------------ actions

func _fail(text: String) -> void:
	Audio.sfx("deny")
	app.toast(text, UI.AMBER)


func _upgrade() -> void:
	var err := Profile.upgrade_card(_sel)
	if err != "":
		_fail(err)
		return
	Audio.sfx("upgrade")
	app.toast("%s is now %s!" % [GameData.card(_sel)["name"], TIER_NAMES[int(Profile.build_of(_sel)["tier"])]], UI.GOOD)
	relayout()


func _unlock_mod(id: String) -> void:
	var err := Profile.buy_card_mod(id)
	if err != "":
		_fail(err)
		return
	Audio.sfx("buy")
	relayout()


func _fit_mod(id: String) -> void:
	var err := Profile.set_card_mod(_sel, id)
	if err != "":
		_fail(err)
		return
	Audio.sfx("mod_install" if id != "" else "back")
	relayout()


func _paint(id: String) -> void:
	if not Profile.owns_paint(id):
		var err := Profile.buy_paint(id)
		if err != "":
			_fail(err)
			return
		Audio.sfx("buy")
	var err2 := Profile.set_paint(_sel, id)
	if err2 != "":
		_fail(err2)
		return
	Audio.sfx("pick")
	relayout()
