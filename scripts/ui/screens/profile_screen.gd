extends GameScreen
## Your player profile: who you are (name, picture and title, all picked from
## fixed choices), your Maker Rating and league, your record, and the ranked
## queue. There is no typed text anywhere on it.

const LEAGUE_COLORS := [Color("9aa5b4"), Color("7fd1a0"), Color("5ab8ff"), Color("ffb347"), Color("ff7a5a"), Color("c78bff"), Color("ffd84a")]

var _body: Control
var _searching := false
var _found: Dictionary = {}
var _msg := ""


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_proving_closeup_v2.png", 0.74)
	top_bar("Profile")
	_body = null
	if P:
		_body = scroll_body(76, 1560)
		_identity(Rect2(20, 12, 680, 520))
		_record(Rect2(20, 548, 680, 996))
	else:
		_body = Control.new()
		_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_body)
		_identity(Rect2(30, 84, 520, 622))
		_record(Rect2(566, 84, 684, 622))
	if not _found.is_empty():
		_show_match()


# ------------------------------------------------------------------ identity

func _identity(r: Rect2) -> void:
	UI.panel(_body, r)
	var p: Dictionary = Profile.player()
	var rating := Profile.rating()
	var lg := Rating.league(rating)
	var col: Color = LEAGUE_COLORS[int(lg["index"])]
	var x := r.position.x + 20
	var y := r.position.y + 16

	# Picture and name.
	var art := Profile.avatar_id()
	var frame := UI.panel(_body, Rect2(x, y, 150, 150), UI.box(Color("0b1220"), col, 4, 18, 8))
	if art != "":
		var raw: String = GameData.RAW % art
		if ResourceLoader.exists(raw):
			var img := UI.image(raw, Rect2(8, 8, 134, 134), true)
			frame.add_child(img)
	var name_l := UI.label(Profile.player_name(), 30, UI.CREAM, true, 5)
	UI.place(_body, name_l, Vector2(x + 168, y + 4), Vector2(r.size.x - 200, 38))
	var title_l := UI.label(Profile.title_name(), 20, UI.AMBER, false)
	UI.place(_body, title_l, Vector2(x + 168, y + 44), Vector2(r.size.x - 200, 28))
	var league_l := UI.label(Rating.league_text(rating), 26, col, true, 4)
	UI.place(_body, league_l, Vector2(x + 168, y + 78), Vector2(r.size.x - 200, 34))
	var rate_l := UI.label("Maker Rating  %d" % rating, 20, UI.CREAM, false)
	UI.place(_body, rate_l, Vector2(x + 168, y + 114), Vector2(r.size.x - 200, 28))
	y += 166

	# Progress to the next league.
	if int(lg["next"]) > 0:
		var span := float(int(lg["next"]) - int(lg["floor"]))
		var frac := clampf(float(rating - int(lg["floor"])) / span, 0.0, 1.0)
		var bar := UI.panel(_body, Rect2(x, y, r.size.x - 40, 16), UI.box(Color("0b1220"), UI.BRASS_DARK, 2, 8))
		var fill := UI.panel(bar, Rect2(2, 2, maxf(8.0, (r.size.x - 44) * frac), 12), UI.box(col, Color.TRANSPARENT, 0, 6))
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nl := UI.label("%d to %s" % [int(lg["next"]) - rating, Rating.LEAGUES[int(lg["index"]) + 1]["name"]], 15, UI.MUTED, false)
		UI.place(_body, nl, Vector2(x, y + 18), Vector2(r.size.x - 40, 22))
	y += 50

	# Pickers: only fixed choices.
	UI.place(_body, UI.label("Make it yours", 20, UI.GOLD), Vector2(x, y), Vector2(r.size.x - 40, 28))
	y += 32
	var adj := int(p["adj"])
	var noun := int(p["noun"])
	var num := int(p["num"])
	_picker("Word", PlayerIdentity.ADJECTIVES[adj], Vector2(x, y), r.size.x - 40,
		func(): Profile.set_player_look(adj - 1, noun, num, str(p["avatar"])), func(): Profile.set_player_look(adj + 1, noun, num, str(p["avatar"])))
	y += 46
	_picker("Word", PlayerIdentity.NOUNS[noun], Vector2(x, y), r.size.x - 40,
		func(): Profile.set_player_look(adj, noun - 1, num, str(p["avatar"])), func(): Profile.set_player_look(adj, noun + 1, num, str(p["avatar"])))
	y += 46
	_picker("Number", "%02d" % num, Vector2(x, y), r.size.x - 40,
		func(): Profile.set_player_look(adj, noun, num - 1, str(p["avatar"])), func(): Profile.set_player_look(adj, noun, num + 1, str(p["avatar"])))
	y += 46
	var owned := Profile.owned_creatures()
	var at := maxi(0, owned.find(art))
	var art_name: String = str(GameData.card(art)["name"]) if art != "" else "-"
	_picker("Picture", art_name, Vector2(x, y), r.size.x - 40,
		func(): if not owned.is_empty(): Profile.set_player_look(adj, noun, num, owned[posmod(at - 1, owned.size())]),
		func(): if not owned.is_empty(): Profile.set_player_look(adj, noun, num, owned[posmod(at + 1, owned.size())]))
	y += 46
	var titles := Profile.earned_titles()
	var ti := 0
	for i in titles.size():
		if titles[i]["id"] == p["title"]:
			ti = i
	_picker("Title", str(titles[ti]["name"]), Vector2(x, y), r.size.x - 40,
		func(): Profile.set_title(str(titles[posmod(ti - 1, titles.size())]["id"])),
		func(): Profile.set_title(str(titles[posmod(ti + 1, titles.size())]["id"])))


