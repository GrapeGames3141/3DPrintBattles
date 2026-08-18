class_name UnifiedRules
extends RefCounted
## Version 0.7 account rules.  This is deliberately data-first so a hosted
## authority can apply the same transitions without a UI or a local save.

const STARTER_IDS: Array[String] = ["cinderpaw", "aquafin", "voltwig"]
const PACKS := {"pack_3":{"count":3,"price":60}, "pack_5":{"count":5,"price":90}, "pack_10":{"count":10,"price":160}}
const SINGLE_PRICES := {"common":18,"uncommon":28,"rare":42,"epic":64,"legendary":90,"mythic":120,"prismatic":140,"primordial":160}
const PRINT_TICKS := {"common":1,"uncommon":2,"rare":2,"epic":3,"legendary":3,"mythic":4,"prismatic":4,"primordial":5}
const PRINTER_NODES := {
	"calibrated_rails":{"cost":60,"group":"Fabrication","requires":[]}, "heated_bed":{"cost":120,"group":"Fabrication","requires":["calibrated_rails"]}, "rapid_start":{"cost":180,"group":"Fabrication","requires":["heated_bed"]},
	"spool_5":{"cost":60,"group":"Spool","requires":[]}, "spool_7":{"cost":120,"group":"Spool","requires":["spool_5"]}, "spool_10":{"cost":180,"group":"Spool","requires":["spool_7"]}, "high_flow":{"cost":220,"group":"Spool","requires":["spool_10"]},
	"collector_5":{"cost":50,"group":"Recovery","requires":[]}, "clip_smelter":{"cost":100,"group":"Recovery","requires":["collector_5"]}, "spooler":{"cost":150,"group":"Recovery","requires":["clip_smelter"]}, "collector_8":{"cost":160,"group":"Recovery","requires":["collector_5"]}, "closed_loop":{"cost":220,"group":"Recovery","requires":["spooler"]}
}
const NEW_CREATURES := [
	{"id":"embermoth","name":"Embermoth","rarity":"rare","element":"Fire","hp":48,"attack":16,"cost":4,"ability":"Searwing"}, {"id":"ripplehorn","name":"Ripplehorn","rarity":"rare","element":"Water","hp":58,"attack":14,"cost":4,"ability":"Wave Ram"}, {"id":"geargecko","name":"Geargecko","rarity":"uncommon","element":"Stone","hp":44,"attack":12,"cost":3,"ability":"Gear Grip"}, {"id":"lumilynx","name":"Lumilynx","rarity":"epic","element":"Arcane","hp":66,"attack":21,"cost":5,"ability":"Lumen Leap"}
]
const EXTRA_SPELLS := ["Bed Jam", "Filament Leak", "Printer Ward", "Emergency Vent"]
const EXTRA_EQUIPMENT := ["Swiftweave Suit", "Salvager Suit", "Recycler Core", "Guardian Core"]
const REFILLS := [{"id":"raw_filament","name":"Raw Filament","amount":2},{"id":"heated_spool","name":"Heated Spool","amount":3},{"id":"pocket_coil","name":"Pocket Coil","amount":1},{"id":"fresh_roll","name":"Fresh Roll","amount":4},{"id":"reserve_drum","name":"Reserve Drum","amount":6},{"id":"full_hopper","name":"Full Hopper","amount":10}]

