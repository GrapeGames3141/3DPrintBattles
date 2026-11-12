class_name BattleEngine
extends RefCounted
## Deterministic, integer-only battle rules.
##
## State is a plain Dictionary (ints, strings, arrays) so it can be deep-copied
## for AI search and sent over the network unchanged. All mutation goes through
## `apply`, which returns the list of events the screen animates.
##
## Character references are strings: "u<uid>" for a print, "p<seat>" for a printer.

const SCRAP := "filament_scrap"


# ------------------------------------------------------------------ setup

## cfg = {"seed": int, "first": -1|0|1,
##        "players": [{"printer": id, "deck": [ids], "upgrades": {frame, bed, spool}, "hp_bonus": int}, x2]}
static func new_game(cfg: Dictionary) -> Dictionary:
	var st := {
		"rng": int(cfg.get("seed", 1)) & 0x7fffffff,
		"turn": 0,
		"active": 0,
		"over": false,
		"winner": -1,
		"uid": 1,
		"players": [],
	}
	for seat in 2:
		var pc: Dictionary = cfg["players"][seat]
		var up: Dictionary = pc.get("upgrades", {})
		var hp: int = GameData.PRINTER_HP + 2 * clampi(int(up.get("frame", 0)), 0, 3) + int(pc.get("hp_bonus", 0))
		hp = maxi(hp, 10)
		var deck: Array = (pc["deck"] as Array).duplicate()
		_shuffle(st, deck)
		st["players"].append({
			"printer": str(pc["printer"]),
			"hp": hp, "max_hp": hp, "armor": 0,
			"fil": 0, "max_fil": 0,
			"power_used": false,
			"deck": deck, "hand": [], "board": [],
			"fatigue": 0,
			"bed": clampi(int(up.get("bed", 0)), 0, 3),
			"spool": clampi(int(up.get("spool", 0)), 0, 2),
		})
	var first: int = int(cfg.get("first", -1))
	if first != 0 and first != 1:
		first = _rand(st, 2)
	st["active"] = first
	var ev: Array = []
	for seat in 2:
		var n: int = 3 if seat == first else 4
		for i in n:
			_draw(st, seat, ev)
		var scraps: int = int(st["players"][seat]["spool"]) + (0 if seat == first else 1)
		for i in scraps:
			_give(st, seat, SCRAP, ev)
	_start_turn(st, ev)
	return st


# ---------------------------------------------------------------- queries

static func seat_of(ref: String) -> int:
	return int(ref.substr(1)) if ref.begins_with("p") else -1


static func find_unit(st: Dictionary, uid: int) -> Dictionary:
	for p in st["players"]:
		for u in p["board"]:
			if int(u["uid"]) == uid:
				return u
	return {}


static func unit_of(st: Dictionary, ref: String) -> Dictionary:
	if not ref.begins_with("u"):
		return {}
	return find_unit(st, int(ref.substr(1)))


static func hand_card(st: Dictionary, seat: int, uid: int) -> Dictionary:
	for c in st["players"][seat]["hand"]:
		if int(c["uid"]) == uid:
			return c
	return {}


static func has_guard(st: Dictionary, seat: int) -> bool:
	for u in st["players"][seat]["board"]:
		if (u["kw"] as Array).has("guard"):
			return true
	return false


static func max_attacks(u: Dictionary) -> int:
	return 2 if (u["kw"] as Array).has("twin") else 1


static func can_attack(u: Dictionary) -> bool:
	if int(u["atk"]) <= 0 or int(u["jam"]) > 0:
		return false
	if int(u["attacks"]) >= max_attacks(u):
		return false
	if bool(u["fresh"]) and not (u["kw"] as Array).has("rush"):
		return false
	return true


## Legal attack targets for one of the active player's prints.
static func attack_targets(st: Dictionary, uid: int) -> Array:
	var u := find_unit(st, uid)
	if u.is_empty() or st["over"] or int(u["seat"]) != int(st["active"]) or not can_attack(u):
		return []
	var foe: int = 1 - int(u["seat"])
	var guard := has_guard(st, foe)
	var out: Array = []
	for t in st["players"][foe]["board"]:
		if not guard or (t["kw"] as Array).has("guard"):
			out.append("u%d" % int(t["uid"]))
	if not guard and not bool(u["fresh"]):
		out.append("p%d" % foe)
	return out


