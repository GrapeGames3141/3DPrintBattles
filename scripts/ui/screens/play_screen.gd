extends GameScreen
## Pick a deck, then pick a fight: campaign rival, quick battle, or a friend.

var _body: Control
var _p2_slot := -1
var _wait: Control
var _address: LineEdit
var _typed := ""


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_proving_closeup_v2.png", 0.74)
	top_bar("Battle")
	if _p2_slot < 0:
		_p2_slot = int(Profile.data["active_deck"])
	_wait = null
	_body = null
	_address = null
	for pair in [[app.net.guest_ready, _on_guest_ready], [app.net.connected, _on_connected],
			[app.net.game_started, _on_game_started], [app.net.dropped, _on_dropped]]:
		if not (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).connect(pair[1])
	_refresh()


func _exit_tree() -> void:
	super()
	for pair in [[app.net.guest_ready, _on_guest_ready], [app.net.connected, _on_connected],
			[app.net.game_started, _on_game_started], [app.net.dropped, _on_dropped]]:
		if (pair[0] as Signal).is_connected(pair[1]):
			(pair[0] as Signal).disconnect(pair[1])


func _heading(text: String, pos: Vector2) -> void:
	UI.place(_body, UI.label(text, 24, UI.GOLD, true, 4), pos, Vector2(340, 30))


func _refresh() -> void:
	if is_instance_valid(_address):
		_typed = _address.text
	if is_instance_valid(_body):
		# In portrait the body lives inside a scroll area; drop the whole thing.
		var holder: Node = _body.get_parent() if _body.get_parent() != self else _body
		remove_child(holder)
		holder.queue_free()
	if P:
		_body = scroll_body(76, 1600)
		_deck_section(Rect2(20, 12, 680, 268), true)
		_campaign_section(Vector2(20, 292), 680)
		_versus_section(Rect2(20, 926, 680, 660))
	else:
		_body = Control.new()
		_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_body)
		_deck_section(Rect2(30, 84, 372, 622), false)
		_campaign_section(Vector2(416, 84), 486)
		_versus_section(Rect2(916, 84, 334, 622))


func _deck_section(r: Rect2, compact: bool) -> void:
	var active := int(Profile.data["active_deck"])
	var x := r.position.x
	var y := r.position.y
	UI.panel(_body, r)
	_heading("Your deck", Vector2(x + 18, y + 10))
	var bw := (r.size.x - 36 - 16) / 3.0 if compact else r.size.x - 36
	for i in Profile.DECK_SLOTS:
		var d := Profile.deck(i)
		var err := Profile.deck_error(i)
		var p: Dictionary = GameData.printer(d["printer"])
		var b := UI.button("", "primary" if i == active else "plain", Vector2(bw, 62))
		b.pressed.connect(func():
			Profile.set_active_deck(i)
			_refresh())
		UI.place(_body, b, Vector2(x + 18 + i * (bw + 8), y + 50) if compact else Vector2(x + 18, y + 50 + i * 70))
		var nm := UI.label("Deck %d" % (i + 1) if compact else "Deck %d  -  %s" % [i + 1, p["name"]], 19, Color.WHITE if i == active else UI.CREAM)
		nm.position = Vector2(14, 6)
		nm.size = Vector2(bw - 20, 24)
		b.add_child(nm)
		var stt := UI.label("Ready" if err == "" else "%d / %d cards" % [(d["cards"] as Array).size(), GameData.DECK_SIZE],
			14, UI.GOOD if err == "" else UI.AMBER, false)
		stt.position = Vector2(14, 32)
		stt.size = Vector2(bw - 20, 22)
		b.add_child(stt)
	var ap: Dictionary = GameData.printer(Profile.active_deck()["printer"])
	var edit := UI.button("Edit decks", "plain", Vector2(170 if compact else 200, 46))
	edit.pressed.connect(func(): app.go("collection"))
	if compact:
		_body.add_child(PrinterRig.make(ap["id"], Profile.installed_mods(ap["id"]), Rect2(x + 14, y + 124, 140, 130)))
		UI.place(_body, UI.label(ap["name"], 22, GameData.element_color(ap["element"]), true, 4), Vector2(x + 166, y + 132), Vector2(300, 28))
		var pw := UI.label("%s: %s" % [ap["power"]["name"], ap["power"]["text"]], 15, UI.CREAM, false)
		pw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(_body, pw, Vector2(x + 166, y + 164), Vector2(320, 70))
		UI.place(_body, edit, Vector2(x + r.size.x - 188, y + 196))
	else:
		_body.add_child(PrinterRig.make(ap["id"], Profile.installed_mods(ap["id"]), Rect2(x + 86, y + 264, 200, 184)))
		var pn := UI.label(ap["name"], 23, GameData.element_color(ap["element"]), true, 4)
		pn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI.place(_body, pn, Vector2(x, y + 450), Vector2(r.size.x, 28))
		var pw := UI.label("%s: %s" % [ap["power"]["name"], ap["power"]["text"]], 15, UI.CREAM, false)
		pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI.place(_body, pw, Vector2(x + 20, y + 480), Vector2(r.size.x - 40, 46))
		UI.place(_body, edit, Vector2(x + r.size.x * 0.5 - 100, y + 560))


