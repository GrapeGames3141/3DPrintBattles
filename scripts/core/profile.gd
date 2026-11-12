extends Node
## Autoload `Profile`: the player's local save (coins, cards, decks, printers,
## workshop upgrades, campaign progress, settings). Stored as JSON in user://.

signal changed

const SAVE_VERSION := 1
const DECK_SLOTS := 3

var path := "user://printforge_profile.json"
var data: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	# Tests and screenshot tours point this at a throwaway file.
	var override := OS.get_environment("PRINTFORGE_PROFILE")
	if override != "":
		path = "user://%s.json" % override.validate_filename()
	_rng.randomize()
	load_profile()


static func fresh() -> Dictionary:
	var decks: Array = []
	for i in DECK_SLOTS:
		decks.append({"cards": [], "printer": "ember_forge"})
	return {
		"version": SAVE_VERSION,
		"started": false,
		"starter": "",
		"coins": 0,
		"cards": {},
		"decks": decks,
		"active_deck": 0,
		"printers": [],
		"upgrades": {"frame": 0, "bed": 0, "spool": 0, "sorter": 0},
		"packs": {"standard": 0, "premium": 0},
		"rivals_beaten": [],
		"stats": {"wins": 0, "losses": 0, "packs_opened": 0},
		"settings": {"music": 0.5, "sfx": 0.8, "fullscreen": false},
	}


func load_profile() -> void:
	data = fresh()
	if not FileAccess.file_exists(path):
		return
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary:
		push_warning("Profile at %s could not be read; starting fresh." % path)
		return
	_merge(data, parsed)
	_sanitize()


func save() -> void:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write profile: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path))
	changed.emit()


func reset() -> void:
	data = fresh()
	save()


## Copies known keys from a loaded save over the defaults, so older or partial
## saves keep working when new fields are added.
func _merge(into: Dictionary, from: Dictionary) -> void:
	for k in into:
		if not from.has(k):
			continue
		if into[k] is Dictionary and from[k] is Dictionary and k != "cards":
			_merge(into[k], from[k])
		elif typeof(into[k]) == typeof(from[k]) or (into[k] is int and from[k] is float):
			into[k] = from[k]
	if from.get("cards") is Dictionary:
		into["cards"] = from["cards"]


## JSON turns every number into a float and may carry stale ids; put it right.
func _sanitize() -> void:
	data["coins"] = maxi(0, int(data["coins"]))
	data["active_deck"] = clampi(int(data["active_deck"]), 0, DECK_SLOTS - 1)
	var cards: Dictionary = {}
	for id in data["cards"]:
		var def := GameData.card(str(id))
		if not def.is_empty() and not def.get("token", false) and int(data["cards"][id]) > 0:
			cards[str(id)] = mini(int(data["cards"][id]), GameData.max_copies(str(id)))
	data["cards"] = cards
	for k in data["upgrades"]:
		var u := GameData.upgrade(k)
		data["upgrades"][k] = clampi(int(data["upgrades"][k]), 0, (u.get("costs", []) as Array).size())
	for k in data["packs"]:
		data["packs"][k] = maxi(0, int(data["packs"][k]))
	for k in data["stats"]:
		data["stats"][k] = int(data["stats"][k])
	var owned: Array = []
	for id in data["printers"]:
		if GameData.printer(str(id))["id"] == str(id) and not owned.has(str(id)):
			owned.append(str(id))
	data["printers"] = owned
	var decks: Array = data["decks"]
	while decks.size() < DECK_SLOTS:
		decks.append({"cards": [], "printer": "ember_forge"})
	decks.resize(DECK_SLOTS)
	for d in decks:
		var list: Array = []
		for id in d.get("cards", []):
			if owned_count(str(id)) > 0:
				list.append(str(id))
		d["cards"] = list
		if not owned.has(str(d.get("printer", ""))):
			d["printer"] = owned[0] if not owned.is_empty() else "ember_forge"


# ------------------------------------------------------------------ basics

func started() -> bool:
	return bool(data["started"])


func coins() -> int:
	return int(data["coins"])


func owned_count(id: String) -> int:
	return int(data["cards"].get(id, 0))


func owns_printer(id: String) -> bool:
	return (data["printers"] as Array).has(id)


func upgrade_level(id: String) -> int:
	return int(data["upgrades"].get(id, 0))


func battle_upgrades() -> Dictionary:
	return {"frame": upgrade_level("frame"), "bed": upgrade_level("bed"), "spool": upgrade_level("spool")}


func packs(kind: String) -> int:
	return int(data["packs"].get(kind, 0))


func total_packs() -> int:
	return packs("standard") + packs("premium")


func setting(key: String) -> Variant:
	return data["settings"].get(key)


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	save()


func collection_progress() -> Vector2i:
	var have := 0
	var total := 0
	for c in GameData.collectible():
		total += 1
		if owned_count(c["id"]) > 0:
			have += 1
	return Vector2i(have, total)


