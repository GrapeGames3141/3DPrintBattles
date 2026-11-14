extends SceneTree
## Visual tour: drives the real game through its screens and saves a
## screenshot of each, so the look can be checked without clicking through.
##
##   PRINTFORGE_PROFILE=tour godot --path . --disable-vsync -s tests/tour.gd -- <output dir> [shot names...]

var out_dir := ""
var only: Array = []
var app: Node


func _initialize() -> void:
	var a := Array(OS.get_cmdline_user_args())
	out_dir = a[0] if not a.is_empty() else OS.get_user_data_dir()
	only = a.slice(1)
	run()


func shot(name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])
	print("shot ", name)


func want(name: String) -> bool:
	return only.is_empty() or only.has(name)


func wait(t: float) -> void:
	await create_timer(t).timeout


func go(screen: String, args := {}) -> void:
	app.go(screen, args)
	await wait(0.45)


func run() -> void:
	await process_frame
	var profile := root.get_node("Profile")
	profile.data = profile.fresh()
	app = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await wait(0.6)
	if want("starter"):
		app.current._pick("cinderpaw")
		await shot("starter")
	profile.choose_starter("cinderpaw")
	profile.give_starter_deck()
	profile.data["coins"] = 900
	await go("menu")
	if want("menu"):
		await shot("menu")
		app.current._open_help()
		await shot("help")
		for ch in 3:
			var book = load("res://scripts/ui/handbook.gd").open(app.current, ch)
			await shot("handbook%d" % ch)
			app.current.close_modal(book)
		app.current._close_popup()
		app.current._open_settings()
		await shot("settings")
		app.current._close_popup()
		app.current._open_testing()
		await shot("testing")
		app.current._close_popup()
	if want("collection"):
		await go("collection")
		await shot("collection")
		app.current._open_filters()
		await shot("filters")
		app.current._close_filters()
		app.current._element = "Fire"
		app.current._sort = "rarity"
		app.current._refresh()
		await shot("collection_fire")
		app.current._element = ""
		app.current._sort = "cost"
		app.current._refresh()
		app.current._show_preview("glassdrake")
		await shot("collection_preview")
		for id in ["spoolcolossus", "multimeterbeetle", "firmware_update", "corexy_frame"]:
			app.current._show_preview(id)
			await shot("preview_" + id)
	if want("shop"):
		await go("shop")
		await shot("shop")
		app.current._open("standard")
		await wait(0.9)
		await shot("pack_sealed")
		var op = app.current._opener
		op._tear_dir = 1
		op._touch_pack()
		op._tear = 0.55
		op._apply_tear()
		await shot("pack_tearing")
		op._auto_rip()
		await wait(0.62)
		await shot("pack_pulling")
		await wait(1.2)
		await shot("pack_flip")
		op._press = op._stack_center()
		op._drag_card(op._stack_center() + Vector2(150, -30))
		await shot("pack_flip_drag")
		op._send_top(1)
		await wait(0.5)
		op._send_top(-1)
		await wait(0.5)
		await shot("pack_flip_3")
		for i in 3:
			op._send_top(1)
			await wait(0.45)
		await wait(1.0)
		await shot("pack_open")
		app.current._close_opener()
		# A premium pack with a great card waiting under the top one.
		app.current._open_kind = "premium"
		app.current._open_cards = [
			{"id": "heat_gun", "new": false, "lost": true}, {"id": "starloom", "new": true, "lost": false},
			{"id": "glassdrake", "new": true, "lost": false}, {"id": "helm", "new": false, "lost": false},
			{"id": "voltwig", "new": false, "lost": true}]
		app.current._start_opener("sealed", 0)
		await wait(0.9)
		await shot("pack_premium")
		op = app.current._opener
		op.show_stage("flip", 0)
		await wait(0.5)
		await shot("pack_under_glow")
		op._send_top(1)
		await wait(0.7)
		await shot("pack_legendary")
		app.current._close_opener()
	if want("blueprints"):
		profile.data["xp"] = 5000
		profile.data["coins"] = 9000
		for id in ["mossmunk", "cinderpaw", "heat_gun", "glassdrake", "helm"]:
			profile.data["cards"][id] = maxi(profile.owned_count(id), 1)
		for i in 4:
			profile.add_card("cinderpaw")
		profile.upgrade_card("cinderpaw")
		profile.buy_card_mod("sharp_nozzle")
		profile.buy_paint("amber")
		profile.set_paint("cinderpaw", "amber")
		profile.set_card_mod("cinderpaw", "sharp_nozzle")
		profile.upgrade_card("cinderpaw")
		profile.buy_card_mod("infill")
		profile.set_card_mod("cinderpaw", "infill")
		await go("blueprints", {"card": "cinderpaw"})
		await shot("blueprints")
		app.current._sel = "heat_gun"
		app.current.relayout()
		await wait(0.4)
		await shot("blueprints_tool")
	if want("workshop"):
		profile.data["xp"] = 3000
		profile.data["coins"] = 5000
		profile.buy_mod("spool")
		profile.buy_mod("frame")
		profile.buy_mod("sorter")
		await go("workshop")
		await shot("workshop")
		app.current._tab = "mods"
		app.current.relayout()
		await wait(0.4)
		await shot("workshop_mods")
		app.current._tab = "printers"
		app.current._open_install("ember_forge")
		await wait(0.4)
		await shot("workshop_install")
		app.current._install_for = ""
		# A fully modded machine: every mod owned and fitted.
		profile.data["xp"] = 999999
		profile.data["coins"] = 9999999
		for pass_i in 4:
			for m in GameData.PRINTER_MODS:
				profile.buy_mod(m["id"])
		for pass_i in 3:
			for id in ["stepper", "frame", "spool", "bed"]:
				profile.upgrade_mod("ember_forge", id)
		app.current._open_install("ember_forge")
		await wait(0.4)
		await shot("workshop_install_all")
		app.current._install_for = ""
		# ...and on the battlefield (and in portrait if the tour runs at 720x1280).
		profile.ensure_battle_deck()
		await go("battle", {"session": load("res://scripts/core/battle_session.gd").quick(profile.active_deck(), 1)})
		await wait(0.8)
		await shot("battle_modded")
	if want("profile"):
		for g in [[1010, true], [1030, true], [1100, false], [1060, true], [1210, true]]:
			profile.record_ranked("Swift Gear 07", int(g[0]), bool(g[1]))
		await go("profile")
		await shot("profile")
		app.current._found = Ladder.opponent(profile.rating(), 21)
		app.current.relayout()
		await wait(0.4)
		await shot("profile_match")
		app.current._found = {}
		app.current.relayout()
	if want("play"):
		await go("play")
		await shot("play")
	if want("tutorial"):
		await go("battle", {"session": load("res://scripts/core/battle_session.gd").tutorial()})
		await wait(0.8)
		await shot("tutorial")
		app.current._tips_done["goal"] = true
		app.current._tips_done["filament"] = true
		app.current._show_tip("")
		app.current._coach_update()
		await wait(0.3)
		await shot("tutorial_action")
		await long_print_shots()
	if want("battle"):
		await battle_shots()
	quit()


