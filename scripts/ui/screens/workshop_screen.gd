extends GameScreen
## Buy new Printers and permanent workshop upgrades.

var _body: Control


func build() -> void:
	app.set_background("res://assets/ui/workshop/workshop_maker_closeup_v2.png", 0.78)
	top_bar("Printers & Upgrades")
	_body = Control.new()
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_refresh()


func _refresh() -> void:
	for ch in _body.get_children():
		ch.queue_free()
	UI.place(_body, UI.label("Printers", 26, UI.GOLD, true, 4), Vector2(34, 82), Vector2(300, 32))
	var note := UI.label("Prints that share their Printer's element get +1 Health.", 15, UI.MUTED, false)
	UI.place(_body, note, Vector2(160, 90), Vector2(600, 22))
	for i in GameData.PRINTERS.size():
		var p: Dictionary = GameData.PRINTERS[i]
		var pos := Vector2(30 + (i % 3) * 262, 120 + (i / 3) * 296)
		var col := GameData.element_color(p["element"])
		var owned := Profile.owns_printer(p["id"])
		var cell := UI.panel(_body, Rect2(pos, Vector2(250, 284)), UI.box(Color(UI.PANEL, 0.95), col if owned else UI.BRASS_DARK, 3 if owned else 2, 14, 6))
		var img := UI.image("res://assets/printers/%s.png" % p["id"], Rect2(55, 6, 140, 128))
		if not owned:
			img.modulate = Color(0.55, 0.58, 0.66)
		cell.add_child(img)
		var nm := UI.label(p["name"], 21, col)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.position = Vector2(0, 134)
		nm.size = Vector2(250, 26)
		cell.add_child(nm)
		var pw := UI.label("%s (2 Filament)\n%s" % [p["power"]["name"], p["power"]["text"]], 14, UI.CREAM, false)
		pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		pw.position = Vector2(10, 162)
		pw.size = Vector2(230, 64)
		cell.add_child(pw)
		if owned:
			var tick := IconView.make("check", 22, UI.GOOD)
			tick.position = Vector2(78, 240)
			cell.add_child(tick)
			var ol := UI.label("Owned", 19, UI.GOOD)
			ol.position = Vector2(108, 238)
			ol.size = Vector2(100, 26)
			cell.add_child(ol)
		else:
			var price := Profile.printer_price(p["id"])
			var buy := UI.button("Buy for %d" % price, "primary", Vector2(190, 44), 19)
			buy.disabled = Profile.coins() < price
			buy.pressed.connect(_buy_printer.bind(p["id"]))
			buy.position = Vector2(30, 230)
			cell.add_child(buy)

	UI.place(_body, UI.label("Workshop Upgrades", 26, UI.GOLD, true, 4), Vector2(830, 82), Vector2(400, 32))
	for i in GameData.UPGRADES.size():
		var u: Dictionary = GameData.UPGRADES[i]
		var pos := Vector2(826, 120 + i * 146)
		var lvl := Profile.upgrade_level(u["id"])
		var top: int = (u["costs"] as Array).size()
		var cell := UI.panel(_body, Rect2(pos, Vector2(430, 136)))
		var ic := IconView.make(u["icon"], 46, UI.AMBER)
		ic.position = Vector2(16, 16)
		cell.add_child(ic)
		var nm := UI.label(u["name"], 21, UI.CREAM)
		nm.position = Vector2(76, 12)
		nm.size = Vector2(240, 26)
		cell.add_child(nm)
		for k in top:
			var pip := IconView.make("hex", 20, UI.GOLD if k < lvl else Color("3a4660"))
			pip.position = Vector2(76 + k * 26, 44)
			cell.add_child(pip)
		var tx := UI.label(u["text"], 14, UI.MUTED, false)
		tx.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tx.position = Vector2(16, 76)
		tx.size = Vector2(270, 54)
		cell.add_child(tx)
		var cost := Profile.upgrade_cost(u["id"])
		if cost < 0:
			var mx := UI.label("MAX", 24, UI.GOOD)
			mx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			mx.position = Vector2(296, 52)
			mx.size = Vector2(120, 32)
			cell.add_child(mx)
		else:
			var buy := UI.button("Upgrade\n%d" % cost, "primary", Vector2(124, 76), 18)
			buy.disabled = Profile.coins() < cost
			buy.pressed.connect(_buy_upgrade.bind(u["id"]))
			buy.position = Vector2(294, 30)
			cell.add_child(buy)


func _buy_printer(id: String) -> void:
	var err := Profile.buy_printer(id)
	if err != "":
		Audio.sfx("error")
		app.toast(err, UI.AMBER)
		return
	Audio.sfx("buy")
	app.toast("%s added to your workshop. Pick it for a deck in Collection & Decks." % GameData.printer(id)["name"], UI.GOOD)
	_refresh()


func _buy_upgrade(id: String) -> void:
	var err := Profile.buy_upgrade(id)
	if err != "":
		Audio.sfx("error")
		app.toast(err, UI.AMBER)
		return
	Audio.sfx("buy")
	_refresh()
