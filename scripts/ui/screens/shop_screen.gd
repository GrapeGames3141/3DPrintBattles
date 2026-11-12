extends GameScreen
## Buy card packs with Forge Coins and open them.

var _body: Control
var _opening: Control
var _revealed := 0
var _slots: Array = []


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_yard_closeup_v2.png", 0.72)
	top_bar("Card Packs")
	_body = Control.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_refresh()


## A sealed pack, drawn as a printed filament box.
static func pack_art(kind: String, px: float = 1.0) -> Control:
	var def: Dictionary = GameData.PACKS[kind]
	var tint := Color(def["tint"])
	var root := Control.new()
	root.size = Vector2(210, 290)
	root.scale = Vector2(px, px)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.panel(root, Rect2(0, 0, 210, 290), UI.box(tint.darkened(0.62), tint, 5, 16, 10))
	UI.panel(root, Rect2(14, 14, 182, 262), UI.box(tint.darkened(0.78), tint.darkened(0.3), 2, 10))
	var lines := ColorRect.new()
	lines.material = CardView.lines_material()
	lines.position = Vector2(8, 8)
	lines.size = Vector2(194, 274)
	lines.modulate.a = 2.0
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(lines)
	var spool := IconView.make("spool", 120, tint)
	spool.position = Vector2(45, 44)
	root.add_child(spool)
	var star := IconView.make("star" if kind == "premium" else "hex", 40, UI.GOLD if kind == "premium" else UI.CREAM)
	star.position = Vector2(85, 84)
	root.add_child(star)
	var band := UI.panel(root, Rect2(0, 186, 210, 62), UI.box(Color(0.03, 0.05, 0.1, 0.9), tint, 2, 0))
	var nm := UI.label(def["name"], 19, UI.CREAM)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.size = band.size
	band.add_child(nm)
	return root


func _refresh() -> void:
	for ch in _body.get_children():
		ch.queue_free()
	var kinds := ["standard", "premium"]
	for i in kinds.size():
		var kind: String = kinds[i]
		var def: Dictionary = GameData.PACKS[kind]
		var x := 150.0 + i * 520.0
		UI.panel(_body, Rect2(x, 104, 460, 580))
		var art := pack_art(kind)
		art.position = Vector2(x + 125, 124)
		_body.add_child(art)
		var desc := UI.label(def["text"], 18, UI.CREAM, false)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(_body, desc, Vector2(x, 426), Vector2(460, 26))
		var buy := UI.button("Buy for %d" % int(def["price"]), "primary", Vector2(300, 56), 24)
		buy.disabled = Profile.coins() < int(def["price"])
		buy.pressed.connect(_buy.bind(kind))
		UI.place(_body, buy, Vector2(x + 80, 466))
		var have := Profile.packs(kind)
		var hl := UI.label("You have %d to open" % have if have > 0 else "None waiting to be opened", 18, UI.GOLD if have > 0 else UI.MUTED, false)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(_body, hl, Vector2(x, 536), Vector2(460, 26))
		var open := UI.button("Open a pack", "go", Vector2(300, 60), 26)
		open.disabled = have <= 0
		open.pressed.connect(_open.bind(kind))
		UI.place(_body, open, Vector2(x + 80, 574))
	var tip := UI.label("Win battles to earn Forge Coins. Spare copies you cannot use are recycled into coins.", 17, UI.MUTED, false)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(_body, tip, Vector2(0, 692), Vector2(1280, 24))


func _buy(kind: String) -> void:
	var err := Profile.buy_pack(kind)
	if err != "":
		Audio.sfx("error")
		app.toast(err, UI.AMBER)
		return
	Audio.sfx("buy")
	_refresh()


