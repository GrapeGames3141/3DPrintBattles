class_name DeckInfo
extends RefCounted
## Reads a deck and says what it is: an automatic name like "Fire Rush", its
## cost curve, and a few counts. Nothing here is typed by the player, so every
## deck still has a name without any free text.


static func analyse(cards: Array, printer_id := "") -> Dictionary:
	var info := {"count": cards.size(), "creatures": 0, "tools": 0, "upgrades": 0, "avg_cost": 0.0,
		"curve": [0, 0, 0, 0, 0, 0, 0, 0], "keywords": {}, "element": "", "style": "", "name": "Empty deck"}
	if cards.is_empty():
		return info
	var elements := {}
	var total := 0
	var damage_cards := 0
	var engine_cards := 0
	for id in cards:
		var def: Dictionary = GameData.card(str(id))
		if def.is_empty():
			continue
		var cost := int(def["cost"])
		total += cost
		info["curve"][clampi(cost, 0, 7)] += 1
		match str(def["type"]):
			"creature":
				info["creatures"] += 1
				elements[def["element"]] = int(elements.get(def["element"], 0)) + 1
			"tool":
				info["tools"] += 1
			"upgrade":
				info["upgrades"] += 1
		for k in def.get("kw", []):
			info["keywords"][k] = int(info["keywords"].get(k, 0)) + 1
		for list in [def.get("effects", []), def.get("on_print", [])]:
			for e in list:
				var op := str(e.get("op", ""))
				if op in ["damage", "heat", "destroy"]:
					damage_cards += 1
				elif op in ["draw", "spool", "filament"]:
					engine_cards += 1
	info["avg_cost"] = float(total) / float(cards.size())
	# The deck's element: the one most prints share, falling back to the Printer's.
	var best := ""
	var best_n := 0
	for el in elements:
		if int(elements[el]) > best_n or (int(elements[el]) == best_n and str(el) < best):
			best = str(el)
			best_n = int(elements[el])
	if best == "" and printer_id != "":
		best = str(GameData.printer(printer_id).get("element", ""))
	var focused: bool = best_n * 100 >= maxi(1, int(info["creatures"])) * 40
	info["element"] = best if focused or int(info["creatures"]) == 0 else "Mixed"
	var kw: Dictionary = info["keywords"]
	var fast := int(kw.get("rush", 0)) + int(kw.get("twin", 0))
	var wall := int(kw.get("guard", 0)) + int(kw.get("brim", 0))
	var avg: float = info["avg_cost"]
	var style := "Midrange"
	if avg <= 2.6 and int(info["creatures"]) >= 13:
		style = "Swarm"
	elif fast >= 4 and avg <= 3.6:
		style = "Rush"
	elif avg >= 4.8:
		style = "Heavy"
	elif wall >= 5:
		style = "Wall"
	elif avg >= 4.2:
		style = "Heavy"
	elif damage_cards >= 5:
		style = "Burn"
	elif int(kw.get("thief", 0)) >= 3:
		style = "Thieves"
	elif int(kw.get("scorch", 0)) >= 3:
		style = "Heat"
	elif engine_cards >= 5:
		style = "Engine"
	info["style"] = style
	info["name"] = "%s %s" % [info["element"], style] if cards.size() >= 10 else "Unfinished deck"
	return info
