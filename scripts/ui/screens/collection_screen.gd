extends GameScreen
## Browse every card, print missing copies with coins, and build decks.

const COLS := 4
const ROWS := 2
const CARD_SCALE := 0.6
const FILTERS := [["All", ""], ["Prints", "creature"], ["Tools", "tool"], ["Upgrades", "upgrade"]]

var _filter := ""
var _page := 0
var _slot := 0
var _grid: Control
var _deck_panel: Control
var _preview: Control
var _page_label: Label
var _filter_buttons: Array = []


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_terminal_closeup_v2.png", 0.78)
	top_bar("Collection & Decks")
	_slot = int(Profile.data["active_deck"])

	for i in FILTERS.size():
		var b := UI.button(FILTERS[i][0], "plain", Vector2(118, 40), 18)
		b.pressed.connect(_set_filter.bind(FILTERS[i][1]))
		UI.place(self, b, Vector2(30 + i * 126, 84))
		_filter_buttons.append(b)
	var prev := UI.button("<", "plain", Vector2(46, 40))
	prev.pressed.connect(_turn.bind(-1))
	UI.place(self, prev, Vector2(690, 84))
	_page_label = UI.label("", 20)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI.place(self, _page_label, Vector2(738, 84), Vector2(84, 40))
	var next := UI.button(">", "plain", Vector2(46, 40))
	next.pressed.connect(_turn.bind(1))
	UI.place(self, next, Vector2(824, 84))

	_grid = Control.new()
	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_grid)
	_deck_panel = Control.new()
	_deck_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_deck_panel)
	_refresh()


func _cards() -> Array:
	var out: Array = []
	for c in GameData.collectible():
		if _filter == "" or c["type"] == _filter:
			out.append(c)
	return out


func _set_filter(f: String) -> void:
	_filter = f
	_page = 0
	_refresh()


func _turn(dir: int) -> void:
	var pages := maxi(1, ceili(_cards().size() / float(COLS * ROWS)))
	_page = posmod(_page + dir, pages)
	_refresh()


func _refresh() -> void:
	_hide_preview()
	for i in _filter_buttons.size():
		(_filter_buttons[i] as Button).modulate = Color(1.0, 0.86, 0.45) if FILTERS[i][1] == _filter else Color.WHITE
	_build_grid()
	_build_deck()


func _build_grid() -> void:
	for ch in _grid.get_children():
		ch.queue_free()
	var cards := _cards()
	var per := COLS * ROWS
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
		var pos := Vector2(34 + (i % COLS) * 212, 138 + (i / COLS) * 286)
		var owned := Profile.owned_count(id)
		var cap := GameData.max_copies(id)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed", "focus"]:
			hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		UI.place(_grid, hit, pos, Vector2(CardView.W, CardView.H) * CARD_SCALE)
		var card := CardView.make(id, CARD_SCALE)
		hit.add_child(card)
		card.set_dimmed(owned == 0)
		card.set_raw(owned == 0)
		var in_deck := deck.count(id)
		if in_deck > 0:
			card.set_count("%d in deck" % in_deck, UI.GOLD)
			card.set_glow(UI.GOLD)
		hit.pressed.connect(_add.bind(id))
		hit.mouse_entered.connect(_show_preview.bind(id))
		hit.mouse_exited.connect(_hide_preview)

		var own := UI.label("Owned %d / %d" % [owned, cap], 15, UI.CREAM if owned > 0 else UI.MUTED, false)
		UI.place(_grid, own, pos + Vector2(2, 254), Vector2(96, 22))
		if owned < cap:
			var craft := UI.button("Print  %d" % Profile.craft_cost(id), "plain", Vector2(78, 26), 13)
			craft.tooltip_text = "Print one copy of this card for Forge Coins"
			craft.disabled = Profile.coins() < Profile.craft_cost(id)
			craft.pressed.connect(_craft.bind(id))
			UI.place(_grid, craft, pos + Vector2(102, 253))


