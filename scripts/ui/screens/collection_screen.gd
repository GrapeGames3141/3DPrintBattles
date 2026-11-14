extends GameScreen
## Browse every card, print missing copies with coins, and build decks.

const FILTERS := [["All", ""], ["Prints", "creature"], ["Tools", "tool"], ["Upgrades", "upgrade"]]

var _filter := ""
## The Filter popup: element and rarity ("" = any), owned/missing, and sort order.
var _element := ""
var _rarity := ""
var _owned := ""
var _sort := "cost"
var _popup: Control
var _filter_btn: Button
var _page := 0
var _slot := -1
var _grid: Control
var _deck_panel: Control
var _preview: Control
var _page_label: Label
var _filter_buttons: Array = []
var _inspect: Control


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_terminal_closeup_v2.png", 0.78)
	top_bar("Collection & Decks")
	if _slot < 0:
		_slot = int(Profile.data["active_deck"])
	_filter_buttons = []
	_preview = null
	_inspect = null
	# Tabs are laid out one after another by their real widths, so a long label
	# ("Upgrades") can never run under the next button.
	var fw := 64.0 if P else 104.0
	var tx := 16.0 if P else 30.0
	var tabs: Array = []
	for i in FILTERS.size():
		var b := UI.button(FILTERS[i][0], "plain", Vector2(fw, 40), 16 if P else 18)
		b.pressed.connect(_set_filter.bind(FILTERS[i][1]))
		tabs.append(b)
		_filter_buttons.append(b)
	_filter_btn = UI.button("Filter", "plain", Vector2(80 if P else 110, 40), 16 if P else 18)
	_filter_btn.pressed.connect(_open_filters)
	tabs.append(_filter_btn)
	for i in tabs.size():
		var b: Button = tabs[i]
		UI.place(self, b, Vector2(tx, 84))
		tx += maxf(b.size.x, b.get_combined_minimum_size().x) + (14.0 if i == FILTERS.size() - 1 else 8.0)
	var px := 530.0 if P else 750.0
	var prev := UI.button("<", "plain", Vector2(46, 40))
	prev.pressed.connect(_turn.bind(-1))
	UI.place(self, prev, Vector2(px, 84))
	_page_label = UI.label("", 20)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.place(self, _page_label, Vector2(px + 48, 84), Vector2(84, 40))
	var next := UI.button(">", "plain", Vector2(46, 40))
	next.pressed.connect(_turn.bind(1))
	UI.place(self, next, Vector2(px + 134, 84))

	_grid = Control.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_grid)
	_deck_panel = Control.new()
	_deck_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deck_panel)
	_refresh()


func _cols() -> int:
	return 3 if P else 4


func _cards() -> Array:
	var out: Array = []
	for c in GameData.collectible():
		if _filter != "" and c["type"] != _filter:
			continue
		if _element != "" and str(c.get("element", "")) != _element:
			continue
		if _rarity != "" and c["rarity"] != _rarity:
			continue
		var have := Profile.owned_count(c["id"])
		if _owned == "owned" and have == 0:
			continue
		if _owned == "missing" and have > 0:
			continue
		out.append(c)
	var rank := func(c: Dictionary) -> int: return GameData.RARITY_ORDER.find(c["rarity"])
	match _sort:
		"rarity":
			out.sort_custom(func(a, b):
				if rank.call(a) != rank.call(b):
					return rank.call(a) > rank.call(b)
				return a["name"] < b["name"])
		"name":
			out.sort_custom(func(a, b): return a["name"] < b["name"])
		"element":
			out.sort_custom(func(a, b):
				var ea := str(a.get("element", "~"))
				var eb := str(b.get("element", "~"))
				if ea != eb:
					return ea < eb
				if a["cost"] != b["cost"]:
					return a["cost"] < b["cost"]
				return a["name"] < b["name"])
	return out


func _filters_active() -> int:
	var n := 0
	for v in [_element, _rarity, _owned]:
		if v != "":
			n += 1
	if _sort != "cost":
		n += 1
	return n


