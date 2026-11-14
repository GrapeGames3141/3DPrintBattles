class_name Ladder
extends RefCounted
## A computer opponent built to sit near a given rating: a deck of its own
## (rarer cards as the rating climbs), a Printer, a smarter AI and higher
## Blueprint tiers. This is who ranked play pairs you with when nobody else is
## waiting, and it is how ranked works with no server at all.


## `tune` is the strength of your own Printer mods (GameData.tune): the
## opponent's Printer is fitted with random mods worth the same, so upgrading
## your machine never makes ranked matches lopsided.
static func opponent(rating: int, seed_v: int, tune := 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var opp_rating := maxi(Rating.FLOOR, rating + rng.randi_range(-60, 60))
	var printer: Dictionary = GameData.PRINTERS[rng.randi() % GameData.PRINTERS.size()]
	var deck := build_deck(rng, str(printer["element"]), opp_rating)
	var creatures: Array = []
	for id in deck:
		if GameData.card(id)["type"] == "creature":
			creatures.append(id)
	var mods := build_mods(rng, tune)
	return {
		"name": PlayerIdentity.random_name(rng), "rating": opp_rating, "printer": str(printer["id"]), "deck": deck,
		"mods": mods, "tune": GameData.tune(mods),
		"level": 1 if opp_rating < 1250 else 2,
		"tier": 1 if opp_rating < 1100 else (2 if opp_rating < 1500 else 3),
		"hp_bonus": clampi(roundi(float(opp_rating - 1000) / 150.0), -3, 3),
		"avatar": str(creatures[rng.randi() % creatures.size()]) if not creatures.is_empty() else "",
	}


## Random Printer mods worth at most `budget` Tune, each one only once what it
## needs is in. Levels rise as the budget allows, so a big budget gets upgraded mods.
static func build_mods(rng: RandomNumberGenerator, budget: int) -> Dictionary:
	var mods: Dictionary = {}
	var spent := 0
	var guard := 0
	while guard < 400:
		guard += 1
		var options: Array = []
		for m in GameData.PRINTER_MODS:
			var id := str(m["id"])
			var lvl := int(mods.get(id, 0))
			var pts := int(GameData.MOD_TUNE_POINTS[m["rarity"]])
			if lvl >= GameData.mod_max_level(id) or spent + pts > budget:
				continue
			if lvl == 0 and not GameData.missing_requirements(id, mods.keys()).is_empty():
				continue
			options.append(id)
		if options.is_empty():
			break
		var pick: String = options[rng.randi() % options.size()]
		mods[pick] = int(mods.get(pick, 0)) + 1
		spent += int(GameData.MOD_TUNE_POINTS[GameData.mod(pick)["rarity"]])
	return mods


## A legal 20-card deck: mostly prints of the Printer's element, a few tools and
## equipment, and fewer big cards the lower the rating.
static func build_deck(rng: RandomNumberGenerator, element: String, rating: int) -> Array:
	var allowed := ["common", "uncommon"]
	if rating >= 900:
		allowed.append("rare")
	if rating >= 1200:
		allowed.append("epic")
	if rating >= 1500:
		allowed.append("legendary")
	var big_cap := 1 if rating < 1200 else (2 if rating < 1500 else 4)
	var creatures: Array = []
	var others: Array = []
	for c in GameData.collectible():
		if not allowed.has(str(c["rarity"])):
			continue
		if c["type"] == "creature":
			creatures.append(c)
		else:
			others.append(c)
	var deck: Array = []
	var counts := {}
	var big := 0
	_fill(rng, deck, counts, creatures, 13, element, big_cap, big)
	_fill(rng, deck, counts, others, GameData.DECK_SIZE, "", big_cap, 99)
	# A thin pool (very low rating) can leave gaps: top up from anything allowed.
	var guard := 0
	while deck.size() < GameData.DECK_SIZE and guard < 500:
		guard += 1
		var c: Dictionary = creatures[rng.randi() % creatures.size()]
		if int(counts.get(c["id"], 0)) < GameData.max_copies(str(c["id"])):
			counts[c["id"]] = int(counts.get(c["id"], 0)) + 1
			deck.append(str(c["id"]))
	return deck


static func _fill(rng: RandomNumberGenerator, deck: Array, counts: Dictionary, pool: Array, target: int, element: String, big_cap: int, big_used: int) -> void:
	var guard := 0
	var big := big_used
	while deck.size() < target and guard < 3000:
		guard += 1
		var c: Dictionary = pool[rng.randi() % pool.size()]
		var id := str(c["id"])
		# Prefer the Printer's own element: other elements are skipped most of the time.
		if element != "" and str(c.get("element", element)) != element and rng.randf() < 0.7:
			continue
		if int(counts.get(id, 0)) >= GameData.max_copies(id):
			continue
		var is_big: bool = int(c["cost"]) >= 6
		if is_big and big >= big_cap:
			continue
		if is_big:
			big += 1
		counts[id] = int(counts.get(id, 0)) + 1
		deck.append(id)
