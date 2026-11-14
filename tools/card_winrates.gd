extends SceneTree
## Card balance probe: plays computer-vs-computer games with random legal decks
## and reports how often each card's deck wins. A card well above or below 50%
## over many games is probably over- or under-powered.
##
##   godot --headless --path . -s tools/card_winrates.gd -- <games> [min_games]

func _initialize() -> void:
	var a := Array(OS.get_cmdline_user_args())
	var games := int(a[0]) if a.size() > 0 else 600
	var min_games := int(a[1]) if a.size() > 1 else 40
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	var pool: Array = []
	for c in GameData.collectible():
		pool.append(str(c["id"]))
	var printers: Array = []
	for p in GameData.PRINTERS:
		printers.append(str(p["id"]))
	var seen := {}
	var won := {}
	for g in games:
		var decks: Array = []
		var pr: Array = []
		for seat in 2:
			decks.append(_random_deck(rng, pool))
			pr.append(printers[rng.randi() % printers.size()])
		var st := BattleEngine.new_game({"seed": 7000 + g * 31, "players": [
			{"printer": pr[0], "deck": decks[0], "builds": GameData.uniform_builds(decks[0], 1)},
			{"printer": pr[1], "deck": decks[1], "builds": GameData.uniform_builds(decks[1], 1)}]})
		var steps := 0
		while not st["over"] and steps < 5000:
			steps += 1
			var seat: int = int(st["active"])
			BattleEngine.apply(st, seat, BattleAI.choose(st, seat, 2))
		var winner := int(st["winner"])
		for seat in 2:
			for id in _unique(decks[seat]):
				seen[id] = int(seen.get(id, 0)) + 1
				if winner == seat:
					won[id] = int(won.get(id, 0)) + 1
	var rows: Array = []
	for id in seen:
		if int(seen[id]) >= min_games:
			var rate := float(int(won.get(id, 0))) / float(seen[id])
			rows.append({"id": id, "n": int(seen[id]), "rate": rate})
	rows.sort_custom(func(x, y): return x["rate"] > y["rate"])
	print("games %d, cards with >= %d games: %d" % [games, min_games, rows.size()])
	for r in rows:
		var c := GameData.card(r["id"])
		print("%5.1f%%  n=%-4d  %-10s %-9s cost %d  %s" % [r["rate"] * 100.0, r["n"], c["type"], c["rarity"], int(c["cost"]), c["id"]])
	quit()


func _unique(deck: Array) -> Array:
	var u := {}
	for id in deck:
		u[id] = true
	return u.keys()


func _random_deck(rng: RandomNumberGenerator, pool: Array) -> Array:
	var deck: Array = []
	var counts := {}
	var guard := 0
	while deck.size() < GameData.DECK_SIZE and guard < 2000:
		guard += 1
		var id: String = pool[rng.randi() % pool.size()]
		if int(counts.get(id, 0)) >= GameData.max_copies(id):
			continue
		counts[id] = int(counts.get(id, 0)) + 1
		deck.append(id)
	return deck