func _open_filters() -> void:
	if is_instance_valid(_popup):
		return
	_popup = modal()
	var box := dialog(_popup, Vector2(680, 560))
	var title := UI.label("Filter and sort", 30, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, title, Vector2(0, 14), Vector2(box.size.x, 40))
	var y := 66.0
	y = _chip_row(box, y, "Element", [["Any", ""], ["Fire", "Fire"], ["Water", "Water"], ["Lightning", "Lightning"], ["Nature", "Nature"], ["Ice", "Ice"], ["Stone", "Stone"], ["Wind", "Wind"], ["Arcane", "Arcane"]], _element, func(v): _element = v)
	var rar: Array = [["Any", ""]]
	for r in GameData.RARITY_ORDER:
		rar.append([str(GameData.RARITIES[r]["name"]), r])
	y = _chip_row(box, y, "Rarity", rar, _rarity, func(v): _rarity = v)
	y = _chip_row(box, y, "Show", [["All", ""], ["Owned", "owned"], ["Missing", "missing"]], _owned, func(v): _owned = v)
	y = _chip_row(box, y, "Sort by", [["Cost", "cost"], ["Rarity", "rarity"], ["Name", "name"], ["Element", "element"]], _sort, func(v): _sort = v)
	var clear := UI.button("Clear", "plain", Vector2(150, 50), 20)
	clear.pressed.connect(func():
		_element = ""
		_rarity = ""
		_owned = ""
		_sort = "cost"
		_page = 0
		_close_filters())
	UI.place(box, clear, Vector2(box.size.x * 0.5 - 160, box.size.y - 66))
	var done := UI.button("Show %d cards" % _cards().size(), "go", Vector2(190, 50), 20)
	done.pressed.connect(func():
		_page = 0
		_close_filters())
	UI.place(box, done, Vector2(box.size.x * 0.5 + 10, box.size.y - 66))


## One labelled row of toggle chips; returns the next y.
func _chip_row(box: Control, y: float, label: String, options: Array, current: String, setter: Callable) -> float:
	UI.place(box, UI.label(label, 18, UI.CREAM), Vector2(24, y), Vector2(120, 26))
	var chip_w := 108.0
	var x := 24.0
	var yy := y + 28.0
	var buttons: Array = []
	for o in options:
		if x + chip_w > box.size.x - 20:
			x = 24.0
			yy += 40.0
		var b := UI.button(o[0], "plain", Vector2(chip_w, 34), 14)
		var val: String = o[1]
		b.modulate = Color(1.0, 0.86, 0.45) if val == current else Color.WHITE
		b.pressed.connect(func():
			setter.call(val)
			for k in buttons.size():
				(buttons[k] as Button).modulate = Color(1.0, 0.86, 0.45) if options[k][1] == val else Color.WHITE)
		UI.place(box, b, Vector2(x, yy))
		buttons.append(b)
		x += chip_w + 6.0
	return yy + 52.0


func _close_filters() -> void:
	close_modal(_popup)
	_popup = null
	_refresh()


func _set_filter(f: String) -> void:
	_filter = f
	_page = 0
	_refresh()


## Swiping the card grid left or right turns the page (finger or mouse drag).
## A swipe also sets `_swiped_at`, so the card under the finger is not added
## to the deck when the finger lifts.
const SWIPE_MIN := 90.0
var _swipe_from := Vector2.ZERO
var _swiping := false
var _swiped_at := -1000


func _grid_area() -> Rect2:
	var pitch_x := 228.0 if P else 212.0
	var pitch_y := CardView.H * (0.68 if P else 0.6) + 34.0
	var x0 := 22.0 if P else 34.0
	return Rect2(0, 130, x0 + _cols() * pitch_x, 2.0 * pitch_y + 30.0)


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
		return
	if is_instance_valid(_popup) or is_instance_valid(_inspect):
		_swiping = false
		return
	var at: Vector2 = (make_input_local(event) as InputEventMouseButton).position
	if (event as InputEventMouseButton).pressed:
		_swiping = _grid_area().has_point(at)
		_swipe_from = at
		return
	if not _swiping:
		return
	_swiping = false
	var d := at - _swipe_from
	if absf(d.x) >= SWIPE_MIN and absf(d.x) > absf(d.y) * 1.5:
		_swiped_at = Time.get_ticks_msec()
		_turn(-1 if d.x > 0.0 else 1)


