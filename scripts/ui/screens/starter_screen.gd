extends GameScreen
## First launch: pick a starter print. It decides your first Printer.

var _cards: Dictionary = {}
var _choice := ""
var _confirm: Button
var _blurb: Label


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_printer_closeup_v2.png", 0.72)
	var title := UI.label("Welcome to the workshop, Apprentice", 44, UI.CREAM, true, 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, title, Vector2(0, 28), Vector2(1280, 56))
	var sub := UI.label("Choose your first print. It comes with a Printer, a starter deck and three card packs.", 21, UI.MUTED, false)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, sub, Vector2(0, 88), Vector2(1280, 30))

	var ids := ["cinderpaw", "aquafin", "voltwig"]
	for i in ids.size():
		var id: String = ids[i]
		var x := 210.0 + i * 300.0
		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_NONE
		hit.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		hit.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		UI.place(self, hit, Vector2(x, 140), Vector2(260, 364))
		var card := CardView.make(id, 0.86)
		card.position = Vector2(1, 1)
		hit.add_child(card)
		hit.pressed.connect(_pick.bind(id))
		_cards[id] = card
		var p: Dictionary = GameData.printer(GameData.STARTER_PRINTER[id])
		var pn := UI.label(p["name"], 22, GameData.element_color(p["element"]), true, 4)
		pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(self, pn, Vector2(x - 20, 512), Vector2(300, 28))
		var pw := UI.label("Power: %s" % p["power"]["text"], 16, UI.CREAM, false)
		pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(self, pw, Vector2(x - 20, 540), Vector2(300, 44))

	_blurb = UI.label("", 20, UI.GOLD)
	_blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, _blurb, Vector2(0, 596), Vector2(1280, 28))
	_confirm = UI.button("Pick a print", "go", Vector2(360, 60), 26)
	_confirm.disabled = true
	_confirm.pressed.connect(_start)
	UI.place(self, _confirm, Vector2(460, 636))


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
	app.go("menu")
