extends SceneTree
## Drives the real game UI: mouse drags and clicks on the battlefield, then
## whole matches (vs AI, pass-and-play) played out through the battle screen
## at high speed. Exits 0 when nothing broke.
##
##   PRINTFORGE_PROFILE=smoke godot --path . --disable-vsync -s tests/ui_smoke.gd

var app: Node
var fails := 0
var Session: GDScript


func _initialize() -> void:
	run()


func ok(cond: bool, what: String) -> void:
	if cond:
		print("  ok: ", what)
	else:
		fails += 1
		print("  FAIL: ", what)


func wait(t: float) -> void:
	await create_timer(t).timeout


func settle(scr) -> void:
	# Wait for the battle screen to finish animating.
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000:
		await process_frame
		if not scr._busy and scr._queue.is_empty():
			return


func mouse(pos: Vector2, pressed: Variant = null) -> void:
	var ev: InputEventMouse
	if pressed == null:
		var m := InputEventMouseMotion.new()
		ev = m
	else:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = pressed
		ev = b
	ev.position = pos
	ev.global_position = pos
	root.push_input(ev)
	await process_frame


func drag(from: Vector2, to: Vector2) -> void:
	await mouse(from)
	await mouse(from, true)
	for i in 6:
		await mouse(from.lerp(to, (i + 1) / 6.0))
	await mouse(to, false)


func click(pos: Vector2) -> void:
	await mouse(pos)
	await mouse(pos, true)
	await mouse(pos, false)


func card_center(scr, uid: int) -> Vector2:
	for h in scr._hand:
		if int(h["uid"]) == uid:
			return h["node"].position + Vector2(150, 210) + Vector2(0, -50)
	return Vector2.ZERO


## The menu is the painted workshop: tapping each object opens its screen.
func hotspot_checks() -> void:
	var want := {"battle": "play_screen.gd", "blueprints": "blueprint_screen.gd", "workshop": "workshop_screen.gd",
		"collection": "collection_screen.gd", "shop": "shop_screen.gd"}
	var spots: Array = []
	for ch in app.current.get_children():
		if ch.get_script() != null and str(ch.get_script().resource_path).ends_with("hotspot.gd"):
			spots.append(ch)
	ok(spots.size() == want.size(), "the menu has a hotspot for each place (%d)" % spots.size())
	var opened: Array = []
	for i in spots.size():
		app.go("menu")
		await wait(0.5)
		var hs: Array = []
		for ch in app.current.get_children():
			if ch.get_script() != null and str(ch.get_script().resource_path).ends_with("hotspot.gd"):
				hs.append(ch)
		var h = hs[i]
		var mid := Vector2.ZERO
		for q in h.outline:
			mid += q
		mid /= h.outline.size()
		ok(Geometry2D.is_point_in_polygon(mid, h.outline), "hotspot %d has a tappable middle" % i)
		await click(mid + app.stage.global_position)
		await wait(0.6)
		opened.append(app.current.get_script().resource_path.get_file())
	for f in want.values():
		ok(opened.has(f), "tapping the painted workshop opens %s" % f)
	app.go("menu")
	await wait(0.5)