static func all_cards() -> Array:
	var cards: Array = []
	for raw in Catalog.CREATURES + NEW_CREATURES:
		var c: Dictionary = raw.duplicate(true); c["type"] = "creature"; c["print_ticks"] = int(PRINT_TICKS.get(str(c.get("rarity", "common")), 1)); cards.append(c)
	for index in 10:
		var name := str(Catalog.SUITS[index % Catalog.SUITS.size()].get("name", "Suit")) if index < 5 else str(Catalog.CORE_BLUEPRINTS[index - 5].get("name", "Core"))
		cards.append({"id":"equipment_%02d" % index,"name":name,"type":"equipment","rarity":"uncommon" if index < 6 else "rare","cost":1 + index / 4,"effect":"guard" if index % 2 == 0 else "attack"})
	for index in EXTRA_EQUIPMENT.size(): cards.append({"id":["swiftweave_suit","salvager_suit","recycler_core","guardian_core"][index],"name":EXTRA_EQUIPMENT[index],"type":"equipment","rarity":"rare","cost":2,"effect":"guard" if index == 3 else "attack"})
	var spell_sources: Array = []
	for source in Catalog.SUPPORT_CARDS:
		if str(source.get("id", "")) not in ["raw_filament", "heated_spool"] and spell_sources.size() < 28: spell_sources.append(source)
	for source in spell_sources:
		var spell: Dictionary = source.duplicate(true); spell["type"] = "spell"; cards.append(spell)
	for index in EXTRA_SPELLS.size():
		cards.append({"id":["bed_jam","filament_leak","printer_ward","emergency_vent"][index],"name":EXTRA_SPELLS[index],"type":"spell","rarity":"rare","cost":2,"effect":["slow_printer","steal_filament","printer_guard","cleanse_printer"][index]})
	for refill in REFILLS:
		var card: Dictionary = refill.duplicate(true); card["type"] = "refill"; card["rarity"] = "common"; card["cost"] = 0; cards.append(card)
	return cards

static func card(id: String) -> Dictionary:
	for definition in all_cards():
		if str(definition.get("id", "")) == id: return definition
	return {}

static func ensure(source: Dictionary) -> Dictionary:
	var p := source.duplicate(true)
	if not p.has("owned_cards") or not p.get("owned_cards") is Dictionary: p["owned_cards"] = {}
	if not p.has("card_xp") or not p.get("card_xp") is Dictionary: p["card_xp"] = {}
	if not p.has("card_builds") or not p.get("card_builds") is Dictionary: p["card_builds"] = {}
	if not p.has("forge_xp"): p["forge_xp"] = int(p.get("xp", 0))
	if not p.has("printer_nodes") or not p.get("printer_nodes") is Array: p["printer_nodes"] = []
	if not p.has("workshop_filament"): p["workshop_filament"] = 30
	if not p.has("pending_pack_reveal") or not p.get("pending_pack_reveal") is Dictionary: p["pending_pack_reveal"] = {}
	if not p.has("unified_settlements") or not p.get("unified_settlements") is Dictionary: p["unified_settlements"] = {}
	if not p.has("unified_launch_sequence"): p["unified_launch_sequence"] = 0
	if not p.has("decks") or not p.get("decks") is Array: p["decks"] = []
	if not p.has("active_deck_id"): p["active_deck_id"] = "starter-deck"
	if not p.has("onboarding") or not p.get("onboarding") is Dictionary: p["onboarding"] = {"state":"choose_starter","starter_id":""}
	# Legacy support cards become unified spell/refill ownership; printed creatures
	# and equipment blueprints each grant their corresponding card.
	for id in p.get("support_cards", {}):
		if not card(str(id)).is_empty(): p.owned_cards[str(id)] = maxi(int(p.owned_cards.get(str(id), 0)), int(p.support_cards[id]))
	for creature in p.get("creatures", []):
		if creature is Dictionary:
			var id := str(creature.get("creature_id", ""))
			if not card(id).is_empty(): p.owned_cards[id] = maxi(1, int(p.owned_cards.get(id, 0)))
	var starter := str(p.onboarding.get("starter_id", ""))
	if starter in STARTER_IDS:
		p.owned_cards[starter] = maxi(3, int(p.owned_cards.get(starter, 0)))
		if str(p.onboarding.get("state", "")) == "complete": p.onboarding["state"] = "complete"
	for raw in p.get("decks", []):
		if not raw is Dictionary: continue
		var old_cards: Array = raw.get("cards", []) if raw.get("cards", []) is Array else []
		var repaired: Array = []
		for id in old_cards:
			if not card(str(id)).is_empty() and repaired.count(str(id)) < 3: repaired.append(str(id))
		while repaired.size() < 15: repaired.append(starter if starter in STARTER_IDS else "cinderpaw")
		raw["cards"] = repaired.slice(0, 15)
	if p.decks.is_empty() and starter in STARTER_IDS and str(p.onboarding.get("state", "")) == "complete": _make_starter_deck(p)
	return p

