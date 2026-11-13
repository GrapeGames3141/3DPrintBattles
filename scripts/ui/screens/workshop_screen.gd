extends GameScreen
## The workshop: your Maker Rank, the Printers you can buy, and the mods you
## bolt into their slots. Everything here is the long game: ranks and prices
## are set so that owning it all takes a long time.

var _tab := "printers"
var _body: Control
var _popup: Control
var _install_for := ""


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_maker_closeup_v2.png", 0.8)
	top_bar("Workshop")
	_body = null
	_popup = null
	_rank_panel()
	_tabs()
	_refresh()
	if _install_for != "":
		_open_install(_install_for)


# ------------------------------------------------------------------- header

func _rank_panel() -> void:
	var r: Dictionary = Profile.rank()
	var box := Rect2(16, 80, W - 32, 64)
	UI.panel(self, box, UI.box(Color(0.04, 0.07, 0.14, 0.94), UI.BRASS_DARK, 2, 14))
	var title := UI.label("Maker Rank %d" % int(r["rank"]), 24, UI.GOLD, true, 4)
	UI.place(self, title, box.position + Vector2(14, 6), Vector2(240, 30))
	var bar := Rect2(box.position + Vector2(14, 40), Vector2(box.size.x - 28, 14))
	UI.panel(self, bar, UI.box(Color("0a1322"), UI.CYAN.darkened(0.5), 2, 7))
	var need: int = int(r["need"])
	var frac := 1.0 if need == 0 else float(r["into"]) / float(need)
	if frac > 0.0:
		UI.panel(self, Rect2(bar.position + Vector2(2, 2), Vector2(maxf((bar.size.x - 4) * frac, 10.0), bar.size.y - 4)), UI.box(UI.CYAN, Color.TRANSPARENT, 0, 5))
	var text := "MAX RANK" if need == 0 else "%d / %d XP" % [int(r["into"]), need]
	var xp := UI.label(text, 16, UI.CREAM, false)
	xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI.place(self, xp, box.position + Vector2(box.size.x - 330, 12), Vector2(316, 24))
	var hint := UI.label(_next_unlock(), 15, UI.MUTED, false)
	hint.clip_text = true
	UI.place(self, hint, box.position + Vector2(280, 12), Vector2(maxf(box.size.x - 640.0, 10.0), 24))
	hint.visible = not P


## The nearest thing a higher rank would let you buy.
func _next_unlock() -> String:
	var rank := Profile.rank_level()
	var best := ""
	var best_rank := 999
	for p in GameData.PRINTERS:
		if not Profile.owns_printer(p["id"]) and Profile.printer_rank(p["id"]) > rank and Profile.printer_rank(p["id"]) < best_rank:
			best_rank = Profile.printer_rank(p["id"])
			best = "Rank %d: %s" % [best_rank, p["name"]]
	for m in GameData.PRINTER_MODS:
		var need := int(m["rank"])
		if not Profile.owns_mod(str(m["id"])) and need > rank and need < best_rank:
			best_rank = need
			best = "Rank %d: %s" % [need, m["name"]]
	return "Next unlock  -  " + best if best != "" else ""


func _tabs() -> void:
	var names := {"printers": "Printers", "mods": "Mods"}
	var x := 16.0
	for key in ["printers", "mods"]:
		var b := UI.button(names[key], "primary" if _tab == key else "plain", Vector2(150, 44), 21)
		b.pressed.connect(func():
			_tab = key
			relayout())
		UI.place(self, b, Vector2(x, 154))
		x += 160.0
	var crate := UI.button("Mod Crate   %d" % GameData.MOD_CRATE_PRICE, "primary", Vector2(250, 44), 19)
	crate.tooltip_text = "A random mod, picked by rarity: a card mod or a Printer mod"
	crate.disabled = Profile.coins() < GameData.MOD_CRATE_PRICE
	crate.pressed.connect(_open_crate)
	UI.place(self, crate, Vector2(W - 16.0 - 250.0, 154))
	var owned := UI.label("%d of %d Printers   %d of %d mods" % [(Profile.data["printers"] as Array).size(), GameData.PRINTERS.size(), _mods_owned(), GameData.PRINTER_MODS.size()], 16, UI.MUTED, false)
	UI.place(self, owned, Vector2(340, 164), Vector2(W - 360, 24))
	owned.visible = not P