func run() -> void:
	await process_frame
	Session = load("res://scripts/core/battle_session.gd")
	var profile := root.get_node("Profile")
	profile.data = profile.fresh()
	# The tutorial must be played on the Printer the player picked.
	for starter in GameData.STARTER_PRINTER:
		profile.data = profile.fresh()
		profile.choose_starter(starter)
		for slot in profile.DECK_SLOTS:
			ok(str(profile.deck(slot)["printer"]) == str(GameData.STARTER_PRINTER[starter]), "deck %d starts on the %s you picked" % [slot + 1, starter])
		var tut = Session.tutorial()
		var want_printer: String = GameData.STARTER_PRINTER[starter]
		ok(str(tut.state["players"][0]["printer"]) == want_printer, "tutorial uses the %s you picked (%s)" % [want_printer, starter])
		ok(str(tut.state["players"][1]["printer"]) != want_printer, "tutorial opponent has a different Printer than %s" % want_printer)
	# A save stuck on an empty deck switches back to the one that can battle.
	profile.data = profile.fresh()
	profile.choose_starter("voltwig")
	profile.set_active_deck(1)
	profile.ensure_battle_deck()
	ok(int(profile.data["active_deck"]) == 0, "an empty active deck falls back to the playable one")
	ok(profile.deck_error(0) == "", "the starter deck is playable")
	# Testing tools: coins and XP can be set outright, within limits.
	profile.data = profile.fresh()
	profile.choose_starter("cinderpaw")
	profile.set_coins(123456)
	ok(profile.coins() == 123456, "testing tools set coins exactly")
	profile.set_coins(-5)
	ok(profile.coins() == 0, "coins cannot go below zero")
	profile.set_xp(GameData.xp_for_rank(GameData.RANK_MAX))
	ok(profile.rank_level() == GameData.RANK_MAX, "testing tools can set max Maker Rank")
	profile.set_xp(GameData.xp_for_rank(10))
	ok(profile.rank_level() == 10, "testing tools can set Maker Rank 10")
	profile.data = profile.fresh()
	profile.choose_starter("cinderpaw")
	app = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await wait(0.5)
	ok(app.current != null and app.current.get_script().resource_path.ends_with("menu_screen.gd"), "boots to the menu")

	await hotspot_checks()
	await pack_checks(profile)
	await blueprint_checks(profile)
	await input_checks(profile)
	Engine.time_scale = 12.0
	await full_match("tutorial", Session.tutorial(), profile)
	await full_match("rival", Session.vs_rival(profile.active_deck(), GameData.RIVALS[0]), profile)
	# A deck of Scorch, Thief and Heat cards, so those animations run through the real battle screen.
	var heat_deck := {"printer": "ember_forge", "cards": ["emberling", "emberling", "kilnpup", "kilnpup", "cindermoth", "cindermoth",
		"vinehare", "vinehare", "siphonshark", "siphonshark", "thermochameleon", "thermochameleon", "voltviper", "blazehound",
		"crystalscorp", "hot_plate", "heat_block", "kiln", "spiked_gauntlets", "thermal_core"]}
	await full_match("heat", Session.quick(heat_deck, 1), profile)
	await full_match("quick", Session.quick(profile.active_deck(), 2), profile)
	await full_match("hotseat", Session.hotseat(profile.active_deck(), profile.active_deck()), profile)
	Engine.time_scale = 1.0
	await ranked_checks(profile)
	print("\nui smoke: %d failed" % fails)
	quit(1 if fails > 0 else 0)


## Profile and the ranked queue: open the profile from the menu pill, find a
## match, see the preview, then play the battle and check the rating moves.
func ranked_checks(profile) -> void:
	print("ranked ladder")
	app.go("menu")
	await wait(0.6)
	var pill: Button = null
	for b in app.current.find_children("*", "Button", true, false):
		if b.flat and b.get_parent() is Panel and b.size.x > 200:
			pill = b
	ok(pill != null, "the coin pill is a button")
	if pill != null:
		pill.pressed.emit()
	await wait(0.6)
	ok(app.current.get_script().resource_path.ends_with("profile_screen.gd"), "the pill opens the profile")
	var scr = app.current
	var name_before: String = profile.player_name()
	for b in scr.find_children("*", "Button", true, false):
		if b.text == ">":
			b.pressed.emit()
			break
	await wait(0.4)
	ok(profile.player_name() != name_before or profile.player()["adj"] != 0, "the arrows change your name words")
	scr = app.current
	scr._toggle_search()
	await wait(0.4)
	ok(scr._searching or not scr._found.is_empty(), "the search starts")
	await wait(2.4)
	scr = app.current
	ok(not scr._found.is_empty(), "a ranked opponent is found")
	var fight: Button = null
	for b in scr.find_children("*", "Button", true, false):
		if b.text == "Fight!":
			fight = b
	ok(fight != null, "the match preview offers Fight!")
	var opp: Dictionary = scr._found
	var before: int = profile.rating()
	var games_before: int = int(profile.player()["ranked_games"])
	Engine.time_scale = 12.0
	await full_match("ranked", Session.ranked(profile.active_deck(), opp), profile)
	Engine.time_scale = 1.0
	ok(int(profile.player()["ranked_games"]) == games_before + 1, "the ranked game is counted")
	ok(profile.rating() != before, "the rating moved (%d -> %d)" % [before, profile.rating()])
	ok((profile.player()["history"] as Array).size() >= 1, "the game is in your history")


