extends SceneTree
## Headless rules tests.  Run:
##   godot --headless --path . -s tests/test_rules.gd
## Exits 0 when every check passes.

var _fails := 0
var _checks := 0


func _initialize() -> void:
	_catalog()
	_basics()
	_keywords()
	_effects()
	_limits()
	_printing()
	_network_view()
	_ai_games()
	print("\n%d checks, %d failed" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_fails += 1
		print("  FAIL: " + what)


## A game with fixed decks where seat 0 goes first and both sides can print 10
## Filament a turn from a huge spool, so costs never get in the way.
func game(deck0: Array, deck1: Array, printer0 := "ember_forge", printer1 := "tide_press", up0 := {}) -> Dictionary:
	var pad0: Array = deck0.duplicate()
	var pad1: Array = deck1.duplicate()
	while pad0.size() < 20:
		pad0.append("mossmunk")
	while pad1.size() < 20:
		pad1.append("mossmunk")
	var st := BattleEngine.new_game({"seed": 7, "first": 0, "players": [
		{"printer": printer0, "deck": pad0, "upgrades": up0},
		{"printer": printer1, "deck": pad1}]})
	for p in st["players"]:
		p["flow"] = 10
		p["speed"] = 10
		p["spool"] = 99
	return st


## Puts a specific card in a seat's hand and returns its hand uid.
func give(st: Dictionary, seat: int, id: String) -> int:
	var uid: int = int(st["uid"])
	st["uid"] = uid + 1
	st["players"][seat]["hand"].append({"uid": uid, "id": id})
	return uid


## Puts a print straight onto a board, ready to attack.
func put(st: Dictionary, seat: int, id: String) -> Dictionary:
	var ev: Array = []
	var u := BattleEngine._summon(st, seat, id, 99, ev, false)
	u["fresh"] = false
	return u


func act(st: Dictionary, seat: int, a: Dictionary) -> Dictionary:
	return BattleEngine.apply(st, seat, a)


func _catalog() -> void:
	print("catalog")
	var ids := {}
	for c in GameData.CARDS:
		ok(not ids.has(c["id"]), "duplicate card id " + c["id"])
		ids[c["id"]] = true
		ok(GameData.RARITIES.has(c["rarity"]), c["id"] + " rarity")
		ok(c["type"] in ["creature", "tool", "upgrade"], c["id"] + " type")
		for list in [c.get("on_print", []), c.get("shatter", []), c.get("effects", [])]:
			for e in list:
				ok(e["op"] in ["damage", "heal", "draw", "filament", "spool", "armor", "summon", "buff", "jam", "destroy", "bounce", "copy"], c["id"] + " op " + e["op"])
				if e["op"] == "summon":
					ok(GameData.has_card(e["card"]), c["id"] + " summons a real card")
		for k in c.get("kw", []):
			ok(GameData.KEYWORDS.has(k), c["id"] + " keyword " + k)
		if c["type"] == "creature":
			ok(GameData.ELEMENTS.has(c["element"]), c["id"] + " element")
	ok(GameData.collectible().size() == 47, "47 collectible cards (got %d)" % GameData.collectible().size())
	ok(GameData.deck_error(GameData.expand(GameData.STARTER_DECK)) == "", "starter deck is legal")
	for r in GameData.RIVALS:
		var err := GameData.deck_error(GameData.expand(r["deck"]))
		ok(err == "", "rival %s deck legal: %s" % [r["id"], err])
		ok(GameData.printer(r["printer"])["id"] == r["printer"], "rival %s printer" % r["id"])
		ok(GameData.PACKS.has(r["pack"]), "rival %s pack" % r["id"])
	for s in GameData.STARTER_PRINTER:
		ok(GameData.has_card(s), "starter " + s)


func _basics() -> void:
	print("basics")
	var st := BattleEngine.new_game({"seed": 3, "first": 0, "players": [
		{"printer": "ember_forge", "deck": GameData.expand(GameData.STARTER_DECK)},
		{"printer": "tide_press", "deck": GameData.expand(GameData.STARTER_DECK)}]})
	var p0: Dictionary = st["players"][0]
	var p1: Dictionary = st["players"][1]
	ok(p0["hand"].size() == 4 and p0["deck"].size() == 16, "first player: 3 cards + turn draw")
	ok(p1["hand"].size() == 5, "second player: 4 cards + Filament Scrap")
	ok(p1["hand"][4]["id"] == "filament_scrap", "second player holds a scrap")
	ok(int(p0["flow"]) == GameData.PRINT_SPEED and int(p0["spool"]) == GameData.SPOOL_SIZE, "turn 1: full print speed and a full spool")
	ok(not act(st, 1, {"t": "end"})["ok"], "cannot act out of turn")
	ok(act(st, 0, {"t": "end"})["ok"], "end turn")
	ok(int(st["active"]) == 1 and int(p1["flow"]) == GameData.PRINT_SPEED, "turn passes")

	st = game(["voltwig"], [])
	var h := give(st, 0, "stoneback")
	var before: Dictionary = st.duplicate(true)
	st["players"][0]["spool"] = 2
	ok(not act(st, 0, {"t": "play", "hand": h})["ok"], "more Filament than the spool holds is rejected")
	st["players"][0]["spool"] = 99
	ok(before["players"][0]["hand"].size() == st["players"][0]["hand"].size(), "rejected play changes nothing")
	var res := act(st, 0, {"t": "play", "hand": h})
	ok(res["ok"] and st["players"][0]["board"].size() == 1, "print lands on the bench")
	ok(int(st["players"][0]["flow"]) == 7 and int(st["players"][0]["spool"]) == 96, "cost comes off this turn's speed and off the spool")
	var u: Dictionary = st["players"][0]["board"][0]
	ok(BattleEngine.attack_targets(st, int(u["uid"])).is_empty(), "fresh print cannot attack")
	act(st, 0, {"t": "end"})
	act(st, 1, {"t": "end"})
	ok(BattleEngine.attack_targets(st, int(u["uid"])) == ["p1"], "next turn it can hit the Printer")
	var hp_before: int = int(st["players"][1]["hp"])
	ok(act(st, 0, {"t": "attack", "unit": int(u["uid"]), "target": "p1"})["ok"], "attack Printer")
	ok(int(st["players"][1]["hp"]) == hp_before - 2, "Printer takes the print's Attack")
	ok(not act(st, 0, {"t": "attack", "unit": int(u["uid"]), "target": "p1"})["ok"], "one attack per turn")

	st = game([], [])
	var a := put(st, 0, "voltwig")
	var b := put(st, 1, "stoneback")
	act(st, 0, {"t": "attack", "unit": int(a["uid"]), "target": "u%d" % int(b["uid"])})
	ok(st["players"][0]["board"].is_empty(), "attacker takes counter damage and shatters (1 hp vs 2 atk)")
	ok(int(b["hp"]) == 4, "defender took 2")

	st = game([], [])
	st["players"][1]["hp"] = 2
	a = put(st, 0, "cinderpaw")
	res = act(st, 0, {"t": "attack", "unit": int(a["uid"]), "target": "p1"})
	ok(st["over"] and int(st["winner"]) == 0, "destroying the Printer wins")
	ok(res["events"].back()["e"] == "over", "over event is last")
	ok(not act(st, 0, {"t": "end"})["ok"], "nothing after the battle ends")
	st = game([], [])
	act(st, 1, {"t": "concede"})
	ok(st["over"] and int(st["winner"]) == 0, "concede works out of turn")


func _keywords() -> void:
	print("keywords")
	var st := game([], [])
	var a := put(st, 0, "galehopper")
	var g := put(st, 1, "mossmunk")
	var o := put(st, 1, "cinderpaw")
	ok(BattleEngine.attack_targets(st, int(a["uid"])) == ["u%d" % int(g["uid"])], "Guard must be attacked first")
	ok(not act(st, 0, {"t": "attack", "unit": int(a["uid"]), "target": "p1"})["ok"], "cannot go around Guard")
	ok(not act(st, 0, {"t": "attack", "unit": int(a["uid"]), "target": "u%d" % int(o["uid"])})["ok"], "cannot hit another print behind Guard")

	st = game([], [])
	var e := put(st, 1, "cinderpaw")
	var h := give(st, 0, "galehopper")
	act(st, 0, {"t": "play", "hand": h})
	var r: Dictionary = st["players"][0]["board"][0]
	ok(BattleEngine.attack_targets(st, int(r["uid"])) == ["u%d" % int(e["uid"])], "Rush: prints only on the first turn")

	st = game([], [])
	a = put(st, 0, "cinderpaw")
	var br := put(st, 1, "brambleowl")
	act(st, 0, {"t": "attack", "unit": int(a["uid"]), "target": "u%d" % int(br["uid"])})
	ok(int(br["hp"]) == 3 and not br["kw"].has("brim"), "Brim soaks the first hit and pops")

	st = game([], [])
	st["players"][0]["hp"] = 10
	var c := put(st, 0, "coralisk")
	act(st, 0, {"t": "attack", "unit": int(c["uid"]), "target": "p1"})
	ok(int(st["players"][0]["hp"]) == 13, "Siphon repairs by damage dealt")

	st = game([], [])
	var t := put(st, 0, "thunderelk")
	ok(act(st, 0, {"t": "attack", "unit": int(t["uid"]), "target": "p1"})["ok"], "Twin Nozzle first attack")
	ok(act(st, 0, {"t": "attack", "unit": int(t["uid"]), "target": "p1"})["ok"], "Twin Nozzle second attack")
	ok(not act(st, 0, {"t": "attack", "unit": int(t["uid"]), "target": "p1"})["ok"], "no third attack")

	st = game([], [])
	var mine := put(st, 0, "cinderpaw")
	var foe := put(st, 1, "stoneback")
	h = give(st, 0, "frostling")
	act(st, 0, {"t": "play", "hand": h, "target": "u%d" % int(foe["uid"])})
	ok(int(foe["jam"]) == 1, "Jam applied")
	act(st, 0, {"t": "end"})
	ok(BattleEngine.attack_targets(st, int(foe["uid"])).is_empty(), "jammed print cannot attack")
	act(st, 1, {"t": "end"})
	ok(int(foe["jam"]) == 0, "Jam clears after the owner's turn")
	ok(int(mine["jam"]) == 0, "own prints unaffected")


func _effects() -> void:
	print("effects")
	var st := game([], [])
	var foe := put(st, 1, "mossmunk")
	var h := give(st, 0, "cinderpaw")
	ok(not act(st, 0, {"t": "play", "hand": h})["ok"], "targeted On Print needs a target when one exists")
	ok(act(st, 0, {"t": "play", "hand": h, "target": "u%d" % int(foe["uid"])})["ok"], "On Print with target")
	ok(int(foe["hp"]) == 2, "On Print damage")
	ok(int(st["players"][0]["board"][0]["max_hp"]) == 3, "Fire print is attuned to the Ember Forge (+1 Health)")

	st = game([], [])
	h = give(st, 0, "frostling")
	ok(act(st, 0, {"t": "play", "hand": h})["ok"], "On Print with nothing to target still prints")
	h = give(st, 0, "printed_wrench")
	ok(BattleEngine.play_error(st, 0, h) != "", "tool with no target cannot be played")

	st = game([], [])
	var g := put(st, 0, "glassdrake")
	var e1 := put(st, 1, "cinderpaw")
	var e2 := put(st, 1, "stoneback")
	h = give(st, 1, "printed_wrench")
	act(st, 0, {"t": "end"})
	act(st, 1, {"t": "play", "hand": h, "target": "u%d" % int(g["uid"])})
	ok(st["players"][0]["board"].is_empty(), "wrench destroys Glassdrake")
	ok(st["players"][1]["board"].size() == 1 and int(e2["hp"]) == 4, "Shatter hits all enemy prints (and can chain kills)")
	ok(int(e1["hp"]) <= 0, "cinderpaw died to Shatter")

	st = game([], [])
	var big := put(st, 1, "ironmaw")
	var small := put(st, 1, "mossmunk")
	h = give(st, 0, "bed_scraper")
	ok(BattleEngine.play_targets(st, 0, "bed_scraper") == ["u%d" % int(small["uid"])], "scraper only targets 3 or less Attack")
	h = give(st, 0, "voidmanta")
	act(st, 0, {"t": "play", "hand": h, "target": "u%d" % int(big["uid"])})
	ok(st["players"][1]["board"].size() == 1, "Voidmanta destroys a print")

	st = game([], [])
	foe = put(st, 1, "ironmaw")
	foe["hp"] = 2
	h = give(st, 0, "skyforge")
	var hand_before: int = st["players"][1]["hand"].size()
	act(st, 0, {"t": "play", "hand": h, "target": "u%d" % int(foe["uid"])})
	ok(st["players"][1]["board"].is_empty() and st["players"][1]["hand"].size() == hand_before + 1, "Skyforge bounces a print to hand")
	ok(st["players"][1]["hand"].back()["id"] == "ironmaw", "bounced card is the same print")

	st = game([], [])
	var m := put(st, 0, "mossmunk")
	h = give(st, 0, "titan_plate")
	act(st, 0, {"t": "play", "hand": h, "target": "u%d" % int(m["uid"])})
	ok(int(m["atk"]) == 5 and int(m["hp"]) == 9 and m["gear"] == ["titan_plate"], "upgrade attaches and buffs")
	h = give(st, 0, "rainbow_spool")
	act(st, 0, {"t": "play", "hand": h, "target": "u%d" % int(m["uid"])})
	ok(st["players"][0]["board"].size() == 2 and int(st["players"][0]["board"][1]["atk"]) == 5, "Rainbow Spool copies with buffs")
	h = give(st, 0, "emergency_stop")
	st["players"][0]["flow"] = 10
	put(st, 1, "worldcoil")
	act(st, 0, {"t": "play", "hand": h})
	ok(st["players"][0]["board"].is_empty() and st["players"][1]["board"].is_empty(), "Emergency Stop clears both beds, through Brim")

	st = game([], [])
	h = give(st, 0, "test_print")
	act(st, 0, {"t": "play", "hand": h})
	ok(st["players"][0]["board"].size() == 2, "Test Print makes two cubes")
	h = give(st, 0, "hex_keys")
	act(st, 0, {"t": "play", "hand": h})
	ok(int(st["players"][0]["board"][0]["atk"]) == 2 and int(st["players"][0]["board"][1]["hp"]) == 2, "Hex Keys buffs all")
	st["players"][0]["flow"] = 0
	var spool_before: int = int(st["players"][0]["spool"])
	h = give(st, 0, "spare_spool")
	act(st, 0, {"t": "play", "hand": h})
	ok(int(st["players"][0]["flow"]) == 1 and int(st["players"][0]["spool"]) == spool_before + 3, "Spare Spool tops up the spool and gives a burst of speed")

	# printer powers
	st = game([], [])
	foe = put(st, 1, "mossmunk")
	ok(not act(st, 0, {"t": "power"})["ok"], "Hot Nozzle needs a target")
	ok(act(st, 0, {"t": "power", "target": "p1"})["ok"], "Hot Nozzle")
	ok(int(st["players"][1]["hp"]) == GameData.PRINTER_HP - 1 and int(st["players"][0]["flow"]) == 10 - GameData.POWER_COST, "power costs Filament and deals 1")
	ok(not act(st, 0, {"t": "power", "target": "p1"})["ok"], "power once per turn")
	st = game([], [], "stone_kiln")
	act(st, 0, {"t": "power"})
	ok(int(st["players"][0]["armor"]) == 2, "Reinforce gives Armor")
	BattleEngine._damage(st, "p0", 3, [])
	ok(int(st["players"][0]["armor"]) == 0 and int(st["players"][0]["hp"]) == GameData.PRINTER_HP - 1, "Armor soaks damage first")
	st = game([], [], "arcane_engine")
	var hs: int = st["players"][0]["hand"].size()
	act(st, 0, {"t": "power"})
	ok(st["players"][0]["hand"].size() == hs + 1 and int(st["players"][0]["hp"]) == GameData.PRINTER_HP - 2, "Blueprint Scan draws and costs 2 Health")
	st = game([], [], "volt_rig")
	act(st, 0, {"t": "power"})
	ok(st["players"][0]["board"].size() == 1, "Test Cube prints a cube")

	# workshop upgrades
	st = game([], [], "ember_forge", "tide_press", {"frame": 3, "bed": 2, "spool": 2})
	ok(int(st["players"][0]["hp"]) == GameData.PRINTER_HP + 6, "Reinforced Frame adds Health")
	ok(int(st["players"][0]["spool_max"]) == GameData.SPOOL_SIZE + 2 * GameData.SPOOL_PER_UPGRADE, "Bigger Spool holds more Filament")
	h = give(st, 0, "mossmunk")
	act(st, 0, {"t": "play", "hand": h})
	ok(int(st["players"][0]["board"][0]["atk"]) == 3 and int(st["players"][0]["board"][0]["hp"]) == 5, "Heated Bed buffs the first print")
	h = give(st, 0, "mossmunk")
	act(st, 0, {"t": "play", "hand": h})
	ok(int(st["players"][0]["board"][1]["atk"]) == 1, "...and only the first")


func _limits() -> void:
	print("limits")
	var st := game([], [])
	for i in GameData.MAX_BOARD:
		put(st, 0, "mossmunk")
	var h := give(st, 0, "mossmunk")
	ok(BattleEngine.play_error(st, 0, h) == "Your bench is full.", "bench limit")
	h = give(st, 0, "test_print")
	ok(act(st, 0, {"t": "play", "hand": h})["ok"] and st["players"][0]["board"].size() == GameData.MAX_BOARD, "summons stop at a full bed")

	st = game([], [])
	while st["players"][0]["hand"].size() < GameData.MAX_HAND:
		give(st, 0, "mossmunk")
	var deck_before: int = st["players"][0]["deck"].size()
	var ev: Array = []
	BattleEngine._draw(st, 0, ev)
	ok(st["players"][0]["hand"].size() == GameData.MAX_HAND and st["players"][0]["deck"].size() == deck_before - 1 and ev[0]["e"] == "burn", "overdraw burns the card")

	st = game([], [])
	st["players"][0]["deck"].clear()
	BattleEngine._draw(st, 0, [])
	BattleEngine._draw(st, 0, [])
	ok(int(st["players"][0]["hp"]) == GameData.PRINTER_HP - 3, "drawing from an empty deck hurts more each time: 1 then 2")


## A game at the real print speed, with seat 0 to act and a known spool.
func slow_game() -> Dictionary:
	var st := game([], [])
	for p in st["players"]:
		p["speed"] = 3
		p["flow"] = 3
		p["spool"] = 40
		p["spool_max"] = 40
	return st


func _printing() -> void:
	print("spool, print speed and long prints")
	var st := slow_game()
	var p0: Dictionary = st["players"][0]
	var h := give(st, 0, "ironmaw")
	ok(BattleEngine.is_long(st, 0, h) and BattleEngine.play_error(st, 0, h) == "", "a 5-cost card at speed 3 is a long print")
	var res := act(st, 0, {"t": "play", "hand": h})
	ok(res["ok"] and p0["board"].is_empty() and BattleEngine.hand_card(st, 0, h).is_empty(), "it leaves the hand but does not land yet")
	ok(p0["job"]["id"] == "ironmaw" and int(p0["job"]["paid"]) == 3 and int(p0["job"]["cost"]) == 5, "it takes the rest of this turn's speed")
	ok(int(p0["flow"]) == 0 and int(p0["spool"]) == 35, "the whole cost comes off the spool at once")
	ok(res["events"][0]["e"] == "job" and bool(res["events"][0]["start"]), "a job event announces it")
	ok(BattleEngine.deploy_error(st, 0) == "That print is not finished yet.", "an unfinished print cannot be deployed")
	var h2 := give(st, 0, "mossmunk")
	ok(BattleEngine.play_error(st, 0, h2) == "Your Printer is done printing for this turn.", "nothing more can be printed with no speed left")
	act(st, 0, {"t": "end"})
	act(st, 1, {"t": "end"})
	ok(int(p0["job"]["paid"]) == 5 and int(p0["flow"]) == 1, "next turn the Printer finishes it first and keeps the change")
	ok(BattleEngine.job_ready(p0["job"]) and BattleEngine.legal_actions(st, 0).has({"t": "deploy"}), "a finished print can be deployed")
	var h3 := give(st, 0, "coalgriffin")
	ok(BattleEngine.play_error(st, 0, h3) == "Your Printer is busy with another print.", "only one long print at a time")
	ok(BattleEngine.play_error(st, 0, h2) == "", "small cards still print around a finished one")
	res = act(st, 0, {"t": "deploy"})
	ok(res["ok"] and p0["board"].size() == 1 and p0["board"][0]["id"] == "ironmaw" and p0["job"].is_empty(), "deploying puts it on the bench")
	ok(int(p0["flow"]) == 1 and int(p0["spool"]) == 35, "deploying is free")
	var summon: Dictionary = {}
	for e in res["events"]:
		if e["e"] == "summon":
			summon = e
	ok(bool(summon.get("built", false)), "the summon is marked as already built")

	# A long print that needs a target picks it when it is deployed.
	st = slow_game()
	p0 = st["players"][0]
	var foe := put(st, 1, "stoneback")
	h = give(st, 0, "coalgriffin")
	ok(act(st, 0, {"t": "play", "hand": h})["ok"] and int(foe["hp"]) == 6, "starting a long print needs no target and does nothing yet")
	act(st, 0, {"t": "end"})
	act(st, 1, {"t": "end"})
	ok(int(p0["job"]["paid"]) == 6 and int(p0["flow"]) == 0, "6 Filament takes two full turns")
	ok(not act(st, 0, {"t": "deploy"})["ok"], "its On Print still needs a target")
	ok(act(st, 0, {"t": "deploy", "target": "u%d" % int(foe["uid"])})["ok"] and int(foe["hp"]) == 3, "the target is chosen at deploy time")

	# Tools and upgrades can be long prints too.
	st = slow_game()
	p0 = st["players"][0]
	put(st, 1, "voltwig")
	put(st, 1, "cinderpaw")
	h = give(st, 0, "bed_leveling")
	act(st, 0, {"t": "play", "hand": h})
	ok(st["players"][1]["board"].size() == 2, "a long tool has no effect while it prints")
	act(st, 0, {"t": "end"})
	act(st, 1, {"t": "end"})
	ok(act(st, 0, {"t": "deploy"})["ok"] and st["players"][1]["board"].is_empty(), "the tool goes off when deployed")

	# The spool is all there is.
	st = slow_game()
	p0 = st["players"][0]
	p0["spool"] = 2
	h = give(st, 0, "stoneback")
	ok(BattleEngine.play_error(st, 0, h) == "Not enough Filament left on your Spool.", "an empty spool stops printing")
	ok(BattleEngine.power_error(st, 0) == "", "but what is left can still be used")
	p0["spool"] = 1
	ok(BattleEngine.power_error(st, 0) != "", "the Printer Power needs Filament on the spool too")

	# Shattered prints go back on the spool as scrap; tokens do not.
	st = slow_game()
	var mine := put(st, 0, "voltwig")
	var wall := put(st, 1, "stoneback")
	act(st, 0, {"t": "attack", "unit": int(mine["uid"]), "target": "u%d" % int(wall["uid"])})
	ok(int(st["players"][0]["spool"]) == 40 + GameData.SCRAP_REFUND, "a shattered print returns scrap to its owner's spool")
	var bot := put(st, 0, "test_bot")
	act(st, 0, {"t": "end"})
	act(st, 1, {"t": "attack", "unit": int(wall["uid"]), "target": "u%d" % int(bot["uid"])})
	ok(int(st["players"][0]["spool"]) == 40 + GameData.SCRAP_REFUND, "a token returns nothing")

	# A thin hand is topped up at the start of the turn.
	st = slow_game()
	st["players"][1]["hand"].clear()
	act(st, 0, {"t": "end"})
	ok(st["players"][1]["hand"].size() == GameData.HAND_TOP_UP, "an empty hand is drawn back up to %d" % GameData.HAND_TOP_UP)
	st["players"][0]["hand"].clear()
	st["players"][0]["deck"].clear()
	var hp: int = int(st["players"][0]["hp"])
	act(st, 1, {"t": "end"})
	ok(int(st["players"][0]["hp"]) == hp - 1 and int(st["players"][0]["fatigue"]) == 1, "topping up never draws twice from an empty deck")

	# The other player can see what is on the Printer.
	st = slow_game()
	h = give(st, 0, "worldcoil")
	act(st, 0, {"t": "play", "hand": h})
	ok(BattleEngine.view_for(st, 1)["players"][0]["job"]["id"] == "worldcoil", "a long print is visible to the opponent")
	var turns := 0
	while not BattleEngine.job_ready(st["players"][0]["job"]) and turns < 10:
		act(st, 0, {"t": "end"})
		act(st, 1, {"t": "end"})
		turns += 1
	ok(turns == 2, "a 9-cost print is ready on the third turn (%d turns later)" % turns)


func _network_view() -> void:
	print("network view")
	var st := game([], [])
	var v := BattleEngine.view_for(st, 0)
	var leaked := false
	for c in v["players"][1]["hand"]:
		if c["id"] != "?":
			leaked = true
	for id in v["players"][0]["deck"] + v["players"][1]["deck"]:
		if id != "?":
			leaked = true
	ok(not leaked and int(v["rng"]) == 0, "opponent hand, decks and dice are hidden")
	ok(v["players"][0]["hand"][0]["id"] != "?", "own hand is visible")
	ok(v["players"][1]["hand"].size() == st["players"][1]["hand"].size(), "hand sizes are kept")
	var res := act(st, 0, {"t": "end"})
	var red := BattleEngine.redact_events(res["events"], 0)
	for e in red:
		if e["e"] == "draw" and int(e["seat"]) == 1:
			ok(e["card"]["id"] == "?", "opponent's draw is hidden")
	ok(st["players"][1]["hand"].back()["id"] != "?", "redaction does not touch the real state")


## Plays AI against AI. Returns the winner (-2 draw, -3 stalled).
func play_out(seed_: int, cfg0: Dictionary, cfg1: Dictionary, lvl0: int, lvl1: int) -> Dictionary:
	var st := BattleEngine.new_game({"seed": seed_, "players": [cfg0, cfg1]})
	var first: int = int(st["active"])
	var steps := 0
	while not st["over"] and steps < 4000:
		steps += 1
		var seat: int = int(st["active"])
		var a := BattleAI.choose(st, seat, lvl0 if seat == 0 else lvl1)
		var res := BattleEngine.apply(st, seat, a)
		if not res["ok"]:
			ok(false, "AI chose an illegal action %s: %s" % [a, res["error"]])
			BattleEngine.apply(st, seat, {"t": "end"})
	return {"winner": int(st["winner"]) if st["over"] else -3, "turns": int(st["turn"]), "first": first}


func _ai_games() -> void:
	print("ai games")
	var t0 := Time.get_ticks_msec()
	var games := 0
	var stalls := 0
	var first_wins := 0
	var total_turns := 0
	var rivals: Array = GameData.RIVALS
	# Every rival deck against the starter deck, both at Craftsman level.
	var starter := {"printer": "ember_forge", "deck": GameData.expand(GameData.STARTER_DECK)}
	print("  starter deck (Craftsman) vs each rival at its own level, 20 games each:")
	for r in rivals:
		var wins := 0
		for i in 20:
			var res := play_out(1000 + i * 37, starter, {"printer": r["printer"], "deck": GameData.expand(r["deck"]), "hp_bonus": r["hp_bonus"]}, 1, int(r["level"]))
			games += 1
			total_turns += int(res["turns"])
			if int(res["winner"]) == -3:
				stalls += 1
			if int(res["winner"]) == 0:
				wins += 1
			if int(res["winner"]) == int(res["first"]):
				first_wins += 1
		print("    vs %-18s player wins %2d/20" % [r["name"], wins])
	# Skill ordering: same deck, Master vs Apprentice.
	var master_wins := 0
	for i in 40:
		var hi_seat := i % 2
		var res := play_out(5000 + i * 91, starter, starter, 2 if hi_seat == 0 else 0, 2 if hi_seat == 1 else 0)
		games += 1
		total_turns += int(res["turns"])
		if int(res["winner"]) == -3:
			stalls += 1
		if int(res["winner"]) == hi_seat:
			master_wins += 1
		if int(res["winner"]) == int(res["first"]):
			first_wins += 1
	print("  Master beats Apprentice (mirror deck): %d/40" % master_wins)
	print("  first player won %d/%d, average %.1f turns, %d ms" % [first_wins, games, float(total_turns) / games, Time.get_ticks_msec() - t0])
	ok(stalls == 0, "no AI game stalls (%d did)" % stalls)
	ok(master_wins >= 26, "Master clearly beats Apprentice (%d/40)" % master_wins)
	ok(first_wins > games * 35 / 100 and first_wins < games * 65 / 100, "going first is not decisive (%d/%d)" % [first_wins, games])
