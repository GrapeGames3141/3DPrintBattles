extends Node
## Autoload `Profile`: the player's local save (coins, cards, decks, printers,
## Printer mods, Maker Rank, campaign progress, settings). Stored as JSON in user://.

signal changed

const SAVE_VERSION := 2
## Save keys whose contents are free-form dictionaries (ids come from the save).
const FREE_KEYS := ["cards", "mods", "installed", "builds", "spares"]
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
		"tutorial_done": false,
		"starter": "",
		"coins": 0,
		"cards": {},
		"decks": decks,
		"active_deck": 0,
		"printers": [],
		"xp": 0,
		"mods": {},
		"installed": {},
		"builds": {},
		"spares": {},
		"card_mods": [],
		"paints": ["original", "sky", "rose", "lime"],
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
	var migrated := _migrate(parsed)
	_merge(data, parsed)
	_sanitize()
	if migrated:
		_auto_install()
		save()


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
		if FREE_KEYS.has(k):
			if from[k] is Dictionary:
				into[k] = from[k]
		elif into[k] is Dictionary and from[k] is Dictionary:
			_merge(into[k], from[k])
		elif typeof(into[k]) == typeof(from[k]) or (into[k] is int and from[k] is float):
			into[k] = from[k]


## Brings an older save up to date. Version 1 had four workshop upgrades; they
## become the matching Printer mods. Returns true if anything was converted.
func _migrate(parsed: Dictionary) -> bool:
	if int(parsed.get("version", 1)) >= SAVE_VERSION:
		return false
	var mods: Dictionary = {}
	var old: Dictionary = parsed.get("upgrades", {}) if parsed.get("upgrades") is Dictionary else {}
	for id in ["frame", "bed", "spool", "sorter"]:
		var level := clampi(int(old.get(id, 0)), 0, GameData.mod_max(id))
		if level > 0:
			mods[id] = level
	parsed["mods"] = mods
	parsed["version"] = SAVE_VERSION
	return true


## Puts every owned mod on every Printer that has room, in catalog order.
func _auto_install() -> void:
	for printer_id in data["printers"]:
		var list: Array = []
		for m in GameData.PRINTER_MODS:
			if list.size() < GameData.printer_slots(printer_id) and mod_level(m["id"]) > 0:
				list.append(m["id"])
		data["installed"][printer_id] = list


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
	data["xp"] = maxi(0, int(data["xp"]))
	var builds: Dictionary = {}
	for id in data["builds"]:
		if cards.has(str(id)) and data["builds"][id] is Dictionary:
			var clean: Dictionary = GameData.clean_builds([str(id)], {str(id): data["builds"][id]})
			if clean.has(str(id)):
				builds[str(id)] = clean[str(id)]
	data["builds"] = builds
	var spares: Dictionary = {}
	for id in data["spares"]:
		if cards.has(str(id)) and int(data["spares"][id]) > 0:
			spares[str(id)] = mini(int(data["spares"][id]), GameData.MAX_SPARES)
	data["spares"] = spares
	var card_mods: Array = []
	for id in data["card_mods"]:
		if not GameData.card_mod(str(id)).is_empty() and not card_mods.has(str(id)):
			card_mods.append(str(id))
	data["card_mods"] = card_mods
	var paints: Array = []
	for p in GameData.PAINTS:
		if (data["paints"] as Array).has(p["id"]) or int(p["price"]) == 0:
			paints.append(p["id"])
	data["paints"] = paints
	var mods: Dictionary = {}
	for k in data["mods"]:
		var level := clampi(int(data["mods"][k]), 0, GameData.mod_max(str(k)))
		if level > 0:
			mods[str(k)] = level
	data["mods"] = mods
	for k in data["packs"]:
		data["packs"][k] = maxi(0, int(data["packs"][k]))
	for k in data["stats"]:
		data["stats"][k] = int(data["stats"][k])
	var owned: Array = []
	for id in data["printers"]:
		if GameData.printer(str(id))["id"] == str(id) and not owned.has(str(id)):
			owned.append(str(id))
	data["printers"] = owned
	var installed: Dictionary = {}
	for printer_id in owned:
		var list: Array = []
		for id in (data["installed"].get(printer_id, []) as Array):
			if mod_level(str(id)) > 0 and not list.has(str(id)) and list.size() < GameData.printer_slots(printer_id):
				list.append(str(id))
		installed[printer_id] = list
	data["installed"] = installed
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


