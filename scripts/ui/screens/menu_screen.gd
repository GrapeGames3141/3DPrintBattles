extends GameScreen
## The workshop hub.

var _popup: Control
var _popup_kind := ""


## Where things are in the painted workshop, in the picture's own pixels
## (portrait 941x1672, landscape 1672x941). Each is an outline around the object,
## where its plaque sits, and what tapping it opens.
const SCENE := {
	"portrait": {
		"battle": {"poly": [[232, 440], [750, 440], [750, 780], [232, 780]], "label": [450, 815]},
		"blueprints": {"poly": [[185, 175], [785, 175], [785, 355], [185, 355]], "label": [485, 385]},
		"workshop": {"poly": [[0, 700], [130, 690], [290, 705], [345, 880], [345, 950], [130, 995], [0, 965]], "label": [172, 1030]},
		"collection": {"poly": [[640, 770], [920, 830], [920, 990], [830, 1010], [640, 985]], "label": [800, 735]},
		"shop": {"poly": [[689, 1150], [760, 1129], [838, 1217], [839, 1260], [765, 1284], [745, 1270], [692, 1200]], "label": [765, 1335]},
		"glow": [["lamp", 58, 165, 90], ["lamp", 905, 335, 90], ["nozzle", 178, 848, 48], ["screen", 778, 880, 150], ["rune", 888, 1090, 70]],
	},
	"landscape": {
		"battle": {"poly": [[462, 258], [1198, 258], [1198, 610], [1090, 650], [552, 650], [462, 610]], "label": [830, 618]},
		"blueprints": {"poly": [[572, 80], [1192, 80], [1192, 230], [572, 230]], "label": [882, 250]},
		"workshop": {"poly": [[85, 395], [460, 395], [460, 675], [85, 675]], "label": [272, 700]},
		"collection": {"poly": [[1215, 415], [1542, 415], [1542, 625], [1400, 650], [1180, 640], [1215, 560]], "label": [1380, 395]},
		"shop": {"poly": [[1314, 727], [1380, 713], [1476, 779], [1476, 801], [1415, 823], [1400, 823], [1315, 747]], "label": [1395, 868]},
		"glow": [["lamp", 100, 110, 110], ["lamp", 1568, 95, 110], ["lamp", 1258, 215, 90], ["nozzle", 272, 556, 60], ["screen", 1380, 520, 190], ["rune", 1528, 700, 80]],
	},
}

var _repaint_queued := false


func build() -> void:
	Profile.ensure_battle_deck()
	var scene_key := "portrait" if P else "landscape"
	app.set_background("res://assets/ui/workshop/workshop_overview_%s_v4.png" % scene_key, 0.0)
	_popup = null
	if not get_viewport().size_changed.is_connected(_on_viewport_resized):
		get_viewport().size_changed.connect(_on_viewport_resized)
	var scene: Dictionary = SCENE[scene_key]

	# Ambient light: lanterns flicker, the nozzle and the monitor glow.
	for g in scene["glow"]:
		_add_glow(str(g[0]), _pt(Vector2(g[1], g[2])), float(g[3]) * _scale())

	var packs := Profile.total_packs()
	var d := Profile.active_deck()
	var p: Dictionary = GameData.printer(d["printer"])
	var err := Profile.deck_error(int(Profile.data["active_deck"]))
	var prog := Profile.collection_progress()
	var beaten: int = (Profile.data["rivals_beaten"] as Array).size()
	var st: Dictionary = Profile.data["stats"]
	var info := {
		"battle": ["Battle", [[("%s  -  Deck %d ready" % [p["name"], int(Profile.data["active_deck"]) + 1]) if err == "" else "Deck needs attention", UI.GOOD if err == "" else UI.BAD],
			["%d of %d rivals beaten  -  %d W, %d L" % [beaten, GameData.RIVALS.size(), int(st["wins"]), int(st["losses"])], UI.MUTED]],
			"Rivals, quick battles, a friend or the tutorial", UI.GOOD],
		"blueprints": ["Blueprints", [["Upgrade, mod and paint your cards", UI.MUTED]], "Mk II and III, card mods and paints", UI.GOLD],
		"workshop": ["Workshop", [["Printers & Mods", UI.MUTED]], "Buy Printers and fit mods to them", UI.GOLD],
		"collection": ["Collection & Decks", [["%d of %d cards collected" % [prog.x, prog.y], UI.MUTED]], "Browse every card and build your decks", UI.CYAN],
		"shop": ["Card Packs", [[("%d to open" % packs) if packs > 0 else "Buy and open packs", UI.GOLD if packs > 0 else UI.MUTED]], "Rip open packs for new cards", UI.AMBER],
	}
	for key in ["battle", "blueprints", "workshop", "collection", "shop"]:
		var def: Dictionary = scene[key]
		var pts := PackedVector2Array()
		for q in def["poly"]:
			pts.append(_pt(Vector2(q[0], q[1])))
		var inf: Array = info[key]
		var h := Hotspot.make(pts, _pt(Vector2(def["label"][0], def["label"][1])), inf[0], inf[1], inf[2], inf[3])
		h.attention = key == "shop" and packs > 0
		h.activated.connect(app.go.bind("play" if key == "battle" else key))
		_keep_plaque_on_screen(h)
		if h.attention:
			h.set_badge(str(packs))
		add_child(h)

	# Coins and rank, and the three small buttons.
	var pill := UI.panel(self, Rect2(14, 12, 250, 44), UI.box(Color("0b1220", 0.86), UI.BRASS, 2, 22))
	pill.add_child(IconView.make("coin", 26, UI.GOLD))
	(pill.get_child(0) as Control).position = Vector2(10, 9)
	var pl := UI.label("%d  -  Rank %d" % [Profile.coins(), Profile.rank_level()], 19, UI.CREAM)
	pl.position = Vector2(44, 6)
	pl.size = Vector2(200, 30)
	pill.add_child(pl)
	var how := UI.button("?", "plain" if bool(Profile.data["tutorial_done"]) else "go", Vector2(46, 44), 22)
	how.pressed.connect(_open_help)
	UI.place(self, how, Vector2(W - 14 - 46 - 8 - 112 - 8 - 76, 12))
	var stg := UI.button("Settings", "plain", Vector2(112, 44), 17)
	stg.pressed.connect(_open_settings)
	UI.place(self, stg, Vector2(W - 14 - 76 - 8 - 112, 12))
	var quit := UI.button("Quit", "plain", Vector2(76, 44), 17)
	quit.pressed.connect(func(): get_tree().quit())
	UI.place(self, quit, Vector2(W - 14 - 76, 12))

	if _popup_kind == "help":
		_open_help()
	elif _popup_kind == "settings":
		_open_settings()
	elif _popup_kind == "testing":
		_open_testing()