func _mods_owned() -> int:
	var n := 0
	for m in GameData.PRINTER_MODS:
		if Profile.owns_mod(str(m["id"])):
			n += 1
	return n


# ------------------------------------------------------------------ content

func _refresh() -> void:
	if is_instance_valid(_body):
		(_body.get_parent() as Node).queue_free()
	if _tab == "printers":
		_printers_tab()
	else:
		_mods_tab()


func _printers_tab() -> void:
	var pitch := 270.0
	var cols := maxi(1, int((W - 12.0 + 20.0) / pitch))
	var rows := ceili(float(GameData.PRINTERS.size()) / cols)
	_body = scroll_body(206, rows * 332.0 + 20.0)
	var x0 := (W - 12.0 - (cols * pitch - 20.0)) * 0.5
	for i in GameData.PRINTERS.size():
		var p: Dictionary = GameData.PRINTERS[i]
		var pos := Vector2(x0 + (i % cols) * pitch, 8.0 + (i / cols) * 332.0)
		_printer_cell(p, pos)


func _printer_cell(p: Dictionary, pos: Vector2) -> void:
	var id: String = p["id"]
	var col := GameData.element_color(p["element"])
	var owned := Profile.owns_printer(id)
	var rank_ok := Profile.rank_level() >= Profile.printer_rank(id)
	var cell := UI.panel(_body, Rect2(pos, Vector2(250, 318)), UI.box(Color(UI.PANEL, 0.95), col if owned else UI.BRASS_DARK, 3 if owned else 2, 14, 6))
	var img := PrinterRig.make(id, Profile.installed_mods(id) if owned else [], Rect2(55, 6, 140, 124))
	if not owned:
		img.modulate = Color(0.55, 0.58, 0.66) if rank_ok else Color(0.3, 0.32, 0.38)
	cell.add_child(img)
	var nm := UI.label(p["name"], 21, col)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(cell, nm, Vector2(0, 130), Vector2(250, 26))
	var meta := UI.label("%s   -   %d mods fitted" % [p["element"], Profile.installed_mods(id).size()] if owned else p["element"], 14, UI.MUTED, false)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(cell, meta, Vector2(0, 156), Vector2(250, 20))
	var pw := UI.label("%s (%d Filament)\n%s" % [p["power"]["name"], GameData.power_cost(id), p["power"]["text"]], 14, UI.CREAM, false)
	pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(cell, pw, Vector2(10, 180), Vector2(230, 62))
	if owned:
		var b := UI.button("Mods  %d / %d" % [Profile.installed_mods(id).size(), _mods_owned()], "go", Vector2(200, 46), 19)
		b.pressed.connect(func(): _open_install(id))
		UI.place(cell, b, Vector2(25, 256))
	elif not rank_ok:
		var lock := UI.label("Needs Maker Rank %d" % Profile.printer_rank(id), 17, UI.AMBER)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(cell, lock, Vector2(0, 252), Vector2(250, 24))
		var cost := UI.label("%d coins" % Profile.printer_price(id), 15, UI.MUTED, false)
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(cell, cost, Vector2(0, 280), Vector2(250, 22))
	else:
		var buy := UI.button("Buy for %d" % Profile.printer_price(id), "primary", Vector2(200, 46), 19)
		buy.disabled = Profile.coins() < Profile.printer_price(id)
		buy.pressed.connect(_buy_printer.bind(id))
		UI.place(cell, buy, Vector2(25, 256))