# -------------------------------------------------------------------- rank

## {"rank", "into", "need"} for the Maker Rank.
func rank() -> Dictionary:
	return GameData.rank_from_xp(int(data["xp"]))


func rank_level() -> int:
	return int(rank()["rank"])


## Adds Maker XP. Returns {"gained", "from", "to"} ranks.
func add_xp(amount: int) -> Dictionary:
	var before := rank_level()
	data["xp"] = int(data["xp"]) + maxi(amount, 0)
	return {"gained": amount, "from": before, "to": rank_level()}


## Testing tools (Settings): set the purse and the Maker XP outright.
const TEST_MAX_COINS := 9999999
const TEST_MAX_XP := 999999


func set_coins(amount: int) -> void:
	data["coins"] = clampi(amount, 0, TEST_MAX_COINS)
	save()


## Sets total Maker XP. Ranks follow from it, so lowering it lowers the rank.
func set_xp(amount: int) -> void:
	data["xp"] = clampi(amount, 0, TEST_MAX_XP)
	save()


# -------------------------------------------------------------- printer mods

func mod_level(id: String) -> int:
	return int(data["mods"].get(id, 0))


## Coins the next level of a mod costs, or -1 when it is at the top.
func mod_cost(id: String) -> int:
	var costs: Array = GameData.mod(id).get("costs", [])
	var lvl := mod_level(id)
	return int(costs[lvl]) if lvl < costs.size() else -1


## Maker Rank the next level of a mod needs, or 0 at the top.
func mod_rank(id: String) -> int:
	var ranks: Array = GameData.mod(id).get("ranks", [])
	var lvl := mod_level(id)
	return int(ranks[lvl]) if lvl < ranks.size() else 0


## Everything a crate could still give you: card mods you do not have and
## the next level of every Printer mod.
func _mod_pool() -> Array:
	var pool: Array = []
	for m in GameData.CARD_MODS:
		if not owns_card_mod(str(m["id"])):
			pool.append({"kind": "card", "id": str(m["id"]), "name": str(m["name"]), "rarity": str(m["rarity"]), "text": str(m["text"])})
	for m in GameData.PRINTER_MODS:
		if mod_level(str(m["id"])) < GameData.mod_max(str(m["id"])):
			pool.append({"kind": "printer", "id": str(m["id"]), "name": str(m["name"]), "rarity": str(m["rarity"]),
				"text": GameData.mod_text(str(m["id"]), mod_level(str(m["id"])) + 1)})
	return pool


## Gives one random mod, picked by rarity like a pack card, and returns it
## ({} when there is nothing left to find). Rank does not matter: a lucky find
## can be something you could not buy yet.
func award_random_mod(rng: RandomNumberGenerator = null) -> Dictionary:
	var pool := _mod_pool()
	if pool.is_empty():
		return {}
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var total := 0
	for e in pool:
		total += int(GameData.PACK_WEIGHTS[e["rarity"]])
	var roll := rng.randi_range(0, total - 1)
	var pick: Dictionary = pool[0]
	for e in pool:
		roll -= int(GameData.PACK_WEIGHTS[e["rarity"]])
		if roll < 0:
			pick = e
			break
	if pick["kind"] == "card":
		(data["card_mods"] as Array).append(pick["id"])
	else:
		data["mods"][pick["id"]] = mod_level(pick["id"]) + 1
	save()
	return pick


func buy_mod_crate(rng: RandomNumberGenerator = null) -> Dictionary:
	if coins() < GameData.MOD_CRATE_PRICE:
		return {"error": "Not enough Forge Coins."}
	if _mod_pool().is_empty():
		return {"error": "You already have every mod."}
	data["coins"] = coins() - GameData.MOD_CRATE_PRICE
	return award_random_mod(rng)


