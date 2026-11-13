extends GameScreen
## The workshop hub.

var _popup: Control
var _popup_kind := ""


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_overview_%s_v4.png" % ("portrait" if P else "landscape"), 0.18)
	_popup = null
	var px := 60.0 if P else 40.0
	var py := 50.0 if P else 36.0
	var pw := 600.0 if P else 420.0
	var ph := 716.0 if P else 648.0

	UI.panel(self, Rect2(px, py, pw, ph), UI.box(Color(0.03, 0.05, 0.1, 0.86), UI.BRASS, 3, 18, 10))
	var t1 := UI.label("PrintForge", 54, UI.GOLD, true, 8)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, t1, Vector2(px, py + 16), Vector2(pw, 64))
	var t2 := UI.label("L E G E N D S", 26, UI.CYAN, true, 6)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, t2, Vector2(px, py + 76), Vector2(pw, 34))

	var packs := Profile.total_packs()
	var items := [
		["Battle", "go", "play"],
		["Collection & Decks", "primary", "collection"],
		["Card Packs" + (" (%d to open)" % packs if packs > 0 else ""), "primary", "shop"],
		["Printers & Upgrades", "primary", "workshop"],
	]
	var bw := pw - 60.0
	var y := py + 136.0
	for it in items:
		var b := UI.button(it[0], it[1], Vector2(bw, 62), 26)
		b.pressed.connect(app.go.bind(it[2]))
		UI.place(self, b, Vector2(px + 30, y))
		y += 74.0
	var third := (bw - 16.0) / 3.0
	var how := UI.button("How to Play", "plain" if bool(Profile.data["tutorial_done"]) else "go", Vector2(third + 24, 50), 16)
	how.pressed.connect(_open_help)
	UI.place(self, how, Vector2(px + 30, y + 8))
	var stg := UI.button("Settings", "plain", Vector2(third, 50), 16)
	stg.pressed.connect(_open_settings)
	UI.place(self, stg, Vector2(px + 30 + third + 32, y + 8))
	var quit := UI.button("Quit", "plain", Vector2(third - 24, 50), 16)
	quit.pressed.connect(func(): get_tree().quit())
	UI.place(self, quit, Vector2(px + 30 + third * 2.0 + 40, y + 8))

	var prog := Profile.collection_progress()
	var beaten: int = (Profile.data["rivals_beaten"] as Array).size()
	var lines := [
		["coin", UI.GOLD, "%d Forge Coins" % Profile.coins()],
		["burst", UI.CYAN, "Maker Rank %d" % Profile.rank_level()],
		["pack", UI.CYAN, "%d of %d cards collected" % [prog.x, prog.y]],
		["star", UI.AMBER, "%d of %d rivals beaten" % [beaten, GameData.RIVALS.size()]],
		["shield", UI.GOOD, "%d wins, %d losses" % [int(Profile.data["stats"]["wins"]), int(Profile.data["stats"]["losses"])]],
	]
	var ly := y + 74.0
	for l in lines:
		var ic := IconView.make(l[0], 24, l[1])
		UI.place(self, ic, Vector2(px + 44, ly + 2))
		UI.place(self, UI.label(l[2], 19, UI.CREAM, false), Vector2(px + 80, ly), Vector2(pw - 100, 28))
		ly += 31.0

	# The active deck's printer, standing on the bench.
	var d := Profile.active_deck()
	var p: Dictionary = GameData.printer(d["printer"])
	var cpos := Vector2(205, 790) if P else Vector2(930, 440)
	var card := UI.panel(self, Rect2(cpos, Vector2(310, 244)), UI.box(Color(0.03, 0.05, 0.1, 0.86), GameData.element_color(p["element"]), 3, 16, 8))
	card.add_child(UI.image("res://assets/printers/%s.png" % p["id"], Rect2(70, 8, 170, 156)))
	var pn := UI.label(p["name"], 24, GameData.element_color(p["element"]), true, 4)
	pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pn.position = Vector2(0, 164)
	pn.size = Vector2(310, 30)
	card.add_child(pn)
	var err := Profile.deck_error(int(Profile.data["active_deck"]))
	var dl := UI.label("Deck %d ready" % (int(Profile.data["active_deck"]) + 1) if err == "" else "Deck needs attention", 17, UI.GOOD if err == "" else UI.BAD, false)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.position = Vector2(0, 198)
	dl.size = Vector2(310, 24)
	card.add_child(dl)
	if _popup_kind == "help":
		_open_help()
	elif _popup_kind == "settings":
		_open_settings()


func _close_popup() -> void:
	close_modal(_popup)
	_popup = null
	_popup_kind = ""