func _mods_tab() -> void:
	var cols := 1 if P else 2
	var pitch_x := 600.0
	var mods: Array = GameData.PRINTER_MODS.duplicate()
	mods.sort_custom(func(a, b):
		var ra := GameData.RARITY_ORDER.find(a["rarity"])
		var rb := GameData.RARITY_ORDER.find(b["rarity"])
		if ra != rb:
			return ra < rb
		return int(a["cost"]) < int(b["cost"]))
	var rows := ceili(float(mods.size()) / cols)
	_body = scroll_body(206, rows * 150.0 + 20.0)
	var width := minf(W - 40.0, 580.0)
	var x0 := (W - 12.0 - (cols * pitch_x - (pitch_x - width))) * 0.5
	for i in mods.size():
		var m: Dictionary = mods[i]
		_mod_cell(m, Vector2(x0 + (i % cols) * pitch_x, 8.0 + (i / cols) * 150.0), width)


func _mod_cell(m: Dictionary, pos: Vector2, width: float) -> void:
	var id: String = m["id"]
	var own := Profile.owns_mod(id)
	var cell := UI.panel(_body, Rect2(pos, Vector2(width, 138)), UI.box(Color(UI.PANEL, 0.95), UI.AMBER if own else UI.BRASS_DARK, 2, 14, 6))
	var ic := IconView.make(m["icon"], 46, UI.AMBER)
	ic.position = Vector2(16, 14)
	cell.add_child(ic)
	var part := UI.tex("res://assets/printer_mods/%s.png" % id)
	if part != null:
		var pic := TextureRect.new()
		pic.texture = part
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pic.position = Vector2(width - 150, 8)
		pic.size = Vector2(86, 86)
		pic.modulate = Color.WHITE if own else Color(0.7, 0.72, 0.8)
		cell.add_child(pic)
	var nm := UI.label(m["name"], 22, GameData.rarity_color(str(m["rarity"])))
	UI.place(cell, nm, Vector2(76, 10), Vector2(width - 230, 28))
	var rt := UI.label(str(GameData.RARITIES[m["rarity"]]["name"]), 13, UI.MUTED, false)
	UI.place(cell, rt, Vector2(76, 40), Vector2(200, 20))
	var tx := UI.label(GameData.mod_text(id), 15, UI.CREAM, false)
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(cell, tx, Vector2(16, 66), Vector2(width - 160, 40))
	var needs: Array = GameData.mod_requires(id)
	if not needs.is_empty():
		var names: Array = []
		for r in needs:
			names.append(str(GameData.mod(str(r))["name"]))
		var missing := Profile.mod_locked_by(id)
		var nl := UI.label("Needs: " + ", ".join(names), 14, UI.AMBER if not missing.is_empty() else UI.GOOD, false)
		nl.clip_text = true
		UI.place(cell, nl, Vector2(16, 110), Vector2(width - 160, 20))
	var side := Vector2(width - 146, 94)
	if own:
		var mx := UI.label("OWNED", 22, UI.GOOD)
		mx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(cell, mx, Vector2(width - 150, 98), Vector2(136, 30))
		return
	var cost := int(m["cost"])
	var need := int(m["rank"])
	var locked_by := Profile.mod_locked_by(id)
	if not locked_by.is_empty():
		var lock := UI.label("Buy %s first" % GameData.mod(str(locked_by[0]))["name"], 15, UI.AMBER, false)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(cell, lock, Vector2(width - 150, 98), Vector2(136, 36))
		return
	if Profile.rank_level() < need:
		var lock := UI.label("Rank %d" % need, 20, UI.AMBER)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(cell, lock, Vector2(width - 150, 92), Vector2(136, 26))
		var c := UI.label("%d coins" % cost, 15, UI.MUTED, false)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(cell, c, Vector2(width - 150, 116), Vector2(136, 20))
		return
	var buy := UI.button("Buy  %d" % cost, "primary", Vector2(136, 38), 18)
	buy.disabled = Profile.coins() < cost
	buy.pressed.connect(_buy_mod.bind(id))
	UI.place(cell, buy, side - Vector2(4, 0) + Vector2(0, 0))


# ------------------------------------------------------------------ actions

