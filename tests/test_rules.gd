extends SceneTree
## Headless rules tests.  Run:
##   godot --headless --path . -s tests/test_rules.gd
## Exits 0 when every check passes.

var _fails := 0
var _checks := 0


func _initialize() -> void:
	_catalog()
	_audio()
	_basics()
	_keywords()
	_heat_and_theft()
	_effects()
	_limits()
	_printing()
	_mods()
	_blueprints()
	_progression()
	_random_mods()
	_ranked()
	_network_view()
	_ai_games()
	_fuzz_games()
	print("\n%d checks, %d failed" % [_checks, _fails])
	quit(1 if _fails > 0 else 0)


func ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_fails += 1
		print("  FAIL: " + what)


## A game with fixed decks where seat 0 goes first and both sides can print 10
## Filament a turn from a huge spool, so costs never get in the way.
func game(deck0: Array, deck1: Array, printer0 := "ember_forge", printer1 := "tide_press", mods0 := {}) -> Dictionary:
	var pad0: Array = deck0.duplicate()
	var pad1: Array = deck1.duplicate()
	while pad0.size() < 20:
		pad0.append("mossmunk")
	while pad1.size() < 20:
		pad1.append("mossmunk")
	var st := BattleEngine.new_game({"seed": 7, "first": 0, "players": [
		{"printer": printer0, "deck": pad0, "mods": mods0},
		{"printer": printer1, "deck": pad1}]})
	for p in st["players"]:
		p["flow"] = 10
		p["speed"] = 10
		p["spool"] = 99
	return st


## A new game with the real print speed, for checking what mods add to it.
func raw_game(mods0: Dictionary) -> Dictionary:
	return BattleEngine.new_game({"seed": 7, "first": 0, "players": [
		{"printer": "ember_forge", "deck": GameData.expand(GameData.STARTER_DECK), "mods": mods0},
		{"printer": "tide_press", "deck": GameData.expand(GameData.STARTER_DECK)}]})


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
				ok(e["op"] in ["damage", "heal", "draw", "filament", "spool", "armor", "summon", "buff", "jam", "destroy", "bounce", "copy", "heat", "steal"], c["id"] + " op " + e["op"])
				if e["op"] == "summon":
					ok(GameData.has_card(e["card"]), c["id"] + " summons a real card")
		for k in c.get("kw", []):
			ok(GameData.KEYWORDS.has(k), c["id"] + " keyword " + k)
		if c["type"] == "creature":
			ok(GameData.ELEMENTS.has(c["element"]), c["id"] + " element")
	ok(GameData.collectible().size() == 282, "282 collectible cards (got %d)" % GameData.collectible().size())
	for c in GameData.collectible():
		ok(FileAccess.file_exists(GameData.art_path(c)) or ResourceLoader.exists(GameData.art_path(c)), "%s has art" % c["id"])
		if c["type"] == "creature":
			ok(ResourceLoader.exists(GameData.RAW % c["id"]) or FileAccess.file_exists(GameData.RAW % c["id"]), "%s has a raw print" % c["id"])
	var by_rarity: Dictionary = {}
	var by_type: Dictionary = {}
	for c in GameData.collectible():
		by_rarity[c["rarity"]] = int(by_rarity.get(c["rarity"], 0)) + 1
		by_type[c["type"]] = int(by_type.get(c["type"], 0)) + 1
	ok(by_type == {"creature": 172, "tool": 67, "upgrade": 43}, "172 prints, 67 tools, 43 pieces of equipment (%s)" % str(by_type))
	# Every kind of card, and every element of print, comes in every rarity.
	for kind in ["creature", "tool", "upgrade"]:
		for r in GameData.RARITY_ORDER:
			var n := 0
			for c in GameData.collectible():
				if c["type"] == kind and c["rarity"] == r:
					n += 1
			ok(n >= 2, "%s cards come in %s (%d)" % [kind, r, n])
	for el in ["Fire", "Water", "Lightning", "Nature", "Ice", "Stone", "Wind", "Arcane"]:
		for r in GameData.RARITY_ORDER:
			var n := 0
			for c in GameData.collectible():
				if c["type"] == "creature" and c["element"] == el and c["rarity"] == r:
					n += 1
			ok(n >= 1, "%s prints come in %s" % [el, r])
	for c in GameData.collectible():
		ok(str(c["name"]) != "" and (c["type"] == "creature" or str(c.get("text", "")) != ""), "%s has a name and rules text" % c["id"])
		ok(int(c["cost"]) >= 0 and int(c["cost"]) <= 9, "%s cost in range" % c["id"])
	# Mods come in every rarity too, with a price and a rank.
	var mod_rarities := {}
	for m in GameData.CARD_MODS + GameData.PRINTER_MODS:
		ok(GameData.RARITIES.has(m.get("rarity", "")), "mod %s has a rarity" % m["id"])
		mod_rarities[m["rarity"]] = true
	for r in GameData.RARITY_ORDER:
		ok(mod_rarities.has(r), "there are %s mods" % r)
	ok(GameData.CARD_MODS.size() >= 45 and GameData.PRINTER_MODS.size() >= 23, "plenty of mods (%d card, %d Printer)" % [GameData.CARD_MODS.size(), GameData.PRINTER_MODS.size()])
	for r in GameData.RARITY_ORDER:
		ok(int(by_rarity.get(r, 0)) >= 6, "at least 6 %s cards (%d)" % [r, int(by_rarity.get(r, 0))])
	ok(GameData.deck_error(GameData.expand(GameData.STARTER_DECK)) == "", "starter deck is legal")
	for r in GameData.RIVALS:
		var err := GameData.deck_error(GameData.expand(r["deck"]))
		ok(err == "", "rival %s deck legal: %s" % [r["id"], err])
		ok(GameData.printer(r["printer"])["id"] == r["printer"], "rival %s printer" % r["id"])
		ok(GameData.PACKS.has(r["pack"]), "rival %s pack" % r["id"])
	for s in GameData.STARTER_PRINTER:
		ok(GameData.has_card(s), "starter " + s)


## Every sound and track the game asks for must exist as a file.
func _audio() -> void:
	print("audio")
	var audio: GDScript = load("res://scripts/core/audio.gd")
	var names: Dictionary = {}
	for n in audio.TUNE:
		names[n] = "tuned"
	for n in audio.ALIAS.values():
		names[n] = "alias"
	var rx := RegEx.new()
	rx.compile("(?:sfx|stinger)\\(\"([a-z_]+)\"")
	var dirs: Array = ["res://scripts/ui", "res://scripts/ui/screens", "res://scripts/core"]
	for d in dirs:
		for f in DirAccess.get_files_at(d):
			if f.ends_with(".gd"):
				var text := FileAccess.get_file_as_string("%s/%s" % [d, f])
				for m in rx.search_all(text):
					names[m.get_string(1)] = "%s/%s" % [d, f]
	for el in GameData.ELEMENTS:
		if el != "Neutral":
			names["atk_" + el.to_lower()] = "element " + el
	for n in names:
		if n.ends_with("_"):
			continue          # a prefix built at run time (atk_ + element), checked above
		ok(FileAccess.file_exists("res://assets/audio/sfx_%s.wav" % n) or audio.ALIAS.has(n), "sound effect '%s' has a file (%s)" % [n, names[n]])
	for track in audio.TRACKS:
		var layers: Array = audio.TRACKS[track]
		ok(not layers.is_empty(), "track %s has layers" % track)
		for path in layers:
			ok(FileAccess.file_exists(path) or ResourceLoader.exists(path), "music file %s" % path)


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