## Opens a pack the way a player does: swipe to rip it, flick and tap through
## the cards, with a turn of the screen in the middle.
func pack_checks(profile) -> void:
	print("card packs")
	var owned_before: int = profile.packs("standard")
	app.go("shop")
	await wait(0.6)
	var scr = app.current
	scr._open("standard")
	await wait(0.6)
	var op = scr._opener
	ok(op != null and op.stage == "sealed" and profile.packs("standard") == owned_before - 1, "opening a pack shows it sealed")
	var box: Rect2 = op._pack_rect()
	var y: float = box.position.y + 40.0
	# A short swipe only starts the tear.
	await drag(Vector2(box.position.x + 20.0, y), Vector2(box.position.x + box.size.x * 0.4, y))
	ok(op.stage == "sealed" and op._tear > 0.2 and op._tear < 0.7, "a short swipe tears the strip part of the way (%.2f)" % op._tear)
	await drag(Vector2(box.position.x + box.size.x * 0.4, y), Vector2(box.end.x + 30.0, y))
	ok(op.stage != "sealed", "swiping the rest of the way rips the pack open")
	await wait(1.8)
	ok(op.stage == "flip" and op.index == 0 and op._nodes.size() == 5, "the cards come out as a stack")
	var c: Vector2 = op._stack_center()
	await drag(c, c + Vector2(30, 0))
	await wait(0.3)
	ok(op.index == 0, "a small nudge leaves the top card where it is")
	await drag(c, c + Vector2(200, -20))
	await wait(0.5)
	ok(op.index == 1, "flicking the top card shows the next one")
	await click(c)
	await wait(0.5)
	ok(op.index == 2, "tapping the top card also moves on")
	root.size = Vector2i(720, 1280)
	await wait(0.6)
	scr = app.current
	op = scr._opener
	ok(app.portrait and op != null and op.stage == "flip" and op.index == 2, "turning the screen keeps the place in the pack")
	c = op._stack_center()
	for i in 3:
		await click(c)
		await wait(0.5)
	await wait(0.8)
	ok(op.stage == "summary", "after the last card everything is laid out")
	root.size = Vector2i(1280, 720)
	await wait(0.6)
	scr = app.current
	op = scr._opener
	ok(not app.portrait and op != null and op.stage == "summary", "and the summary survives turning back")
	var again: Button = null
	for b in op.find_children("*", "Button", true, false):
		if b.text.begins_with("Open another"):
			again = b
	ok(again != null, "Open another is offered while packs remain")
	if again != null:
		again.pressed.emit()
		await wait(0.6)
		op = scr._opener
		ok(op != null and op.stage == "sealed" and profile.packs("standard") == owned_before - 2, "Open another starts the next pack")
		# A tap on the pack rips it without a swipe; Skip jumps to the spread.
		await click(op._pack_center())
		await wait(2.0)
		ok(op.stage == "flip", "tapping the pack rips it open too")
		op._skip.pressed.emit()
		await wait(0.2)
		ok(op.stage == "summary", "Skip goes straight to the spread")
	for b in op.find_children("*", "Button", true, false):
		if b.text == "Done":
			b.pressed.emit()
	await wait(0.3)
	ok(scr._opener == null and scr._open_cards.is_empty(), "Done closes the pack")
	app.go("menu")
	await wait(0.5)