## Characters matching a target kind, from `seat`'s point of view.
static func targets_for(st: Dictionary, seat: int, kind: String, max_atk: int = -1) -> Array:
	var out: Array = []
	var foe: int = 1 - seat
	var sides: Array = []
	match kind:
		"enemy", "enemy_print":
			sides = [foe]
		"friendly", "friendly_print":
			sides = [seat]
		"any", "any_print":
			sides = [seat, foe]
		_:
			return out
	for s in sides:
		for u in st["players"][s]["board"]:
			if max_atk >= 0 and int(u["atk"]) > max_atk:
				continue
			out.append("u%d" % int(u["uid"]))
		if not kind.ends_with("_print"):
			out.append("p%d" % s)
	return out


## Valid targets for playing a hand card. Empty for untargeted cards.
static func play_targets(st: Dictionary, seat: int, card_id: String) -> Array:
	var def := GameData.card(card_id)
	var kind: String = def.get("target", "")
	if kind == "":
		return []
	return targets_for(st, seat, kind, int(def.get("target_max_atk", -1)))


static func power_targets(st: Dictionary, seat: int) -> Array:
	var power: Dictionary = GameData.printer(st["players"][seat]["printer"])["power"]
	var kind: String = power.get("target", "")
	if kind == "":
		return []
	return targets_for(st, seat, kind)


## "" when the card can be played right now, else the reason it cannot.
static func play_error(st: Dictionary, seat: int, hand_uid: int) -> String:
	if st["over"]:
		return "The battle is over."
	if seat != int(st["active"]):
		return "It is not your turn."
	var c := hand_card(st, seat, hand_uid)
	if c.is_empty():
		return "That card is not in your hand."
	var def := GameData.card(c["id"])
	var p: Dictionary = st["players"][seat]
	if int(def["cost"]) > int(p["fil"]):
		return "Not enough Filament."
	if def["type"] == "creature":
		if (p["board"] as Array).size() >= GameData.MAX_BOARD:
			return "Your print bed is full."
	elif def.get("target", "") != "" and play_targets(st, seat, c["id"]).is_empty():
		return "There is nothing to use that on."
	return ""


static func power_error(st: Dictionary, seat: int) -> String:
	if st["over"]:
		return "The battle is over."
	if seat != int(st["active"]):
		return "It is not your turn."
	var p: Dictionary = st["players"][seat]
	if bool(p["power_used"]):
		return "Your Printer Power is already used this turn."
	if int(p["fil"]) < GameData.POWER_COST:
		return "Not enough Filament."
	var power: Dictionary = GameData.printer(p["printer"])["power"]
	if power.get("target", "") != "" and power_targets(st, seat).is_empty():
		return "There is nothing to use that on."
	for e in power["effects"]:
		if e["op"] == "summon" and (p["board"] as Array).size() >= GameData.MAX_BOARD:
			return "Your print bed is full."
	return ""


## Does a card played now need the player to pick a target?
static func needs_target(st: Dictionary, seat: int, card_id: String) -> bool:
	var def := GameData.card(card_id)
	if def.get("target", "") == "":
		return false
	return not play_targets(st, seat, card_id).is_empty()


## Every legal action for `seat` (used by the AI).
static func legal_actions(st: Dictionary, seat: int) -> Array:
	var out: Array = []
	if st["over"] or seat != int(st["active"]):
		return out
	var p: Dictionary = st["players"][seat]
	var seen: Dictionary = {}
	for c in p["hand"]:
		if seen.has(c["id"]):
			continue
		seen[c["id"]] = true
		if play_error(st, seat, int(c["uid"])) != "":
			continue
		var tg := play_targets(st, seat, c["id"])
		if tg.is_empty():
			out.append({"t": "play", "hand": int(c["uid"])})
		else:
			for t in tg:
				out.append({"t": "play", "hand": int(c["uid"]), "target": t})
	for u in p["board"]:
		for t in attack_targets(st, int(u["uid"])):
			out.append({"t": "attack", "unit": int(u["uid"]), "target": t})
	if power_error(st, seat) == "":
		var pt := power_targets(st, seat)
		if pt.is_empty():
			out.append({"t": "power"})
		else:
			for t in pt:
				out.append({"t": "power", "target": t})
	out.append({"t": "end"})
	return out


