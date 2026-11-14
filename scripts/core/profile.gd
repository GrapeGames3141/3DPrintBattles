extends Node
## Autoload `Profile`: the player's local save (coins, cards, decks, printers,
## Printer mods, Maker Rank, campaign progress, settings). Stored as JSON in user://.

signal changed

const SAVE_VERSION := 3
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
		decks.append({"cards": [], "printer": "ember_forge", "sleeve": "forge"})
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
		"player": PlayerIdentity.fresh_player(),
		"settings": {"music": 0.5, "sfx": 0.8, "fullscreen": false},
	}


## The game used to be called PrintForge Legends, and Godot keeps saves in a
## folder named after the game. Copy the old save across the first time.
func _import_old_save() -> void:
	if OS.get_environment("PRINTFORGE_PROFILE") != "" or OS.has_feature("mobile"):
		return
	var root := OS.get_data_dir().path_join("Godot" if OS.get_name() in ["Windows", "macOS"] else "godot").path_join("app_userdata")
	var old := root.path_join("PrintForge Legends").path_join("printforge_profile.json")
	if not FileAccess.file_exists(old):
		return
	var text := FileAccess.get_file_as_string(old)
	if not JSON.parse_string(text) is Dictionary:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()


func load_profile() -> void:
	data = fresh()
	if not FileAccess.file_exists(path):
		_import_old_save()
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


## Coins paid for the higher levels Printer mods used to have. Mods are one
## purchase now, so a save that had level 2 or 3 gets those coins back.
const LEGACY_LEVEL_COSTS := {
	"stepper": [3200], "spool": [700, 1500], "frame": [800, 1800], "bed": [900, 2000],
	"enclosure": [1300, 2800], "sensor": [2200], "preheater": [1600], "sorter": [500, 1100],
	"cooling_duct": [1500], "self_cleaning": [1800], "spool_feeder": [2600], "capacitor_bank": [2000],
	"failsafe": [4500], "plating": [4000], "thermal_mass": [5000], "prehensile_gantry": [5200],
}


## Brings an older save up to date. Version 1 had four workshop upgrades; they
## become the matching Printer mods. Version 2 had mod levels and slots: now a
## mod is bought once, and every mod you own is fitted to every Printer.
## Returns true if anything was converted.
func _migrate(parsed: Dictionary) -> bool:
	var version := int(parsed.get("version", 1))
	if version >= SAVE_VERSION:
		return false
	var mods: Dictionary = {}
	if version < 2:
		var old: Dictionary = parsed.get("upgrades", {}) if parsed.get("upgrades") is Dictionary else {}
		for id in ["frame", "bed", "spool", "sorter"]:
			if int(old.get(id, 0)) > 0:
				mods[id] = int(old[id])
	elif parsed.get("mods") is Dictionary:
		mods = parsed["mods"]
	var refund := 0
	var single: Dictionary = {}
	for id in mods:
		var level := int(mods[id])
		if level <= 0:
			continue
		single[str(id)] = 1
		var extra: Array = LEGACY_LEVEL_COSTS.get(str(id), [])
		for i in mini(level - 1, extra.size()):
			refund += int(extra[i])
	parsed["mods"] = single
	parsed["coins"] = int(parsed.get("coins", 0)) + refund
	parsed["version"] = SAVE_VERSION
	return true


## Fits every owned mod to every Printer that can run it.
func _auto_install() -> void:
	for printer_id in data["printers"]:
		var list: Array = []
		for m in GameData.PRINTER_MODS:
			if owns_mod(str(m["id"])):
				list.append(str(m["id"]))
		data["installed"][printer_id] = _valid_list(list)