func _turn(dir: int) -> void:
	var pages := maxi(1, ceili(_cards().size() / float(_cols() * 2)))
	_page = posmod(_page + dir, pages)
	_refresh()


func _refresh() -> void:
	_hide_preview()
	for i in _filter_buttons.size():
		(_filter_buttons[i] as Button).modulate = Color(1.0, 0.86, 0.45) if FILTERS[i][1] == _filter else Color.WHITE
	if _filter_btn != null:
		var n := _filters_active()
		_filter_btn.text = "Filter" if n == 0 else "Filter (%d)" % n
		_filter_btn.modulate = Color(1.0, 0.86, 0.45) if n > 0 else Color.WHITE
	_build_grid()
	_build_deck()


func _build_grid() -> void:
	for ch in _grid.get_children():
		ch.queue_free()
	var cards := _cards()
	var cols := _cols()
	var per := cols * 2
	var s := 0.68 if P else 0.6
	var cw := CardView.W * s
	var ch_px := CardView.H * s
	var pitch_x := 228.0 if P else 212.0
	var pitch_y := ch_px + 34.0
	var x0 := 22.0 if P else 34.0
	var pages := maxi(1, ceili(cards.size() / float(per)))
	_page = clampi(_page, 0, pages - 1)
	_page_label.text = "%d / %d" % [_page + 1, pages]
	var deck: Array = Profile.deck(_slot)["cards"]
	for i in per:
		var idx := _page * per + i
		if idx >= cards.size():
			break
		var def: Dictionary = cards[idx]
		var id: String = def["id"]
		var pos := Vector2(x0 + (i % cols) * pitch_x, 138 + (i / cols) * pitch_y)
		var owned := Profile.owned_count(id)
		var cap := GameData.max_copies(id)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		for stl in ["normal", "hover", "pressed", "focus"]:
			hit.add_theme_stylebox_override(stl, StyleBoxEmpty.new())
		UI.place(_grid, hit, pos, Vector2(cw, ch_px))
		var card := CardView.make(id, s, Profile.build_of(id))
		hit.add_child(card)
		card.set_dimmed(owned == 0)
		card.set_raw(owned == 0)
		var in_deck := deck.count(id)
		if in_deck > 0:
			card.set_count("%d in deck" % in_deck, UI.GOLD)
			card.set_glow(UI.GOLD)
		hit.pressed.connect(_add.bind(id))
		if not P:
			hit.mouse_entered.connect(_show_preview.bind(id))
			hit.mouse_exited.connect(_hide_preview)
			hit.button_up.connect(func(): if DisplayServer.is_touchscreen_available(): _hide_preview())

		var spare := Profile.spare_count(id)
		var own_text := "Owned %d" % owned
		if spare > 0:
			own_text += "  (%d spare)" % spare
		var own := UI.label(own_text, 15, UI.AMBER if spare > 0 else (UI.CREAM if owned > 0 else UI.MUTED), false)
		UI.place(_grid, own, pos + Vector2(2, ch_px + 3), Vector2(cw - 34, 22))
		var look := UI.button("?", "plain", Vector2(30, 26), 14)
		look.tooltip_text = "Look at this card up close"
		look.pressed.connect(_open_inspect.bind(id))
		UI.place(_grid, look, pos + Vector2(cw - 30, ch_px + 2))