func _campaign_section(pos: Vector2, w: float) -> void:
	var x := pos.x
	UI.panel(_body, Rect2(pos, Vector2(w, 622)))
	_heading("Campaign", Vector2(x + 18, pos.y + 10))
	var next := Profile.next_rival_index()
	for i in GameData.RIVALS.size():
		var r: Dictionary = GameData.RIVALS[i]
		var beaten := Profile.rival_beaten(r["id"])
		var open := beaten or i <= next
		var y := pos.y + 48.0 + i * 56.0
		var col := GameData.element_color(GameData.printer(r["printer"])["element"])
		UI.panel(_body, Rect2(x + 14, y, w - 28, 50), UI.box(Color("0f1a30") if open else Color("0b111e"), col if open else Color("2a3346"), 2, 8))
		var img := UI.image("res://assets/printers/%s.png" % r["printer"], Rect2(x + 20, y + 3, 48, 44))
		img.modulate = Color.WHITE if open else Color(0.35, 0.38, 0.45)
		_body.add_child(img)
		UI.place(_body, UI.label(r["name"], 18, UI.CREAM if open else UI.MUTED), Vector2(x + 74, y + 3), Vector2(w - 250, 24))
		var sub := "%s  -  %s" % [r["title"], GameData.AI_LEVELS[int(r["level"])]]
		UI.place(_body, UI.label(sub, 13, UI.MUTED, false), Vector2(x + 74, y + 26), Vector2(w - 230, 20))
		if beaten:
			UI.place(_body, IconView.make("check", 20, UI.GOOD), Vector2(x + w - 154, y + 15))
		if open:
			var go := UI.button("Rematch" if beaten else "Fight", "plain" if beaten else "go", Vector2(104, 38), 17)
			go.pressed.connect(_fight_rival.bind(i))
			UI.place(_body, go, Vector2(x + w - 124, y + 6))
		else:
			UI.place(_body, IconView.make("lock", 22, Color("4a5568")), Vector2(x + w - 82, y + 14))