func buy_mod(id: String) -> String:
	var cost := mod_cost(id)
	if cost < 0:
		return "That mod is already at its top level."
	if rank_level() < mod_rank(id):
		return "Reach Maker Rank %d to buy that." % mod_rank(id)
	if coins() < cost:
		return "Not enough Forge Coins."
	data["coins"] = coins() - cost
	data["mods"][id] = mod_level(id) + 1
	save()
	return ""


func installed_mods(printer_id: String) -> Array:
	return data["installed"].get(printer_id, [])


## Puts a mod you own into a Printer's slot, or empties the slot with "".
func install_mod(printer_id: String, slot: int, mod_id: String) -> String:
	if not owns_printer(printer_id):
		return "You do not own that Printer."
	var list: Array = (data["installed"].get(printer_id, []) as Array).duplicate()
	if slot < 0 or slot >= GameData.printer_slots(printer_id):
		return "That Printer has no such slot."
	while list.size() <= slot:
		list.append("")
	if mod_id != "":
		if mod_level(mod_id) <= 0:
			return "You have not bought that mod yet."
		var at := list.find(mod_id)
		if at >= 0 and at != slot:
			list[at] = ""
		list[slot] = mod_id
	else:
		list[slot] = ""
	while not list.is_empty() and list.back() == "":
		list.pop_back()
	data["installed"][printer_id] = list
	save()
	return ""


## The mods a battle on this Printer gets: {mod id: level}, only what is installed.
func battle_mods(printer_id: String) -> Dictionary:
	var out: Dictionary = {}
	for id in installed_mods(printer_id):
		if str(id) != "" and mod_level(str(id)) > 0:
			out[str(id)] = mod_level(str(id))
	return GameData.clean_mods(printer_id, out)


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
	# Every deck starts on the Printer you picked; the others are not yours yet.
	for i in range(1, data["decks"].size()):
		data["decks"][i]["printer"] = printer_id
	data["active_deck"] = 0
	save()


# ------------------------------------------------------------------- decks

func deck(slot: int) -> Dictionary:
	var d: Dictionary = data["decks"][clampi(slot, 0, DECK_SLOTS - 1)]
	# A deck can only sit on a Printer you own.
	var owned: Array = data["printers"]
	if not owned.is_empty() and not owned.has(str(d.get("printer", ""))):
		d["printer"] = owned[0]
	return d


func active_deck() -> Dictionary:
	return deck(int(data["active_deck"]))


func set_active_deck(slot: int) -> void:
	data["active_deck"] = clampi(slot, 0, DECK_SLOTS - 1)
	save()


## If the battle deck is not playable but another deck is, switch to that one.
## (An older version let you pick an empty deck just by looking at it.)
func ensure_battle_deck() -> void:
	if deck_error(int(data["active_deck"])) == "":
		return
	for i in DECK_SLOTS:
		if deck_error(i) == "":
			data["active_deck"] = i
			save()
			return


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
		# A spare copy: a little coin, and a spare kept for the card's Blueprint.
		var refund: int = int(GameData.RARITIES[GameData.card(id)["rarity"]]["recycle"])
		data["coins"] = coins() + refund
		var kept := spares(id) < GameData.MAX_SPARES
		if kept:
			data["spares"][id] = spares(id) + 1
		return {"id": id, "new": false, "recycled": refund, "spare": kept}
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


# --------------------------------------------------------------- Blueprints

func spares(id: String) -> int:
	return int(data["spares"].get(id, 0))


## The card's Blueprint, with defaults filled in.
func build_of(id: String) -> Dictionary:
	var b := GameData.default_build()
	var saved: Dictionary = data["builds"].get(id, {})
	for k in b:
		if saved.has(k):
			b[k] = saved[k]
	return b


func _set_build(id: String, b: Dictionary) -> void:
	if int(b["tier"]) <= 1 and str(b["mod"]) == "" and str(b["paint"]) == "original":
		data["builds"].erase(id)
	else:
		data["builds"][id] = b