func _heat_and_theft() -> void:
	print("heat and theft")
	# Scorch: hitting a print heats it; heat costs 1 Health at the start of the owner's turn.
	var st := game([], [])
	var a := put(st, 0, "cinderpaw")
	a["kw"].append("scorch")
	var v := put(st, 1, "stoneback")
	var hp0: int = int(v["hp"])
	act(st, 0, {"t": "attack", "unit": int(a["uid"]), "target": "u%d" % int(v["uid"])})
	ok(int(v["heat"]) == 2, "Scorch heats the print it hits")
	ok(int(v["hp"]) < hp0, "...and the hit still lands")
	var hp1: int = int(v["hp"])
	act(st, 0, {"t": "end"})
	ok(int(v["hp"]) == hp1 - 1 and int(v["heat"]) == 1, "a heated print takes 1 damage at the start of its owner's turn")
	act(st, 1, {"t": "end"})
	act(st, 0, {"t": "end"})
	ok(int(v["heat"]) == 0 and int(v["hp"]) == hp1 - 2, "heat runs out after its turns")
	act(st, 1, {"t": "end"})
	act(st, 0, {"t": "end"})
	ok(int(v["hp"]) == hp1 - 2, "and then stops hurting")

	# Thief: steals 1 Attack and gives +1 Health; a heated print gives double.
	st = game([], [])
	var t := put(st, 0, "mossmunk")
	t["kw"].append("thief")
	t["atk"] = 1
	t["hp"] = 5
	t["max_hp"] = 5
	var big := put(st, 1, "stoneback")
	big["atk"] = 4
	big["hp"] = 9
	big["max_hp"] = 9
	big["kw"] = []
	act(st, 0, {"t": "attack", "unit": int(t["uid"]), "target": "u%d" % int(big["uid"])})
	ok(int(big["atk"]) == 3 and int(t["atk"]) == 2, "Thief takes 1 Attack from the print it hits")
	ok(int(t["max_hp"]) == 6 and int(t["loot"]) == 1, "...gains +1 Health and remembers the theft")
	ok(str(t["loot_el"]) == "Stone", "...and whose filament it took")
	st = game([], [])
	t = put(st, 0, "mossmunk")
	t["kw"].append("thief")
	t["atk"] = 1
	t["hp"] = 9
	t["max_hp"] = 9
	big = put(st, 1, "stoneback")
	big["atk"] = 4
	big["hp"] = 12
	big["max_hp"] = 12
	big["kw"] = []
	big["heat"] = 2
	act(st, 0, {"t": "attack", "unit": int(t["uid"]), "target": "u%d" % int(big["uid"])})
	ok(int(big["atk"]) == 2 and int(t["atk"]) == 3 and int(t["max_hp"]) == 11, "a heated print gives up twice as much")

	# The steal op: damage the target and take that much, plus Attack.
	st = game([], [])
	var s := put(st, 0, "mossmunk")
	var w := put(st, 1, "stoneback")
	w["kw"] = []
	var ev: Array = []
	BattleEngine._run(st, 0, [{"op": "steal", "atk": 2, "hp": 2, "to": "target"}], {"target": "u%d" % int(w["uid"]), "self": int(s["uid"])}, ev)
	ok(int(s["atk"]) == int(GameData.card("mossmunk")["atk"]) + 2 and int(w["hp"]) == int(GameData.card("stoneback")["hp"]) - 2, "steal moves Attack and Health")
	ok(ev.any(func(e): return e["e"] == "steal"), "steal reports an event")
	st = game([], [])
	s = put(st, 0, "mossmunk")
	w = put(st, 1, "brambleowl")
	BattleEngine._run(st, 0, [{"op": "steal", "atk": 0, "hp": 3, "to": "target"}], {"target": "u%d" % int(w["uid"]), "self": int(s["uid"])}, ev)
	ok(int(s["loot"]) == 0, "Brim stops a steal (no damage lands, nothing is taken)")


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
	st = game([], [], "delta_rig", "tide_press", {"frame": 1, "bed": 1, "spool": 1})
	ok(int(st["players"][0]["hp"]) == GameData.PRINTER_HP + 2, "Reinforced Frame adds Health")
	ok(int(st["players"][0]["spool_max"]) == GameData.SPOOL_SIZE + 5, "Bigger Spool holds more Filament")
	h = give(st, 0, "mossmunk")
	act(st, 0, {"t": "play", "hand": h})
	ok(int(st["players"][0]["board"][0]["atk"]) == 2 and int(st["players"][0]["board"][0]["hp"]) == 4, "Heated Bed buffs the first print")
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