# ----------------------------------------------------------------- starter

func choose_starter(creature_id: String) -> void:
	if started() or not GameData.STARTER_PRINTER.has(creature_id):
		return
	data["started"] = true
	data["starter"] = creature_id
	data["coins"] = GameData.STARTER_COINS
	data["packs"]["standard"] = GameData.STARTER_PACKS
	var printer_id: String = GameData.STARTER_PRINTER[creature_id]
	data["printers"] = [printer_id]
	for id in GameData.STARTER_DECK:
		data["cards"][id] = int(GameData.STARTER_DECK[id])
	for id in GameData.STARTER_EXTRA:
		data["cards"][id] = mini(owned_count(id) + int(GameData.STARTER_EXTRA[id]), GameData.max_copies(id))
	data["decks"][0] = {"cards": GameData.expand(GameData.STARTER_DECK), "printer": printer_id}
	data["active_deck"] = 0
	save()


# ------------------------------------------------------------------- decks

func deck(slot: int) -> Dictionary:
	return data["decks"][clampi(slot, 0, DECK_SLOTS - 1)]


func active_deck() -> Dictionary:
	return deck(int(data["active_deck"]))


func set_active_deck(slot: int) -> void:
	data["active_deck"] = clampi(slot, 0, DECK_SLOTS - 1)
	save()


func deck_error(slot: int) -> String:
	var d := deck(slot)
	var err := GameData.deck_error(d["cards"])
	if err != "":
		return err
	var counts := GameData.count_cards(d["cards"])
	for id in counts:
		if int(counts[id]) > owned_count(id):
			return "You do not own enough copies of %s." % GameData.card(id)["name"]
	if not owns_printer(d["printer"]):
		return "Pick a Printer you own for this deck."
	return ""


## Adds a card to a deck if the rules allow it. Returns "" or the reason.
func deck_add(slot: int, id: String) -> String:
	var list: Array = deck(slot)["cards"]
	if list.size() >= GameData.DECK_SIZE:
		return "This deck is full."
	var have := list.count(id)
	if have >= owned_count(id):
		return "You have no more copies of that card."
	if have >= GameData.max_copies(id):
		return "A deck can hold only %d of that card." % GameData.max_copies(id)
	list.append(id)
	save()
	return ""


func deck_remove(slot: int, id: String) -> void:
	var list: Array = deck(slot)["cards"]
	var i := list.find(id)
	if i >= 0:
		list.remove_at(i)
		save()


func deck_set_printer(slot: int, printer_id: String) -> void:
	if owns_printer(printer_id):
		deck(slot)["printer"] = printer_id
		save()


func deck_clear(slot: int) -> void:
	deck(slot)["cards"] = []
	save()


## Fills the rest of a deck with the best cards the player owns, on a curve.
func deck_autofill(slot: int) -> void:
	var list: Array = deck(slot)["cards"]
	var element: String = GameData.printer(deck(slot)["printer"])["element"]
	var pool: Array = []
	for c in GameData.collectible():
		for i in owned_count(c["id"]) - list.count(c["id"]):
			pool.append(c)
	# Prefer prints, cheap cards, and the Printer's own element.
	pool.sort_custom(func(a, b): return _fill_score(a, element) > _fill_score(b, element))
	for c in pool:
		if list.size() >= GameData.DECK_SIZE:
			break
		list.append(c["id"])
	save()


func _fill_score(c: Dictionary, element: String) -> float:
	var s := float(GameData.RARITY_ORDER.find(c["rarity"])) * 1.5
	if c["type"] == "creature":
		s += 4.0
		if c.get("element", "") == element:
			s += 1.5
	s -= absf(float(c["cost"]) - 3.0) * 0.8
	return s


# ------------------------------------------------------------- collection

## Adds one copy. Extra copies past the deck limit are recycled into coins.
## Returns {"id", "new": bool, "recycled": int}.
func add_card(id: String) -> Dictionary:
	var have := owned_count(id)
	if have >= GameData.max_copies(id):
		var refund: int = int(GameData.RARITIES[GameData.card(id)["rarity"]]["recycle"])
		data["coins"] = coins() + refund
		return {"id": id, "new": false, "recycled": refund}
	data["cards"][id] = have + 1
	return {"id": id, "new": have == 0, "recycled": 0}


func craft_cost(id: String) -> int:
	return int(GameData.RARITIES[GameData.card(id)["rarity"]]["craft"])


## Print one copy of a card for coins. Returns "" or the reason it failed.
func craft(id: String) -> String:
	if owned_count(id) >= GameData.max_copies(id):
		return "You already own the most copies a deck can hold."
	var cost := craft_cost(id)
	if coins() < cost:
		return "Not enough Forge Coins."
	data["coins"] = coins() - cost
	data["cards"][id] = owned_count(id) + 1
	save()
	return ""