## "" if the card can go up a tier now, else why not.
func tier_error(id: String) -> String:
	if owned_count(id) <= 0:
		return "You do not own that card."
	var tier := int(build_of(id)["tier"])
	if tier >= GameData.MAX_TIER:
		return "Already Mk III."
	var next := tier + 1
	if rank_level() < GameData.TIER_RANK[next]:
		return "Reach Maker Rank %d for Mk %s." % [GameData.TIER_RANK[next], ["", "I", "II", "III"][next]]
	if spares(id) < GameData.TIER_SPARES[next]:
		return "Needs %d spare cop%s (you have %d)." % [GameData.TIER_SPARES[next], "y" if GameData.TIER_SPARES[next] == 1 else "ies", spares(id)]
	if coins() < GameData.tier_coins(id, next):
		return "Not enough Forge Coins."
	return ""


func upgrade_card(id: String) -> String:
	var err := tier_error(id)
	if err != "":
		return err
	var b := build_of(id)
	var next: int = int(b["tier"]) + 1
	data["coins"] = coins() - GameData.tier_coins(id, next)
	var left: int = spares(id) - int(GameData.TIER_SPARES[next])
	if left > 0:
		data["spares"][id] = left
	else:
		data["spares"].erase(id)
	b["tier"] = next
	_set_build(id, b)
	save()
	return ""


## Print an extra copy of a card to keep as a spare for its Blueprint.
func craft_spare(id: String) -> String:
	if owned_count(id) <= 0:
		return "You need the card itself first."
	if spares(id) >= GameData.MAX_SPARES:
		return "You are holding the most spares you can."
	var cost := craft_cost(id)
	if coins() < cost:
		return "Not enough Forge Coins."
	data["coins"] = coins() - cost
	data["spares"][id] = spares(id) + 1
	save()
	return ""


func owns_card_mod(id: String) -> bool:
	return (data["card_mods"] as Array).has(id)


func buy_card_mod(id: String) -> String:
	var m := GameData.card_mod(id)
	if m.is_empty():
		return "Unknown mod."
	if owns_card_mod(id):
		return "You already have that mod."
	if rank_level() < int(m["rank"]):
		return "Reach Maker Rank %d to unlock that." % int(m["rank"])
	if coins() < int(m["cost"]):
		return "Not enough Forge Coins."
	data["coins"] = coins() - int(m["cost"])
	(data["card_mods"] as Array).append(id)
	save()
	return ""


## Fits an unlocked mod onto a card (Mk II or higher), or "" to take it off.
func set_card_mod(id: String, mod_id: String) -> String:
	if owned_count(id) <= 0:
		return "You do not own that card."
	var b := build_of(id)
	if mod_id != "":
		if int(b["tier"]) < 2:
			return "Mods fit from Mk II."
		if not owns_card_mod(mod_id):
			return "Unlock that mod first."
		if not GameData.mod_fits(mod_id, id):
			return "That mod does not fit this card."
	b["mod"] = mod_id
	_set_build(id, b)
	save()
	return ""


func owns_paint(id: String) -> bool:
	return (data["paints"] as Array).has(id)


func buy_paint(id: String) -> String:
	var p := GameData.paint(id)
	if p["id"] != id:
		return "Unknown paint."
	if owns_paint(id):
		return "You already have that paint."
	if rank_level() < int(p["rank"]):
		return "Reach Maker Rank %d for that paint." % int(p["rank"])
	if coins() < int(p["price"]):
		return "Not enough Forge Coins."
	data["coins"] = coins() - int(p["price"])
	(data["paints"] as Array).append(id)
	save()
	return ""


func set_paint(id: String, paint_id: String) -> String:
	if owned_count(id) <= 0:
		return "You do not own that card."
	if not owns_paint(paint_id):
		return "Buy that paint first."
	var b := build_of(id)
	b["paint"] = paint_id
	_set_build(id, b)
	save()
	return ""