func _open_settings() -> void:
	if is_instance_valid(_popup):
		return
	_popup_kind = "settings"
	_popup = modal()
	var box := dialog(_popup, Vector2(500, 460))
	var title := UI.label("Settings", 34, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, title, Vector2(0, 20), Vector2(500, 44))
	var y := 96.0
	for key in ["music", "sfx"]:
		UI.place(box, UI.label("Music" if key == "music" else "Sound effects", 22), Vector2(50, y), Vector2(200, 30))
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(Profile.setting(key))
		s.focus_mode = Control.FOCUS_NONE
		s.value_changed.connect(func(v: float):
			Profile.set_setting(key, v)
			Audio.apply_volume()
			if key == "sfx":
				Audio.sfx("coin"))
		UI.place(box, s, Vector2(250, y + 4), Vector2(200, 28))
		y += 56.0
	if not OS.has_feature("mobile"):
		var fs := UI.button("Fullscreen: %s" % ("On" if bool(Profile.setting("fullscreen")) else "Off"), "plain", Vector2(400, 50))
		fs.pressed.connect(func():
			Profile.set_setting("fullscreen", not bool(Profile.setting("fullscreen")))
			app.apply_fullscreen()
			fs.text = "Fullscreen: %s" % ("On" if bool(Profile.setting("fullscreen")) else "Off"))
		UI.place(box, fs, Vector2(50, y))
	y += 70.0
	var reset := UI.button("Erase progress and start over", "danger", Vector2(400, 50))
	var armed := [false]
	reset.pressed.connect(func():
		if not armed[0]:
			armed[0] = true
			reset.text = "Press again to erase everything"
			return
		Profile.reset()
		_popup_kind = ""
		app.go("starter"))
	UI.place(box, reset, Vector2(50, y))
	var ver := UI.label("Version %s" % GameData.VERSION, 15, UI.MUTED, false)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, ver, Vector2(0, 350), Vector2(500, 22))
	var done := UI.button("Done", "go", Vector2(200, 52))
	done.pressed.connect(_close_popup)
	UI.place(box, done, Vector2(150, 384))


func _open_help() -> void:
	if is_instance_valid(_popup):
		return
	_popup_kind = "help"
	_popup = modal()
	var box := dialog(_popup, Vector2(700, 1040) if P else Vector2(900, 650))
	var bw := box.size.x
	var title := UI.label("How to Play", 36, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, title, Vector2(0, 18), Vector2(bw, 46))
	var rules := [
		["spool", UI.CYAN, "Filament", "Your Printer prints %d Filament a turn. Cards cost Filament, and it all comes off your Spool." % GameData.PRINT_SPEED],
		["snow", UI.CYAN, "Long prints", "Bigger cards go on your Printer and finish over the next turns. Tap the print when it is ready."],
		["cube", UI.AMBER, "Prints", "Drag a print from your hand onto your side of the bench. It can attack from your next turn."],
		["burst", UI.AMBER, "Attacking", "Drag your print onto an enemy print or Printer. Prints deal their Attack to each other."],
		["flame", UI.BAD, "Tools", "One-shot effects. Drag a tool onto its target, or tap the card and then tap the target."],
		["shield", Color("dfe6f0"), "Upgrades", "Printed armor that you bolt onto one of your prints. It stays on for the rest of the battle."],
		["star", UI.GOLD, "Printer Power", "Each Printer has a Power. It costs Filament and can be used once per turn."],
		["hex", UI.BAD, "Winning", "Bring the enemy Printer's Health to 0. Win coins, open card packs, and build a stronger deck."],
	]
	var y := 78.0
	var pitch := 92.0 if P else 56.0
	for r in rules:
		var ic := IconView.make(r[0], 34, r[1])
		UI.place(box, ic, Vector2(34, y + 4))
		UI.place(box, UI.label(r[2], 21, UI.CREAM), Vector2(84, y - 2), Vector2(260, 28))
		var tx := UI.label(r[3], 16, UI.MUTED, false)
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(box, tx, Vector2(84, y + 24), Vector2(bw - 120, pitch - 26))
		y += pitch
	var kw: Array = []
	for k in GameData.KEYWORDS:
		kw.append("%s: %s" % [GameData.KEYWORDS[k]["name"], GameData.KEYWORDS[k]["text"]])
	var kl := UI.label("\n".join(kw) if P else "   ".join(kw.slice(0, 3)) + "\n" + "   ".join(kw.slice(3)), 14 if P else 13, UI.CREAM, false)
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(box, kl, Vector2(20, y + 4), Vector2(bw - 40, 130 if P else 44))
	var by := box.size.y - 70.0
	var tut := UI.button("Play the tutorial", "primary", Vector2(250, 50))
	tut.pressed.connect(func():
		_popup_kind = ""
		app.go("battle", {"session": BattleSession.tutorial()}))
	UI.place(box, tut, Vector2(bw * 0.5 - 260, by))
	var done := UI.button("Got it", "go", Vector2(250, 50))
	done.pressed.connect(_close_popup)
	UI.place(box, done, Vector2(bw * 0.5 + 10, by))