func _mods() -> void:
	print("printer mods")
	var m := {"stepper": 1, "enclosure": 1}
	var st := BattleEngine.new_game({"seed": 4, "first": 0, "players": [
		{"printer": "delta_rig", "deck": GameData.expand(GameData.STARTER_DECK), "mods": m},
		{"printer": "tide_press", "deck": GameData.expand(GameData.STARTER_DECK)}]})
	ok(int(st["players"][0]["speed"]) == GameData.PRINT_SPEED + 1 and int(st["players"][0]["flow"]) == GameData.PRINT_SPEED + 1, "Stepper Motors add print speed")
	ok(int(st["players"][0]["armor"]) == 2, "Enclosure starts you with Armor")
	# No limit on how many mods a Printer carries, and one of each.
	var every := {}
	for pm in GameData.PRINTER_MODS:
		every[pm["id"]] = 1
	ok(GameData.clean_mods("ember_forge", every).size() == GameData.PRINTER_MODS.size(), "a Printer can carry every mod at once")
	ok(GameData.clean_mods("ember_forge", {"stepper": 9, "nope": 1, "bed": 0}) == {"stepper": 1}, "unknown mods and level 0 are dropped, and a mod counts once")
	# Mods that need other mods.
	ok(GameData.clean_mods("ember_forge", {"dual_extruder": 1}).is_empty(), "Dual Extruder does nothing without Stepper Motors")
	ok(GameData.clean_mods("ember_forge", {"dual_extruder": 1, "stepper": 1}).size() == 2, "...and works with them")
	ok(GameData.clean_mods("ember_forge", {"direct_drive": 1, "dual_extruder": 1, "stepper": 1}).size() == 2, "Direct Drive needs two mods, and one of them is missing")
	ok(GameData.clean_mods("ember_forge", {"direct_drive": 1, "dual_extruder": 1, "stepper": 1, "hot_end": 1}).size() == 4, "with both it works")
	var chain := raw_game({"stepper": 1, "dual_extruder": 1, "direct_drive": 1, "hot_end": 1})
	ok(int(chain["players"][0]["speed"]) == GameData.PRINT_SPEED + 3, "three speed mods in a chain add up: %d Filament a turn" % int(chain["players"][0]["speed"]))
	ok(int(chain["players"][0]["power_cost"]) == 1, "(and the Hot End still takes 1 off the Power)")
	ok(chain["players"][0]["mods"].size() == 4, "the mods a Printer carries are in the game state for the picture")
	var broken := raw_game({"direct_drive": 1, "dual_extruder": 1})
	ok(int(broken["players"][0]["speed"]) == GameData.PRINT_SPEED, "a dependent mod without its parents gives nothing")
	for pm in GameData.PRINTER_MODS:
		for r in GameData.mod_requires(pm["id"]):
			ok(not GameData.mod(str(r)).is_empty() and str(r) != str(pm["id"]), "%s needs a real, different mod (%s)" % [pm["id"], r])
	var dual_speed := raw_game({"stepper": 1, "overdrive_board": 1, "capacitor_bank": 1})
	ok(int(dual_speed["players"][0]["flow"]) == GameData.PRINT_SPEED + 1 + 2 + 3, "Overdrive Board and Capacitor Bank add to the first turn's speed")

	st = game([], [], "ember_forge", "tide_press", {"sensor": 1})
	var mine := put(st, 0, "voltwig")
	var wall := put(st, 1, "stoneback")
	var before: int = int(st["players"][0]["spool"])
	act(st, 0, {"t": "attack", "unit": int(mine["uid"]), "target": "u%d" % int(wall["uid"])})
	ok(int(st["players"][0]["spool"]) == before + 2, "Filament Sensor returns more scrap")

	st = game([], [], "delta_rig", "tide_press", {"preheater": 1})
	st["players"][0]["flow"] = 3
	var h := give(st, 0, "ironmaw")
	act(st, 0, {"t": "play", "hand": h})
	ok(int(st["players"][0]["job"]["paid"]) == 4, "Pre-heater: the first long print starts 2 ahead (3 now + 2, held back one short)")
	st["players"][0]["job"] = {}
	st["players"][0]["flow"] = 3
	h = give(st, 0, "ironmaw")
	act(st, 0, {"t": "play", "hand": h})
	ok(int(st["players"][0]["job"]["paid"]) == 3, "...but only the first")

	st = game([], [], "ember_forge", "tide_press", {"slicer": 1})
	st["players"][1]["hand"].clear()
	st["players"][0]["hand"].clear()
	act(st, 0, {"t": "end"})
	act(st, 1, {"t": "end"})
	ok(st["players"][0]["hand"].size() == 4 and st["players"][1]["hand"].size() == 3, "Smart Slicer tops a thin hand up to 4 (and only yours)")

	var hand_plain := 0
	var hand_quick := 0
	for q in [0, 1]:
		var g := BattleEngine.new_game({"seed": 5, "first": 0, "players": [
			{"printer": "ember_forge", "deck": GameData.expand(GameData.STARTER_DECK), "mods": {"quickstart": q}},
			{"printer": "tide_press", "deck": GameData.expand(GameData.STARTER_DECK)}]})
		if q == 0:
			hand_plain = g["players"][0]["hand"].size()
		else:
			hand_quick = g["players"][0]["hand"].size()
	ok(hand_quick == hand_plain + 1, "Quick Start draws one more card on turn one")

	st = game([], [], "delta_rig", "tide_press", {"hot_end": 1})
	ok(int(st["players"][0]["power_cost"]) == 2, "All-metal Hot End: Rapid Pull costs 3, now 2")
	st = game([], [], "ember_forge", "tide_press", {"hot_end": 1})
	ok(int(st["players"][0]["power_cost"]) == 1, "Hot Nozzle costs 1 with the Hot End")
	st["players"][0]["flow"] = 1
	ok(BattleEngine.power_error(st, 0) == "", "and can be used with 1 Filament")

	st = game([], [], "ember_forge", "tide_press", {"mixer": 1})
	var cat := put(st, 0, "cinderpaw")
	ok(int(cat["atk"]) == 4 and int(cat["hp"]) == 3, "Colour Mixer: a matching-element print gets +1 Attack (and the usual +1 Health)")
	var off := put(st, 0, "aquafin")
	ok(int(off["atk"]) == 2, "...other elements do not")
	st = game([], [], "delta_rig", "tide_press", {"mixer": 1})
	var bot := put(st, 0, "test_bot")
	ok(int(bot["atk"]) == 1 and int(bot["hp"]) == 1, "Neutral Printers attune nothing")

	# New Printer Powers do what they say.
	st = game([], [], "frost_chamber", "tide_press")
	var foe := put(st, 1, "stoneback")
	ok(act(st, 0, {"t": "power", "target": "u%d" % int(foe["uid"])})["ok"] and int(foe["jam"]) == 1, "Flash Freeze jams a print")
	st = game([], [], "cyclone_rig", "tide_press")
	var plain := put(st, 0, "mossmunk")
	act(st, 0, {"t": "power", "target": "u%d" % int(plain["uid"])})
	ok((plain["kw"] as Array).has("rush"), "Tailwind gives Rush")
	st = game([], [], "resin_vat", "tide_press")
	plain = put(st, 0, "mossmunk")
	act(st, 0, {"t": "power", "target": "u%d" % int(plain["uid"])})
	ok(int(plain["hp"]) == 5, "Cure gives +2 Health")
	st = game([], [], "pellet_press", "tide_press")
	var sp: int = int(st["players"][0]["spool"])
	act(st, 0, {"t": "power"})
	ok(int(st["players"][0]["spool"]) == sp - 2 + 4, "Hopper Refill nets +2 Filament on the Spool")
	st = game([], [], "titan_gantry", "tide_press")
	act(st, 0, {"t": "power"})
	ok(int(st["players"][0]["armor"]) == 3 and int(st["players"][0]["flow"]) == 7, "Brace gives 3 Armor for 3 Filament")
	st = game([], [], "delta_rig", "tide_press")
	var cards_before: int = st["players"][0]["hand"].size()
	act(st, 0, {"t": "power"})
	ok(st["players"][0]["hand"].size() == cards_before + 1, "Rapid Pull draws")


## A throwaway Profile to test saves, ranks and the shop without touching the real one.
func fresh_profile() -> Node:
	var pr: Node = load("res://scripts/core/profile.gd").new()
	pr.path = "user://test_profile_rules.json"
	pr.data = pr.fresh()
	pr.choose_starter("cinderpaw")
	return pr


