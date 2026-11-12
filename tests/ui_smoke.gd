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


func run() -> void:
	await process_frame
	Session = load("res://scripts/core/battle_session.gd")
	var profile := root.get_node("Profile")
	profile.data = profile.fresh()
	profile.choose_starter("cinderpaw")
	app = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await wait(0.5)
	ok(app.current != null and app.current.get_script().resource_path.ends_with("menu_screen.gd"), "boots to the menu")

	await input_checks(profile)
	Engine.time_scale = 12.0
	await full_match("tutorial", Session.tutorial(), profile)
	await full_match("rival", Session.vs_rival(profile.active_deck(), GameData.RIVALS[0]), profile)
	await full_match("quick", Session.quick(profile.active_deck(), 2), profile)
	await full_match("hotseat", Session.hotseat(profile.active_deck(), profile.active_deck()), profile)
	Engine.time_scale = 1.0
	print("\nui smoke: %d failed" % fails)
	quit(1 if fails > 0 else 0)


func input_checks(profile) -> void:
	print("mouse input")
	var session = Session.vs_rival(profile.active_deck(), GameData.RIVALS[0])
	var st: Dictionary = session.state
	st["active"] = 0
	for seat in 2:
		st["players"][seat]["max_fil"] = 8
		st["players"][seat]["fil"] = 8
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
	ok(int(session.state["players"][0]["fil"]) == 5, "its Filament cost was paid")

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
	st["players"][0]["fil"] = 8
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
	var home := "menu_screen.gd" if label == "tutorial" else "play_screen.gd"
	ok(app.current.get_script().resource_path.ends_with(home), "Continue returns to %s" % home)