static func choose_starter(source: Dictionary, id: String) -> Dictionary:
	var p := ensure(source)
	if str(p.onboarding.get("state", "choose_starter")) != "choose_starter": return fail(p, "Starter already selected.")
	if id not in STARTER_IDS: return fail(p, "Choose a Forge Trio print.")
	p.onboarding = {"state":"starter_selected","starter_id":id,"starter_instance_id":""}; p.owned_cards[id] = maxi(3, int(p.owned_cards.get(id, 0)))
	return ok(p, {"card_id":id,"count":3})

static func print_starter(source: Dictionary) -> Dictionary:
	var p := ensure(source); var id := str(p.onboarding.get("starter_id", ""))
	if str(p.onboarding.get("state", "")) != "starter_selected" or id not in STARTER_IDS: return fail(p, "Choose a starter first.")
	p.onboarding["state"] = "complete"; p.onboarding["starter_instance_id"] = "starter-%s" % id
	if not p.has("creatures") or not p.get("creatures") is Array: p["creatures"] = []
	p.creatures.append({"instance_id":"starter-%s" % id,"creature_id":id,"bound":true,"tradable":false,"source":"starter"})
	_make_starter_deck(p); return ok(p, {"free":true,"creature_id":id})

static func _make_starter_deck(p: Dictionary) -> void:
	var starter := str(p.onboarding.get("starter_id", "cinderpaw")); var cards: Array = [starter,starter,starter,"raw_filament","raw_filament","heated_spool","pocket_coil","fresh_roll","reinforced_layer","quick_patch","arcane_spark","windup","printer_ward","bed_jam","swiftweave_suit"]
	for id in cards: p.owned_cards[id] = maxi(int(p.owned_cards.get(id, 0)), cards.count(id))
	p.decks = [{"id":"starter-deck","name":"Starter Deck","cards":cards}]; p.active_deck_id = "starter-deck"

static func save_deck(source: Dictionary, cards: Array, deck_id := "starter-deck") -> Dictionary:
	var p := ensure(source); var legal := deck_reason(p, cards)
	if not legal.is_empty(): return fail(p, legal)
	var found := false
	for deck in p.decks:
		if str(deck.get("id", "")) == deck_id: deck["cards"] = cards.duplicate(); found = true
	if not found: p.decks.append({"id":deck_id,"name":"Forge Deck","cards":cards.duplicate()})
	p.active_deck_id = deck_id; return ok(p, {"deck_id":deck_id,"cards":cards.duplicate()})

static func deck_reason(p: Dictionary, cards: Array) -> String:
	if cards.size() != 15: return "Deck needs 15 cards."
	var creatures := 0
	for id in cards:
		var def := card(str(id))
		if def.is_empty(): return "Unknown card."
		if cards.count(id) > 3: return "Maximum three copies."
		if int(p.owned_cards.get(str(id), 0)) < cards.count(id): return "Deck uses cards not owned."
		if str(def.get("type", "")) == "creature": creatures += 1
	return "Deck needs at least three creatures." if creatures < 3 else ""

static func buy_pack(source: Dictionary, pack_id: String, random_bytes: PackedByteArray = PackedByteArray()) -> Dictionary:
	var p := ensure(source); var pack: Dictionary = PACKS.get(pack_id, {})
	if pack.is_empty(): return fail(p, "Choose a 3, 5, or 10 card pack.")
	if int(p.get("coins", 0)) < int(pack.price): return fail(p, "Not enough Forge Coins.")
	var entropy := random_bytes if random_bytes.size() >= 8 else Crypto.new().generate_random_bytes(32)
	var seed := 0
	for byte in entropy: seed = (seed * 257 + int(byte)) & 0x7fffffff
	var cards: Array = []
	for _i in int(pack.count):
		seed = _next(seed)
		cards.append(_weighted_card(seed))
	p.coins = int(p.coins) - int(pack.price)
	for id in cards: p.owned_cards[id] = int(p.owned_cards.get(id, 0)) + 1
	p.pending_pack_reveal = {"pack_id":pack_id,"cards":cards,"seed_commit":str(seed)}
	return ok(p, {"pack_id":pack_id,"cards":cards,"price":int(pack.price),"pending_reveal":true})