# ------------------------------------------------------------ painted scene

## The background fills the window and keeps its shape, cropping what does not fit.
func _cover() -> Array:
	var tex: Texture2D = app.bg.texture
	var ts := tex.get_size()
	var vp := get_viewport().get_visible_rect().size
	var s := maxf(vp.x / ts.x, vp.y / ts.y)
	return [s, (vp - ts * s) * 0.5, (vp - app.stage_size) * 0.5]


func _scale() -> float:
	return float(_cover()[0])


## A point in the background picture's pixels, as a point on this screen.
func _pt(px: Vector2) -> Vector2:
	var c := _cover()
	return (c[1] as Vector2) + px * float(c[0]) - (c[2] as Vector2)


## Keeps a plaque inside the screen when the picture is cropped around it.
func _keep_plaque_on_screen(h: Hotspot) -> void:
	h._anchor.x = clampf(h._anchor.x + h.position.x, 150.0, W - 150.0) - h.position.x
	h._anchor.y = clampf(h._anchor.y + h.position.y, 70.0, H - 60.0) - h.position.y
	h._place_plaque()


## A soft light on the picture. kind: lamp (flickers), nozzle, screen, rune.
func _add_glow(kind: String, at: Vector2, radius: float) -> void:
	var col := {"lamp": Color(1.0, 0.7, 0.3), "nozzle": Color(1.0, 0.6, 0.2), "screen": Color(0.25, 0.6, 1.0), "rune": Color(0.3, 0.7, 1.0)}[kind] as Color
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	var r := TextureRect.new()
	r.texture = gt
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	r.material = add
	r.size = Vector2(radius, radius) * 2.0
	r.position = at - Vector2(radius, radius)
	r.pivot_offset = Vector2(radius, radius)
	var lo := {"lamp": 0.16, "nozzle": 0.10, "screen": 0.05, "rune": 0.10}[kind] as float
	var hi := {"lamp": 0.34, "nozzle": 0.30, "screen": 0.16, "rune": 0.30}[kind] as float
	r.modulate = Color(col.r, col.g, col.b, lo)
	add_child(r)
	var tw := r.create_tween().set_loops()
	if kind == "lamp":
		# Candle-like: short, uneven steps.
		for i in 6:
			tw.tween_property(r, "modulate:a", randf_range(lo, hi), randf_range(0.12, 0.4))
	else:
		var span := randf_range(1.6, 2.6)
		tw.tween_property(r, "modulate:a", hi, span).set_trans(Tween.TRANS_SINE)
		tw.tween_property(r, "modulate:a", lo, span).set_trans(Tween.TRANS_SINE)


func _on_viewport_resized() -> void:
	if _repaint_queued:
		return
	_repaint_queued = true
	call_deferred("_repaint")


func _repaint() -> void:
	_repaint_queued = false
	if is_inside_tree() and not is_queued_for_deletion():
		relayout()


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
