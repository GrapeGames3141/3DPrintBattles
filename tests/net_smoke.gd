extends SceneTree
## Network test: run one copy as host and one as guest; they connect through
## the real Battle menu and play a whole match against each other.
##
##   PRINTFORGE_PROFILE=neta godot --headless --path . -s tests/net_smoke.gd -- host &
##   PRINTFORGE_PROFILE=netb godot --headless --path . -s tests/net_smoke.gd -- join

var role := "host"
var app: Node


func _initialize() -> void:
	role = Array(OS.get_cmdline_user_args())[0]
	run()


func wait(t: float) -> void:
	await create_timer(t).timeout


func fail(msg: String) -> void:
	print("[%s] FAIL: %s" % [role, msg])
	quit(1)


func run() -> void:
	await process_frame
	var profile := root.get_node("Profile")
	profile.data = profile.fresh()
	profile.choose_starter("cinderpaw" if role == "host" else "aquafin")
	app = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(app)
	await wait(0.5)
	app.go("play")
	await wait(0.6)
	var play = app.current
	if role == "host":
		play._host()
	else:
		play._address.text = "127.0.0.1"
		play._join()
	var t0 := Time.get_ticks_msec()
	while not app.current.get_script().resource_path.ends_with("battle_screen.gd"):
		await wait(0.1)
		if Time.get_ticks_msec() - t0 > 20000:
			fail("never reached the battle screen")
			return
	Engine.time_scale = 12.0
	var scr = app.current
	var session = scr.session
	var my: int = session.my_seat
	print("[%s] battle started as seat %d, opponent hand hidden: %s" % [role, my, str(session.view()["players"][1 - my]["hand"][0]["id"] == "?")])
	t0 = Time.get_ticks_msec()
	while not session.state["over"]:
		await wait(0.1)
		if Time.get_ticks_msec() - t0 > 90000:
			fail("match did not finish (turn %d)" % int(session.state["turn"]))
			return
		if scr._busy or not scr._queue.is_empty() or scr._closed:
			continue
		if int(session.state["active"]) == my:
			var before: int = int(session.state["uid"]) + int(session.state["turn"]) * 1000 + int(session.state["players"][my]["fil"])
			session.submit(my, BattleAI.choose(session.view(), my, 1))
			# Guests wait for the host's answer before choosing again.
			var w0 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - w0 < 3000:
				await process_frame
				var now: int = int(session.state["uid"]) + int(session.state["turn"]) * 1000 + int(session.state["players"][my]["fil"])
				if now != before or session.state["over"] or scr._busy:
					break
	await wait(3.0)
	var won: bool = int(session.state["winner"]) == my
	var has_result := false
	for b in scr.find_children("*", "Button", true, false):
		if b.text == "Continue":
			has_result = true
	print("[%s] match over on turn %d, %s, result screen: %s, coins %d" % [role, int(session.state["turn"]), "WON" if won else "lost", str(has_result), profile.coins()])
	quit(0 if has_result else 1)