func hand_uid(session, id: String) -> int:
	for c in session.state["players"][0]["hand"]:
		if c["id"] == id:
			return int(c["uid"])
	return -1


## Waits for the computer's turn to finish and the screen to catch up.
func my_turn_again(session) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 30000:
		await process_frame
		if session.state["over"]:
			return
		if int(session.state["active"]) == 0 and not app.current._busy and app.current._queue.is_empty():
			return


## Continues the tutorial battle: start a long print, then send it out.
func long_print_shots() -> void:
	var scr = app.current
	var session = scr.session
	for id in ["goal", "filament", "guard", "print", "fresh", "attack", "tool", "upgrade"]:
		scr._tips_done[id] = true
	session.submit(0, {"t": "play", "hand": hand_uid(session, "mossmunk")})
	await wait(2.2)
	session.submit(0, {"t": "end"})
	await my_turn_again(session)
	scr._show_tip("")
	scr._coach_update()
	await wait(0.4)
	await shot("long_tip")
	session.submit(0, {"t": "play", "hand": hand_uid(session, "runestag")})
	await wait(0.55)
	await shot("long_start")
	await wait(1.6)
	await shot("long_waiting")
	session.submit(0, {"t": "end"})
	await my_turn_again(session)
	scr._show_tip("")
	scr._coach_update()
	await wait(0.4)
	await shot("long_ready")
	session.submit(0, {"t": "deploy"})
	await wait(0.3)
	await shot("long_deploy")
	await wait(1.5)