## Buys a Mod Crate and shows what was in it.
func _open_crate() -> void:
	var got := Profile.buy_mod_crate()
	if got.has("error"):
		Audio.sfx("deny")
		app.toast(str(got["error"]), UI.AMBER)
		return
	Audio.sfx("reveal_epic" if got["rarity"] in ["epic", "legendary"] else "reveal")
	var m := modal()
	var col := GameData.rarity_color(str(got["rarity"]))
	var box := dialog(m, Vector2(520, 380), UI.box(Color(UI.PANEL, 0.97), col, 4, 18, 12))
	var head := UI.label("Mod Crate", 30, UI.GOLD)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, head, Vector2(0, 18), Vector2(520, 40))
	var rar := UI.label(str(GameData.RARITIES[got["rarity"]]["name"]).to_upper(), 20, col)
	rar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, rar, Vector2(0, 76), Vector2(520, 28))
	var nm := UI.label(str(got["name"]), 38, col, true, 6)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, nm, Vector2(0, 108), Vector2(520, 50))
	var tx := UI.label(str(got["text"]), 19, UI.CREAM, false)
	tx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(box, tx, Vector2(30, 170), Vector2(460, 60))
	var where := UI.label("A card mod: fit it from a card's Blueprint." if got["kind"] == "card" else "A Printer mod: it is fitted to your Printers already.", 16, UI.MUTED, false)
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, where, Vector2(0, 244), Vector2(520, 24))
	var ok := UI.button("Nice!", "go", Vector2(220, 56), 24)
	ok.pressed.connect(func():
		close_modal(m)
		relayout())
	UI.place(box, ok, Vector2(150, 296))

func _buy_printer(id: String) -> void:
	var err := Profile.buy_printer(id)
	if err != "":
		Audio.sfx("deny")
		app.toast(err, UI.AMBER)
		return
	Audio.sfx("buy")
	app.toast("%s added to your workshop. Pick it for a deck in Collection & Decks." % GameData.printer(id)["name"], UI.GOOD)
	relayout()


func _buy_mod(id: String) -> void:
	var err := Profile.buy_mod(id)
	if err != "":
		Audio.sfx("deny")
		app.toast(err, UI.AMBER)
		return
	Audio.sfx("buy")
	relayout()


# ------------------------------------------------------------------ install

var _install_rig: PrinterRig
var _install_rows: Control
var _install_count: Label