static func clear_pack_reveal(source: Dictionary) -> Dictionary:
	var p := ensure(source); var cards: Array = p.pending_pack_reveal.get("cards", []) if p.pending_pack_reveal is Dictionary else []
	p.pending_pack_reveal = {}; return ok(p, {"cards":cards})

## Market singles are a small deterministic shelf, not a browseable locked
## catalog. The day key is supplied by the facade so a server can reproduce the
## exact offer list; buying validates against the same list atomically.
static func market_offers(day_key: String) -> Array:
	var source := all_cards(); var seed := 19
	for byte in day_key.to_utf8_buffer(): seed = int((seed * 131 + int(byte)) & 0x7fffffff)
	var offers: Array = []
	while offers.size() < mini(8, source.size()):
		seed = _next(seed)
		var card_def: Dictionary = source[seed % source.size()]
		var id := str(card_def.get("id", ""))
		var duplicate := false
		for offered in offers:
			if str(offered.get("id", "")) == id: duplicate = true; break
		if duplicate: continue
		offers.append({"id":id,"price":int(SINGLE_PRICES.get(str(card_def.get("rarity", "common")), 18)),"day_key":day_key})
	return offers

static func buy_market_card(source: Dictionary, card_id: String, day_key: String) -> Dictionary:
	var p := ensure(source); var offered: Dictionary = {}
	for offer in market_offers(day_key):
		if str(offer.get("id", "")) == card_id: offered = offer; break
	if offered.is_empty(): return fail(p, "That card is not offered in the current Market.")
	if int(p.get("coins", 0)) < int(offered.price): return fail(p, "Not enough Forge Coins.")
	p.coins = int(p.coins) - int(offered.price)
	p.owned_cards[card_id] = int(p.owned_cards.get(card_id, 0)) + 1
	# Ownership is the only single-purchase effect: build/XP state is untouched.
	return ok(p, {"card_id":card_id,"price":int(offered.price),"day_key":day_key})

static func apply_printer_nodes(source: Dictionary, desired: Array) -> Dictionary:
	var p := ensure(source); var wanted := desired.duplicate(); var cost := 0; var refund := 0
	for id in wanted:
		var node: Dictionary = PRINTER_NODES.get(str(id), {})
		if node.is_empty(): return fail(p, "Unknown printer node.")
		for parent in node.requires: if str(parent) not in wanted: return fail(p, "Select prerequisites first.")
		if str(id) not in p.printer_nodes: cost += int(node.cost)
	for id in p.printer_nodes:
		if str(id) not in wanted: refund += int(PRINTER_NODES.get(str(id), {}).get("cost", 0))
	if int(p.forge_xp) + refund < cost: return fail(p, "Not enough Forge XP.")
	p.forge_xp = int(p.forge_xp) + refund - cost; p.printer_nodes = wanted; return ok(p, {"cost":cost,"refund":refund,"nodes":wanted})

static func settle_unified_battle(source: Dictionary, result_id: String, played: Array, victory: bool, salvage: int, coins: int = 0) -> Dictionary:
	var p := ensure(source)
	if result_id.is_empty(): return fail(p, "Battle result needs an id.")
	if p.unified_settlements.has(result_id): return ok(p, {"id":result_id,"duplicate":true})
	var xp_result := award_card_xp(p, played, victory); p = xp_result.profile
	p.workshop_filament = int(p.workshop_filament) + maxi(0, salvage)
	p.coins = int(p.coins) + maxi(0, coins)
	p.forge_xp = int(p.forge_xp) + (12 if victory else 4)
	p.unified_settlements[result_id] = true
	return ok(p, {"id":result_id,"duplicate":false,"salvage":maxi(0, salvage),"coins":maxi(0, coins)})