# ---------------------------------------------------------------- actions

## Applies one action. Returns {"ok": bool, "error": String, "events": Array}.
## A rejected action leaves the state untouched.
static func apply(st: Dictionary, seat: int, action: Dictionary) -> Dictionary:
	var ev: Array = []
	if st["over"]:
		return _fail("The battle is over.")
	var kind: String = str(action.get("t", ""))
	if kind == "concede":
		if seat != 0 and seat != 1:
			return _fail("Unknown player.")
		_finish(st, 1 - seat, ev)
		return {"ok": true, "error": "", "events": ev}
	if seat != int(st["active"]):
		return _fail("It is not your turn.")
	var err := ""
	match kind:
		"end":
			_end_turn(st, ev)
		"play":
			err = _play(st, seat, action, ev)
		"attack":
			err = _attack(st, seat, action, ev)
		"power":
			err = _power(st, seat, action, ev)
		_:
			err = "Unknown action."
	if err != "":
		return _fail(err)
	return {"ok": true, "error": "", "events": ev}


static func _fail(msg: String) -> Dictionary:
	return {"ok": false, "error": msg, "events": []}


static func _play(st: Dictionary, seat: int, a: Dictionary, ev: Array) -> String:
	var hand_uid: int = int(a.get("hand", -1))
	var err := play_error(st, seat, hand_uid)
	if err != "":
		return err
	var p: Dictionary = st["players"][seat]
	var c := hand_card(st, seat, hand_uid)
	var def := GameData.card(c["id"])
	var target: String = str(a.get("target", ""))
	var valid := play_targets(st, seat, c["id"])
	if valid.is_empty():
		target = ""
	elif not valid.has(target):
		return "Choose a valid target."

	p["fil"] = int(p["fil"]) - int(def["cost"])
	(p["hand"] as Array).erase(c)
	ev.append({"e": "play", "seat": seat, "card": c.duplicate(), "target": target, "fil": int(p["fil"])})

	match def["type"]:
		"creature":
			var slot: int = clampi(int(a.get("slot", 99)), 0, (p["board"] as Array).size())
			var u := _summon(st, seat, c["id"], slot, ev, true)
			_run(st, seat, def.get("on_print", []), {"target": target, "self": int(u["uid"])}, ev)
		"tool":
			_run(st, seat, def.get("effects", []), {"target": target, "self": -1}, ev)
		"upgrade":
			var u := unit_of(st, target)
			if not u.is_empty():
				var b: Dictionary = def["buff"]
				_buff(u, int(b["atk"]), int(b["hp"]), b.get("kw", []))
				(u["gear"] as Array).append(c["id"])
				ev.append({"e": "gear", "uid": int(u["uid"]), "id": c["id"], "unit": u.duplicate(true)})
	_resolve(st, ev)
	return ""


static func _attack(st: Dictionary, seat: int, a: Dictionary, ev: Array) -> String:
	var uid: int = int(a.get("unit", -1))
	var u := find_unit(st, uid)
	if u.is_empty() or int(u["seat"]) != seat:
		return "That is not your print."
	if int(u["jam"]) > 0:
		return "That print is jammed."
	if not can_attack(u):
		return "That print cannot attack right now."
	var target: String = str(a.get("target", ""))
	if not attack_targets(st, uid).has(target):
		if has_guard(st, 1 - seat):
			return "A Guard print is in the way."
		return "That is not a valid target."

	u["attacks"] = int(u["attacks"]) + 1
	ev.append({"e": "attack", "seat": seat, "uid": uid, "target": target})
	var t := unit_of(st, target)
	var counter: int = int(t["atk"]) if not t.is_empty() else 0
	var dealt: int = _damage(st, target, int(u["atk"]), ev)
	if counter > 0:
		_damage(st, "u%d" % uid, counter, ev)
	if dealt > 0 and (u["kw"] as Array).has("siphon"):
		_heal(st, "p%d" % seat, dealt, ev)
	_resolve(st, ev)
	return ""