func _open(kind: String) -> void:
	var cards := Profile.open_pack(kind)
	if cards.is_empty():
		return
	Audio.sfx("print")
	_opening = modal()
	_revealed = 0
	_slots = []
	var title := UI.label(GameData.PACKS[kind]["name"], 40, UI.GOLD, true, 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(_opening, title, Vector2(0, 62), Vector2(1280, 52))
	var sub := UI.label("Click each card to reveal it", 20, UI.MUTED, false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(_opening, sub, Vector2(0, 116), Vector2(1280, 28))
	var s := 0.7
	var w := CardView.W * s
	var gap := 30.0
	var x0 := (1280.0 - (cards.size() * w + (cards.size() - 1) * gap)) * 0.5
	for i in cards.size():
		var info: Dictionary = cards[i]
		var pos := Vector2(x0 + i * (w + gap), 170)
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		for st in ["normal", "hover", "pressed", "focus"]:
			hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		UI.place(_opening, hit, pos, Vector2(w, CardView.H * s))
		var card := CardView.make("?", s)
		# Flip around the card's middle, so offset for the centred pivot.
		card.pivot_offset = Vector2(CardView.W, CardView.H) * 0.5
		card.position = -card.pivot_offset * (1.0 - s)
		hit.add_child(card)
		var tag := UI.label("", 20, UI.GOLD, true, 6)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(_opening, tag, pos + Vector2(-20, CardView.H * s + 14), Vector2(w + 40, 28))
		var slot := {"hit": hit, "card": card, "tag": tag, "info": info, "open": false}
		_slots.append(slot)
		hit.pressed.connect(_flip.bind(i))
		# Deal the cards in one after another.
		card.modulate.a = 0.0
		var tw := card.create_tween()
		tw.tween_interval(0.08 * i)
		tw.tween_property(card, "modulate:a", 1.0, 0.18)

	var all := UI.button("Reveal all", "plain", Vector2(200, 54), 22)
	all.name = "RevealAll"
	all.pressed.connect(func():
		for i in _slots.size():
			_flip(i))
	UI.place(_opening, all, Vector2(430, 590))
	var done := UI.button("Done", "go", Vector2(200, 54), 22)
	done.name = "Done"
	done.pressed.connect(func():
		close_modal(_opening)
		_refresh())
	UI.place(_opening, done, Vector2(650, 590))
	if Profile.packs(kind) > 0:
		var again := UI.button("Open another (%d left)" % Profile.packs(kind), "primary", Vector2(300, 54), 20)
		again.pressed.connect(func():
			close_modal(_opening)
			_open(kind))
		UI.place(_opening, again, Vector2(490, 654))


func _flip(i: int) -> void:
	var slot: Dictionary = _slots[i]
	if slot["open"]:
		return
	slot["open"] = true
	var card: CardView = slot["card"]
	var info: Dictionary = slot["info"]
	var def := GameData.card(info["id"])
	var rank: int = GameData.RARITY_ORDER.find(def["rarity"])
	Audio.sfx("reveal" if rank >= 3 else "card", 1.0 + rank * 0.06)
	var base := card.scale
	var tw := card.create_tween()
	tw.tween_property(card, "scale:x", 0.0, 0.12)
	tw.tween_callback(func():
		card.set_card(info["id"])
		if rank >= 2:
			card.set_glow(GameData.rarity_color(def["rarity"])))
	tw.tween_property(card, "scale:x", base.x, 0.14)
	if rank >= 3:
		tw.tween_property(card, "scale", base * 1.08, 0.1)
		tw.tween_property(card, "scale", base, 0.14)
	var tag: Label = slot["tag"]
	if int(info["recycled"]) > 0:
		tag.text = "Spare copy: +%d coins" % int(info["recycled"])
		tag.add_theme_color_override("font_color", UI.MUTED)
		tag.add_theme_font_size_override("font_size", 16)
	elif bool(info["new"]):
		tag.text = "NEW!"
	else:
		tag.text = GameData.RARITIES[def["rarity"]]["name"]
		tag.add_theme_color_override("font_color", GameData.rarity_color(def["rarity"]))
