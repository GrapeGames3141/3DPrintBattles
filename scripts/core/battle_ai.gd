class_name BattleAI
extends RefCounted
## Computer opponent. It plays by the same rules as a player: it picks one
## legal action at a time by simulating each on a copy of the state and scoring
## the result. It never reads the opponent's hand or either deck order.
##
## level 0 Apprentice: makes loose plays and sometimes picks at random.
## level 1 Craftsman:  always takes the best-scoring single action.
## level 2 Master:     also searches the whole turn for a winning line.

const WIN := 100000.0


static func choose(st: Dictionary, seat: int, level: int) -> Dictionary:
	var actions := BattleEngine.legal_actions(st, seat)
	if actions.size() <= 1:
		return {"t": "end"}
	if level >= 2:
		var kill := _find_lethal(st, seat)
		if not kill.is_empty():
			return kill
		return _plan_turn(st, seat, level)

	var base := _score(st, seat, level)
	var best: Dictionary = {"t": "end"}
	var best_score := base + 0.05
	var good: Array = []
	for a in actions:
		if a["t"] == "end":
			continue
		var sim := _sim(st, seat, a)
		if sim.is_empty():
			continue
		var s := _score(sim, seat, level)
		if s > base + 0.05:
			good.append(a)
		if s > best_score:
			best_score = s
			best = a

	if level == 0:
		# Apprentices are distractible: they often take any reasonable-looking
		# play instead of the best one, and now and then stop early.
		var roll := _noise(st, 100)
		if roll < 12:
			return {"t": "end"}
		if roll < 60 and not good.is_empty():
			return good[_noise(st, 7919) % good.size()]
	return best


## Master: beam search over the rest of this turn, so it lines up print speed
## and attack order instead of grabbing the best single step.
static func _plan_turn(st: Dictionary, seat: int, level: int) -> Dictionary:
	var beam: Array = [{"st": st, "first": {}, "score": _score(st, seat, level)}]
	var best: Dictionary = beam[0]
	for depth in 6:
		var next: Array = []
		for node in beam:
			for a in BattleEngine.legal_actions(node["st"], seat):
				if a["t"] == "end":
					continue
				var sim := _sim(node["st"], seat, a)
				if sim.is_empty():
					continue
				next.append({"st": sim, "first": a if (node["first"] as Dictionary).is_empty() else node["first"],
					"score": _score(sim, seat, level)})
		if next.is_empty():
			break
		next.sort_custom(func(x, y): return x["score"] > y["score"])
		if next.size() > 4:
			next.resize(4)
		if float(next[0]["score"]) > float(best["score"]) + 0.05:
			best = next[0]
		beam = next
	return best["first"] if not (best["first"] as Dictionary).is_empty() else {"t": "end"}


static func _sim(st: Dictionary, seat: int, action: Dictionary) -> Dictionary:
	var copy: Dictionary = st.duplicate(true)
	# Scramble the copy's dice so the AI cannot foresee real random outcomes.
	copy["rng"] = (int(copy["rng"]) ^ 0x2545F491) & 0x7fffffff
	var res := BattleEngine.apply(copy, seat, action)
	return copy if res["ok"] else {}


## A cheap deterministic pick that varies from decision to decision.
static func _noise(st: Dictionary, n: int) -> int:
	var h: int = int(st["rng"]) * 31 + int(st["turn"]) * 977 + int(st["uid"]) * 131
	for p in st["players"]:
		h = h * 17 + int(p["hp"]) * 7 + (p["hand"] as Array).size() * 3 + int(p["flow"])
	return absi(h) % maxi(n, 1)


static func _unit_value(u: Dictionary) -> float:
	var atk := float(u["atk"])
	var hp := float(u["hp"])
	var kw: Array = u["kw"]
	var v := 2.0 + atk * 2.0 + hp * 1.6
	if kw.has("guard"):
		v += hp * 0.5
	if kw.has("brim"):
		v += 1.5 + atk
	if kw.has("siphon"):
		v += 2.0
	if kw.has("twin"):
		v += atk
	if int(u["jam"]) > 0:
		v -= atk
	return v


## What a card is worth once it is in play, before it has done anything.
static func _card_value(id: String) -> float:
	var def := GameData.card(id)
	if def.get("type", "") != "creature":
		return 2.5 + 2.4 * float(def.get("cost", 0))
	var atk := float(def["atk"])
	var hp := float(def["hp"])
	var kw: Array = def.get("kw", [])
	var v := 2.0 + atk * 2.0 + hp * 1.6
	if kw.has("guard"):
		v += hp * 0.5
	if kw.has("brim"):
		v += 1.5 + atk
	if kw.has("siphon"):
		v += 2.0
	if kw.has("twin"):
		v += atk
	if def.has("on_print"):
		v += 1.0 + 0.6 * float(def["cost"])
	return v