## The Blueprint screen: upgrade a card, fit a mod, paint it, and play it.
func blueprint_checks(profile) -> void:
	print("blueprints")
	profile.data["xp"] = 6000
	profile.data["coins"] = 5000
	profile.data["cards"]["cinderpaw"] = 2
	profile.data["spares"]["cinderpaw"] = 1
	app.go("blueprints", {"card": "cinderpaw"})
	await wait(0.6)
	var scr = app.current
	ok(scr._sel == "cinderpaw", "the Blueprint screen opens on the chosen card")
	scr._upgrade()
	await wait(0.4)
	ok(int(profile.build_of("cinderpaw")["tier"]) == 2, "Upgrade takes the card to Mk II")
	app.current._unlock_mod("sharp_nozzle")
	app.current._fit_mod("sharp_nozzle")
	app.current._paint("rose")
	await wait(0.4)
	var b: Dictionary = profile.build_of("cinderpaw")
	ok(b["mod"] == "sharp_nozzle" and b["paint"] == "rose", "the mod and paint are saved on the card")
	var deck: Dictionary = profile.active_deck()
	var session = Session.vs_rival(deck, GameData.RIVALS[0])
	var mine: Dictionary = session.state["players"][0]["builds"]
	ok(mine.has("cinderpaw") and int(mine["cinderpaw"]["tier"]) == 2, "a battle with that deck uses the Blueprint")
	var st: Dictionary = session.state
	st["active"] = 0
	st["players"][0]["hand"].clear()
	st["players"][0]["hand"].append({"uid": 950, "id": "cinderpaw"})
	st["players"][0]["flow"] = 9
	app.go("battle", {"session": session})
	await wait(1.4)
	scr = app.current
	await settle(scr)
	var hand_card = scr._hand[0]["node"]
	ok(int(GameData.built("cinderpaw", hand_card.build)["atk"]) == 6 and hand_card.build.get("paint", "") == "rose", "the card in hand shows its built stats and paint")
	session.submit(0, {"t": "play", "hand": 950, "target": "p1"})
	await settle(scr)
	var board: Array = session.state["players"][0]["board"]
	ok(board.size() == 1 and int(board[0]["atk"]) >= 6 and str(board[0]["paint"]) == "rose", "the print on the bench is the built one (Attack %d)" % int(board[0]["atk"]))
	var shown = scr._units[int(board[0]["uid"])]
	ok(shown.paint_id == "rose", "and it is painted rose on the bench")
	app.go("menu")
	await wait(0.5)


