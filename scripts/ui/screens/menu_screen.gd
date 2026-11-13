extends GameScreen
## The workshop hub.

var _popup: Control
var _popup_kind := ""


func build() -> void:
	Profile.ensure_battle_deck()
	app.set_background("res://assets/ui/workshop/workshop_overview_%s_v4.png" % ("portrait" if P else "landscape"), 0.18)
	_popup = null
	var px := 60.0 if P else 40.0
	var py := 50.0 if P else 20.0
	var pw := 600.0 if P else 420.0
	var ph := 780.0 if P else 680.0

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
		["Blueprints", "primary", "blueprints"],
		["Workshop: Printers & Mods", "primary", "workshop"],
	]
	var bw := pw - 60.0
	var y := py + 128.0
	for it in items:
		var b := UI.button(it[0], it[1], Vector2(bw, 56), 25)
		b.pressed.connect(app.go.bind(it[2]))
		UI.place(self, b, Vector2(px + 30, y))
		y += 66.0
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
		["coin", UI.GOLD, "%d Forge Coins   -   Maker Rank %d" % [Profile.coins(), Profile.rank_level()]],
		["pack", UI.CYAN, "%d of %d cards collected" % [prog.x, prog.y]],
		["star", UI.AMBER, "%d of %d rivals beaten" % [beaten, GameData.RIVALS.size()]],
		["shield", UI.GOOD, "%d wins, %d losses" % [int(Profile.data["stats"]["wins"]), int(Profile.data["stats"]["losses"])]],
	]
	var ly := y + 68.0
	for l in lines:
		var ic := IconView.make(l[0], 24, l[1])
		UI.place(self, ic, Vector2(px + 44, ly + 2))
		UI.place(self, UI.label(l[2], 19, UI.CREAM, false), Vector2(px + 80, ly), Vector2(pw - 100, 28))
		ly += 30.0

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
	elif _popup_kind == "testing":
		_open_testing()


func _close_popup() -> void:
	close_modal(_popup)
	_popup = null
	_popup_kind = ""


func _open_settings() -> void:
	if is_instance_valid(_popup):
		return
	_popup_kind = "settings"
	_popup = modal()
	var box := dialog(_popup, Vector2(500, 530))
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
	y += 60.0
	var testing := UI.button("Testing tools: set coins and XP", "plain", Vector2(400, 50), 18)
	testing.pressed.connect(func():
		_close_popup()
		_open_testing())
	UI.place(box, testing, Vector2(50, y))
	y += 60.0
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
	UI.place(box, ver, Vector2(0, 438), Vector2(500, 22))
	var done := UI.button("Done", "go", Vector2(200, 52))
	done.pressed.connect(_close_popup)
	UI.place(box, done, Vector2(150, 468))


## Numbers only, with the number keyboard on a phone.
func _number_field(value: int) -> LineEdit:
	var f := LineEdit.new()
	f.text = str(value)
	f.alignment = HORIZONTAL_ALIGNMENT_CENTER
	f.max_length = 7
	f.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	f.add_theme_font_size_override("font_size", 22)
	f.text_changed.connect(func(t: String):
		var digits := ""
		for ch in t:
			if ch >= "0" and ch <= "9":
				digits += ch
		if digits != t:
			f.text = digits
			f.caret_column = digits.length())
	return f


## Settings > Testing tools: put any amount of coins and Maker XP in the save
## so the late game can be tried without grinding to it.
func _open_testing() -> void:
	if is_instance_valid(_popup):
		return
	_popup_kind = "testing"
	_popup = modal()
	var box := dialog(_popup, Vector2(500, 500))
	var title := UI.label("Testing tools", 34, UI.GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, title, Vector2(0, 18), Vector2(500, 44))

	UI.place(box, UI.label("Coins", 20), Vector2(32, 86), Vector2(110, 30))
	var coins := _number_field(Profile.coins())
	UI.place(box, coins, Vector2(155, 78), Vector2(175, 44))
	var set_coins := UI.button("Set", "go", Vector2(120, 44), 20)
	UI.place(box, set_coins, Vector2(340, 78))
	set_coins.pressed.connect(func():
		Profile.set_coins(int(coins.text) if coins.text != "" else 0)
		coins.text = str(Profile.coins())
		Audio.sfx("coin"))
	for i in 3:
		var amount: int = [1000, 10000, 100000][i]
		var add := UI.button("+%s" % _grouped(amount), "plain", Vector2(130, 40), 18)
		UI.place(box, add, Vector2(47 + i * 138, 132))
		add.pressed.connect(func():
			Profile.set_coins(Profile.coins() + amount)
			coins.text = str(Profile.coins())
			Audio.sfx("coin"))

	UI.place(box, UI.label("Maker XP", 20), Vector2(32, 210), Vector2(110, 30))
	var xp := _number_field(int(Profile.data["xp"]))
	UI.place(box, xp, Vector2(155, 202), Vector2(175, 44))
	var info := UI.label("", 17, UI.CREAM, false)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, info, Vector2(20, 254), Vector2(460, 26))
	var show_rank := func():
		var rk := Profile.rank()
		info.text = "Maker Rank %d of %d  ·  %s" % [int(rk["rank"]), GameData.RANK_MAX, ("max rank" if int(rk["need"]) == 0 else "%d XP to the next rank" % (int(rk["need"]) - int(rk["into"])))]
	show_rank.call()
	var set_xp := UI.button("Set", "go", Vector2(120, 44), 20)
	UI.place(box, set_xp, Vector2(340, 202))
	set_xp.pressed.connect(func():
		Profile.set_xp(int(xp.text) if xp.text != "" else 0)
		xp.text = str(Profile.data["xp"])
		show_rank.call()
		Audio.sfx("coin"))
	var quick: Array = [["+1,000 XP", -1], ["Rank 10", 10], ["Max rank", GameData.RANK_MAX]]
	for i in 3:
		var q: Array = quick[i]
		var b := UI.button(q[0], "plain", Vector2(130, 40), 18)
		UI.place(box, b, Vector2(47 + i * 138, 290))
		b.pressed.connect(func():
			if int(q[1]) < 0:
				Profile.set_xp(int(Profile.data["xp"]) + 1000)
			else:
				Profile.set_xp(GameData.xp_for_rank(int(q[1])))
			xp.text = str(Profile.data["xp"])
			show_rank.call()
			Audio.sfx("coin"))

	var note := UI.label("Changes your real save. Maker Rank unlocks Printers, mods, Blueprint tiers and paints.", 15, UI.MUTED, false)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(box, note, Vector2(30, 346), Vector2(440, 44))
	var back := UI.button("Back to settings", "plain", Vector2(210, 52), 19)
	back.pressed.connect(func():
		_close_popup()
		relayout()
		_open_settings())
	UI.place(box, back, Vector2(30, 420))
	var done := UI.button("Done", "go", Vector2(200, 52))
	done.pressed.connect(func():
		_close_popup()
		relayout())
	UI.place(box, done, Vector2(270, 420))


func _grouped(n: int) -> String:
	var s := str(n)
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += ","
		out += s[i]
	return out


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