## A print on the Printer is worth more the closer it is to done. Starting one
## has to beat spending the same turn on something small, but not by much.
static func _job_value(job: Dictionary) -> float:
	if job.is_empty():
		return 0.0
	var done := float(job["paid"]) / maxf(float(job["cost"]), 1.0)
	return _card_value(job["id"]) * (0.45 + 0.5 * minf(done, 1.0))


static func _score(st: Dictionary, seat: int, level: int) -> float:
	if st["over"]:
		var w: int = int(st["winner"])
		if w == seat:
			return WIN
		return -WIN if w == 1 - seat else -WIN * 0.5
	var me: Dictionary = st["players"][seat]
	var foe: Dictionary = st["players"][1 - seat]
	var face_w: float = [0.6, 1.2, 1.3][clampi(level, 0, 2)]
	var s := 0.0
	var my_hp := float(int(me["hp"]) + int(me["armor"]))
	var foe_hp := float(int(foe["hp"]) + int(foe["armor"]))
	s += my_hp * 1.0
	if my_hp <= 10.0:
		s -= (10.0 - my_hp) * 1.5
	s -= foe_hp * face_w
	if foe_hp <= 10.0:
		s += (10.0 - foe_hp) * 0.8
	var foe_threat := 0.0
	var my_guard := false
	for u in me["board"]:
		s += _unit_value(u)
		if (u["kw"] as Array).has("guard"):
			my_guard = true
	for u in foe["board"]:
		s -= _unit_value(u) * 1.1
		if int(u["jam"]) == 0:
			foe_threat += float(u["atk"]) * (2.0 if (u["kw"] as Array).has("twin") else 1.0)
	for c in me["hand"]:
		s += 1.5 + 0.5 * float(GameData.card(c["id"]).get("cost", 0))
	s -= float((foe["hand"] as Array).size()) * 2.0
	s += _job_value(me["job"]) - _job_value(foe["job"]) * 1.05
	# Filament only starts to feel scarce when the spool is nearly empty.
	s += minf(float(me["spool"]), 12.0) * 0.35
	if level >= 1 and not my_guard and foe_threat >= my_hp:
		s -= 40.0
	return s


## Depth-first search of this turn's actions for a line that destroys the
## enemy Printer. Returns the first action of that line, or {}.
static func _find_lethal(st: Dictionary, seat: int) -> Dictionary:
	var foe: Dictionary = st["players"][1 - seat]
	var reach := 0
	for u in st["players"][seat]["board"]:
		reach += int(u["atk"]) * BattleEngine.max_attacks(u)
	# Quick reject: nowhere near enough damage on board plus burn in hand.
	if reach + int(st["players"][seat]["flow"]) * 3 + 6 < int(foe["hp"]) + int(foe["armor"]):
		return {}
	var budget := [500]
	return _lethal_dfs(st, seat, 0, budget)


static func _lethal_dfs(st: Dictionary, seat: int, depth: int, budget: Array) -> Dictionary:
	if depth >= 9:
		return {}
	for a in BattleEngine.legal_actions(st, seat):
		if a["t"] == "end":
			continue
		if budget[0] <= 0:
			return {}
		budget[0] -= 1
		var sim := _sim(st, seat, a)
		if sim.is_empty():
			continue
		if sim["over"]:
			if int(sim["winner"]) == seat:
				return a
			continue
		# Only follow lines that keep pressure on: damage dealt or board grown.
		if not _is_pressure(st, sim, seat):
			continue
		if not _lethal_dfs(sim, seat, depth + 1, budget).is_empty():
			return a
	return {}


static func _is_pressure(before: Dictionary, after: Dictionary, seat: int) -> bool:
	var b: Dictionary = before["players"][1 - seat]
	var a: Dictionary = after["players"][1 - seat]
	if int(a["hp"]) + int(a["armor"]) < int(b["hp"]) + int(b["armor"]):
		return true
	if (a["board"] as Array).size() < (b["board"] as Array).size():
		return true
	var atk_b := 0
	var atk_a := 0
	for u in before["players"][seat]["board"]:
		if BattleEngine.can_attack(u):
			atk_b += int(u["atk"])
	for u in after["players"][seat]["board"]:
		if BattleEngine.can_attack(u):
			atk_a += int(u["atk"])
	return atk_a > atk_b