## Plays a few scripted turns so the board has things on it.
func battle_shots() -> void:
	var session = load("res://scripts/core/battle_session.gd").vs_rival(root.get_node("Profile").active_deck(), GameData.RIVALS[2])
	var st: Dictionary = session.state
	# Stage a mid-game position.
	for seat in 2:
		st["players"][seat]["spool"] = 23 - seat * 9
	st["active"] = 0
	st["players"][0]["flow"] = 3
	st["players"][1]["flow"] = 0
	for id in ["stoneback", "cinderpaw", "voltwig"]:
		var u := BattleEngine._summon(st, 0, id, 99, [], false)
		u["fresh"] = false
	for id in ["glassdrake", "mossmunk", "brambleowl", "frostling"]:
		var u := BattleEngine._summon(st, 1, id, 99, [], false)
		u["fresh"] = false
	st["players"][1]["board"][3]["jam"] = 1
	st["players"][0]["board"][0]["gear"].append("chest_plate")
	st["players"][0]["hp"] = 17
	st["players"][1]["hp"] = 12
	st["players"][1]["armor"] = 2
	# A long print part-way done on my Printer, and a finished one on theirs.
	st["players"][0]["job"] = {"uid": 900, "id": "coalgriffin", "cost": 6, "paid": 3}
	st["players"][1]["job"] = {"uid": 901, "id": "emergency_stop", "cost": 6, "paid": 6}
	await go("battle", {"session": session})
	await wait(1.2)
	await shot("battle")
	var scr = app.current
	# Play a print from hand to watch the layer-by-layer animation mid-way.
	var hand: Array = session.state["players"][0]["hand"]
	for c in hand:
		if GameData.card(c["id"])["type"] == "creature" and BattleEngine.play_error(session.state, 0, int(c["uid"])) == "" \
				and not BattleEngine.needs_target(session.state, 0, c["id"]):
			session.submit(0, {"t": "play", "hand": int(c["uid"])})
			break
	await wait(0.75)
	await shot("battle_printing")
	await wait(1.9)
	# Tap one of my prints: the Guard stands out and what it shields goes grey.
	for u in session.state["players"][0]["board"]:
		if not BattleEngine.attack_targets(session.state, int(u["uid"])).is_empty():
			scr._mouse = scr._units[int(u["uid"])].center()
			scr._on_press()
			scr._on_release()
			break
	await wait(0.25)
	await shot("battle_guard")
	scr._cancel()
	# Attack with the first ready print.
	for u in session.state["players"][0]["board"]:
		var tg := BattleEngine.attack_targets(session.state, int(u["uid"]))
		if not tg.is_empty():
			session.submit(0, {"t": "attack", "unit": int(u["uid"]), "target": tg[0]})
			break
	await wait(0.3)
	await shot("battle_attack")
	await wait(1.0)
	scr._hover_uid = int(session.state["players"][0]["hand"][0]["uid"])
	scr._layout_hand()
	await wait(0.3)
	await shot("battle_hover")
	scr._hover_uid = -1
	session.submit(0, {"t": "end"})
	await wait(4.5)
	await shot("battle_enemy_turn")
	session.submit(0, {"t": "concede"})
	await wait(1.6)
	await shot("battle_result")