func _build_deck() -> void:
	for ch in _deck_panel.get_children():
		ch.queue_free()
	var r := Rect2(12, 800, 696, 472) if P else Rect2(892, 84, 368, 622)
	var x := r.position.x
	var y := r.position.y
	var w := r.size.x
	UI.panel(_deck_panel, r)
	var tabw := (w - 24 - 12) / 3.0
	for i in Profile.DECK_SLOTS:
		var b := UI.button("Deck %d" % (i + 1), "primary" if i == _slot else "plain", Vector2(tabw, 40), 18)
		b.pressed.connect(_pick_slot.bind(i))
		UI.place(_deck_panel, b, Vector2(x + 12 + i * (tabw + 6), y + 12))

	var d := Profile.deck(_slot)
	_deck_identity(x, y + 54.0, w, d)
	y += 38.0
	var p: Dictionary = GameData.printer(d["printer"])
	_deck_panel.add_child(PrinterRig.make(p["id"], Profile.installed_mods(p["id"]), Rect2(x + 10, y + 60, 84, 76)))
	UI.place(_deck_panel, UI.label("%s (active)" % p["name"], 20, GameData.element_color(p["element"])), Vector2(x + 100, y + 62), Vector2(w - 210, 26))
	var pw := UI.label("%s: %s" % [p["power"]["name"], p["power"]["text"]], 13, UI.MUTED, false)
	pw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(_deck_panel, pw, Vector2(x + 100, y + 88), Vector2(w - 196, 50))
	var swap := UI.button("Change", "plain", Vector2(84, 40), 16)
	swap.disabled = (Profile.data["printers"] as Array).size() < 2
	swap.tooltip_text = "Pick the one Printer you battle with. Every deck uses it, and only its mods count."
	swap.pressed.connect(_swap_printer)
	UI.place(_deck_panel, swap, Vector2(x + w - 96, y + 76))

	var list: Array = d["cards"]
	var err := Profile.deck_error(_slot)
	var count := UI.label("%d cards  (%d-%d)" % [list.size(), GameData.DECK_MIN, GameData.DECK_MAX], 20, UI.GOOD if err == "" else UI.AMBER)
	UI.place(_deck_panel, count, Vector2(x + 16, y + 144), Vector2(200, 26))
	if err == "" and _slot != int(Profile.data["active_deck"]):
		var use := UI.button("Use for battles", "go", Vector2(170, 30), 15)
		use.tooltip_text = "Fight with this deck in every mode"
		use.pressed.connect(func():
			Profile.set_active_deck(_slot)
			_refresh())
		UI.place(_deck_panel, use, Vector2(x + w - 184, y + 142))
	else:
		var text := "Tap cards above to add them" if P else "Click cards on the left to add them"
		var col := UI.MUTED
		if err == "":
			text = "Your battle deck"
			col = UI.GOLD
		var hint := UI.label(text, 14, col, false)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		UI.place(_deck_panel, hint, Vector2(x + w - 250, y + 148), Vector2(236, 22))

	var list_h := r.size.y - 176 - 62 - 38.0
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.place(_deck_panel, scroll, Vector2(x + 12, y + 176), Vector2(w - 22, list_h))
	var rows := GridContainer.new()
	rows.columns = 2 if P else 1
	rows.add_theme_constant_override("h_separation", 6)
	rows.add_theme_constant_override("v_separation", 3)
	scroll.add_child(rows)
	var row_w := (w - 46) / rows.columns
	var counts := GameData.count_cards(list)
	var ids: Array = counts.keys()
	ids.sort_custom(func(a, b):
		var ca: Dictionary = GameData.card(a)
		var cb: Dictionary = GameData.card(b)
		if ca["cost"] != cb["cost"]:
			return ca["cost"] < cb["cost"]
		return ca["name"] < cb["name"])
	for id in ids:
		var def: Dictionary = GameData.card(id)
		var row := Button.new()
		row.focus_mode = Control.FOCUS_NONE
		row.custom_minimum_size = Vector2(row_w, 34 if P else 32)
		row.tooltip_text = "Click to remove one copy"
		var tint: Color = GameData.rarity_color(def["rarity"])
		row.add_theme_stylebox_override("normal", UI.box(Color("0f1a30"), Color(tint, 0.7), 1, 6))
		row.add_theme_stylebox_override("hover", UI.box(Color("3a2020"), UI.BAD, 1, 6))
		row.add_theme_stylebox_override("pressed", UI.box(Color("3a2020"), UI.BAD, 1, 6))
		row.pressed.connect(_remove.bind(id))
		if not P:
			row.mouse_entered.connect(_show_preview.bind(id, true))
			row.mouse_exited.connect(_hide_preview)
		rows.add_child(row)
		var cost := Badge.make("spool", CardView.COST_BLUE, 28)
		cost.position = Vector2(3, 2)
		cost.set_value(int(def["cost"]))
		row.add_child(cost)
		var nm := UI.label(def["name"], 16, UI.CREAM, false)
		nm.position = Vector2(40, 4)
		nm.size = Vector2(row_w - 90, 24)
		nm.clip_text = true
		row.add_child(nm)
		var n := UI.label("x%d" % int(counts[id]), 17, UI.GOLD)
		n.position = Vector2(row_w - 44, 4)
		n.size = Vector2(40, 24)
		row.add_child(n)

	var half := (w - 36) * 0.5
	var fill := UI.button("Auto-fill", "go", Vector2(half, 44), 18)
	fill.disabled = list.size() >= GameData.DECK_MIN
	fill.pressed.connect(func():
		Profile.deck_autofill(_slot)
		_refresh())
	UI.place(_deck_panel, fill, Vector2(x + 12, r.end.y - 56))
	var clear := UI.button("Clear deck", "plain", Vector2(half, 44), 18)
	clear.disabled = list.is_empty()
	clear.pressed.connect(func():
		Profile.deck_clear(_slot)
		_refresh())
	UI.place(_deck_panel, clear, Vector2(x + 24 + half, r.end.y - 56))