static func _power(st: Dictionary, seat: int, a: Dictionary, ev: Array) -> String:
	var err := power_error(st, seat)
	if err != "":
		return err
	var p: Dictionary = st["players"][seat]
	var target: String = str(a.get("target", ""))
	var valid := power_targets(st, seat)
	if valid.is_empty():
		target = ""
	elif not valid.has(target):
		return "Choose a valid target."
	p["fil"] = int(p["fil"]) - GameData.POWER_COST
	p["power_used"] = true
	ev.append({"e": "power", "seat": seat, "target": target, "fil": int(p["fil"])})
	_run(st, seat, GameData.printer(p["printer"])["power"]["effects"], {"target": target, "self": -1}, ev)
	_resolve(st, ev)
	return ""


static func _end_turn(st: Dictionary, ev: Array) -> void:
	var seat: int = int(st["active"])
	for u in st["players"][seat]["board"]:
		if int(u["jam"]) > 0:
			u["jam"] = 0
			ev.append({"e": "unjam", "uid": int(u["uid"])})
	st["active"] = 1 - seat
	_start_turn(st, ev)


static func _start_turn(st: Dictionary, ev: Array) -> void:
	var seat: int = int(st["active"])
	var p: Dictionary = st["players"][seat]
	st["turn"] = int(st["turn"]) + 1
	p["max_fil"] = mini(GameData.MAX_FILAMENT, int(p["max_fil"]) + 1)
	p["fil"] = int(p["max_fil"])
	p["power_used"] = false
	for u in p["board"]:
		u["fresh"] = false
		u["attacks"] = 0
	ev.append({"e": "turn", "seat": seat, "turn": int(st["turn"]), "fil": int(p["fil"]), "max_fil": int(p["max_fil"])})
	_draw(st, seat, ev)
	_resolve(st, ev)


# ---------------------------------------------------------------- effects

static func _run(st: Dictionary, seat: int, effects: Array, ctx: Dictionary, ev: Array) -> void:
	for e in effects:
		if st["over"]:
			return
		var op: String = e["op"]
		var p: Dictionary = st["players"][seat]
		match op:
			"draw":
				for i in int(e["n"]):
					_draw(st, seat, ev)
			"filament":
				p["fil"] = mini(GameData.MAX_FILAMENT, int(p["fil"]) + int(e["n"]))
				ev.append({"e": "fil", "seat": seat, "fil": int(p["fil"]), "max_fil": int(p["max_fil"])})
			"armor":
				p["armor"] = int(p["armor"]) + int(e["n"])
				ev.append({"e": "armor", "seat": seat, "armor": int(p["armor"])})
			"summon":
				for i in int(e["n"]):
					if (p["board"] as Array).size() < GameData.MAX_BOARD:
						_summon(st, seat, e["card"], (p["board"] as Array).size(), ev, false)
			_:
				for ref in _refs(st, seat, str(e.get("to", "")), ctx):
					_run_on(st, seat, e, ref, ev)


static func _run_on(st: Dictionary, seat: int, e: Dictionary, ref: String, ev: Array) -> void:
	match e["op"]:
		"damage":
			_damage(st, ref, int(e["n"]), ev)
		"heal":
			_heal(st, ref, int(e["n"]), ev)
		"buff":
			var u := unit_of(st, ref)
			if not u.is_empty():
				_buff(u, int(e.get("atk", 0)), int(e.get("hp", 0)), e.get("kw", []))
				ev.append({"e": "buff", "uid": int(u["uid"]), "unit": u.duplicate(true)})
		"jam":
			var u := unit_of(st, ref)
			if not u.is_empty():
				u["jam"] = 1
				ev.append({"e": "jam", "uid": int(u["uid"])})
		"destroy":
			var u := unit_of(st, ref)
			if not u.is_empty():
				u["hp"] = 0
				u["doomed"] = true
				ev.append({"e": "destroy", "uid": int(u["uid"])})
		"bounce":
			var u := unit_of(st, ref)
			if not u.is_empty():
				var owner: int = int(u["seat"])
				(st["players"][owner]["board"] as Array).erase(u)
				ev.append({"e": "bounce", "uid": int(u["uid"]), "seat": owner})
				_give(st, owner, u["id"], ev)
		"copy":
			var u := unit_of(st, ref)
			var board: Array = st["players"][seat]["board"]
			if not u.is_empty() and board.size() < GameData.MAX_BOARD:
				var twin: Dictionary = u.duplicate(true)
				twin["uid"] = _next_uid(st)
				twin["seat"] = seat
				twin["fresh"] = true
				twin["attacks"] = 0
				twin["jam"] = 0
				board.insert(mini(board.find(u) + 1, board.size()), twin)
				ev.append({"e": "summon", "seat": seat, "unit": twin.duplicate(true), "slot": board.find(twin), "hand": false})