func _picker(label: String, value: String, pos: Vector2, w: float, prev: Callable, next: Callable) -> void:
	UI.place(_body, UI.label(label, 16, UI.MUTED, false), pos + Vector2(0, 8), Vector2(80, 26))
	var b1 := UI.button("<", "plain", Vector2(44, 38), 20)
	b1.pressed.connect(func():
		prev.call()
		relayout())
	UI.place(_body, b1, pos + Vector2(86, 0))
	var v := UI.label(value, 19, UI.CREAM)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(_body, v, pos + Vector2(134, 6), Vector2(w - 134 - 52, 28))
	var b2 := UI.button(">", "plain", Vector2(44, 38), 20)
	b2.pressed.connect(func():
		next.call()
		relayout())
	UI.place(_body, b2, pos + Vector2(w - 44, 0))


# -------------------------------------------------------------------- record

func _record(r: Rect2) -> void:
	UI.panel(_body, r)
	var p: Dictionary = Profile.player()
	var x := r.position.x + 20
	var w := r.size.x - 40
	var y := r.position.y + 14
	UI.place(_body, UI.label("Ranked", 24, UI.GOLD, true, 4), Vector2(x, y), Vector2(w, 32))
	y += 38
	var err := Profile.deck_error(int(Profile.data["active_deck"]))
	var go := UI.button("Searching...  tap to cancel" if _searching else "Find a ranked match", "danger" if _searching else "go", Vector2(w, 56), 22)
	go.disabled = err != "" and not _searching
	go.pressed.connect(_toggle_search)
	UI.place(_body, go, Vector2(x, y))
	y += 62
	var hint := _msg if _msg != "" else ("Your deck needs attention first." if err != "" else "Plays your active deck. Win to climb the leagues.")
	var hl := UI.label(hint, 15, UI.BAD if err != "" else UI.MUTED, false)
	hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(_body, hl, Vector2(x, y), Vector2(w, 40))
	y += 44
	var games := int(p["ranked_games"])
	var wins := int(p["ranked_wins"])
	var rows := [
		["Ranked record", "%d W  %d L%s" % [wins, games - wins, ("   (%d%%)" % (wins * 100 / games)) if games > 0 else ""]],
		["Streak", _streak_text(int(p["streak"]))],
		["Best rating", "%d  (%s)" % [int(p["best_rating"]), Rating.league_text(int(p["best_rating"]))]],
		["Campaign", "%d W  %d L" % [int(Profile.data["stats"]["wins"]), int(Profile.data["stats"]["losses"])]],
		["Cards", "%d of %d" % [Profile.collection_progress().x, Profile.collection_progress().y]],
	]
	for row in rows:
		UI.place(_body, UI.label(str(row[0]), 17, UI.MUTED, false), Vector2(x, y), Vector2(w * 0.4, 26))
		UI.place(_body, UI.label(str(row[1]), 18, UI.CREAM), Vector2(x + w * 0.4, y), Vector2(w * 0.6, 26))
		y += 30
	y += 10
	UI.place(_body, UI.label("Recent games", 20, UI.GOLD), Vector2(x, y), Vector2(w, 28))
	y += 34
	var hist: Array = p["history"]
	if hist.is_empty():
		UI.place(_body, UI.label("No ranked games yet.", 16, UI.MUTED, false), Vector2(x, y), Vector2(w, 26))
	var shown := 0
	for i in range(hist.size() - 1, -1, -1):
		if shown >= (14 if P else 8):
			break
		var h: Dictionary = hist[i]
		var won := bool(h["won"])
		var rowp := UI.panel(_body, Rect2(x, y, w, 36), UI.box(Color(0.08, 0.14, 0.12, 0.7) if won else Color(0.16, 0.08, 0.1, 0.7), Color.TRANSPARENT, 0, 8))
		rowp.add_child(UI.label("W" if won else "L", 18, UI.GOOD if won else UI.BAD))
		(rowp.get_child(0) as Control).position = Vector2(12, 4)
		var nm := UI.label(str(h["opp"]), 16, UI.CREAM, false)
		nm.position = Vector2(44, 6)
		nm.size = Vector2(w - 230, 26)
		rowp.add_child(nm)
		var rr := UI.label("%d" % int(h["opp_rating"]), 16, UI.MUTED, false)
		rr.position = Vector2(w - 190, 6)
		rr.size = Vector2(70, 26)
		rowp.add_child(rr)
		var dl := UI.label("%+d" % int(h["delta"]), 18, UI.GOOD if int(h["delta"]) >= 0 else UI.BAD)
		dl.position = Vector2(w - 100, 4)
		dl.size = Vector2(88, 28)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rowp.add_child(dl)
		y += 40
		shown += 1