static func respec_printer(source: Dictionary) -> Dictionary:
	var p := ensure(source)
	var refund := 0
	for id in p.printer_nodes:
		refund += int(PRINTER_NODES.get(str(id), {}).get("cost", 0))
	p.forge_xp = int(p.forge_xp) + refund
	p.printer_nodes = []
	return ok(p, {"free":true,"refund":refund})

static func build_card(source: Dictionary, card_id: String, node: String) -> Dictionary:
	var p := ensure(source)
	if card(card_id).is_empty() or node not in ["power_a","power_b","tempo_a","tempo_b","utility_a","utility_b"]: return fail(p, "Unknown card build.")
	var active: Array = p.card_builds.get(card_id, []) if p.card_builds.get(card_id, []) is Array else []
	if node in active: return ok(p, {"card_id":card_id,"nodes":active})
	if active.size() >= 4: return fail(p, "A card can use four build nodes.")
	if node.ends_with("b") and node.replace("_b", "_a") not in active: return fail(p, "Unlock the tier-A node first.")
	var cost := 8 if node.ends_with("b") else 4
	if int(p.card_xp.get(card_id, 0)) < cost: return fail(p, "Not enough card XP.")
	p.card_xp[card_id] = int(p.card_xp.get(card_id, 0)) - cost; active.append(node); p.card_builds[card_id] = active; return ok(p, {"card_id":card_id,"nodes":active})

static func build_effect_label(card_id: String, node: String) -> String:
	var card_def := card(card_id); var type := str(card_def.get("type", ""))
	if node == "tempo_a" or node == "tempo_b": return "-1 filament; creatures also print 1 tick faster"
	if type == "creature":
		return {"power_a":"+2 attack","power_b":"+3 attack","utility_a":"+5 HP","utility_b":"+5 HP, +1 guard"}.get(node, "")
	if type == "equipment": return "Power: +1 attachment stat; Utility: +1 guard"
	if type == "refill": return "+1 refill amount"
	return "+1 spell potency (or +2 printer ward)"

static func respec_card(source: Dictionary, card_id: String) -> Dictionary:
	var p := ensure(source)
	var active: Array = p.card_builds.get(card_id, []) if p.card_builds.get(card_id, []) is Array else []
	var refund := 0
	for node in active: refund += 8 if str(node).ends_with("b") else 4
	p.card_xp[card_id] = int(p.card_xp.get(card_id, 0)) + refund
	p.card_builds[card_id] = []
	return ok(p, {"free":true,"refund":refund})

static func award_card_xp(source: Dictionary, played: Array, victory: bool) -> Dictionary:
	var p := ensure(source); var counted := {}
	for id in played:
		var key := str(id)
		if card(key).is_empty() or int(counted.get(key, 0)) >= 3: continue
		counted[key] = int(counted.get(key, 0)) + 1; p.card_xp[key] = int(p.card_xp.get(key, 0)) + 1
	if victory: for key in counted: p.card_xp[key] = int(p.card_xp.get(key, 0)) + 1
	return ok(p, {"played":counted,"victory":victory})

static func _weighted_card(seed: int) -> String:
	var pool := all_cards(); var total := 0
	for item in pool: total += int(Catalog.rarity(str(item.get("rarity", "common"))).get("weight_bps", 4500))
	var roll := seed % total
	for item in pool:
		roll -= int(Catalog.rarity(str(item.get("rarity", "common"))).get("weight_bps", 4500))
		if roll < 0: return str(item.id)
	return str(pool[0].id)
static func _next(seed: int) -> int: return int((seed * 1103515245 + 12345) & 0x7fffffff)
static func ok(profile: Dictionary, payload: Dictionary) -> Dictionary: return {"ok":true,"profile":profile,"payload":payload}
static func fail(profile: Dictionary, error: String) -> Dictionary: return {"ok":false,"profile":profile,"error":error}