## A list of mod ids with unowned and unknown ones, repeats, and mods whose
## requirements are not in the list taken out.
func _valid_list(list: Array) -> Array:
	var set: Dictionary = {}
	for id in list:
		if owns_mod(str(id)) and not GameData.mod(str(id)).is_empty():
			set[str(id)] = 1
	var clean := GameData.clean_mods("", set)
	var out: Array = []
	for m in GameData.PRINTER_MODS:
		if clean.has(m["id"]):
			out.append(str(m["id"]))
	return out


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
		var level := clampi(int(data["mods"][k]), 0, 1) if not GameData.mod(str(k)).is_empty() else 0
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
		var list: Array = _valid_list(data["installed"].get(printer_id, []))
		installed[printer_id] = list
	data["installed"] = installed
	var decks: Array = data["decks"]
	while decks.size() < DECK_SLOTS:
		decks.append({"cards": [], "printer": "ember_forge", "sleeve": "forge"})
	decks.resize(DECK_SLOTS)
	for d in decks:
		if not Sleeves.unlocked(str(d.get("sleeve", "forge")), rank_level()):
			d["sleeve"] = "forge"
		var list: Array = []
		for id in d.get("cards", []):
			if owned_count(str(id)) > 0:
				list.append(str(id))
		d["cards"] = list
		if not owned.has(str(d.get("printer", ""))):
			d["printer"] = owned[0] if not owned.is_empty() else "ember_forge"
	data["player"] = PlayerIdentity.sanitize(data.get("player", {}) if data.get("player") is Dictionary else {})
	if not _earned_titles().any(func(t): return t["id"] == data["player"]["title"]):
		data["player"]["title"] = "rookie"


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

func owns_mod(id: String) -> bool:
	return int(data["mods"].get(id, 0)) > 0


## Mods you need to own before you can buy this one.
func mod_locked_by(id: String) -> Array:
	var out: Array = []
	for r in GameData.mod_requires(id):
		if not owns_mod(str(r)):
			out.append(str(r))
	return out


## Everything a crate could still give you: card mods you do not have and
## Printer mods you do not have yet whose required mods you already own.
func _mod_pool() -> Array:
	var pool: Array = []
	for m in GameData.CARD_MODS:
		if not owns_card_mod(str(m["id"])):
			pool.append({"kind": "card", "id": str(m["id"]), "name": str(m["name"]), "rarity": str(m["rarity"]), "text": str(m["text"])})
	for m in GameData.PRINTER_MODS:
		if not owns_mod(str(m["id"])) and mod_locked_by(str(m["id"])).is_empty():
			pool.append({"kind": "printer", "id": str(m["id"]), "name": str(m["name"]), "rarity": str(m["rarity"]),
				"text": GameData.mod_text(str(m["id"]))})
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
		_own_mod(str(pick["id"]))
	save()
	return pick


func buy_mod_crate(rng: RandomNumberGenerator = null) -> Dictionary:
	if coins() < GameData.MOD_CRATE_PRICE:
		return {"error": "Not enough Forge Coins."}
	if _mod_pool().is_empty():
		return {"error": "No new mods to find right now. Buy the ones that unlock more."}
	data["coins"] = coins() - GameData.MOD_CRATE_PRICE
	return award_random_mod(rng)


## Adds a mod to your collection and fits it to every Printer you own that has
## what it needs.
func _own_mod(id: String) -> void:
	data["mods"][id] = 1
	for printer_id in data["printers"]:
		var list: Array = (data["installed"].get(printer_id, []) as Array).duplicate()
		list.append(id)
		data["installed"][printer_id] = _valid_list(list)


func buy_mod(id: String) -> String:
	var m := GameData.mod(id)
	if m.is_empty():
		return "Unknown mod."
	if owns_mod(id):
		return "You already have that mod."
	var need := mod_locked_by(id)
	if not need.is_empty():
		return "Buy %s first." % GameData.mod(str(need[0]))["name"]
	if rank_level() < int(m["rank"]):
		return "Reach Maker Rank %d to buy that." % int(m["rank"])
	if coins() < int(m["cost"]):
		return "Not enough Forge Coins."
	data["coins"] = coins() - int(m["cost"])
	_own_mod(id)
	save()
	return ""


func installed_mods(printer_id: String) -> Array:
	return data["installed"].get(printer_id, [])


## Fits an owned mod to a Printer. It only works once the mods it needs are on
## the Printer as well.
func install_mod(printer_id: String, mod_id: String) -> String:
	if not owns_printer(printer_id):
		return "You do not own that Printer."
	if not owns_mod(mod_id):
		return "You have not bought that mod yet."
	var list: Array = (data["installed"].get(printer_id, []) as Array).duplicate()
	if list.has(mod_id):
		return ""
	var missing := GameData.missing_requirements(mod_id, list)
	if not missing.is_empty():
		return "Fit %s first." % missing[0]
	list.append(mod_id)
	data["installed"][printer_id] = _valid_list(list)
	save()
	return ""