func _build_deck() -> void:
	for ch in _deck_panel.get_children():
		ch.queue_free()
	var x := 892.0
	UI.panel(_deck_panel, Rect2(x, 84, 368, 622))
	for i in Profile.DECK_SLOTS:
		var b := UI.button("Deck %d" % (i + 1), "primary" if i == _slot else "plain", Vector2(110, 40), 18)
		b.pressed.connect(_pick_slot.bind(i))
		UI.place(_deck_panel, b, Vector2(x + 12 + i * 116, 96))

	var d := Profile.deck(_slot)
	var p: Dictionary = GameData.printer(d["printer"])
	_deck_panel.add_child(UI.image("res://assets/printers/%s.png" % p["id"], Rect2(x + 10, 144, 84, 76)))
	UI.place(_deck_panel, UI.label(p["name"], 20, GameData.element_color(p["element"])), Vector2(x + 100, 146), Vector2(170, 26))
	var pw := UI.label("%s: %s" % [p["power"]["name"], p["power"]["text"]], 13, UI.MUTED, false)
	pw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(_deck_panel, pw, Vector2(x + 100, 172), Vector2(176, 50))
	var swap := UI.button("Swap", "plain", Vector2(76, 40), 16)
	swap.disabled = (Profile.data["printers"] as Array).size() < 2
	swap.tooltip_text = "Use a different Printer you own for this deck"
	swap.pressed.connect(_swap_printer)
	UI.place(_deck_panel, swap, Vector2(x + 280, 160))

	var list: Array = d["cards"]
	var err := Profile.deck_error(_slot)
	var count := UI.label("%d / %d cards" % [list.size(), GameData.DECK_SIZE], 20, UI.GOOD if err == "" else UI.AMBER)
	UI.place(_deck_panel, count, Vector2(x + 16, 228), Vector2(200, 26))
	var hint := UI.label("Ready to battle" if err == "" else "Click cards on the left to add them", 13, UI.MUTED, false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UI.place(_deck_panel, hint, Vector2(x + 150, 232), Vector2(204, 22))

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UI.place(_deck_panel, scroll, Vector2(x + 12, 260), Vector2(346, 380))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 3)
	rows.custom_minimum_size = Vector2(330, 0)
	scroll.add_child(rows)
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
		row.custom_minimum_size = Vector2(330, 32)
		row.tooltip_text = "Click to remove one copy"
		var tint: Color = GameData.rarity_color(def["rarity"])
		row.add_theme_stylebox_override("normal", UI.box(Color("0f1a30"), Color(tint, 0.7), 1, 6))
		row.add_theme_stylebox_override("hover", UI.box(Color("3a2020"), UI.BAD, 1, 6))
		row.add_theme_stylebox_override("pressed", UI.box(Color("3a2020"), UI.BAD, 1, 6))
		row.pressed.connect(_remove.bind(id))
		row.mouse_entered.connect(_show_preview.bind(id, true))
		row.mouse_exited.connect(_hide_preview)
		rows.add_child(row)
		var cost := Badge.make("spool", CardView.COST_BLUE, 28)
		cost.position = Vector2(3, 2)
		cost.set_value(int(def["cost"]))
		row.add_child(cost)
		var nm := UI.label(def["name"], 16, UI.CREAM, false)
		nm.position = Vector2(40, 4)
		nm.size = Vector2(230, 24)
		row.add_child(nm)
		var n := UI.label("x%d" % int(counts[id]), 17, UI.GOLD)
		n.position = Vector2(286, 4)
		n.size = Vector2(40, 24)
		row.add_child(n)

	var fill := UI.button("Auto-fill", "go", Vector2(166, 44), 18)
	fill.disabled = list.size() >= GameData.DECK_SIZE
	fill.pressed.connect(func():
		Profile.deck_autofill(_slot)
		_refresh())
	UI.place(_deck_panel, fill, Vector2(x + 12, 650))
	var clear := UI.button("Clear deck", "plain", Vector2(166, 44), 18)
	clear.disabled = list.is_empty()
	clear.pressed.connect(func():
		Profile.deck_clear(_slot)
		_refresh())
	UI.place(_deck_panel, clear, Vector2(x + 190, 650))


func _pick_slot(i: int) -> void:
	_slot = i
	Profile.set_active_deck(i)
	_refresh()


func _swap_printer() -> void:
	var owned: Array = Profile.data["printers"]
	var i := owned.find(Profile.deck(_slot)["printer"])
	Profile.deck_set_printer(_slot, owned[(i + 1) % owned.size()])
	_refresh()


func _add(id: String) -> void:
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


func _craft(id: String) -> void:
	var err := Profile.craft(id)
	if err != "":
		Audio.sfx("error")
		app.toast(err, UI.AMBER)
		return
	Audio.sfx("print")
	app.toast("Printed %s!" % GameData.card(id)["name"], UI.GOOD)
	_refresh()


## Big readable copy of a card, with its keywords explained.
func _show_preview(id: String, on_left := false) -> void:
	_hide_preview()
	_preview = Control.new()
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.z_index = 30
	add_child(_preview)
	var x := 560.0 if on_left else 920.0
	UI.panel(_preview, Rect2(x - 16, 88, 332, 616), UI.box(Color(0.02, 0.04, 0.08, 0.96), UI.BRASS, 2, 14, 10))
	var card := CardView.make(id, 1.0)
	card.position = Vector2(x, 104)
	card.set_raw(Profile.owned_count(id) == 0)
	_preview.add_child(card)
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
	var l := UI.label("\n".join(help), 15, UI.MUTED, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(_preview, l, Vector2(x, 536), Vector2(300, 160))


func _hide_preview() -> void:
	if is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null