func _progression() -> void:
	print("progression")
	ok(GameData.rank_from_xp(0)["rank"] == 1, "everyone starts at rank 1")
	var need: int = GameData.xp_to_advance(1)
	ok(GameData.rank_from_xp(need - 1)["rank"] == 1 and GameData.rank_from_xp(need)["rank"] == 2, "rank 2 comes at exactly %d XP" % need)
	ok(GameData.rank_from_xp(10000000)["rank"] == GameData.RANK_MAX and GameData.rank_from_xp(10000000)["need"] == 0, "the rank cap holds")
	var inverse_ok := true
	for r in range(1, GameData.RANK_MAX + 1):
		var xp_at := GameData.xp_for_rank(r)
		inverse_ok = inverse_ok and int(GameData.rank_from_xp(xp_at)["rank"]) == r and int(GameData.rank_from_xp(xp_at)["into"]) == 0
		if r > 1:
			inverse_ok = inverse_ok and int(GameData.rank_from_xp(xp_at - 1)["rank"]) == r - 1
	ok(inverse_ok, "xp_for_rank is the exact start of every rank (testing tools set XP with it)")
	var total := 0
	for r in range(1, GameData.RANK_MAX):
		total += GameData.xp_to_advance(r)
	ok(total >= 12000, "the full climb is long (%d XP)" % total)

	var pr := fresh_profile()
	ok(pr.rank_level() == 1 and pr.owns_printer("ember_forge"), "a new player is rank 1 with a Printer")
	pr.data["coins"] = 100000
	ok(pr.buy_printer("stone_kiln") != "", "a Printer needs rank (rank %d)" % pr.printer_rank("stone_kiln"))
	ok(pr.buy_mod("stepper") != "", "a mod needs rank too")
	ok(pr.buy_mod("spool") == "" and pr.owns_mod("spool"), "a rank-1 mod can be bought")
	ok(pr.buy_mod("spool") != "", "and only once")
	ok(pr.installed_mods("ember_forge").has("spool"), "a new mod is fitted to your Printer straight away")
	ok(pr.buy_mod("spool_rack") != "", "a mod that needs another needs your rank first")
	pr.data["xp"] = 100000
	ok(pr.buy_mod("dual_extruder") != "" and not pr.owns_mod("dual_extruder"), "Dual Extruder cannot be bought before Stepper Motors")
	ok(pr.buy_printer("stone_kiln") == "" and pr.owns_printer("stone_kiln"), "with rank, the Printer can be bought")
	ok(pr.installed_mods("stone_kiln").has("spool"), "and it comes with the mods you own")
	ok(pr.buy_printer("tide_press") == "" and pr.owns_printer("tide_press"), "an unpicked starter Printer is buyable")
	var c0: int = pr.coins()
	ok(pr.buy_mod("spool_rack") == "" and pr.coins() == c0 - int(GameData.mod("spool_rack")["cost"]), "mod prices come off your coins")
	ok(pr.buy_mod("frame") == "" and pr.buy_mod("bed") == "" and pr.buy_mod("sorter") == "", "more mods")
	ok(pr.installed_mods("ember_forge").size() == 5, "there is no slot limit: all 5 are fitted")
	ok(pr.battle_mods("ember_forge") == {"spool": 1, "spool_rack": 1, "frame": 1, "bed": 1, "sorter": 1}, "battle mods are everything fitted")

	# Taking a mod off takes its dependants with it, and they need it back to return.
	var gone: Array = pr.remove_mod("ember_forge", "spool")
	ok(gone == ["spool_rack"] and not pr.installed_mods("ember_forge").has("spool_rack"), "removing Bigger Spool also removes the Spool Rack")
	ok(pr.install_mod("ember_forge", "spool_rack") != "", "the Rack cannot go back on without the Spool")
	ok(pr.install_mod("ember_forge", "spool") == "" and pr.install_mod("ember_forge", "spool_rack") == "", "with the Spool back it can")
	ok(pr.install_mod("ember_forge", "stepper") != "", "an unbought mod cannot be fitted")
	pr.remove_mod("stone_kiln", "frame")
	ok(not pr.battle_mods("stone_kiln").has("frame") and pr.battle_mods("ember_forge").has("frame"), "each Printer keeps its own set")

	# Winning pays less than it used to, and gives Maker XP.
	var before: int = pr.coins()
	var xp_before: int = int(pr.data["xp"])
	var rw: Dictionary = pr.record_battle("quick", true, 1, "", "ember_forge")
	ok(int(rw["coins"]) == GameData.WIN_COINS[1] + 4 and pr.coins() == before + int(rw["coins"]), "a win pays %d coins plus the Coin Sorter" % GameData.WIN_COINS[1])
	ok(int(rw["xp"]) == GameData.XP_WIN[1] and int(pr.data["xp"]) == xp_before + int(rw["xp"]), "and Maker XP")
	rw = pr.record_battle("quick", false, 1, "", "ember_forge")
	ok(int(rw["coins"]) == GameData.LOSS_COINS and int(rw["xp"]) == GameData.XP_LOSS[1], "a loss still pays a little")
	rw = pr.record_battle("rival", true, 0, "pip", "ember_forge")
	ok(bool(rw["first_clear"]) and str(rw["pack"]) == "standard" and int(rw["xp"]) == GameData.XP_WIN[0] + GameData.XP_FIRST_CLEAR, "a first clear adds a pack and bonus XP")
	ok(pr.record_battle("hotseat", true)["coins"] == 0, "pass-and-play pays nothing")

	# An old (version 1) save keeps its workshop upgrades as mods.
	var old := {"version": 1, "started": true, "coins": 500, "printers": ["ember_forge"], "upgrades": {"frame": 2, "bed": 1, "spool": 1, "sorter": 3},
		"cards": {"mossmunk": 2}, "decks": [{"cards": [], "printer": "ember_forge"}, {"cards": [], "printer": "ember_forge"}, {"cards": [], "printer": "ember_forge"}]}
	var f := FileAccess.open("user://test_profile_rules.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	var pm: Node = load("res://scripts/core/profile.gd").new()
	pm.path = "user://test_profile_rules.json"
	pm.data = pm.fresh()
	pm.load_profile()
	ok(pm.owns_mod("frame") and pm.owns_mod("sorter") and pm.owns_mod("spool") and pm.owns_mod("bed"), "old upgrades become mods")
	ok(pm.installed_mods("ember_forge").size() == 4, "and are all fitted (no slot limit)")
	ok(pm.coins() == 500 + 800 + 500 + 1100, "the higher levels are refunded: frame 2 + sorter 3 (%d coins)" % pm.coins())
	ok(int(pm.data["version"]) == Profile.SAVE_VERSION and not pm.data.has("upgrades"), "the save is on the new version")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_profile_rules.json"))
	# A version 2 save had levels and slots: levels become one purchase, the coins come back.
	var v2 := {"version": 2, "started": true, "coins": 100, "printers": ["ember_forge", "stone_kiln"], "mods": {"stepper": 2, "spool": 3, "dual_extruder": 1, "frame": 1},
		"installed": {"ember_forge": ["spool", "frame"]},
		"cards": {"mossmunk": 2}, "decks": [{"cards": [], "printer": "ember_forge"}, {"cards": [], "printer": "ember_forge"}, {"cards": [], "printer": "ember_forge"}]}
	f = FileAccess.open("user://test_profile_rules.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(v2))
	f.close()
	var pv: Node = load("res://scripts/core/profile.gd").new()
	pv.path = "user://test_profile_rules.json"
	pv.data = pv.fresh()
	pv.load_profile()
	ok(pv.owns_mod("stepper") and pv.owns_mod("spool") and pv.owns_mod("frame"), "a version 2 save keeps its mods")
	ok(pv.coins() == 100 + 3200 + 700 + 1500, "extra levels are paid back (%d coins)" % pv.coins())
	ok(pv.installed_mods("ember_forge").size() == 4 and pv.installed_mods("stone_kiln").size() == 4, "and every mod is fitted to every Printer")
	ok(pv.battle_mods("stone_kiln") == {"stepper": 1, "spool": 1, "dual_extruder": 1, "frame": 1}, "with the dependent mod working because its parent is there")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_profile_rules.json"))
	pv.free()
	pr.free()
	pm.free()


func _random_mods() -> void:
	print("random mods")
	var pr := fresh_profile()
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	pr.data["coins"] = GameData.MOD_CRATE_PRICE + 5
	var before: int = pr.coins()
	var got: Dictionary = pr.buy_mod_crate(rng)
	ok(not got.has("error") and pr.coins() == before - GameData.MOD_CRATE_PRICE, "a Mod Crate costs %d and gives a mod" % GameData.MOD_CRATE_PRICE)
	ok(pr.buy_mod_crate(rng).has("error"), "no coins, no crate")
	# Keep awarding: every mod and mod level turns up exactly once, nothing repeats, rarities all appear.
	var total := GameData.CARD_MODS.size() + GameData.PRINTER_MODS.size()
	var seen_rarity := {}
	var n := 1
	seen_rarity[got["rarity"]] = true
	var fresh: Array = []
	while true:
		var g: Dictionary = pr.award_random_mod(rng)
		if g.is_empty():
			break
		n += 1
		seen_rarity[g["rarity"]] = true
		if n > total + 5:
			break
	ok(n == total, "crates hand out every mod exactly once (%d of %d)" % [n, total])
	for r in GameData.RARITY_ORDER:
		ok(seen_rarity.has(r), "random mods include %s ones" % r)
	ok(pr.award_random_mod(rng).is_empty(), "nothing left to find once you have them all")
	# A crate never hands out a mod whose parents you do not have.
	var pr3 := fresh_profile()
	var orphan := false
	for i in 40:
		var g3: Dictionary = pr3.award_random_mod(rng)
		if g3.is_empty():
			break
		if g3["kind"] == "printer" and not pr3.mod_locked_by(str(g3["id"])).is_empty():
			orphan = true
	ok(not orphan, "crates only give Printer mods whose required mods you already own")
	# Rarer mods come up less often.
	var common := 0
	var legendary := 0
	var pr2 := fresh_profile()
	for i in 60:
		var g2: Dictionary = pr2.award_random_mod(rng)
		if g2.is_empty():
			break
		if g2["rarity"] == "common":
			common += 1
		if g2["rarity"] == "legendary":
			legendary += 1
	ok(common > legendary, "common mods are found more often than legendary ones (%d vs %d)" % [common, legendary])


func _blueprints() -> void:
	print("blueprints")
	var base := GameData.card("cinderpaw")
	var mk2 := GameData.built("cinderpaw", {"tier": 2})
	var mk3 := GameData.built("cinderpaw", {"tier": 3})
	ok(int(mk2["atk"]) == int(base["atk"]) + 1 and int(mk2["hp"]) == int(base["hp"]), "Mk II creature: +1 Attack")
	ok(int(mk3["atk"]) == int(base["atk"]) + 1 and int(mk3["hp"]) == int(base["hp"]) + 1, "Mk III creature: +1 Health too")
	ok(GameData.card("cinderpaw")["atk"] == 3, "the catalog card itself never changes")
	ok(GameData.built("cinderpaw", {}) == base and GameData.built("cinderpaw", {"tier": 1, "mod": "infill"}) == base, "Mk I is the plain card and takes no mod")
	ok(GameData.built("heat_gun", {"tier": 2})["text"] == "Deal 3 damage.", "a Mk II Heat Gun deals 3 and says so")
	ok(int(GameData.built("heat_gun", {"tier": 2})["effects"][0]["n"]) == 3 and int(GameData.card("heat_gun")["effects"][0]["n"]) == 2, "the numbers change in the effect too")
	ok(GameData.built("test_print", {"tier": 2})["text"] == "Print three 1/1 Test Bots.", "word numbers are rewritten (two -> three)")
	ok(int(GameData.built("calipers", {"tier": 2})["cost"]) == 2, "a card with no number gets cheaper instead")
	ok(int(GameData.built("heat_gun", {"tier": 3})["cost"]) == 1 and int(GameData.built("printed_wrench", {"tier": 3})["cost"]) == 2, "Mk III: -1 cost, never below 1")
	ok(GameData.built("helm", {"tier": 2})["text"] == "Give a friendly print +2/+2.", "equipment strengthens its first number")
	ok(int(GameData.built("shadow_cloak", {"tier": 2})["buff"]["atk"]) == 2, "a +1 Attack Cloak becomes +2")

	# Mods
	var sharp := GameData.built("mossmunk", {"tier": 2, "mod": "sharp_nozzle"})
	ok(int(sharp["atk"]) == 4 and int(sharp["hp"]) == 2, "Sharp Nozzle: +2/-1 on top of Mk II (1+1+2, 3-1)")
	ok((GameData.built("mossmunk", {"tier": 2, "mod": "rapid_layers"})["kw"] as Array).has("rush"), "Rapid Layers gives Rush")
	ok(not GameData.mod_fits("supports", "mossmunk") and GameData.mod_fits("supports", "voltwig"), "Support Material does not fit a card that already has Guard")
	ok(not GameData.mod_fits("overcharge", "calipers") and GameData.mod_fits("overcharge", "heat_gun"), "Overcharge needs an effect with a number")
	ok(not GameData.mod_fits("draft_mode", "voltwig") and GameData.mod_fits("draft_mode", "stoneback"), "Draft Mode needs a cost of 2 or more")
	ok(not GameData.mod_fits("sharp_nozzle", "heat_gun") and not GameData.mod_fits("overcharge", "voltwig"), "creature mods fit creatures, tool mods fit tools")
	var oc := GameData.built("heat_gun", {"tier": 2, "mod": "overcharge"})
	ok(int(oc["cost"]) == 2 and oc["text"] == "Deal 4 damage.", "Overcharge: Mk II (3 damage) +1 and costs 1 more")
	var qd := GameData.built("heat_gun", {"tier": 2, "mod": "quick_draw"})
	ok(qd["text"].contains("draw a card") and (qd["effects"] as Array).size() == 2 and (GameData.card("heat_gun")["effects"] as Array).size() == 1, "Quick Draw adds a draw and leaves the catalog alone")
	var rc := GameData.built("aquafin", {"tier": 2, "mod": "recycler"})
	ok((rc["shatter"] as Array).size() == 1 and not GameData.card("aquafin").has("shatter"), "Recycler adds a Shatter effect")

	# Every card at every tier with every fitting mod stays sane.
	var combos := 0
	for c in GameData.collectible():
		for tier in [1, 2, 3]:
			var mods: Array = [""]
			for m in GameData.CARD_MODS:
				if GameData.mod_fits(m["id"], c["id"]):
					mods.append(m["id"])
			for mod_id in mods:
				var d := GameData.built(c["id"], {"tier": tier, "mod": mod_id})
				combos += 1
				ok(int(d["cost"]) >= 0 and str(d["text"]).length() >= str(GameData.card(c["id"])["text"]).length() - 3, "%s Mk%d %s is well formed" % [c["id"], tier, mod_id])
				if c["type"] == "creature":
					ok(int(d["atk"]) >= 0 and int(d["hp"]) >= 1, "%s Mk%d %s has sane stats" % [c["id"], tier, mod_id])
	print("  (%d card/tier/mod combinations checked)" % combos)

	# The engine plays the Blueprint.
	var build := {"mossmunk": {"tier": 3, "mod": "sharp_nozzle", "paint": "gold"}, "heat_gun": {"tier": 2, "mod": "", "paint": "original"}}
	var st := BattleEngine.new_game({"seed": 8, "first": 0, "players": [
		{"printer": "delta_rig", "deck": GameData.expand(GameData.STARTER_DECK), "builds": build},
		{"printer": "tide_press", "deck": GameData.expand(GameData.STARTER_DECK), "builds": {"mossmunk": {"tier": 3, "mod": "nonsense"}, "ghost_card": {"tier": 3}}}]})
	ok(st["players"][0]["builds"].size() == 2 and st["players"][1]["builds"].size() == 1 and str(st["players"][1]["builds"]["mossmunk"]["mod"]) == "", "builds are cleaned when a battle starts")
	var u := BattleEngine._summon(st, 0, "mossmunk", 99, [], true)
	ok(int(u["atk"]) == 4 and int(u["hp"]) == 3 and int(u["mk"]) == 3 and str(u["paint"]) == "gold", "a printed Mossmunk has its Mk III Sharp Nozzle stats and paint")
	var u2 := BattleEngine._summon(st, 1, "mossmunk", 99, [], true)
	ok(int(u2["atk"]) == 2 and int(u2["hp"]) == 4, "the opponent's own Blueprint is applied to theirs")
	st["players"][0]["flow"] = 3
	st["players"][0]["hand"].append({"uid": 800, "id": "heat_gun"})
	var foe := BattleEngine._summon(st, 1, "ironmaw", 99, [], false)
	act(st, 0, {"t": "play", "hand": 800, "target": "u%d" % int(foe["uid"])})
	ok(int(foe["hp"]) == 7 - 3 and int(st["players"][0]["flow"]) == 2, "a Mk II Heat Gun deals 3 for 1 Filament")

	# A tier raises the cost of nothing, but a mod that costs more can make a card a long print.
	var st2 := game([], [], "ember_forge", "tide_press")
	st2["players"][0]["builds"] = {"ironmaw": {"tier": 2, "mod": "infill", "paint": "original"}}
	var h := give(st2, 0, "ironmaw")
	ok(BattleEngine.def_of(st2, 0, "ironmaw")["cost"] == 6, "Extra Infill makes a 5-cost print cost 6")
	st2["players"][0]["flow"] = 5
	ok(BattleEngine.is_long(st2, 0, h), "and it no longer fits in one turn at speed 5")

	# Network: a guest's builds are cleaned by the host.
	var cleaned := GameData.clean_builds(GameData.expand(GameData.STARTER_DECK),
		{"mossmunk": {"tier": 9, "mod": "sharp_nozzle", "paint": "none"}, "dragon": {"tier": 3}, "voltwig": "junk"})
	ok(cleaned == {"mossmunk": {"tier": 3, "mod": "sharp_nozzle", "mod2": "", "paint": "original"}}, "a guest's builds are clamped; unknown cards, bad paint and junk are dropped")

	# Profile: the Blueprint shop.
	var pr := fresh_profile()
	ok(pr.build_of("mossmunk")["tier"] == 1 and pr.spares("mossmunk") == 0, "everything starts at Mk I")
	pr.data["coins"] = 100000
	pr.data["xp"] = 0
	ok(pr.tier_error("mossmunk") != "", "Mk II needs rank and a spare copy")
	pr.data["xp"] = 1000
	ok(pr.tier_error("mossmunk").begins_with("Needs 1 spare"), "...and the spare copy is what is missing")
	var r1: Dictionary = pr.add_card("mossmunk")
	ok(not bool(r1["new"]) and int(r1["recycled"]) > 0 and bool(r1["spare"]) and pr.spares("mossmunk") == 1, "a duplicate beyond the deck limit is kept as a spare (and pays a little)")
	var c1: int = pr.coins()
	ok(pr.upgrade_card("mossmunk") == "" and pr.build_of("mossmunk")["tier"] == 2, "Mk II")
	ok(c1 - pr.coins() == GameData.tier_coins("mossmunk", 2) and pr.spares("mossmunk") == 0, "it cost coins and the spare")
	ok(pr.set_card_mod("mossmunk", "sharp_nozzle") != "", "a mod must be unlocked first")
	ok(pr.buy_card_mod("sharp_nozzle") == "" and pr.set_card_mod("mossmunk", "sharp_nozzle") == "", "unlock it, then fit it")
	ok(pr.set_card_mod("mossmunk", "heat_gun") != "" and pr.set_card_mod("mossmunk", "overcharge") != "", "only a known mod that fits (not a tool mod on a creature)")
	ok(pr.set_card_mod("voltwig", "sharp_nozzle") == "Mods fit from Mk II.", "a Mk I card has no mod slot yet")
	ok(pr.set_paint("mossmunk", "gold") != "", "an unbought paint cannot be applied")
	pr.data["xp"] = 100000
	ok(pr.buy_paint("gold") == "" and pr.set_paint("mossmunk", "gold") == "", "a bought paint can be applied")
	ok(pr.builds_for(["mossmunk", "mossmunk", "voltwig"]) == {"mossmunk": {"tier": 2, "mod": "sharp_nozzle", "mod2": "", "paint": "gold"}}, "a battle takes the Blueprints of the cards in the deck")
	ok(pr.upgrade_card("mossmunk") != "", "Mk III needs three spares")
	for i in 3:
		pr.add_card("mossmunk")
	ok(pr.upgrade_card("mossmunk") == "" and pr.build_of("mossmunk")["tier"] == 3 and pr.upgrade_card("mossmunk") != "", "Mk III, and that is the top")
	ok(pr.craft_spare("mossmunk") == "" and pr.spares("mossmunk") == 1, "a spare can be printed for coins")
	# Mk III carries two mods; Mk II only one.
	ok(pr.card_mods_on("mossmunk") == ["sharp_nozzle"], "Mk III keeps the mod fitted at Mk II")
	ok(pr.buy_card_mod("infill") == "" and pr.set_card_mod("mossmunk", "infill") == "", "a second mod fits at Mk III")
	ok(pr.card_mods_on("mossmunk") == ["sharp_nozzle", "infill"], "both mods are fitted")
	var two := GameData.built("mossmunk", pr.build_of("mossmunk"))
	var one := GameData.built("mossmunk", {"tier": 3, "mod": "sharp_nozzle"})
	ok(int(two["hp"]) == int(one["hp"]) + 3 and int(two["atk"]) == int(one["atk"]) and int(two["cost"]) == int(one["cost"]) + 1, "the second mod stacks on the first")
	ok(str(two["mod2"]) == "infill" and str(two["mod"]) == "sharp_nozzle", "the built card names both mods")
	ok(pr.buy_card_mod("overclock") == "" and pr.set_card_mod("mossmunk", "overclock") == "Both mod slots are full.", "there are only two slots")
	ok(pr.set_card_mod("mossmunk", "sharp_nozzle") == "" and pr.card_mods_on("mossmunk") == ["infill"], "tapping a fitted mod takes only that one off")
	ok(GameData.fitted_mods("mossmunk", 2, ["sharp_nozzle", "infill"]) == ["sharp_nozzle"], "Mk II has one slot")
	ok(GameData.fitted_mods("mossmunk", 3, ["infill", "infill"]) == ["infill"], "the same mod cannot be fitted twice")
	pr.set_card_mod("mossmunk", "")
	ok(pr.build_of("mossmunk")["mod"] == "" and pr.build_of("mossmunk")["mod2"] == "", "mods come off freely")
	pr.free()

	# Whole matches with every kind of Blueprint go through the AI without an illegal move.
	var wild: Dictionary = {}
	for c in GameData.STARTER_DECK:
		var fitting: Array = []
		for m in GameData.CARD_MODS:
			if GameData.mod_fits(m["id"], c):
				fitting.append(m["id"])
		wild[c] = {"tier": 3, "mod": fitting[0] if not fitting.is_empty() else "", "mod2": fitting[1] if fitting.size() > 1 else "", "paint": "gold"}
	var cfg: Dictionary = {"printer": "ember_forge", "deck": GameData.expand(GameData.STARTER_DECK), "builds": wild}
	var bad := 0
	for i in 6:
		var r := play_out(300 + i, cfg, {"printer": "tide_press", "deck": GameData.expand(GameData.STARTER_DECK)}, 1, 1)
		if int(r["winner"]) == -3:
			bad += 1
	ok(bad == 0, "matches with fully built cards finish")


## Ratings, leagues, the matchmaker, player identity and the ranked ladder.
func _ranked() -> void:
	var v: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://backend/test/rating_vectors.json"))
	for c in v["rating"]:
		ok(Rating.delta(int(c["a"]), int(c["b"]), bool(c["won"]), int(c["games"])) == int(c["delta"]), "rating vector %s" % str(c))
	for w in v["windows"]:
		ok(Matchmaker.window(int(w["seconds"])) == int(w["window"]), "match window after %ds" % int(w["seconds"]))
	for l in v["leagues"]:
		var got := Rating.league(int(l["rating"]))
		ok(got["name"] == l["name"] and int(got["division"]) == int(l["division"]), "league at %d is %s %d (got %s %d)" % [int(l["rating"]), l["name"], int(l["division"]), got["name"], int(got["division"])])
	for m in v["matchmaking"]:
		var got := Matchmaker.pairs(v["queue"], int(m["now"]))
		ok(str(got) == str(m["pairs"]), "pairs at %ds: %s (got %s)" % [int(m["now"]), str(m["pairs"]), str(got)])
	ok(Rating.after(100, 1500, false, 50) == Rating.FLOOR, "rating never falls below the floor")
	ok(Rating.delta(1000, 1000, true, 0) == -Rating.delta(1000, 1000, false, 0), "an even game is zero-sum")
	ok(Rating.delta(1000, 1400, true, 40) > Rating.delta(1000, 1000, true, 40), "beating a stronger player pays more")
	ok(Matchmaker.should_offer_ghost(Matchmaker.GHOST_AFTER) and not Matchmaker.should_offer_ghost(Matchmaker.GHOST_AFTER - 1), "a computer opponent is offered after the wait")
	# Nobody is matched with someone they just played, and a lone player gets no pair.
	var two := [{"id": "x", "rating": 1000, "joined": 0, "recent": ["y"]}, {"id": "y", "rating": 1000, "joined": 0, "recent": []}]
	ok(Matchmaker.pairs(two, 500).is_empty(), "recent opponents are not paired again")
	ok(Matchmaker.pairs([two[0]], 500).is_empty(), "one player alone is not paired")
	# Identity: names come from fixed lists, ids are well formed, damaged saves are repaired.
	var pl := PlayerIdentity.fresh_player()
	ok(PlayerIdentity.valid_id(str(pl["id"])), "a new player gets a 16-hex id")
	ok(PlayerIdentity.name_of(0, 0, 7) == "Swift Maker 07", "names are an adjective, a noun and two digits")
	var bad := PlayerIdentity.sanitize({"id": "nope", "adj": 99, "noun": -3, "num": 1234, "rating": -50, "ranked_games": 3, "ranked_wins": 99, "title": "x",
		"history": [{"opp": "<b>Hax\n</b>", "opp_rating": -4, "won": 1, "delta": 3, "mode": "ranked"}, 5]})
	ok(PlayerIdentity.valid_id(str(bad["id"])) and int(bad["adj"]) < PlayerIdentity.ADJECTIVES.size() and int(bad["noun"]) < PlayerIdentity.NOUNS.size(), "a damaged player record is repaired")
	ok(int(bad["rating"]) == Rating.FLOOR and int(bad["ranked_wins"]) == 3 and (bad["history"] as Array).size() == 1, "ratings are floored, wins capped, junk history dropped")
	ok(not str(bad["history"][0]["opp"]).contains("<") and not str(bad["history"][0]["opp"]).contains("\n"), "opponent names in history keep only letters, digits and spaces")
	# The profile applies a ranked result.
	var pr := fresh_profile()
	ok(pr.rating() == Rating.START and pr.title_name() == "Rookie Maker", "a new profile starts at 1000 as a Rookie Maker")
	var r1: Dictionary = pr.record_ranked("Swift Maker 07", 1000, true)
	ok(int(r1["delta"]) == 20 and pr.rating() == 1020, "a first win against an equal pays 20 (calibration)")
	ok(int(pr.player()["streak"]) == 1 and int(pr.player()["ranked_wins"]) == 1, "the win starts a streak")
	var r2: Dictionary = pr.record_ranked("Bold Gear 01", 1100, false)
	ok(int(r2["delta"]) < 0 and int(pr.player()["streak"]) == -1, "a loss ends it")
	for i in 30:
		pr.record_ranked("Quiet Bolt 03", 1000, true)
	ok((pr.player()["history"] as Array).size() == PlayerIdentity.HISTORY_LIMIT, "history keeps the last %d games" % PlayerIdentity.HISTORY_LIMIT)
	ok(int(pr.player()["best_streak"]) >= 30 and int(pr.player()["best_rating"]) == pr.rating(), "best streak and best rating are tracked")
	ok(pr.set_title("streak") and pr.title_name() == "Hot Streak", "a title you earned can be worn")
	ok(not pr.set_title("league_6"), "a title you have not earned cannot")
	var reward: Dictionary = pr.record_battle("ranked", true, 1, "", "ember_forge", {"name": "Sunny Spool 09", "rating": pr.rating()})
	ok(reward.has("rating") and int(reward["xp"]) == GameData.XP_PVP_WIN, "a ranked win pays PvP XP and carries the rating change")
	pr.set_player_look(2, 3, 105, "cinderpaw")
	ok(pr.player_name() == "Clever Spool 05" and pr.avatar_id() == "cinderpaw", "you choose your name words, number (mod 100) and picture")
	pr.set_player_look(2, 3, 5, "glassdrake")
	ok(pr.avatar_id() != "glassdrake", "you cannot wear a print you do not own")
	# The ladder builds legal, rating-appropriate opponents, the same way every time.
	for rating in [100, 800, 1000, 1250, 1500, 1900, 2400]:
		for sd in 6:
			var o: Dictionary = Ladder.opponent(rating, 100 + sd)
			ok(GameData.deck_error(o["deck"]) == "", "ladder deck at %d (seed %d) is legal" % [rating, sd])
			ok(absi(int(o["rating"]) - rating) <= 60 or rating < 160, "the opponent sits near rating %d (%d)" % [rating, int(o["rating"])])
			ok(GameData.printer(str(o["printer"]))["id"] == o["printer"], "the opponent has a real Printer")
	ok(str(Ladder.opponent(1300, 5)) == str(Ladder.opponent(1300, 5)), "the same seed makes the same opponent")
	var low: Dictionary = Ladder.opponent(500, 3)
	var high: Dictionary = Ladder.opponent(2000, 3)
	var rare_low := 0
	var rare_high := 0
	for id in low["deck"]:
		if GameData.card(id)["rarity"] in ["epic", "legendary"]:
			rare_low += 1
	for id in high["deck"]:
		if GameData.card(id)["rarity"] in ["epic", "legendary"]:
			rare_high += 1
	ok(rare_low == 0 and int(low["tier"]) < int(high["tier"]), "low-rated opponents use no epics or legendaries and lower Blueprint tiers")
	# A full battle against a ladder opponent can be played out, as the ranked session sets it up.
	var opp: Dictionary = Ladder.opponent(1000, 9)
	var mine: Array = GameData.expand(GameData.STARTER_DECK)
	var st := BattleEngine.new_game({"seed": 5, "players": [
		{"printer": "ember_forge", "deck": mine, "builds": GameData.uniform_builds(mine, 1)},
		{"printer": opp["printer"], "deck": (opp["deck"] as Array).duplicate(), "hp_bonus": int(opp["hp_bonus"]),
			"builds": GameData.uniform_builds(opp["deck"], int(opp["tier"]))}]})
	var steps := 0
	while not st["over"] and steps < 5000:
		steps += 1
		var seat: int = int(st["active"])
		BattleEngine.apply(st, seat, BattleAI.choose(st, seat, int(opp["level"])))
	ok(st["over"], "a game against a ladder opponent finishes")


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
		else:
			for e in res["events"]:
				_seen[e["e"]] = int(_seen.get(e["e"], 0)) + 1
	return {"winner": int(st["winner"]) if st["over"] else -3, "turns": int(st["turn"]), "first": first}


var _seen := {}


## Random decks from the whole catalog, random Printers with random mods and
## Blueprints, played by the AI: nothing may break, stall or be illegal.
func _fuzz_games() -> void:
	print("fuzz games")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261113
	var pool: Array = GameData.collectible()
	var stalls := 0
	var games := 0
	_seen = {}
	var rarity_cards := {}
	for g in 150:
		var cfgs: Array = []
		for side in 2:
			var cards: Array = pool.duplicate()
			for i in range(cards.size() - 1, 0, -1):
				var j := rng.randi_range(0, i)
				var t = cards[i]
				cards[i] = cards[j]
				cards[j] = t
			var deck: Array = []
			var counts := {}
			for c in cards:
				if deck.size() >= GameData.DECK_SIZE:
					break
				var n: int = int(counts.get(c["id"], 0))
				if n < GameData.max_copies(c["id"]):
					counts[c["id"]] = n + 1
					deck.append(c["id"])
					rarity_cards[c["rarity"]] = true
			ok(GameData.deck_error(deck) == "", "fuzz deck %d/%d is legal: %s" % [g, side, GameData.deck_error(deck)])
			var printer: Dictionary = GameData.PRINTERS[rng.randi_range(0, GameData.PRINTERS.size() - 1)]
			var mods := {}
			for m in GameData.PRINTER_MODS:
				if rng.randf() < 0.45:
					mods[m["id"]] = 1
			var builds := {}
			for id in deck:
				var tier := rng.randi_range(1, 3)
				var mod_id := ""
				if tier >= 2 and rng.randf() < 0.7:
					var m: Dictionary = GameData.CARD_MODS[rng.randi_range(0, GameData.CARD_MODS.size() - 1)]
					if GameData.mod_fits(m["id"], id):
						mod_id = m["id"]
				builds[id] = {"tier": tier, "mod": mod_id, "paint": "original"}
			cfgs.append({"printer": printer["id"], "deck": deck, "mods": mods, "builds": builds})
		var res := play_out(rng.randi(), cfgs[0], cfgs[1], rng.randi_range(0, 2), rng.randi_range(0, 2))
		games += 1
		if int(res["winner"]) == -3:
			stalls += 1
	print("  %d games, %d stalls, events seen: %s" % [games, stalls, str(_seen)])
	ok(stalls == 0, "random-deck games never stall (%d did)" % stalls)
	ok(int(_seen.get("heat", 0)) > 0 and int(_seen.get("steal", 0)) > 0, "heat and steal actually happen in play")
	ok(int(_seen.get("melt", 0)) > 0, "heated prints melt")
	_seen = {}


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
