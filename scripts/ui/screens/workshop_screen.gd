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
		var need := Profile.mod_rank(m["id"])
		if need > rank and need < best_rank:
			best_rank = need
			best = "Rank %d: %s level %d" % [need, m["name"], Profile.mod_level(m["id"]) + 1]
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
	crate.tooltip_text = "A random mod, picked by rarity: a card mod or a level of a Printer mod"
	crate.disabled = Profile.coins() < GameData.MOD_CRATE_PRICE
	crate.pressed.connect(_open_crate)
	UI.place(self, crate, Vector2(W - 16.0 - 250.0, 154))
	var owned := UI.label("%d of %d Printers   %d of %d mod levels" % [(Profile.data["printers"] as Array).size(), GameData.PRINTERS.size(), _mod_levels_owned(), _mod_levels_total()], 16, UI.MUTED, false)
	UI.place(self, owned, Vector2(340, 164), Vector2(W - 360, 24))
	owned.visible = not P


func _mod_levels_owned() -> int:
	var n := 0
	for m in GameData.PRINTER_MODS:
		n += Profile.mod_level(m["id"])
	return n


func _mod_levels_total() -> int:
	var n := 0
	for m in GameData.PRINTER_MODS:
		n += GameData.mod_max(m["id"])
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
	var img := UI.image("res://assets/printers/%s.png" % id, Rect2(55, 6, 140, 124))
	if not owned:
		img.modulate = Color(0.55, 0.58, 0.66) if rank_ok else Color(0.3, 0.32, 0.38)
	cell.add_child(img)
	var nm := UI.label(p["name"], 21, col)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(cell, nm, Vector2(0, 130), Vector2(250, 26))
	var meta := UI.label("%s   -   %d mod slots" % [p["element"], GameData.printer_slots(id)], 14, UI.MUTED, false)
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(cell, meta, Vector2(0, 156), Vector2(250, 20))
	var pw := UI.label("%s (%d Filament)\n%s" % [p["power"]["name"], GameData.power_cost(id), p["power"]["text"]], 14, UI.CREAM, false)
	pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(cell, pw, Vector2(10, 180), Vector2(230, 62))
	if owned:
		var used := 0
		for m in Profile.installed_mods(id):
			if str(m) != "":
				used += 1
		var b := UI.button("Mods  %d / %d" % [used, GameData.printer_slots(id)], "go", Vector2(200, 46), 19)
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
		return int(a["costs"][0]) < int(b["costs"][0]))
	var rows := ceili(float(mods.size()) / cols)
	_body = scroll_body(206, rows * 150.0 + 20.0)
	var width := minf(W - 40.0, 580.0)
	var x0 := (W - 12.0 - (cols * pitch_x - (pitch_x - width))) * 0.5
	for i in mods.size():
		var m: Dictionary = mods[i]
		_mod_cell(m, Vector2(x0 + (i % cols) * pitch_x, 8.0 + (i / cols) * 150.0), width)


func _mod_cell(m: Dictionary, pos: Vector2, width: float) -> void:
	var id: String = m["id"]
	var lvl := Profile.mod_level(id)
	var top := GameData.mod_max(id)
	var cell := UI.panel(_body, Rect2(pos, Vector2(width, 138)), UI.box(Color(UI.PANEL, 0.95), UI.AMBER if lvl > 0 else UI.BRASS_DARK, 2, 14, 6))
	var ic := IconView.make(m["icon"], 46, UI.AMBER)
	ic.position = Vector2(16, 14)
	cell.add_child(ic)
	var nm := UI.label(m["name"], 22, GameData.rarity_color(str(m["rarity"])))
	UI.place(cell, nm, Vector2(76, 10), Vector2(width - 230, 28))
	var rt := UI.label(str(GameData.RARITIES[m["rarity"]]["name"]), 13, UI.MUTED, false)
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI.place(cell, rt, Vector2(width - 150, 14), Vector2(136, 20))
	for k in top:
		var pip := IconView.make("hex", 20, UI.GOLD if k < lvl else Color("3a4660"))
		pip.position = Vector2(76 + k * 26, 42)
		cell.add_child(pip)
	var shown := lvl if lvl >= top else lvl + 1
	var prefix := "" if lvl >= top else ("Level %d:  " % shown)
	var tx := UI.label(prefix + GameData.mod_text(id, shown), 15, UI.MUTED, false)
	tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(cell, tx, Vector2(16, 72), Vector2(width - 160, 60))
	var cost := Profile.mod_cost(id)
	if cost < 0:
		var mx := UI.label("MAX", 24, UI.GOOD)
		mx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(cell, mx, Vector2(width - 140, 50), Vector2(124, 32))
		return
	var need := Profile.mod_rank(id)
	if Profile.rank_level() < need:
		var lock := UI.label("Rank %d" % need, 20, UI.AMBER)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(cell, lock, Vector2(width - 146, 36), Vector2(130, 28))
		var c := UI.label("%d coins" % cost, 15, UI.MUTED, false)
		c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(cell, c, Vector2(width - 146, 66), Vector2(130, 22))
		return
	var buy := UI.button("Buy\n%d" % cost, "primary", Vector2(124, 70), 19)
	buy.disabled = Profile.coins() < cost
	buy.pressed.connect(_buy_mod.bind(id))
	UI.place(cell, buy, Vector2(width - 140, 34))


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
	var where := UI.label("A card mod: fit it from a card's Blueprint." if got["kind"] == "card" else "A Printer mod level: install it from the Mods tab.", 16, UI.MUTED, false)
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

