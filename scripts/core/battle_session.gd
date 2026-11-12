class_name BattleSession
extends RefCounted
## One battle from this device's point of view. The battle screen only talks
## to a session, so it does not care whether the other side is the computer,
## a second player on the same screen, or someone across the network.

signal updated(events: Array, view: Dictionary)
signal closed(reason: String)

var mode := "quick"          # "rival" | "quick" | "hotseat" | "lan"
var state: Dictionary = {}   # the real state (local, host) or the latest view (guest)
var humans: Array = [0]      # seats played on this device
var my_seat := 0
var ai_level := 1
var rival_id := ""
var arena := "daily_arena"
var names: Array = ["You", "Rival"]
var net: NetLink
var is_guest := false


static func player_config(deck: Dictionary) -> Dictionary:
	return {"printer": deck["printer"], "deck": (deck["cards"] as Array).duplicate(), "upgrades": Profile.battle_upgrades()}


static func vs_rival(deck: Dictionary, rival: Dictionary) -> BattleSession:
	var s := BattleSession.new()
	s.mode = "rival"
	s.rival_id = rival["id"]
	s.ai_level = int(rival["level"])
	s.arena = rival["arena"]
	s.names = ["You", rival["name"]]
	s._start(player_config(deck), {"printer": rival["printer"], "deck": GameData.expand(rival["deck"]), "hp_bonus": int(rival["hp_bonus"])})
	return s


static func quick(deck: Dictionary, level: int) -> BattleSession:
	var s := BattleSession.new()
	s.mode = "quick"
	s.ai_level = level
	# Sparring partners borrow a campaign deck that suits the difficulty.
	var pool: Array = []
	for r in GameData.RIVALS:
		if int(r["level"]) <= level and int(r["level"]) >= level - 1:
			pool.append(r)
	var r: Dictionary = pool[randi() % pool.size()]
	s.arena = "daily_arena"
	s.names = ["You", "%s Sparring Rig" % GameData.AI_LEVELS[level]]
	s._start(player_config(deck), {"printer": r["printer"], "deck": GameData.expand(r["deck"])})
	return s


static func hotseat(deck0: Dictionary, deck1: Dictionary) -> BattleSession:
	var s := BattleSession.new()
	s.mode = "hotseat"
	s.humans = [0, 1]
	s.names = ["Player 1", "Player 2"]
	s._start(player_config(deck0), player_config(deck1))
	return s


static func lan_host(link: NetLink, deck: Dictionary, guest: Dictionary) -> BattleSession:
	var s := BattleSession.new()
	s.mode = "lan"
	s.net = link
	s.names = ["You", "Opponent"]
	s._start(player_config(deck), guest)
	link.action_received.connect(s._on_guest_action)
	link.dropped.connect(s._on_dropped)
	link.send_start(BattleEngine.view_for(s.state, 1), {"arena": s.arena})
	return s


static func lan_guest(link: NetLink, view: Dictionary, info: Dictionary) -> BattleSession:
	var s := BattleSession.new()
	s.mode = "lan"
	s.net = link
	s.is_guest = true
	s.my_seat = 1
	s.humans = [1]
	s.names = ["Opponent", "You"]
	s.arena = str(info.get("arena", "daily_arena"))
	s.state = view
	link.update_received.connect(s._on_update)
	link.dropped.connect(s._on_dropped)
	return s


## Checks what a guest sent before it is used to build a battle.
static func guest_config(info: Dictionary) -> Dictionary:
	var deck: Array = []
	for id in info.get("deck", []):
		deck.append(str(id))
	if GameData.deck_error(deck) != "":
		return {}
	var printer := str(info.get("printer", ""))
	if GameData.printer(printer)["id"] != printer:
		return {}
	var up: Dictionary = {}
	for k in ["frame", "bed", "spool"]:
		up[k] = int((info.get("upgrades", {}) as Dictionary).get(k, 0))
	return {"printer": printer, "deck": deck, "upgrades": up}


func _start(cfg0: Dictionary, cfg1: Dictionary) -> void:
	state = BattleEngine.new_game({"seed": randi() & 0x7fffffff, "players": [cfg0, cfg1]})


## What this device is allowed to see right now.
func view() -> Dictionary:
	if is_guest:
		return state
	if mode == "lan":
		return BattleEngine.view_for(state, 0)
	return state.duplicate(true)


func is_human(seat: int) -> bool:
	return humans.has(seat)


func is_ai_turn() -> bool:
	return mode in ["rival", "quick"] and not state["over"] and not is_human(int(state["active"]))


## Sends a player's action. Returns "" or the reason it was refused.
func submit(seat: int, action: Dictionary) -> String:
	if is_guest:
		net.send_action(action)
		return ""
	var res := BattleEngine.apply(state, seat, action)
	if not res["ok"]:
		return res["error"]
	_publish(res["events"])
	return ""


## Lets the computer take one action. The screen calls this between animations.
func ai_step() -> void:
	if not is_ai_turn():
		return
	var seat: int = int(state["active"])
	var res := BattleEngine.apply(state, seat, BattleAI.choose(state, seat, ai_level))
	if not res["ok"]:
		res = BattleEngine.apply(state, seat, {"t": "end"})
	_publish(res["events"])


func leave() -> void:
	if net != null:
		if net.action_received.is_connected(_on_guest_action):
			net.action_received.disconnect(_on_guest_action)
		if net.update_received.is_connected(_on_update):
			net.update_received.disconnect(_on_update)
		if net.dropped.is_connected(_on_dropped):
			net.dropped.disconnect(_on_dropped)
		net.close()


func _publish(events: Array) -> void:
	if mode == "lan":
		net.send_update(BattleEngine.redact_events(events, 1), BattleEngine.view_for(state, 1))
		updated.emit(BattleEngine.redact_events(events, 0), view())
	else:
		updated.emit(events, view())


func _on_guest_action(action: Dictionary) -> void:
	# The guest always sits in seat 1; anything illegal is simply ignored.
	var res := BattleEngine.apply(state, 1, action)
	if res["ok"]:
		_publish(res["events"])


func _on_update(events: Array, new_view: Dictionary) -> void:
	state = new_view
	updated.emit(events, new_view)


func _on_dropped(reason: String) -> void:
	closed.emit(reason)