func input_checks(profile) -> void:
	print("mouse input")
	var session = Session.vs_rival(profile.active_deck(), GameData.RIVALS[0])
	var st: Dictionary = session.state
	st["active"] = 0
	for seat in 2:
		st["players"][seat]["speed"] = 8
		st["players"][seat]["flow"] = 8
	st["players"][0]["hand"].clear()
	var ids := ["stoneback", "heat_gun", "cinderpaw", "glue_stick"]
	var uids := {}
	for id in ids:
		var uid: int = int(st["uid"])
		st["uid"] = uid + 1
		st["players"][0]["hand"].append({"uid": uid, "id": id})
		uids[id] = uid
	var mine: Dictionary = BattleEngine._summon(st, 0, "voltwig", 99, [], false)
	mine["fresh"] = false
	var foe: Dictionary = BattleEngine._summon(st, 1, "mossmunk", 99, [], false)
	app.go("battle", {"session": session})
	await wait(1.6)
	var scr = app.current
	await settle(scr)

	# 1. Drag an untargeted print from hand onto the bed.
	await drag(card_center(scr, uids["stoneback"]), Vector2(700, 380))
	await settle(scr)
	ok(session.state["players"][0]["board"].size() == 2, "dragging a print onto the bed plays it")
	ok(int(session.state["players"][0]["flow"]) == 5 and int(session.state["players"][0]["spool"]) == GameData.SPOOL_SIZE - 3, "its Filament came off this turn's speed and the Spool")

	# 2. Drag from a ready print to an enemy print to attack.
	var a_node = scr._units[int(mine["uid"])]
	var f_node = scr._units[int(foe["uid"])]
	await drag(a_node.center(), f_node.center())
	await settle(scr)
	ok(int(BattleEngine.find_unit(session.state, int(foe["uid"])).get("hp", -1)) == 1, "drag-attack hits the Guard print (3 -> 1)")

	# 3. Click a targeted tool, then click the target (two separate clicks).
	await click(card_center(scr, uids["heat_gun"]))
	ok(scr._mode == "target" and scr._sticky, "clicking a targeted card waits for a target")
	await click(scr._units[int(foe["uid"])].center())
	await settle(scr)
	ok(session.state["players"][1]["board"].is_empty(), "click-click Heat Gun finishes the print")

	# 4. Targeted On Print creature onto the enemy Printer.
	var hp_before: int = int(session.state["players"][1]["hp"])
	await drag(card_center(scr, uids["cinderpaw"]), scr._printers[1].center())
	await settle(scr)
	ok(int(session.state["players"][1]["hp"]) == hp_before - 1 and session.state["players"][0]["board"].size() >= 2, "On Print target by drag works")

	# 5. A drag released back over the hand cancels.
	var hand_before: int = session.state["players"][0]["hand"].size()
	var c := card_center(scr, uids["glue_stick"])
	await mouse(c)
	await mouse(c, true)
	await mouse(c + Vector2(200, -30))
	await mouse(Vector2(640, 20), false)
	await settle(scr)
	ok(session.state["players"][0]["hand"].size() == hand_before and scr._mode == "idle", "releasing off-target cancels")

	# 6. Printer Power: button, then target.
	scr._on_power()
	ok(scr._mode == "target", "Hot Nozzle asks for a target")
	await click(scr._printers[1].center())
	await settle(scr)
	ok(bool(session.state["players"][0]["power_used"]), "Printer Power was used")

	# 6b. Tap a card (no drag), then tap the bench: the touch way to play.
	st = session.state
	st["players"][0]["flow"] = 8
	var tap_uid: int = int(st["uid"])
	st["uid"] = tap_uid + 1
	st["players"][0]["hand"].append({"uid": tap_uid, "id": "mossmunk"})
	scr.st = session.view()
	scr._sync()
	await wait(0.3)
	var before_board: int = session.state["players"][0]["board"].size()
	await click(card_center(scr, tap_uid))
	ok(scr._mode == "armed", "tapping a card arms it")
	await click(scr.bed_me.get_center())
	await settle(scr)
	ok(session.state["players"][0]["board"].size() == before_board + 1, "tap card then tap bench plays it")

	# 6d. A card that costs more than this turn's speed goes on the Printer,
	# and is tapped off it once it is finished.
	st = session.state
	st["players"][0]["flow"] = 3
	var long_uid: int = int(st["uid"])
	st["uid"] = long_uid + 1
	st["players"][0]["hand"].append({"uid": long_uid, "id": "ironmaw"})
	scr.st = session.view()
	scr._sync()
	await wait(0.3)
	before_board = session.state["players"][0]["board"].size()
	await drag(card_center(scr, long_uid), scr._printers[0].center())
	await settle(scr)
	ok(session.state["players"][0]["job"].get("id", "") == "ironmaw" and scr._jobs[0] != null and session.state["players"][0]["board"].size() == before_board,
		"dragging a big card to the Printer starts a long print")
	ok(int(session.state["players"][0]["flow"]) == 0 and scr._gauge.flow == 0, "it uses up the rest of this turn's speed")
	await click(scr._jobs[0].center())
	await settle(scr)
	ok(not session.state["players"][0]["job"].is_empty(), "an unfinished print stays on the Printer when tapped")
	session.state["players"][0]["job"]["paid"] = 5
	scr.st = session.view()
	scr._sync()
	await wait(0.3)
	await click(scr._jobs[0].center())
	await settle(scr)
	ok(session.state["players"][0]["job"].is_empty() and session.state["players"][0]["board"].size() == before_board + 1 and scr._jobs[0] == null,
		"tapping the finished print sends it to the bench")

	# 6c. Turn the screen: the battle re-lays itself out and keeps going.
	var units_before: int = scr._units.size()
	root.size = Vector2i(720, 1280)
	await wait(0.6)
	ok(app.portrait and app.stage_size == Vector2(720, 1280), "portrait window switches the stage to 720x1280")
	scr = app.current
	ok(scr._units.size() == units_before and scr._hand.size() == session.state["players"][0]["hand"].size(), "battle survives the turn to portrait")
	ok(scr.bed_me.end.x <= 720.0 and scr._gauge.position.x + scr._gauge.size.x <= 720.0, "portrait layout fits the narrow stage")
	root.size = Vector2i(1280, 720)
	await wait(0.6)
	ok(not app.portrait and app.current._units.size() == units_before, "and back to landscape")
	scr = app.current

	# 7. End Turn button, and the AI answers.
	scr._end_turn()
	await wait(0.3)
	await settle(scr)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 20000:
		await process_frame
		if int(session.state["active"]) == 0 and not scr._busy:
			break
	ok(int(session.state["active"]) == 0 and int(session.state["turn"]) >= 3, "the AI takes its turn and hands back")
	ok(not scr._end_btn.disabled or scr._end_go.visible, "End Turn is live again")