## The Blueprints for the cards in a deck, as a battle takes them.
func builds_for(deck_cards: Array) -> Dictionary:
	return GameData.clean_builds(deck_cards, data["builds"])


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
	if rank_level() < printer_rank(id):
		return "Reach Maker Rank %d to buy that Printer." % printer_rank(id)
	var price := printer_price(id)
	if coins() < price:
		return "Not enough Forge Coins."
	data["coins"] = coins() - price
	(data["printers"] as Array).append(id)
	data["installed"][id] = []
	save()
	return ""


func printer_price(id: String) -> int:
	var price: int = int(GameData.printer(id)["price"])
	# Starter Printers that were not picked cost a flat fee.
	return GameData.STARTER_PRINTER_PRICE if price == 0 else price


func printer_rank(id: String) -> int:
	var rank: int = int(GameData.printer(id).get("rank", 1))
	return GameData.STARTER_PRINTER_RANK if int(GameData.printer(id)["price"]) == 0 else rank


# ----------------------------------------------------------------- results

func rival_beaten(id: String) -> bool:
	return (data["rivals_beaten"] as Array).has(id)


## The next campaign rival the player has not beaten (or the last one).
func next_rival_index() -> int:
	for i in GameData.RIVALS.size():
		if not rival_beaten(GameData.RIVALS[i]["id"]):
			return i
	return GameData.RIVALS.size() - 1


## Records a finished battle and pays out. mode: "rival" | "quick" | "tutorial" | "lan" | "hotseat".
## `printer_id` is the Printer the player used (its Coin Sorter counts).
## Returns {"coins", "xp", "pack", "first_clear", "rank_from", "rank_to"}.
func record_battle(mode: String, won: bool, level: int = 1, rival_id: String = "", printer_id: String = "") -> Dictionary:
	var reward := {"coins": 0, "xp": 0, "pack": "", "first_clear": false, "rank_from": rank_level(), "rank_to": rank_level()}
	if mode == "hotseat":
		return reward
	var lv := clampi(level, 0, 2)
	if mode == "tutorial":
		# Practice: pays once, and never counts as a win or a loss.
		if won and not bool(data["tutorial_done"]):
			data["tutorial_done"] = true
			reward["coins"] = int(GameData.TUTORIAL["coins"])
			reward["xp"] = GameData.XP_TUTORIAL
			reward["first_clear"] = true
			data["coins"] = coins() + int(reward["coins"])
			add_xp(int(reward["xp"]))
			reward["rank_to"] = rank_level()
			save()
		return reward
	var sorter: int = int(GameData.mod("sorter")["per"]) * int(battle_mods(printer_id).get("sorter", 0)) if printer_id != "" else 0
	if won:
		data["stats"]["wins"] = int(data["stats"]["wins"]) + 1
		reward["coins"] = int(GameData.WIN_COINS[lv]) + sorter
		reward["xp"] = GameData.XP_PVP_WIN if mode == "lan" else int(GameData.XP_WIN[lv])
		if mode == "rival" and rival_id != "" and not rival_beaten(rival_id):
			var r := GameData.rival(rival_id)
			(data["rivals_beaten"] as Array).append(rival_id)
			reward["coins"] = int(r["coins"]) + sorter
			reward["xp"] = int(reward["xp"]) + GameData.XP_FIRST_CLEAR
			reward["pack"] = str(r["pack"])
			reward["first_clear"] = true
			data["packs"][reward["pack"]] = packs(reward["pack"]) + 1
	else:
		data["stats"]["losses"] = int(data["stats"]["losses"]) + 1
		reward["coins"] = GameData.LOSS_COINS
		reward["xp"] = GameData.XP_PVP_LOSS if mode == "lan" else int(GameData.XP_LOSS[lv])
	data["coins"] = coins() + int(reward["coins"])
	add_xp(int(reward["xp"]))
	reward["rank_to"] = rank_level()
	# A win sometimes turns up a random mod.
	if won and randf() < GameData.MOD_FIND_CHANCE:
		reward["found_mod"] = award_random_mod()
	save()
	return reward