func _open_install(printer_id: String) -> void:
	_install_for = printer_id
	if is_instance_valid(_popup):
		_popup.get_parent().queue_free()
	_popup = modal(0.88)
	var slots := GameData.printer_slots(printer_id)
	var mods_owned: Array = []
	for m in GameData.PRINTER_MODS:
		if Profile.mod_level(m["id"]) > 0:
			mods_owned.append(m)
	var box := dialog(_popup, Vector2(640, 150 + slots * 62 + 70 + maxi(mods_owned.size(), 1) * 58 + 80))
	var bw := box.size.x
	var title := UI.label("%s mods" % GameData.printer(printer_id)["name"], 30, UI.GOLD, true, 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, title, Vector2(0, 14), Vector2(bw, 40))
	var sub := UI.label("Tap a mod below to bolt it into a free slot. Tap it again to take it out.", 15, UI.MUTED, false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(box, sub, Vector2(24, 58), Vector2(bw - 48, 40))
	var installed: Array = Profile.installed_mods(printer_id)
	var y := 104.0
	for slot in slots:
		var id: String = str(installed[slot]) if slot < installed.size() else ""
		UI.panel(box, Rect2(24, y, bw - 48, 54), UI.box(Color(0.03, 0.06, 0.12, 0.9), UI.CYAN if id != "" else UI.BRASS_DARK, 2, 12))
		var label := "Slot %d   empty" % (slot + 1)
		var col := UI.MUTED
		if id != "":
			label = "Slot %d   %s  (level %d)" % [slot + 1, GameData.mod(id)["name"], Profile.mod_level(id)]
			col = UI.CREAM
		UI.place(box, UI.label(label, 19, col, id != ""), Vector2(40, y + 12), Vector2(bw - 160, 28))
		if id != "":
			var rm := UI.button("Remove", "plain", Vector2(100, 38), 16)
			rm.pressed.connect(func():
				Profile.install_mod(printer_id, slot, "")
				Audio.sfx("back")
				_open_install(printer_id))
			UI.place(box, rm, Vector2(bw - 140, y + 8))
		y += 62.0
	y += 8.0
	UI.place(box, UI.label("Your mods", 20, UI.GOLD), Vector2(28, y), Vector2(300, 26))
	y += 34.0
	if mods_owned.is_empty():
		var none := UI.label("You have not bought any mods yet. Buy some on the Mods tab.", 16, UI.MUTED, false)
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(box, none, Vector2(28, y), Vector2(bw - 56, 44))
		y += 52.0
	for m in mods_owned:
		var id: String = m["id"]
		var on := installed.has(id)
		var b := UI.button("%s  -  %s" % [m["name"], GameData.mod_text(id, Profile.mod_level(id))], "go" if on else "plain", Vector2(bw - 48, 50), 14)
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func(): _toggle_mod(printer_id, id))
		UI.place(box, b, Vector2(24, y))
		y += 58.0
	var done := UI.button("Done", "primary", Vector2(220, 52), 22)
	done.pressed.connect(func():
		_install_for = ""
		close_modal(_popup)
		_popup = null
		relayout())
	UI.place(box, done, Vector2(bw * 0.5 - 110, box.size.y - 70))


func _toggle_mod(printer_id: String, mod_id: String) -> void:
	var list: Array = Profile.installed_mods(printer_id)
	var at := list.find(mod_id)
	if at >= 0:
		Profile.install_mod(printer_id, at, "")
		Audio.sfx("back")
	else:
		var free := -1
		for slot in GameData.printer_slots(printer_id):
			if slot >= list.size() or str(list[slot]) == "":
				free = slot
				break
		if free < 0:
			Audio.sfx("deny")
			app.toast("No free slot. Remove a mod first.", UI.AMBER)
			return
		Profile.install_mod(printer_id, free, mod_id)
		Audio.sfx("mod_install")
	_open_install(printer_id)