# ------------------------------------------------------------------- packs

func buy_pack(kind: String) -> String:
	var def: Dictionary = GameData.PACKS.get(kind, {})
	if def.is_empty():
		return "Unknown pack."
	if coins() < int(def["price"]):
		return "Not enough Forge Coins."
	data["coins"] = coins() - int(def["price"])
	data["packs"][kind] = packs(kind) + 1
	save()
	return ""


func _pick_weighted(weights: Dictionary) -> String:
	var total := 0
	for k in weights:
		total += int(weights[k])
	var roll := _rng.randi_range(1, total)
	for k in weights:
		roll -= int(weights[k])
		if roll <= 0:
			return k
	return weights.keys()[0]


func _random_of_rarity(rarity: String) -> String:
	var pool: Array = []
	for c in GameData.collectible():
		if c["rarity"] == rarity:
			pool.append(c["id"])
	return pool[_rng.randi_range(0, pool.size() - 1)]


## Opens one owned pack. Returns the cards as [{"id", "new", "recycled"}].
func open_pack(kind: String) -> Array:
	if packs(kind) <= 0:
		return []
	var def: Dictionary = GameData.PACKS[kind]
	data["packs"][kind] = packs(kind) - 1
	data["stats"]["packs_opened"] = int(data["stats"]["packs_opened"]) + 1
	var floor_rank: int = GameData.RARITY_ORDER.find(def["guarantee"])
	var rolled: Array = []
	var best := 0
	for i in int(def["size"]):
		var r := _pick_weighted(GameData.PACK_WEIGHTS)
		best = maxi(best, GameData.RARITY_ORDER.find(r))
		rolled.append(r)
	if best < floor_rank:
		rolled[rolled.size() - 1] = _pick_weighted(GameData.PACK_GUARANTEE_WEIGHTS[def["guarantee"]])
	var out: Array = []
	for r in rolled:
		out.append(add_card(_random_of_rarity(r)))
	save()
	return out


# ---------------------------------------------------------------- workshop

func buy_printer(id: String) -> String:
	if owns_printer(id):
		return "You already own that Printer."
	var price: int = int(GameData.printer(id)["price"])
	# Starter printers that were not picked cost a flat fee.
	if price == 0:
		price = 300
	if coins() < price:
		return "Not enough Forge Coins."
	data["coins"] = coins() - price
	(data["printers"] as Array).append(id)
	save()
	return ""


func printer_price(id: String) -> int:
	var price: int = int(GameData.printer(id)["price"])
	return 300 if price == 0 else price


func upgrade_cost(id: String) -> int:
	var costs: Array = GameData.upgrade(id).get("costs", [])
	var lvl := upgrade_level(id)
	return int(costs[lvl]) if lvl < costs.size() else -1


func buy_upgrade(id: String) -> String:
	var cost := upgrade_cost(id)
	if cost < 0:
		return "That upgrade is already at its top level."
	if coins() < cost:
		return "Not enough Forge Coins."
	data["coins"] = coins() - cost
	data["upgrades"][id] = upgrade_level(id) + 1
	save()
	return ""


# ----------------------------------------------------------------- results

func rival_beaten(id: String) -> bool:
	return (data["rivals_beaten"] as Array).has(id)


## The next campaign rival the player has not beaten (or the last one).
func next_rival_index() -> int:
	for i in GameData.RIVALS.size():
		if not rival_beaten(GameData.RIVALS[i]["id"]):
			return i
	return GameData.RIVALS.size() - 1


## Records a finished battle and pays out. mode: "rival" | "quick" | "lan" | "hotseat".
## Returns {"coins": int, "pack": String, "first_clear": bool}.
func record_battle(mode: String, won: bool, level: int = 1, rival_id: String = "") -> Dictionary:
	var reward := {"coins": 0, "pack": "", "first_clear": false}
	if mode == "hotseat":
		return reward
	if won:
		data["stats"]["wins"] = int(data["stats"]["wins"]) + 1
		reward["coins"] = int(GameData.WIN_COINS[clampi(level, 0, 2)]) + 5 * upgrade_level("sorter")
		if mode == "rival" and rival_id != "" and not rival_beaten(rival_id):
			var r := GameData.rival(rival_id)
			(data["rivals_beaten"] as Array).append(rival_id)
			reward["coins"] = int(r["coins"]) + 5 * upgrade_level("sorter")
			reward["pack"] = str(r["pack"])
			reward["first_clear"] = true
			data["packs"][reward["pack"]] = packs(reward["pack"]) + 1
	else:
		data["stats"]["losses"] = int(data["stats"]["losses"]) + 1
		reward["coins"] = GameData.LOSS_COINS
	data["coins"] = coins() + int(reward["coins"])
	save()
	return reward