## Takes a mod off a Printer, and with it every mod that needs it. Returns the
## ids of the other mods that came off.
func remove_mod(printer_id: String, mod_id: String) -> Array:
	var before: Array = (data["installed"].get(printer_id, []) as Array).duplicate()
	var list: Array = before.duplicate()
	list.erase(mod_id)
	var after := _valid_list(list)
	data["installed"][printer_id] = after
	save()
	var gone: Array = []
	for id in before:
		if id != mod_id and not after.has(id):
			gone.append(str(id))
	return gone


## The mods a battle on this Printer gets: {mod id: 1}, only what is fitted.
func battle_mods(printer_id: String) -> Dictionary:
	var out: Dictionary = {}
	for id in installed_mods(printer_id):
		if owns_mod(str(id)):
			out[str(id)] = 1
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


func deck_sleeve(slot: int) -> Dictionary:
	return Sleeves.get_sleeve(str(deck(slot).get("sleeve", "forge")))


## Gives a deck a sleeve you have unlocked.
func deck_set_sleeve(slot: int, id: String) -> bool:
	if not Sleeves.unlocked(id, rank_level()):
		return false
	deck(slot)["sleeve"] = id
	save()
	return true


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
	if int(b["tier"]) <= 1 and str(b["mod"]) == "" and str(b["mod2"]) == "" and str(b["paint"]) == "original":
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


## The mods fitted on a card (up to two, fewer if the tier is low).
func card_mods_on(id: String) -> Array:
	var b := build_of(id)
	return GameData.fitted_mods(id, int(b["tier"]), [str(b["mod"]), str(b["mod2"])])


## Fits an unlocked mod into the card's next free slot (one slot at Mk II, two at
## Mk III), or takes it off if it is already fitted.
func set_card_mod(id: String, mod_id: String) -> String:
	if owned_count(id) <= 0:
		return "You do not own that card."
	var b := build_of(id)
	var tier := int(b["tier"])
	var now := card_mods_on(id)
	if mod_id == "":
		now.clear()
	elif now.has(mod_id):
		now.erase(mod_id)
	else:
		if tier < 2:
			return "Mods fit from Mk II."
		if not owns_card_mod(mod_id):
			return "Unlock that mod first."
		if now.size() >= GameData.mod_slots(tier):
			return "Both mod slots are full." if GameData.mod_slots(tier) > 1 else "Mk III adds a second mod slot."
		var asm: Array = GameData.fitted_mods(id, tier, now + [mod_id])
		if not asm.has(mod_id):
			return "That mod does not fit this card."
		now = asm
	# Removing one can leave the other not fitting; keep only what still does.
	now = GameData.fitted_mods(id, tier, now)
	b["mod"] = now[0] if now.size() > 0 else ""
	b["mod2"] = now[1] if now.size() > 1 else ""
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
	data["installed"][id] = _valid_list(data["mods"].keys())
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
func record_battle(mode: String, won: bool, level: int = 1, rival_id: String = "", printer_id: String = "", opponent: Dictionary = {}) -> Dictionary:
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
	var sorter := 0
	if printer_id != "":
		var carried := battle_mods(printer_id)
		sorter = GameData.mv(carried, "sorter") + GameData.mv(carried, "auto_sorter")
	if won:
		data["stats"]["wins"] = int(data["stats"]["wins"]) + 1
		reward["coins"] = int(GameData.WIN_COINS[lv]) + sorter
		reward["xp"] = GameData.XP_PVP_WIN if mode in ["lan", "ranked"] else int(GameData.XP_WIN[lv])
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
		reward["xp"] = GameData.XP_PVP_LOSS if mode in ["lan", "ranked"] else int(GameData.XP_LOSS[lv])
	if mode == "ranked":
		reward["rating"] = record_ranked(str(opponent.get("name", "Rival")), int(opponent.get("rating", rating())), won)
	data["coins"] = coins() + int(reward["coins"])
	add_xp(int(reward["xp"]))
	reward["rank_to"] = rank_level()
	# A win sometimes turns up a random mod.
	if won and randf() < GameData.MOD_FIND_CHANCE:
		reward["found_mod"] = award_random_mod()
	save()
	return reward