static func _refs(st: Dictionary, seat: int, to: String, ctx: Dictionary) -> Array:
	var foe: int = 1 - seat
	var out: Array = []
	match to:
		"target":
			if str(ctx.get("target", "")) != "":
				out.append(ctx["target"])
		"self":
			if int(ctx.get("self", -1)) >= 0:
				out.append("u%d" % int(ctx["self"]))
		"enemy_printer":
			out.append("p%d" % foe)
		"own_printer":
			out.append("p%d" % seat)
		"enemy_prints":
			for u in st["players"][foe]["board"]:
				out.append("u%d" % int(u["uid"]))
		"friendly_prints", "other_friendly_prints":
			for u in st["players"][seat]["board"]:
				if to == "friendly_prints" or int(u["uid"]) != int(ctx.get("self", -1)):
					out.append("u%d" % int(u["uid"]))
		"all_prints":
			for s in [seat, foe]:
				for u in st["players"][s]["board"]:
					out.append("u%d" % int(u["uid"]))
	return out


static func _buff(u: Dictionary, atk: int, hp: int, kws: Array) -> void:
	u["atk"] = int(u["atk"]) + atk
	u["hp"] = int(u["hp"]) + hp
	u["max_hp"] = int(u["max_hp"]) + hp
	for k in kws:
		if not (u["kw"] as Array).has(k):
			(u["kw"] as Array).append(k)


## Returns the damage that actually landed.
static func _damage(st: Dictionary, ref: String, n: int, ev: Array) -> int:
	if n <= 0:
		return 0
	if ref.begins_with("p"):
		var seat := seat_of(ref)
		var p: Dictionary = st["players"][seat]
		var soak: int = mini(int(p["armor"]), n)
		p["armor"] = int(p["armor"]) - soak
		p["hp"] = int(p["hp"]) - (n - soak)
		ev.append({"e": "damage", "target": ref, "n": n, "hp": int(p["hp"]), "armor": int(p["armor"])})
		return n
	var u := unit_of(st, ref)
	if u.is_empty():
		return 0
	if (u["kw"] as Array).has("brim"):
		(u["kw"] as Array).erase("brim")
		ev.append({"e": "damage", "target": ref, "n": 0, "hp": int(u["hp"]), "brim": true})
		return 0
	u["hp"] = int(u["hp"]) - n
	ev.append({"e": "damage", "target": ref, "n": n, "hp": int(u["hp"])})
	return n


static func _heal(st: Dictionary, ref: String, n: int, ev: Array) -> void:
	var who: Dictionary = st["players"][seat_of(ref)] if ref.begins_with("p") else unit_of(st, ref)
	if who.is_empty():
		return
	var gain: int = mini(n, int(who["max_hp"]) - int(who["hp"]))
	if gain <= 0:
		return
	who["hp"] = int(who["hp"]) + gain
	ev.append({"e": "heal", "target": ref, "n": gain, "hp": int(who["hp"])})


static func _summon(st: Dictionary, seat: int, card_id: String, slot: int, ev: Array, from_hand: bool) -> Dictionary:
	var def := GameData.card(card_id)
	var p: Dictionary = st["players"][seat]
	var u := {
		"uid": _next_uid(st), "id": card_id, "seat": seat,
		"atk": int(def["atk"]), "hp": int(def["hp"]), "max_hp": int(def["hp"]),
		"kw": (def.get("kw", []) as Array).duplicate(),
		"fresh": true, "attacks": 0, "jam": 0, "gear": [],
	}
	# Prints that share their Printer's element come out a little sturdier.
	if def.get("element", "") == GameData.printer(p["printer"])["element"]:
		u["hp"] += 1
		u["max_hp"] += 1
		u["attuned"] = true
	if from_hand and int(p["bed"]) > 0:
		u["atk"] += int(p["bed"])
		u["hp"] += int(p["bed"])
		u["max_hp"] += int(p["bed"])
		p["bed"] = 0
	(p["board"] as Array).insert(clampi(slot, 0, (p["board"] as Array).size()), u)
	ev.append({"e": "summon", "seat": seat, "unit": u.duplicate(true), "slot": (p["board"] as Array).find(u), "hand": from_hand})
	return u


