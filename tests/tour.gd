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
	profile.data["coins"] = 900
	await go("menu")
	if want("menu"):
		await shot("menu")
		app.current._open_help()
		await shot("help")
		app.current._close_popup()
	if want("collection"):
		await go("collection")
		await shot("collection")
		app.current._show_preview("glassdrake")
		await shot("collection_preview")
	if want("shop"):
		await go("shop")
		await shot("shop")
		app.current._open("standard")
		await wait(0.6)
		for i in 5:
			app.current._flip(i)
		await wait(0.6)
		await shot("pack_open")
	if want("workshop"):
		await go("workshop")
		await shot("workshop")
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
	if want("battle"):
		await battle_shots()
	quit()


## Plays a few scripted turns so the board has things on it.
func battle_shots() -> void:
	var session = load("res://scripts/core/battle_session.gd").vs_rival(root.get_node("Profile").active_deck(), GameData.RIVALS[2])
	var st: Dictionary = session.state
	# Stage a mid-game position.
	for seat in 2:
		st["players"][seat]["max_fil"] = 6
		st["players"][seat]["fil"] = 6
	st["active"] = 0
	for id in ["stoneback", "cinderpaw", "voltwig"]:
		var u := BattleEngine._summon(st, 0, id, 99, [], false)
		u["fresh"] = false
	for id in ["glassdrake", "mossmunk", "brambleowl", "frostling"]:
		var u := BattleEngine._summon(st, 1, id, 99, [], false)
		u["fresh"] = false
	st["players"][1]["board"][3]["jam"] = 1
	st["players"][0]["board"][0]["gear"].append("chest_plate")
	st["players"][0]["hp"] = 24
	st["players"][1]["hp"] = 19
	st["players"][1]["armor"] = 2
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
