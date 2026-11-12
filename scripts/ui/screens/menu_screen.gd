extends GameScreen
## The workshop hub.

var _settings: Control


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_overview_landscape_v4.png", 0.18)
	Audio.music("workshop")

	UI.panel(self, Rect2(40, 36, 420, 648), UI.box(Color(0.03, 0.05, 0.1, 0.86), UI.BRASS, 3, 18, 10))
	var t1 := UI.label("PrintForge", 54, UI.GOLD, true, 8)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, t1, Vector2(40, 52), Vector2(420, 64))
	var t2 := UI.label("L E G E N D S", 26, UI.CYAN, true, 6)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(self, t2, Vector2(40, 112), Vector2(420, 34))

	var packs := Profile.total_packs()
	var items := [
		["Battle", "go", "play"],
		["Collection & Decks", "primary", "collection"],
		["Card Packs" + (" (%d to open)" % packs if packs > 0 else ""), "primary", "shop"],
		["Printers & Upgrades", "primary", "workshop"],
	]
	var y := 172.0
	for it in items:
		var b := UI.button(it[0], it[1], Vector2(360, 62), 26)
		b.pressed.connect(app.go.bind(it[2]))
		UI.place(self, b, Vector2(70, y))
		y += 74.0
	var how := UI.button("How to Play", "plain", Vector2(136, 50), 16)
	how.pressed.connect(_open_help)
	UI.place(self, how, Vector2(70, y + 8))
	var st := UI.button("Settings", "plain", Vector2(112, 50), 16)
	st.pressed.connect(_open_settings)
	UI.place(self, st, Vector2(214, y + 8))
	var quit := UI.button("Quit", "plain", Vector2(96, 50), 16)
	quit.pressed.connect(func(): get_tree().quit())
	UI.place(self, quit, Vector2(334, y + 8))

	# Progress summary.
	var prog := Profile.collection_progress()
	var beaten: int = (Profile.data["rivals_beaten"] as Array).size()
	var lines := [
		["coin", UI.GOLD, "%d Forge Coins" % Profile.coins()],
		["pack", UI.CYAN, "%d of %d cards collected" % [prog.x, prog.y]],
		["star", UI.AMBER, "%d of %d rivals beaten" % [beaten, GameData.RIVALS.size()]],
		["shield", UI.GOOD, "%d wins, %d losses" % [int(Profile.data["stats"]["wins"]), int(Profile.data["stats"]["losses"])]],
	]
	var ly := y + 74.0
	for l in lines:
		var ic := IconView.make(l[0], 24, l[1])
		UI.place(self, ic, Vector2(84, ly + 2))
		UI.place(self, UI.label(l[2], 19, UI.CREAM, false), Vector2(120, ly), Vector2(320, 28))
		ly += 31.0

	# The active deck's printer, standing on the bench.
	var d := Profile.active_deck()
	var p: Dictionary = GameData.printer(d["printer"])
	var card := UI.panel(self, Rect2(930, 440, 310, 244), UI.box(Color(0.03, 0.05, 0.1, 0.86), GameData.element_color(p["element"]), 3, 16, 8))
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


func _open_settings() -> void:
	if is_instance_valid(_settings):
		return
	_settings = modal()
	var box := UI.panel(_settings, Rect2(390, 130, 500, 460))
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
		app.go("starter"))
	UI.place(box, reset, Vector2(50, y))
	var ver := UI.label("Version %s" % GameData.VERSION, 15, UI.MUTED, false)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, ver, Vector2(0, 350), Vector2(500, 22))
	var done := UI.button("Done", "go", Vector2(200, 52))
	done.pressed.connect(func(): close_modal(_settings))
	UI.place(box, done, Vector2(150, 384))


func _open_help() -> void:
	if is_instance_valid(_settings):
		return
	_settings = modal()
	var box := UI.panel(_settings, Rect2(190, 50, 900, 620))
	var title := UI.label("How to Play", 36, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, title, Vector2(0, 18), Vector2(900, 46))
	var rules := [
		["spool", UI.CYAN, "Filament", "You get one more Filament each turn, up to 10. Cards cost Filament to play."],
		["cube", UI.AMBER, "Prints", "Drag a print from your hand onto your bed. It can attack from your next turn."],
		["burst", UI.AMBER, "Attacking", "Drag your print onto an enemy print or Printer. Prints deal their Attack to each other."],
		["flame", UI.BAD, "Tools", "One-shot effects. Drag a tool onto its target, or click the card and then click the target."],
		["shield", Color("dfe6f0"), "Upgrades", "Printed armor that you bolt onto one of your prints. It stays on for the rest of the battle."],
		["star", UI.GOLD, "Printer Power", "Each Printer has a Power that costs 2 Filament and can be used once per turn."],
		["hex", UI.BAD, "Winning", "Bring the enemy Printer's Health to 0. Win coins, open card packs, and build a stronger deck."],
	]
	var y := 78.0
	for r in rules:
		var ic := IconView.make(r[0], 34, r[1])
		UI.place(box, ic, Vector2(40, y + 4))
		UI.place(box, UI.label(r[2], 21, UI.CREAM), Vector2(90, y - 2), Vector2(200, 28))
		var tx := UI.label(r[3], 16, UI.MUTED, false)
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(box, tx, Vector2(90, y + 24), Vector2(770, 40))
		y += 62.0
	var kw: Array = []
	for k in GameData.KEYWORDS:
		kw.append("%s: %s" % [GameData.KEYWORDS[k]["name"], GameData.KEYWORDS[k]["text"]])
	var kl := UI.label("   ".join(kw.slice(0, 3)) + "\n" + "   ".join(kw.slice(3)), 13, UI.CREAM, false)
	kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(box, kl, Vector2(20, 512), Vector2(860, 44))
	var done := UI.button("Got it", "go", Vector2(200, 46))
	done.pressed.connect(func(): close_modal(_settings))
	UI.place(box, done, Vector2(350, 562))