static func _draw(st: Dictionary, seat: int, ev: Array) -> void:
	var p: Dictionary = st["players"][seat]
	var deck: Array = p["deck"]
	if deck.is_empty():
		p["fatigue"] = int(p["fatigue"]) + 1
		ev.append({"e": "fatigue", "seat": seat, "n": int(p["fatigue"])})
		_damage(st, "p%d" % seat, int(p["fatigue"]), ev)
		return
	_give(st, seat, deck.pop_back(), ev, true)


static func _give(st: Dictionary, seat: int, card_id: String, ev: Array, from_deck: bool = false) -> void:
	var p: Dictionary = st["players"][seat]
	if (p["hand"] as Array).size() >= GameData.MAX_HAND:
		ev.append({"e": "burn", "seat": seat, "id": card_id})
		return
	var c := {"uid": _next_uid(st), "id": card_id}
	(p["hand"] as Array).append(c)
	ev.append({"e": "draw", "seat": seat, "card": c.duplicate(), "deck": from_deck, "left": (p["deck"] as Array).size()})


## Removes dead prints (running Shatter effects) until the board is stable,
## then checks whether a Printer has been destroyed.
static func _resolve(st: Dictionary, ev: Array) -> void:
	for guard in 32:
		var dead: Array = []
		for s in [int(st["active"]), 1 - int(st["active"])]:
			for u in st["players"][s]["board"]:
				if int(u["hp"]) <= 0:
					dead.append(u)
		if dead.is_empty():
			break
		for u in dead:
			(st["players"][int(u["seat"])]["board"] as Array).erase(u)
			ev.append({"e": "death", "uid": int(u["uid"]), "seat": int(u["seat"])})
		for u in dead:
			_run(st, int(u["seat"]), GameData.card(u["id"]).get("shatter", []), {"target": "", "self": -1}, ev)
	var down0: bool = int(st["players"][0]["hp"]) <= 0
	var down1: bool = int(st["players"][1]["hp"]) <= 0
	if down0 and down1:
		_finish(st, -2, ev)
	elif down0:
		_finish(st, 1, ev)
	elif down1:
		_finish(st, 0, ev)


static func _finish(st: Dictionary, winner: int, ev: Array) -> void:
	if st["over"]:
		return
	st["over"] = true
	st["winner"] = winner
	ev.append({"e": "over", "winner": winner})


# -------------------------------------------------------------------- rng

static func _next_uid(st: Dictionary) -> int:
	var id: int = int(st["uid"])
	st["uid"] = id + 1
	return id


static func _rand(st: Dictionary, n: int) -> int:
	st["rng"] = (int(st["rng"]) * 1103515245 + 12345) & 0x7fffffff
	return (int(st["rng"]) >> 8) % maxi(n, 1)


static func _shuffle(st: Dictionary, list: Array) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := _rand(st, i + 1)
		var tmp = list[i]
		list[i] = list[j]
		list[j] = tmp


# ---------------------------------------------------------------- network

## A copy of the state that is safe to show `seat`: the other hand and both
## decks are hidden.
static func view_for(st: Dictionary, seat: int) -> Dictionary:
	var v: Dictionary = st.duplicate(true)
	v["rng"] = 0
	for s in 2:
		var p: Dictionary = v["players"][s]
		var hidden: Array = []
		for i in (p["deck"] as Array).size():
			hidden.append("?")
		p["deck"] = hidden
		if s != seat:
			for c in p["hand"]:
				c["id"] = "?"
	return v


static func redact_events(events: Array, seat: int) -> Array:
	var out: Array = []
	for e in events:
		if e["e"] == "draw" and int(e["seat"]) != seat and bool(e.get("deck", false)):
			var copy: Dictionary = e.duplicate(true)
			copy["card"]["id"] = "?"
			out.append(copy)
		else:
			out.append(e)
	return out