## One Printer's mods: a big picture of the machine with what it carries, and
## every mod you own to fit or take off. There is no limit on how many it takes.
func _open_install(printer_id: String) -> void:
	_install_for = printer_id
	if is_instance_valid(_popup):
		_popup.get_parent().queue_free()
	_popup = modal(0.88)
	var box := dialog(_popup, Vector2(1120, 660) if not P else Vector2(690, 1180))
	var bw := box.size.x
	var bh := box.size.y
	var pr := GameData.printer(printer_id)
	var title := UI.label("%s mods" % pr["name"], 30, GameData.element_color(pr["element"]), true, 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, title, Vector2(0, 12), Vector2(bw, 40))
	var pic_w := 380.0 if not P else 420.0
	var pic := Vector2(pic_w, pic_w * 0.913)
	var pic_pos := Vector2(24, 70) if not P else Vector2((bw - pic.x) * 0.5, 62)
	UI.panel(box, Rect2(pic_pos - Vector2(8, 8), pic + Vector2(16, 16)), UI.box(Color(0.03, 0.05, 0.1, 0.9), GameData.element_color(pr["element"]), 2, 14))
	_install_rig = PrinterRig.make(printer_id, Profile.installed_mods(printer_id), Rect2(pic_pos, pic))
	box.add_child(_install_rig)
	_install_count = UI.label("", 17, UI.CREAM, false)
	_install_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, _install_count, pic_pos + Vector2(-8, pic.y + 14), Vector2(pic.x + 16, 24))
	var hint := UI.label("Fit every mod you own: there is no limit. Some mods need another one fitted first. Each one changes how the machine looks.", 14, UI.MUTED, false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(box, hint, pic_pos + Vector2(-8, pic.y + 46), Vector2(pic.x + 16, 60))
	var list_pos := Vector2(pic_pos.x + pic.x + 36, 64) if not P else Vector2(24, pic_pos.y + pic.y + 130)
	var list_size := Vector2(bw - list_pos.x - 24, bh - list_pos.y - 90)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.position = list_pos
	scroll.size = list_size
	box.add_child(scroll)
	_install_rows = Control.new()
	_install_rows.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(_install_rows)
	_fill_install_rows(list_size.x - 8.0)
	var done := UI.button("Done", "primary", Vector2(220, 52), 22)
	done.pressed.connect(func():
		_install_for = ""
		close_modal(_popup)
		_popup = null
		relayout())
	UI.place(box, done, Vector2(bw * 0.5 - 110, bh - 68))


## The owned mods, strongest rarity first, each with a switch.
func _fill_install_rows(width: float) -> void:
	for c in _install_rows.get_children():
		c.queue_free()
	var printer_id := _install_for
	var fitted: Array = Profile.installed_mods(printer_id)
	var owned: Array = []
	for m in GameData.PRINTER_MODS:
		if Profile.owns_mod(str(m["id"])):
			owned.append(m)
	owned.sort_custom(func(a, b):
		var ra := GameData.RARITY_ORDER.find(a["rarity"])
		var rb := GameData.RARITY_ORDER.find(b["rarity"])
		if ra != rb:
			return ra > rb
		return int(a["cost"]) < int(b["cost"]))
	_install_count.text = "%d of %d mods fitted" % [fitted.size(), owned.size()]
	if owned.is_empty():
		var none := UI.label("You have not bought any mods yet. Buy some on the Mods tab.", 18, UI.MUTED, false)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(_install_rows, none, Vector2(8, 8), Vector2(width - 16, 60))
		_install_rows.custom_minimum_size = Vector2(width, 80)
		return
	var y := 0.0
	for m in owned:
		var id: String = m["id"]
		var on := fitted.has(id)
		var missing := GameData.missing_requirements(id, fitted)
		var edge := GameData.rarity_color(str(m["rarity"])) if on else UI.BRASS_DARK
		UI.panel(_install_rows, Rect2(0, y, width, 66), UI.box(Color(0.03, 0.06, 0.12, 0.9), edge, 2, 12))
		var part := UI.tex("res://assets/printer_mods/%s.png" % id)
		if part != null:
			var pic := TextureRect.new()
			pic.texture = part
			pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pic.position = Vector2(6, y + 3)
			pic.size = Vector2(60, 60)
			pic.modulate = Color.WHITE if on else Color(0.62, 0.64, 0.72)
			_install_rows.add_child(pic)
		var nm := UI.label(m["name"], 18, GameData.rarity_color(str(m["rarity"])), on)
		nm.clip_text = true
		UI.place(_install_rows, nm, Vector2(72, y + 5), Vector2(width - 72 - 124, 24))
		var line := GameData.mod_text(id)
		var col := UI.MUTED
		if not on and not missing.is_empty():
			line = "Fit %s first." % missing[0]
			col = UI.AMBER
		var tx := UI.label(line, 13, col, false)
		tx.clip_text = true
		tx.autowrap_mode = TextServer.AUTOWRAP_OFF
		UI.place(_install_rows, tx, Vector2(72, y + 32), Vector2(width - 72 - 124, 22))
		var b := UI.button("Fitted" if on else "Fit", "go" if on else "plain", Vector2(108, 42), 17)
		b.disabled = not on and not missing.is_empty()
		b.pressed.connect(func(): _toggle_mod(printer_id, id, width))
		UI.place(_install_rows, b, Vector2(width - 116, y + 12))
		y += 72.0
	_install_rows.custom_minimum_size = Vector2(width, y)


func _toggle_mod(printer_id: String, mod_id: String, width: float) -> void:
	if Profile.installed_mods(printer_id).has(mod_id):
		var gone := Profile.remove_mod(printer_id, mod_id)
		Audio.sfx("back")
		if not gone.is_empty():
			var names: Array = []
			for g in gone:
				names.append(str(GameData.mod(str(g))["name"]))
			app.toast("Also took off: %s" % ", ".join(names), UI.AMBER)
	else:
		var err := Profile.install_mod(printer_id, mod_id)
		if err != "":
			Audio.sfx("deny")
			app.toast(err, UI.AMBER)
			return
		Audio.sfx("mod_install")
	_install_rig.set_mods(Profile.installed_mods(printer_id))
	_fill_install_rows(width)