func full_match(label: String, session, profile) -> void:
	print("full match: ", label)
	var coins_before: int = profile.coins()
	app.go("battle", {"session": session})
	await wait(1.5)
	var scr = app.current
	var guard := 0
	while not session.state["over"] and guard < 3000:
		guard += 1
		await settle(scr)
		if scr._tip_blocking:
			# Tutorial tip: press Got it.
			for b in scr.find_children("*", "Button", true, false):
				if b.text == "Got it":
					b.pressed.emit()
			await wait(0.1)
			continue
		if scr._locked and not session.state["over"]:
			# Pass-and-play curtain: press Ready.
			var pressed := false
			for b in scr.find_children("*", "Button", true, false):
				if b.text == "Ready":
					b.pressed.emit()
					pressed = true
			if not pressed:
				await wait(0.2)
			continue
		var seat: int = int(session.state["active"])
		if session.is_human(seat) and not scr._busy and not session.state["over"]:
			session.submit(seat, BattleAI.choose(session.state, seat, 1))
		else:
			await wait(0.2)
	await settle(scr)
	await wait(2.0)
	ok(session.state["over"], "%s match reaches an end (turn %d)" % [label, int(session.state["turn"])])
	var cont: Button = null
	for b in scr.find_children("*", "Button", true, false):
		if b.text == "Continue":
			cont = b
	ok(cont != null, "%s result screen appears" % label)
	if label == "tutorial":
		ok(scr._tips_done.size() >= 5, "tutorial showed its tips (%d done: %s)" % [scr._tips_done.size(), ", ".join(scr._tips_done.keys())])
		ok(bool(profile.data["tutorial_done"]) == (int(session.state["winner"]) == 0), "tutorial completion is recorded when won")
	elif label != "hotseat":
		ok(profile.coins() > coins_before, "%s pays out coins (%d -> %d)" % [label, coins_before, profile.coins()])
	else:
		ok(profile.coins() == coins_before, "hotseat pays nothing")
	if cont != null:
		cont.pressed.emit()
	await wait(1.0)
	var home := "menu_screen.gd" if label == "tutorial" else ("profile_screen.gd" if label == "ranked" else "play_screen.gd")
	ok(app.current.get_script().resource_path.ends_with(home), "Continue returns to %s" % home)