## The deck's automatic name, its cost curve and its sleeve.
func _deck_identity(x: float, y: float, w: float, d: Dictionary) -> void:
	var info := DeckInfo.analyse(d["cards"], str(d["printer"]))
	var sl: Dictionary = Profile.deck_sleeve(_slot)
	var sw := UI.panel(_deck_panel, Rect2(x + 14, y, 24, 32), UI.box(Color(str(sl["deep"])), Color(str(sl["color"])), 2, 5))
	sw.add_child(IconView.make(str(sl["emblem"]), 16, Color(str(sl["color"]))))
	(sw.get_child(0) as Control).position = Vector2(3, 7)
	var nm := UI.label(str(info["name"]), 18, UI.GOLD)
	UI.place(_deck_panel, nm, Vector2(x + 46, y - 2), Vector2(w - 200, 24))
	var sub := UI.label("avg cost %.1f  -  %d prints" % [float(info["avg_cost"]), int(info["creatures"])], 12, UI.MUTED, false)
	UI.place(_deck_panel, sub, Vector2(x + 46, y + 18), Vector2(w - 200, 18))
	var curve: Array = info["curve"]
	var peak := 1
	for n in curve:
		peak = maxi(peak, int(n))
	for i in curve.size():
		var h := maxf(2.0, 26.0 * float(int(curve[i])) / float(peak))
		var bar := ColorRect.new()
		bar.color = Color(UI.CYAN, 0.85) if int(curve[i]) > 0 else Color(1, 1, 1, 0.12)
		bar.position = Vector2(x + w - 168 + i * 11, y + 30 - h)
		bar.size = Vector2(8, h)
		_deck_panel.add_child(bar)
	var style := UI.button("Sleeve", "plain", Vector2(62, 28), 13)
	style.tooltip_text = "%s - change this deck's card sleeve (more unlock with Maker Rank)" % sl["name"]
	style.pressed.connect(func():
		Profile.deck_set_sleeve(_slot, Sleeves.next_unlocked(str(sl["id"]), Profile.rank_level()))
		_refresh())
	UI.place(_deck_panel, style, Vector2(x + w - 76, y + 2))


func _pick_slot(i: int) -> void:
	# Looking at a deck is not choosing it: the battle deck changes only with
	# the "Use for battles" button.
	_slot = i
	_refresh()


func _swap_printer() -> void:
	var owned: Array = Profile.data["printers"]
	var i := owned.find(Profile.active_printer())
	Profile.set_active_printer(owned[(i + 1) % owned.size()])
	_refresh()


func _add(id: String) -> void:
	if Time.get_ticks_msec() - _swiped_at < 400:
		return
	if Profile.owned_count(id) == 0:
		app.toast("You do not own that card yet. Print it or find it in a pack.", UI.AMBER)
		return
	var err := Profile.deck_add(_slot, id)
	if err != "":
		Audio.sfx("error")
		app.toast(err, UI.AMBER)
		return
	_refresh()