func _versus_section(r: Rect2) -> void:
	var x := r.position.x + 18
	var w := r.size.x - 36
	var y := r.position.y + 10
	UI.panel(_body, r)
	_heading("Practice", Vector2(x, y))
	y += 38
	var tut := UI.button("Tutorial  (learn to play)", "plain" if bool(Profile.data["tutorial_done"]) else "go", Vector2(w, 44), 18)
	tut.pressed.connect(func(): app.go("battle", {"session": BattleSession.tutorial()}))
	UI.place(_body, tut, Vector2(x, y))
	y += 52
	for i in GameData.AI_LEVELS.size():
		var b := UI.button("%s  (+%d coins)" % [GameData.AI_LEVELS[i], int(GameData.WIN_COINS[i])], "plain", Vector2(w, 44), 18)
		b.pressed.connect(_quick.bind(i))
		UI.place(_body, b, Vector2(x, y))
		y += 52
	y += 4
	_heading("Two players", Vector2(x, y))
	y += 38
	var hot := UI.button("Pass & Play on this screen", "primary", Vector2(w, 48), 18)
	hot.pressed.connect(_hotseat)
	UI.place(_body, hot, Vector2(x, y))
	y += 54
	var p2 := UI.button("Player 2 uses Deck %d" % (_p2_slot + 1), "plain", Vector2(w, 36), 15)
	p2.pressed.connect(func():
		_p2_slot = (_p2_slot + 1) % Profile.DECK_SLOTS
		_refresh())
	UI.place(_body, p2, Vector2(x, y))
	y += 48
	UI.place(_body, UI.label("Over the network", 18, UI.CYAN), Vector2(x, y), Vector2(w, 26))
	y += 30
	var host := UI.button("Host a game", "primary", Vector2(w, 46), 18)
	host.pressed.connect(_host)
	UI.place(_body, host, Vector2(x, y))
	y += 54
	_address = LineEdit.new()
	_address.placeholder_text = "Host address, e.g. 192.168.1.20"
	_address.max_length = 64
	_address.text = _typed
	_address.add_theme_font_size_override("font_size", 15)
	UI.place(_body, _address, Vector2(x, y), Vector2(w, 40))
	y += 48
	var join := UI.button("Join a game", "primary", Vector2(w, 46), 18)
	join.pressed.connect(_join)
	UI.place(_body, join, Vector2(x, y))
	y += 52
	var hint := UI.label("Both players need to be on the same network.", 12, UI.MUTED, false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(_body, hint, Vector2(r.position.x, y), Vector2(r.size.x, 20))


func _deck_ready(slot: int) -> bool:
	var err := Profile.deck_error(slot)
	if err != "":
		Audio.sfx("error")
		app.toast("Deck %d is not ready: %s" % [slot + 1, err], UI.AMBER)
		return false
	return true


func _active() -> int:
	return int(Profile.data["active_deck"])


func _fight_rival(i: int) -> void:
	if _deck_ready(_active()):
		app.go("battle", {"session": BattleSession.vs_rival(Profile.active_deck(), GameData.RIVALS[i])})


func _quick(level: int) -> void:
	if _deck_ready(_active()):
		app.go("battle", {"session": BattleSession.quick(Profile.active_deck(), level)})


func _hotseat() -> void:
	if _deck_ready(_active()) and _deck_ready(_p2_slot):
		app.go("battle", {"session": BattleSession.hotseat(Profile.active_deck(), Profile.deck(_p2_slot))})


# ---------------------------------------------------------------- network

func _waiting(title: String, lines: Array) -> void:
	close_modal(_wait)
	_wait = modal()
	var box := dialog(_wait, Vector2(600, 340))
	var bw := box.size.x
	var t := UI.label(title, 30, UI.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.place(box, t, Vector2(0, 26), Vector2(bw, 40))
	var body := UI.label("\n".join(lines), 19, UI.CREAM, false)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.place(box, body, Vector2(30, 84), Vector2(bw - 60, 160))
	var cancel := UI.button("Cancel", "plain", Vector2(200, 50))
	cancel.pressed.connect(func():
		app.net.close()
		close_modal(_wait))
	UI.place(box, cancel, Vector2(bw * 0.5 - 100, 264))


func _host() -> void:
	if not _deck_ready(_active()):
		return
	var err: String = app.net.host()
	if err != "":
		app.toast(err, UI.AMBER)
		return
	var addrs: Array = NetLink.local_addresses()
	_waiting("Waiting for an opponent...", [
		"Ask your opponent to choose Join a game and type this address:",
		"",
		"   ".join(addrs) if not addrs.is_empty() else "(no network address found)",
	])


func _join() -> void:
	if not _deck_ready(_active()):
		return
	var address := _address.text.strip_edges()
	if address == "":
		app.toast("Type the host's address first.", UI.AMBER)
		return
	var err: String = app.net.join(address)
	if err != "":
		app.toast(err, UI.AMBER)
		return
	_waiting("Connecting...", ["Looking for a game at %s" % address])


func _on_connected() -> void:
	var d := Profile.active_deck()
	app.net.send_hello({"deck": d["cards"], "printer": d["printer"], "mods": Profile.battle_mods(d["printer"]), "builds": Profile.builds_for(d["cards"])})


func _on_guest_ready(info: Dictionary) -> void:
	var cfg := BattleSession.guest_config(info)
	if cfg.is_empty():
		app.net.close()
		close_modal(_wait)
		app.toast("Your opponent's deck was not valid.", UI.AMBER)
		return
	app.go("battle", {"session": BattleSession.lan_host(app.net, Profile.active_deck(), cfg)})


func _on_game_started(view: Dictionary, info: Dictionary) -> void:
	app.go("battle", {"session": BattleSession.lan_guest(app.net, view, info)})


func _on_dropped(reason: String) -> void:
	close_modal(_wait)
	app.toast(reason, UI.AMBER)
