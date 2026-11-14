extends GameScreen
## First launch: pick a starter print. It decides your first Printer.

var _cards: Dictionary = {}
var _choice := ""
var _confirm: Button
var _blurb: Label


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_printer_closeup_v2.png", 0.72)
	_cards = {}
	var title := UI.label("Welcome to the workshop, Apprentice", 34 if P else 44, UI.CREAM, true, 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(self, title, Vector2(20, 110 if P else 28), Vector2(W - 40, 96 if P else 56))
	var sub := UI.label("Choose your first print. It comes with a Printer and 20 card packs. Every card you play has to be opened from a pack.", 19 if P else 21, UI.MUTED, false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(self, sub, Vector2(30, 216 if P else 88), Vector2(W - 60, 56 if P else 30))

	var ids := ["cinderpaw", "aquafin", "voltwig"]
	var s := 0.66 if P else 0.86
	var cw := CardView.W * s
	var pitch := 232.0 if P else 300.0
	var x0 := (W - (pitch * 2.0 + cw)) * 0.5
	var y0 := 330.0 if P else 140.0
	for i in ids.size():
		var id: String = ids[i]
		var x := x0 + i * pitch
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		for stl in ["normal", "hover", "pressed"]:
			hit.add_theme_stylebox_override(stl, StyleBoxEmpty.new())
		UI.place(self, hit, Vector2(x, y0), Vector2(cw, CardView.H * s))
		var card := CardView.make(id, s)
		hit.add_child(card)
		hit.pressed.connect(_pick.bind(id))
		_cards[id] = card
		var p: Dictionary = GameData.printer(GameData.STARTER_PRINTER[id])
		var below := y0 + CardView.H * s + 12.0
		var pn := UI.label(p["name"], 20 if P else 22, GameData.element_color(p["element"]), true, 4)
		pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(self, pn, Vector2(x - 16, below), Vector2(cw + 32, 28))
		var pw := UI.label("Power: %s" % p["power"]["text"], 15 if P else 16, UI.CREAM, false)
		pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(self, pw, Vector2(x - 12, below + 30), Vector2(cw + 24, 70))

	_blurb = UI.label("", 20, UI.GOLD)
	_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, _blurb, Vector2(0, 790 if P else 596), Vector2(W, 28))
	_confirm = UI.button("Pick a print", "go", Vector2(380, 64), 26)
	_confirm.disabled = true
	_confirm.pressed.connect(_start)
	UI.place(self, _confirm, Vector2(W * 0.5 - 190, 850 if P else 634))
	if _choice != "":
		_pick(_choice)


func _pick(id: String) -> void:
	_choice = id
	for k in _cards:
		(_cards[k] as CardView).set_glow(UI.GOLD if k == id else null)
	_confirm.disabled = false
	_confirm.text = "Start with %s" % GameData.card(id)["name"]
	_blurb.text = "This choice is permanent for this save."


func _start() -> void:
	if _choice == "":
		return
	Profile.choose_starter(_choice)
	Audio.sfx("reveal")
	# Straight into the guided first battle.
	app.go("battle", {"session": BattleSession.tutorial()})