func _remove(id: String) -> void:
	Profile.deck_remove(_slot, id)
	_refresh()


func _help_lines(id: String) -> String:
	var def := GameData.card(id)
	var help: Array = []
	for k in def.get("kw", []):
		help.append("%s: %s" % [GameData.KEYWORDS[k]["name"], GameData.KEYWORDS[k]["text"]])
	if str(def.get("text", "")).contains("Jam"):
		help.append("Jam: a jammed print cannot attack on its next turn.")
	if def.has("shatter"):
		help.append("Shatter: happens when this print is destroyed.")
	if def["type"] == "upgrade":
		help.append("Upgrades stay on the print for the rest of the battle.")
	if Profile.owned_count(id) == 0:
		help.append("Not owned yet: shown as a raw, unpainted print.")
	else:
		var spare := Profile.spare_count(id)
		help.append("You own %d. A deck can hold %d of this card.%s" % [Profile.owned_count(id), GameData.max_copies(id), ("  %d spare." % spare) if spare > 0 else ""])
	return "\n".join(help)


## Hover preview (mouse): a big readable copy beside the grid.
func _show_preview(id: String, on_left := false) -> void:
	_hide_preview()
	_preview = Control.new()
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.z_index = 30
	add_child(_preview)
	var x := 560.0 if on_left else 920.0
	UI.panel(_preview, Rect2(x - 16, 88, 332, 616), UI.box(Color(0.02, 0.04, 0.08, 0.96), UI.BRASS, 2, 14, 10))
	var card := CardView.make(id, 1.0, Profile.build_of(id))
	card.position = Vector2(x, 104)
	card.set_raw(Profile.owned_count(id) == 0)
	_preview.add_child(card)
	var l := UI.label(_help_lines(id), 15, UI.MUTED, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(_preview, l, Vector2(x, 536), Vector2(300, 160))


func _hide_preview() -> void:
	if is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null


## Full-screen look at one card (the "?" button; works with touch).
func _open_inspect(id: String) -> void:
	close_modal(_inspect)
	_inspect = modal()
	var s := 1.5 if P else 1.2
	var size_px := Vector2(CardView.W, CardView.H) * s
	var top := (H - size_px.y - 170.0) * 0.5
	var card := CardView.make(id, s, Profile.build_of(id))
	card.position = Vector2((W - size_px.x) * 0.5, top)
	card.set_raw(Profile.owned_count(id) == 0)
	_inspect.add_child(card)
	var l := UI.label(_help_lines(id), 18, UI.CREAM, false)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(_inspect, l, Vector2(40, top + size_px.y + 12), Vector2(W - 80, 96))
	var done := UI.button("Close", "go", Vector2(200, 52))
	done.pressed.connect(func(): close_modal(_inspect))
	UI.place(_inspect, done, Vector2(W * 0.5 - 210, top + size_px.y + 112))
	var spare := Profile.spare_count(id)
	if spare > 0:
		var worth := spare * GameData.recycle_value(id)
		var rec := UI.button("Recycle %d spare  +%d coins" % [spare, worth], "plain", Vector2(420, 48), 19)
		rec.tooltip_text = "Only copies a deck cannot hold are recycled; the ones you can use are kept."
		var armed := [false]
		rec.pressed.connect(func():
			if not armed[0]:
				armed[0] = true
				rec.text = "Tap again to recycle  +%d coins" % worth
				return
			var paid: int = Profile.recycle_spares([id])
			Audio.sfx("coin")
			app.toast("Recycled for %d coins" % paid, UI.GOLD)
			close_modal(_inspect)
			_refresh())
		UI.place(_inspect, rec, Vector2(W * 0.5 - 210, top + size_px.y + 176))
	if Profile.owned_count(id) > 0:
		var bp := UI.button("Blueprint", "primary", Vector2(200, 52))
		bp.pressed.connect(func(): app.go("blueprints", {"card": id}))
		UI.place(_inspect, bp, Vector2(W * 0.5 + 10, top + size_px.y + 112))
