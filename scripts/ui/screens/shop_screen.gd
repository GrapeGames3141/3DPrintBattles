extends GameScreen
## Buy card packs with Forge Coins and open them.

var _body: Control
## The pack being opened right now: its kind and the cards that were in it.
var _open_kind := ""
var _open_cards: Array = []
var _opener: PackOpener
var _modal: Control
## Where to pick the opening back up after the screen turns.
var _resume_stage := "sealed"
var _resume_index := 0


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_yard_closeup_v2.png", 0.72)
	top_bar("Card Packs")
	_body = Control.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_refresh()
	if not _open_cards.is_empty():
		_start_opener(_resume_stage, _resume_index)


func relayout() -> void:
	if is_instance_valid(_opener):
		_resume_stage = _opener.stage
		_resume_index = _opener.index
	super.relayout()


## A sealed pack placed by its top-left corner, optionally tipped over a bit.
func _pack_at(kind: String, top_left: Vector2, s: float, lean: float = 0.0) -> PackView:
	var pack := PackView.make(kind, s)
	pack.pivot_offset = Vector2(PackView.W, PackView.H) * 0.5
	pack.position = top_left - pack.pivot_offset * (1.0 - s)
	pack.rotation = lean
	_body.add_child(pack)
	return pack


func _refresh() -> void:
	for ch in _body.get_children():
		ch.queue_free()
	var kinds := ["standard", "premium"]
	var pw := 460.0
	var ph := 520.0 if P else 580.0
	# Vertical offsets inside a pack panel: art, text, buy, count, open.
	var off: Array = [14.0, 312.0, 346.0, 406.0, 440.0] if P else [20.0, 322.0, 362.0, 432.0, 470.0]
	var ps := 0.56
	var art_w := PackView.W * ps
	var art_h := PackView.H * ps
	for i in kinds.size():
		var kind: String = kinds[i]
		var def: Dictionary = GameData.PACKS[kind]
		var x := (W - pw) * 0.5 if P else 150.0 + i * 520.0
		var y := 92.0 + i * (ph + 12.0) if P else 104.0
		UI.panel(_body, Rect2(x, y, pw, ph))
		var have := Profile.packs(kind)
		# Unopened packs pile up behind the front one.
		var corner := Vector2(x + (pw - art_w) * 0.5, y + off[0])
		if have >= 3:
			_pack_at(kind, corner + Vector2(26, 4), ps, 0.11)
		if have >= 2:
			_pack_at(kind, corner + Vector2(-24, 4), ps, -0.1)
		var front := _pack_at(kind, corner, ps)
		if have <= 0:
			front.modulate = Color(0.72, 0.74, 0.8)
		else:
			var tap := Button.new()
			tap.flat = true
			tap.focus_mode = Control.FOCUS_NONE
			for stl in ["normal", "hover", "pressed", "focus"]:
				tap.add_theme_stylebox_override(stl, StyleBoxEmpty.new())
			tap.pressed.connect(_open.bind(kind))
			UI.place(_body, tap, corner, Vector2(art_w, art_h))
		var desc := UI.label(def["text"], 18, UI.CREAM, false)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(_body, desc, Vector2(x, y + off[1]), Vector2(pw, 26))
		var buy := UI.button("Buy for %d" % int(def["price"]), "primary", Vector2(300, 52), 24)
		buy.disabled = Profile.coins() < int(def["price"])
		buy.pressed.connect(_buy.bind(kind))
		UI.place(_body, buy, Vector2(x + 80, y + off[2]))
		var hl := UI.label("You have %d to open" % have if have > 0 else "None waiting to be opened", 18, UI.GOLD if have > 0 else UI.MUTED, false)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(_body, hl, Vector2(x, y + off[3]), Vector2(pw, 26))
		var open := UI.button("Open a pack", "go", Vector2(300, 60), 26)
		open.disabled = have <= 0
		open.pressed.connect(_open.bind(kind))
		UI.place(_body, open, Vector2(x + 80, y + off[4]))
	var tip := UI.label("Win battles to earn Forge Coins. Spare copies you cannot use are recycled into coins.", 17, UI.MUTED, false)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(_body, tip, Vector2(20, 1172 if P else 690), Vector2(W - 40, 60 if P else 24))


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
	_open_kind = kind
	_open_cards = cards
	_start_opener("sealed", 0)


func _start_opener(at_stage: String, at_index: int) -> void:
	_modal = modal(0.94)
	_opener = PackOpener.make(_open_kind, _open_cards, Profile.packs(_open_kind), Vector2(W, H), P, at_stage, at_index)
	_opener.done.connect(_close_opener)
	_opener.another.connect(func():
		var kind := _open_kind
		_close_opener()
		_open(kind))
	_modal.add_child(_opener)


func _close_opener() -> void:
	close_modal(_modal)
	_modal = null
	_opener = null
	_open_cards = []
	_refresh()