func _streak_text(s: int) -> String:
	if s > 1:
		return "%d wins in a row" % s
	if s == 1:
		return "1 win"
	if s < -1:
		return "%d losses in a row" % -s
	if s == -1:
		return "1 loss"
	return "-"


# ------------------------------------------------------------------ the queue

func _toggle_search() -> void:
	if _searching:
		_searching = false
		_msg = "Search cancelled."
		relayout()
		return
	_msg = ""
	_searching = true
	relayout()
	# No server yet: the queue looks for a real player and, finding none, offers
	# a built-to-measure opponent near your rating (Matchmaker.GHOST_AFTER seconds
	# in a live queue; a short wait here so the screen does not flash).
	await get_tree().create_timer(1.6).timeout
	if not is_instance_valid(self) or not _searching:
		return
	_searching = false
	_found = Ladder.opponent(Profile.rating(), randi())
	relayout()


func _show_match() -> void:
	var m := modal()
	var box := dialog(m, Vector2(640, 800) if P else Vector2(860, 470))
	var bw := box.size.x
	var t := UI.label("Match found!", 40, UI.GOLD, true, 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, t, Vector2(0, 14), Vector2(bw, 52))
	var mine := Profile.rating()
	var theirs := int(_found["rating"])
	_side(box, Vector2(bw * 0.25 - 100 if not P else bw * 0.5 - 100, 76 if not P else 66), Profile.player_name(), mine, Profile.avatar_id(), str(Profile.active_deck()["printer"]))
	if not P:
		var vs := UI.label("VS", 36, UI.CREAM, true, 6)
		vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(box, vs, Vector2(bw * 0.5 - 40, 150), Vector2(80, 50))
		_side(box, Vector2(bw * 0.75 - 100, 76), str(_found["name"]), theirs, str(_found["avatar"]), str(_found["printer"]))
	else:
		var vs2 := UI.label("VS", 30, UI.CREAM, true, 6)
		vs2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(box, vs2, Vector2(bw * 0.5 - 40, 300), Vector2(80, 44))
		_side(box, Vector2(bw * 0.5 - 100, 350), str(_found["name"]), theirs, str(_found["avatar"]), str(_found["printer"]))
	var stake := UI.label("Win  %+d      Lose  %+d" % [Rating.delta(mine, theirs, true, int(Profile.player()["ranked_games"])), Rating.delta(mine, theirs, false, int(Profile.player()["ranked_games"]))], 22, UI.CYAN)
	stake.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, stake, Vector2(0, box.size.y - 140), Vector2(bw, 30))
	var fight := UI.button("Fight!", "go", Vector2(240, 58), 26)
	fight.pressed.connect(func():
		var opp := _found
		_found = {}
		app.go("battle", {"session": BattleSession.ranked(Profile.active_deck(), opp)}))
	UI.place(box, fight, Vector2(bw * 0.5 - 250, box.size.y - 84))
	var back := UI.button("Not now", "plain", Vector2(240, 58), 22)
	back.pressed.connect(func():
		_found = {}
		relayout())
	UI.place(box, back, Vector2(bw * 0.5 + 10, box.size.y - 84))


func _side(box: Control, at: Vector2, name: String, rating: int, art: String, printer_id: String) -> void:
	var lg := Rating.league(rating)
	var col: Color = LEAGUE_COLORS[int(lg["index"])]
	var frame := UI.panel(box, Rect2(at + Vector2(25, 0), Vector2(150, 150)), UI.box(Color("0b1220"), col, 4, 18, 8))
	if art != "":
		var raw: String = GameData.RAW % art
		if ResourceLoader.exists(raw):
			frame.add_child(UI.image(raw, Rect2(8, 8, 134, 134), true))
	var n := UI.label(name, 20, UI.CREAM, true, 4)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, n, at + Vector2(-20, 156), Vector2(240, 28))
	var l := UI.label("%s  -  %d" % [Rating.league_text(rating), rating], 17, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, l, at + Vector2(-20, 184), Vector2(240, 24))
	var pn := UI.label(str(GameData.printer(printer_id)["name"]), 15, UI.MUTED, false)
	pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, pn, at + Vector2(-20, 208), Vector2(240, 22))