# ----------------------------------------------------- player profile & rating

func player() -> Dictionary:
	return data["player"]


func player_name() -> String:
	var p: Dictionary = data["player"]
	return PlayerIdentity.name_of(int(p["adj"]), int(p["noun"]), int(p["num"]))


func rating() -> int:
	return int(data["player"]["rating"])


## The print shown as your picture: your pick if you still own it, else the first creature you own.
func avatar_id() -> String:
	var want := str(data["player"]["avatar"])
	if want != "" and owned_count(want) > 0 and GameData.card(want).get("type", "") == "creature":
		return want
	for c in GameData.collectible():
		if c["type"] == "creature" and owned_count(str(c["id"])) > 0:
			return str(c["id"])
	return ""


## What an opponent is told about you in a direct-connect game.
func who() -> Dictionary:
	return PlayerIdentity.who_of(data["player"], avatar_id())


func owned_creatures() -> Array:
	var out: Array = []
	for c in GameData.collectible():
		if c["type"] == "creature" and owned_count(str(c["id"])) > 0:
			out.append(str(c["id"]))
	return out


## Picks the words and number of your name and your picture. Only fixed choices are allowed.
func set_player_look(adj: int, noun: int, num: int, avatar: String) -> void:
	var p: Dictionary = data["player"]
	p["adj"] = posmod(adj, PlayerIdentity.ADJECTIVES.size())
	p["noun"] = posmod(noun, PlayerIdentity.NOUNS.size())
	p["num"] = posmod(num, 100)
	p["avatar"] = avatar if owned_creatures().has(avatar) else ""
	save()
	changed.emit()


func _earned_titles() -> Array:
	var p: Dictionary = data["player"]
	var unique := 0
	for id in data["cards"]:
		unique += 1
	return PlayerIdentity.titles(int(p["best_rating"]), int(data["stats"]["wins"]), int(p["best_streak"]), (data["rivals_beaten"] as Array).size(), unique)


func earned_titles() -> Array:
	return _earned_titles()


func title_name() -> String:
	for t in _earned_titles():
		if t["id"] == data["player"]["title"]:
			return str(t["name"])
	return "Rookie Maker"


func set_title(id: String) -> bool:
	if not _earned_titles().any(func(t): return t["id"] == id):
		return false
	data["player"]["title"] = id
	save()
	changed.emit()
	return true


## Applies one finished ranked game to the rating, streak and history.
func record_ranked(opp_name: String, opp_rating: int, won: bool) -> Dictionary:
	var p: Dictionary = data["player"]
	var before := int(p["rating"])
	var d := Rating.delta(before, opp_rating, won, int(p["ranked_games"]))
	var after := maxi(Rating.FLOOR, before + d)
	var league_before := Rating.league(before)
	p["rating"] = after
	p["ranked_games"] = int(p["ranked_games"]) + 1
	var run := int(p["streak"])
	if won:
		p["ranked_wins"] = int(p["ranked_wins"]) + 1
		run = run + 1 if run > 0 else 1
	else:
		run = run - 1 if run < 0 else -1
	p["streak"] = run
	p["best_streak"] = maxi(int(p["best_streak"]), int(p["streak"]))
	p["best_rating"] = maxi(int(p["best_rating"]), after)
	(p["history"] as Array).append({"opp": opp_name.substr(0, 28), "opp_rating": opp_rating, "won": won, "delta": after - before, "mode": "ranked"})
	if (p["history"] as Array).size() > PlayerIdentity.HISTORY_LIMIT:
		p["history"] = (p["history"] as Array).slice((p["history"] as Array).size() - PlayerIdentity.HISTORY_LIMIT)
	var league_after := Rating.league(after)
	return {"before": before, "after": after, "delta": after - before, "league": Rating.league_text(after),
		"promoted": int(league_after["index"]) > int(league_before["index"]) or (int(league_after["index"]) == int(league_before["index"]) and int(league_after["division"]) != 0 and int(league_after["division"]) < int(league_before["division"])),
		"demoted": int(league_after["index"]) < int(league_before["index"])}
