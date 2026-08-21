class_name UnifiedRules
extends RefCounted
## Canonical PrintForge Legends v3.1 catalog and profile transitions.
## All costs, odds and timers live here rather than in presentation code.

const VERSION := "3.1.0"
const STARTER_IDS: Array[String] = ["cinderpaw", "aquafin", "voltwig"]
const DECK_SLOTS := [{"id":"starter-deck","name":"Forge Deck"},{"id":"deck-slot-2","name":"Queue Deck"},{"id":"deck-slot-3","name":"Arcane Deck"}]
const RARITY_ORDER := ["common","uncommon","rare","epic","legendary","mythic","prismatic","primordial"]
const CREATURE_COSTS := {"common":70,"uncommon":120,"rare":190,"epic":300,"legendary":440,"mythic":530,"prismatic":610,"primordial":680}
const EQUIPMENT_COSTS := {"common":40,"uncommon":75,"rare":120,"epic":185,"legendary":300,"mythic":390,"prismatic":500,"primordial":620}
const PRINT_TURNS := {"common":1,"uncommon":2,"rare":3,"epic":4,"legendary":5,"mythic":6,"prismatic":7,"primordial":8}
const CARD_PRICES := {"common":80,"uncommon":200,"rare":480,"epic":1000,"legendary":2200,"mythic":5000,"prismatic":10000,"primordial":25000}
const BLUEPRINT_PRICES := {"common":50,"uncommon":120,"rare":300,"epic":600,"legendary":1200,"mythic":2500,"prismatic":5000,"primordial":12000}
const WORKSHOP_PRINT_COSTS := {"common":20,"uncommon":40,"rare":70,"epic":110,"legendary":160,"mythic":220,"prismatic":300,"primordial":500}
const PACKS := {"basic":{"count":5,"price":200,"pool_max":"uncommon"},"forge":{"count":5,"price":500,"minimum":"rare","guaranteed":1},"arcane":{"count":8,"price":1100,"minimum":"rare","guaranteed":2},"primordial":{"count":10,"price":2500,"minimum":"epic","guaranteed":1},"champion":{"count":30,"price":6000,"minimum":"epic","guaranteed":3,"legendary":true}}
const WORKSHOP_UPGRADES := {"preprint_slot_i":{"cost":800},"preprint_slot_ii":{"cost":2000,"requires":"preprint_slot_i"},"spool_capacity_i":{"cost":400},"spool_capacity_ii":{"cost":1000,"requires":"spool_capacity_i"},"blueprint_discount":{"cost":1200},"print_yard_expansion":{"cost":600},"forge_speed_i":{"cost":300},"daily_quest_slot":{"cost":3000}}
const UPGRADE_CARDS := {"speed_spool":{"name":"Speed Spool","cost":600},"turbo_spool":{"name":"Turbo Spool","cost":1400},"smelter":{"name":"Smelter","cost":500,"unique_key":"smelter"},"battlefield_collector":{"name":"Battlefield Collector","cost":700,"unique_key":"battlefield_collector"},"spooler":{"name":"Spooler","cost":500},"reinforced_chassis":{"name":"Reinforced Chassis","cost":800},"dual_queue":{"name":"Dual Queue","cost":1600},"emergency_reprint_upgrade":{"name":"Emergency Reprint","cost":3500}}
const SPARK_BUNDLES := {"starter_spark":{"sparks":500,"price_cents":199},"forge_boost":{"sparks":1200,"price_cents":499},"arcane_bundle":{"sparks":2800,"price_cents":999},"master_spool":{"sparks":6500,"price_cents":1999},"primordial_stash":{"sparks":15000,"price_cents":3999}}
const COSMETICS := {
	"copper_classic":{"name":"Copper Classic","kind":"printer_skin","coins":800}, "arctic_forge":{"name":"Arctic Forge","kind":"printer_skin","coins":1200}, "ember_engine":{"name":"Ember Engine","kind":"printer_skin","coins":1200}, "storm_machine":{"name":"Storm Machine","kind":"printer_skin","coins":1600}, "arcane_sanctum":{"name":"Arcane Sanctum","kind":"printer_skin","coins":2000}, "primordial_core":{"name":"Primordial Core","kind":"printer_skin","coins":5000},
	"copper_circuit":{"name":"Copper Circuit","kind":"card_back","coins":400}, "flame_weave":{"name":"Flame Weave","kind":"card_back","coins":600}, "deep_ocean":{"name":"Deep Ocean","kind":"card_back","coins":600}, "static_grid":{"name":"Static Grid","kind":"card_back","coins":600}, "prismatic_spiral":{"name":"Prismatic Spiral","kind":"card_back","coins":2000},
	"night_foundry":{"name":"Night Foundry","kind":"workshop_theme","coins":1500}, "crystal_lab":{"name":"Crystal Lab","kind":"workshop_theme","coins":1500}, "ember_sanctum":{"name":"Ember Sanctum","kind":"workshop_theme","coins":1500}, "floating_workshop":{"name":"Floating Workshop","kind":"workshop_theme","coins":2500}, "primordial_vault":{"name":"Primordial Vault","kind":"workshop_theme","coins":5000},
	"engineer_gizmo":{"name":"Engineer Gizmo","kind":"gizmo_outfit","coins":300}, "scholar_gizmo":{"name":"Scholar Gizmo","kind":"gizmo_outfit","coins":300}, "battle_gizmo":{"name":"Battle Gizmo","kind":"gizmo_outfit","coins":500}, "golden_gizmo":{"name":"Golden Gizmo","kind":"gizmo_outfit","coins":2000}
}
const QUEST_TEMPLATES := {"bronze":["win_1"],"silver":["win_3"],"gold":["destroy_5","three_elements","no_spells"],"legendary":["win_10_streak"]}
const QUEST_REWARDS := {"bronze":{"coins":50,"xp":100,"rarity":"common"},"silver":{"coins":150,"xp":250,"rarity":"uncommon"},"gold":{"coins":400,"xp":500,"rarity":"uncommon"},"legendary":{"coins":1000,"xp":1000,"rarity":"rare"}}
# Kept as an empty compatibility symbol while the legacy Workshop component is
# retired; v3 does not expose refundable printer-node builds.
const PRINTER_NODES := {}

static func new_profile() -> Dictionary:
	# A v3 profile is born in the clean namespace. It deliberately contains no
	# legacy instance/team/suit or 0.7 economy state.
	return ensure({"forge_coins":1000,"sparks":0,"onboarding":{"state":"choose_starter","starter_id":""},"decks":[],"active_deck_id":"starter-deck","spool_level":1,"spool_xp":0,"rng_nonce":1})

static func all_cards() -> Array:
	var cards: Array = []
	for raw in Catalog.CREATURES:
		var card: Dictionary = raw.duplicate(true); var rarity := str(card.get("rarity", "common")); card["type"] = "creature"; card["bend_score"] = int(card.get("bend", 0)); card["filament_cost"] = int(card.get("filament_cost", CREATURE_COSTS.get(rarity, 70))); card["cost"] = card.filament_cost; card["print_turns"] = int(card.get("print_turns", PRINT_TURNS.get(rarity, 1))); card["print_ticks"] = card.print_turns
		# A creature may only expose an action if its authored catalog trigger says
		# so; legacy signatures are presentation metadata, never implicit combat.
		card["ability_trigger"] = str(card.get("ability_trigger", "attack"))
		card["ability_effect"] = str(card.get("ability_effect", "")); card["ability_amount"] = int(card.get("ability_amount", 0)); card["ability_cooldown"] = int(card.get("ability_cooldown", card.get("cooldown", 0)))
		var signature: Dictionary = card.get("signature", {}) if card.get("signature", {}) is Dictionary else {}
		card["ability_damage_bonus"] = int(card.get("ability_damage_bonus", signature.get("damage_bonus", 0)))
		card["ability_effects"] = card.get("ability_effects", signature.get("effects", [])).duplicate(true) if card.get("ability_effects", signature.get("effects", [])) is Array else []
		cards.append(card)
	for data in _equipment_definitions(): cards.append(data)
	for data in _filament_definitions(): cards.append(data)
	for data in _spell_definitions(): cards.append(data)
	for data in _trap_definitions(): cards.append(data)
	for id in UPGRADE_CARDS:
		var u: Dictionary = UPGRADE_CARDS[id]; cards.append({"id":id,"name":str(u.name),"type":"upgrade","rarity":"rare" if id != "emergency_reprint_upgrade" else "legendary","filament_cost":0,"cost":0,"print_turns":0,"unique_key":str(u.get("unique_key", "")),"market_cost":int(u.cost)})
	return cards
static func card(id: String) -> Dictionary:
	for definition in all_cards(): if str(definition.get("id", "")) == id: return definition
	return {}
static func _equipment_definitions() -> Array:
	return [
		_eq("helm","Helm","armor","common",{"armor_hp":10}),_eq("chest_plate","Chest Plate","armor","uncommon",{"armor_hp":18}),_eq("leg_guards","Leg Guards","armor","uncommon",{"armor_hp":14}),_eq("full_suit","Full Suit","armor","rare",{"armor_hp":30}),_eq("arcane_plate","Arcane Plate","armor","epic",{"armor_hp":20,"super_effective_bps":12000}),
		_eq("iron_claw","Iron Claw","weapon","common",{"attack_bonus":5}),_eq("ember_fang","Ember Fang","weapon","uncommon",{"attack_bonus":4,"effect":"ember_fang"}),_eq("frost_shard","Frost Shard","weapon","uncommon",{"attack_bonus":4,"effect":"frost_shard"}),_eq("thunder_coil","Thunder Coil","weapon","rare",{"attack_bonus":3,"effect":"thunder_coil"}),_eq("arcane_drill","Arcane Drill","weapon","epic",{"attack_bonus":5,"effect":"arcane_drill"}),
		_eq("filament_ring","Filament Ring","accessory","uncommon",{"effect":"filament_ring"}),_eq("tidal_core","Tidal Core","accessory","rare",{"effect":"tidal_core"}),_eq("arcane_sigil","Arcane Sigil","accessory","rare",{"effect":"arcane_sigil"})]
static func _eq(id: String, name: String, slot: String, rarity: String, extra: Dictionary) -> Dictionary:
	var value := {"id":id,"name":name,"type":"equipment","rarity":rarity,"equipment_slot":slot,"filament_cost":int(EQUIPMENT_COSTS.get(rarity,40)),"cost":int(EQUIPMENT_COSTS.get(rarity,40)),"print_turns":int(PRINT_TURNS.get(rarity,1)),"print_ticks":int(PRINT_TURNS.get(rarity,1))}; value.merge(extra); return value
static func _filament_definitions() -> Array:
	return [{"id":"raw_filament","name":"Raw Filament","type":"filament","rarity":"common","filament_cost":0,"cost":0,"filament_gain":80},{"id":"heated_spool","name":"Heated Spool","type":"filament","rarity":"uncommon","filament_cost":0,"cost":0,"filament_gain":120},{"id":"emergency_canister","name":"Emergency Canister","type":"filament","rarity":"rare","filament_cost":0,"cost":0,"filament_gain":200},{"id":"recycled_scrap","name":"Recycled Scrap","type":"filament","rarity":"uncommon","filament_cost":0,"cost":0,"filament_gain":0}]
static func _spell_definitions() -> Array:
	return [_spell("layer_melt","Layer Melt",150,"rare"),_spell("print_jam","Print Jam",100,"uncommon"),_spell("spool_drain","Spool Drain",120,"rare"),_spell("forge_surge","Forge Surge",80,"uncommon"),_spell("emergency_reprint_spell","Emergency Reprint",150,"epic"),_spell("blueprint_thief","Blueprint Thief",180,"epic")]
static func _spell(id: String, name: String, cost_value: int, rarity: String) -> Dictionary: return {"id":id,"name":name,"type":"spell","rarity":rarity,"filament_cost":cost_value,"cost":cost_value}
static func _trap_definitions() -> Array:
	return [{"id":"print_interrupt","name":"Print Interrupt","type":"trap","rarity":"rare","filament_cost":0,"cost":0,"trigger":"print_complete"},{"id":"filament_siphon","name":"Filament Siphon","type":"trap","rarity":"uncommon","filament_cost":0,"cost":0,"trigger":"filament"},{"id":"counter_strike","name":"Counter Strike","type":"trap","rarity":"uncommon","filament_cost":0,"cost":0,"trigger":"attack"},{"id":"scrap_grab","name":"Scrap Grab","type":"trap","rarity":"rare","filament_cost":0,"cost":0,"trigger":"destroy"}]

static func ensure(source: Dictionary) -> Dictionary:
	var p := source.duplicate(true)
	p["schema_version"] = 31; p["catalog_version"] = VERSION
	for key in ["owned_cards","owned_blueprints","printed_models","gear_loadouts","market_epochs","quest_state","pack_pity","drop_receipts","claim_receipts","cosmetics","entitlements","notifications","season_receipts","newcomer_claims","unified_settlements"]:
		if not p.has(key) or not p.get(key) is Dictionary: p[key] = {}
	for key in ["workshop_upgrades","preprints","decks","wishlist"]:
		if not p.has(key) or not p.get(key) is Array: p[key] = []
	if not p.has("forge_coins"): p["forge_coins"] = int(p.get("coins", 1000))
	if not p.has("sparks"): p["sparks"] = 0
	if not p.has("revision"): p["revision"] = 0
	if not p.has("unified_launch_sequence"): p["unified_launch_sequence"] = 0
	if not p.has("rng_nonce"): p["rng_nonce"] = 1
	if not p.has("spool_level"): p["spool_level"] = 1
	p.spool_level = clampi(int(p.spool_level), 1, 100)
	if not p.has("spool_xp"): p["spool_xp"] = 0
	if not p.has("wins"): p["wins"] = {"streak":0,"lifetime":0,"since_drop":0}
	if not p.has("season"): p["season"] = {"id":"season-v3-1","xp":0,"paid":false,"claimed":[],"started_at":0,"ends_at":0}
	if not p.season.has("started_at"): p.season.started_at = 0
	if not p.season.has("ends_at"): p.season.ends_at = 0
	if not p.has("newcomer_started_at"): p["newcomer_started_at"] = 0
	if not p.has("academy_rewards"): p["academy_rewards"] = {}
	if not p.has("fake_store_receipts"): p["fake_store_receipts"] = {}
	if not p.has("pending_pack_reveal"): p["pending_pack_reveal"] = {}
	if not p.has("active_deck_id"): p["active_deck_id"] = "starter-deck"
	if not p.has("onboarding") or not p.onboarding is Dictionary: p["onboarding"] = {"state":"choose_starter","starter_id":""}
	if p.decks.is_empty() and str(p.onboarding.get("state", "")) == "complete": _make_starter_deck(p)
	if not p.decks.is_empty(): _ensure_deck_slots(p)
	return p
static func choose_starter(source: Dictionary, id: String) -> Dictionary:
	var p := ensure(source)
	if str(p.onboarding.get("state", "choose_starter")) != "choose_starter" or id not in STARTER_IDS: return fail(p, "Choose an available starter.")
	p.onboarding = {"state":"starter_selected","starter_id":id}; p.owned_blueprints[id] = true; return ok(p, {"card_id":id})
static func print_starter(source: Dictionary) -> Dictionary:
	var p := ensure(source); var id := str(p.onboarding.get("starter_id", "")); if id not in STARTER_IDS: return fail(p,"Choose a starter first.")
	p.onboarding.state = "complete"; p.printed_models["starter-%s" % id] = {"blueprint_id":id,"source":"starter"}; _make_starter_deck(p); return ok(p,{"creature_id":id,"free":true})
static func print_workshop_model(source: Dictionary, blueprint_id: String, receipt_id := "") -> Dictionary:
	var p := ensure(source)
	if not bool(p.owned_blueprints.get(blueprint_id, false)): return fail(p, "Learn this blueprint before printing it.")
	var definition := card(blueprint_id)
	if definition.is_empty() or str(definition.get("type", "")) not in ["creature", "equipment"]: return fail(p, "That Workshop blueprint is unavailable.")
	var receipt := receipt_id if not receipt_id.is_empty() else "workshop-print-%d" % int(p.rng_nonce)
	if p.claim_receipts.has(receipt): return ok(p, {"receipt":receipt,"duplicate":true})
	var rarity := str(definition.get("rarity", "common")); var price := int(WORKSHOP_PRINT_COSTS.get(rarity, 20))
	if int(p.forge_coins) < price: return fail(p, "Not enough Forge Coins.")
	p.forge_coins -= price; p.claim_receipts[receipt] = true
	var model_id := "model-%d" % int(p.rng_nonce); p.rng_nonce += 1
	p.printed_models[model_id] = {"model_id":model_id,"blueprint_id":blueprint_id,"rarity":rarity,"printed_at_nonce":int(p.rng_nonce),"source":"workshop"}
	return ok(p, {"receipt":receipt,"model_id":model_id,"blueprint_id":blueprint_id,"price":price})
static func grant_card(p: Dictionary, card_id: String, count := 1) -> Dictionary:
	if card(card_id).is_empty() or count <= 0: return {"card_id":card_id,"count":0}
	p.owned_cards[card_id] = int(p.owned_cards.get(card_id,0)) + count; return {"card_id":card_id,"count":count}
static func _make_starter_deck(p: Dictionary) -> void:
	var creatures := ["cinderpaw","aquafin","voltwig","mossmunk","frostling","galehopper","stoneback","sparkotter","glassdrake","coralisk"]
	var cards: Array = []
	for id in creatures:
		for _copy in 2: cards.append(id)
	# 20 creatures / 6 filament / 6 spells / 4 equipment / 2 traps / 2 upgrades.
	for id in ["raw_filament","raw_filament","raw_filament","raw_filament","heated_spool","heated_spool","layer_melt","print_jam","spool_drain","forge_surge","emergency_reprint_spell","blueprint_thief","helm","chest_plate","iron_claw","filament_ring","counter_strike","print_interrupt","speed_spool","reinforced_chassis"]: cards.append(id)
	for id in cards: grant_card(p,id,maxi(0,cards.count(id)-int(p.owned_cards.get(id,0))))
	p.decks = [{"id":"starter-deck","name":"Forge Deck","cards":cards}]; _ensure_deck_slots(p); p.active_deck_id = "starter-deck"
static func _ensure_deck_slots(p: Dictionary) -> void:
	for slot in DECK_SLOTS:
		var found := false
		for deck in p.decks:
			if str(deck.get("id", "")) == str(slot.id): found = true; deck["name"] = str(slot.name)
		if not found: p.decks.append({"id":str(slot.id),"name":str(slot.name),"cards":[]})
static func deck_reason(p: Dictionary, cards: Array) -> String:
	if cards.size() < 40: return "Deck needs at least 40 cards."
	for id in cards:
		if card(str(id)).is_empty(): return "Deck contains an unknown card."
		if int(p.owned_cards.get(str(id),0)) < cards.count(id): return "Deck uses cards not owned."
	return ""
static func save_deck(source: Dictionary, cards: Array, deck_id := "starter-deck") -> Dictionary:
	var p := ensure(source); if not DECK_SLOTS.any(func(slot): return str(slot.id) == deck_id): return fail(p,"Choose a fixed deck slot.")
	var reason := deck_reason(p,cards); if not reason.is_empty(): return fail(p,reason)
	var found := false; for deck in p.decks: if str(deck.get("id","")) == deck_id: deck["cards"] = cards.duplicate(); found = true
	if not found: p.decks.append({"id":deck_id,"name":"Deck %d" % (p.decks.size()+1),"cards":cards.duplicate()})
	p.active_deck_id = deck_id; return ok(p,{"deck_id":deck_id})
static func select_active_deck(source: Dictionary, deck_id: String) -> Dictionary:
	var p := ensure(source)
	for deck in p.decks:
		if str(deck.get("id", "")) == deck_id:
			if deck_reason(p, deck.get("cards", [])) != "": return fail(p, "That deck slot is not legal.")
			p.active_deck_id = deck_id; return ok(p, {"deck_id":deck_id})
	return fail(p, "Choose a fixed deck slot.")
static func preprint_slots(p: Dictionary) -> int:
	var upgrades: Array = p.get("workshop_upgrades", []) if p.get("workshop_upgrades", []) is Array else []
	return 3 if "preprint_slot_ii" in upgrades else (2 if "preprint_slot_i" in upgrades else 1)
static func save_preprints(source: Dictionary, ids: Array) -> Dictionary:
	var p := ensure(source); var deck := active_deck(p); if ids.size() > preprint_slots(p): return fail(p,"Not enough Pre-Print Slots.")
	for id in ids: if str(id) not in deck or str(card(str(id)).get("type","")) != "creature" or ids.count(id) > deck.count(id): return fail(p,"Pre-prints must be creature copies in the active deck.")
	p.preprints = ids.duplicate(); return ok(p,{"preprints":ids})
static func active_deck(p: Dictionary) -> Array:
	for deck in p.get("decks", []):
		if str(deck.get("id", "")) == str(p.get("active_deck_id", "starter-deck")):
			var values: Array = deck.get("cards", [])
			return values.duplicate()
	return []

static func grant_spool_xp(p: Dictionary, amount: int) -> Dictionary:
	var gained := maxi(0, amount); var before := int(p.get("spool_level", 1))
	p.spool_xp = int(p.get("spool_xp", 0)) + gained
	while int(p.spool_level) < 100 and int(p.spool_xp) >= int(p.spool_level) * 100:
		p.spool_xp -= int(p.spool_level) * 100
		p.spool_level += 1
	return {"xp":gained,"levels":int(p.spool_level) - before,"level":int(p.spool_level),"next_xp":int(p.spool_level) * 100}

static func market_offers(day_key: String, profile: Dictionary = {}) -> Array:
	var seed := _seed(day_key); var pool := all_cards(); var offers: Array = []; var typed := {"creature":3,"spell":2,"filament":2,"equipment":1,"trap":1,"upgrade":1}
	for type in typed:
		for _i in int(typed[type]):
			seed = _next(seed); var choices: Array = []; for def in pool: if str(def.type) == str(type): choices.append(def)
			var def: Dictionary = choices[seed % choices.size()]; offers.append({"id":str(def.id),"price":int(CARD_PRICES.get(str(def.rarity),80)),"epoch":day_key})
	return offers
static func blueprint_offers(day_key: String, spool_level: int) -> Array:
	var seed := _seed(day_key + ":blueprints"); var result: Array = []; var max_index := _blueprint_max_rarity(spool_level)
	for _i in 12:
		seed = _next(seed); var candidates: Array = []; for creature in Catalog.CREATURES: if RARITY_ORDER.find(str(creature.rarity)) <= max_index: candidates.append(creature)
		# A 0.2% deterministic injection ignores the level gate for this slot.
		if posmod(seed, 10000) < 20:
			candidates = []
			for creature in Catalog.CREATURES: if str(creature.get("rarity", "")) == "primordial": candidates.append(creature)
		var item: Dictionary = candidates[seed % candidates.size()]; result.append({"id":str(item.id),"price":int(BLUEPRINT_PRICES.get(str(item.rarity),50)),"epoch":day_key})
	return result

static func _blueprint_max_rarity(spool_level: int) -> int:
	var level := clampi(spool_level, 1, 100)
	if level <= 5: return 0
	if level <= 10: return 1
	if level <= 20: return 2
	if level <= 35: return 3
	if level <= 50: return 4
	if level <= 70: return 5
	if level <= 90: return 6
	return 7

## Market snapshots take a caller-provided Unix timestamp, keeping local tests
## deterministic while production can replace the clock with server time.
static func market_snapshot(source: Dictionary, unix_time: int) -> Dictionary:
	var p := ensure(source)
	var day_epoch := int(p.get("market_epochs", {}).get("blueprint", unix_time / 86400))
	var card_epoch := int(p.get("market_epochs", {}).get("card", unix_time / 172800))
	var deal_epoch := int(p.get("market_epochs", {}).get("daily_deal", unix_time / 86400))
	var blueprint_key := "blueprint:%d" % day_epoch
	var card_key := "card:%d" % card_epoch
	var blueprints := blueprint_offers(blueprint_key, int(p.get("spool_level", 1)))
	var cards := _typed_card_offers(card_key)
	var all_offers: Array = []
	for offer in blueprints: all_offers.append({"shop":"blueprint","id":str(offer.id),"price":int(offer.price)})
	for offer in cards: all_offers.append({"shop":"card","id":str(offer.id),"price":int(offer.price)})
	for id in PACKS: all_offers.append({"shop":"pack","id":str(id),"price":int(PACKS[id].get("price", 0))})
	for id in UPGRADE_CARDS: all_offers.append({"shop":"upgrade","id":str(id),"price":int(UPGRADE_CARDS[id].get("cost", 0))})
	for id in COSMETICS: all_offers.append({"shop":"cosmetic","id":str(id),"price":int(COSMETICS[id].get("coins", 0))})
	var daily: Dictionary = {} if all_offers.is_empty() else all_offers[posmod(_seed("deal:%d" % deal_epoch), all_offers.size())].duplicate(true)
	daily["discount_bps"] = 2000
	var newcomer := newcomer_shelf(p, unix_time)
	if bool(newcomer.get("active", false)):
		var newcomer_blueprints: Array = []
		for creature in Catalog.CREATURES:
			if str(creature.get("rarity", "")) == "common": newcomer_blueprints.append({"id":str(creature.get("id", "")),"price":int(BLUEPRINT_PRICES.common) / 2,"newcomer":true})
		newcomer["blueprints"] = newcomer_blueprints.slice(0, 3)
	return {"blueprint_epoch":blueprint_key,"card_epoch":card_key,"daily_deal_epoch":deal_epoch,"blueprints":blueprints,"cards":cards,"daily_deal":daily,"packs":PACKS.duplicate(true),"workshop_upgrades":WORKSHOP_UPGRADES.duplicate(true),"upgrade_cards":UPGRADE_CARDS.duplicate(true),"cosmetics":COSMETICS.duplicate(true),"newcomer":newcomer}

static func advance_market_epochs(source: Dictionary, unix_time: int, local_date_key := "") -> Dictionary:
	var p := ensure(source); var epochs: Dictionary = p.market_epochs
	var blueprint_epoch := _seed(local_date_key) if not local_date_key.is_empty() else unix_time / 86400
	var card_epoch := unix_time / 172800; var daily_epoch := blueprint_epoch
	for entry in [["blueprint",blueprint_epoch],["card",card_epoch],["daily_deal",daily_epoch]]:
		var key := str(entry[0]); var requested := int(entry[1]); var current := int(epochs.get(key, -1))
		if requested > current: epochs[key] = requested
		elif current < 0: epochs[key] = requested
	return ok(p, {"epochs":epochs.duplicate(true)})

static func _typed_card_offers(key: String) -> Array:
	var seed := _seed(key)
	var result: Array = []
	var typed := {"creature":3,"spell":2,"filament":2,"equipment":1,"trap":1,"upgrade":1}
	for type in typed:
		var candidates: Array = []
		for definition in all_cards():
			if str(definition.get("type", "")) == type: candidates.append(definition)
		for _index in int(typed[type]):
			seed = _next(seed)
			var rarity := _card_shop_rarity(seed)
			var narrowed: Array = []
			for candidate in candidates:
				if str(candidate.get("rarity", "")) == rarity: narrowed.append(candidate)
			if narrowed.is_empty(): narrowed = candidates
			seed = _next(seed)
			var definition: Dictionary = narrowed[posmod(seed, narrowed.size())]
			result.append({"id":str(definition.get("id", "")),"type":type,"price":int(CARD_PRICES.get(str(definition.get("rarity", "common")), 80)),"epoch":key})
	return result

static func _card_shop_rarity(seed: int) -> String:
	var roll := posmod(seed, 10000)
	if roll < 4000: return "common"
	if roll < 6800: return "uncommon"
	if roll < 8600: return "rare"
	if roll < 9500: return "epic"
	if roll < 9900: return "legendary"
	# The specified 1% Mythic+ band uses the catalog's existing 200/80/20
	# weights, normalized deterministically.
	var top := posmod(_next(seed), 300)
	return "mythic" if top < 200 else ("prismatic" if top < 280 else "primordial")

static func newcomer_shelf(p: Dictionary, unix_time: int) -> Dictionary:
	var started := int(p.get("newcomer_started_at", 0))
	if started <= 0: return {"active":true,"items":[{"kind":"blueprint_discount","discount_bps":5000,"limit":3},{"kind":"basic_pack","price":0,"once":true},{"kind":"upgrade_card","id":"speed_spool","discount_bps":4000,"once":true},{"kind":"spark_bundle","id":"forge_boost","discount_bps":1000,"once":true}]}
	if unix_time - started >= 7 * 86400: return {"active":false,"items":[]}
	return {"active":true,"items":[{"kind":"blueprint_discount","discount_bps":5000,"limit":3},{"kind":"basic_pack","price":0,"once":true},{"kind":"upgrade_card","id":"speed_spool","discount_bps":4000,"once":true},{"kind":"spark_bundle","id":"forge_boost","discount_bps":1000,"once":true}]}

static func begin_newcomer(source: Dictionary, unix_time: int) -> Dictionary:
	var p := ensure(source)
	if int(p.get("newcomer_started_at", 0)) <= 0: p.newcomer_started_at = unix_time
	return ok(p, {"started_at":int(p.newcomer_started_at)})

static func buy_blueprint(source: Dictionary, id: String, unix_time: int) -> Dictionary:
	var p := ensure(source)
	if int(p.get("newcomer_started_at", 0)) <= 0: p.newcomer_started_at = unix_time
	var snapshot := market_snapshot(p, unix_time)
	var offer := {}
	for candidate in snapshot.blueprints:
		if str(candidate.get("id", "")) == id: offer = candidate; break
	if offer.is_empty():
		for candidate in snapshot.get("newcomer", {}).get("blueprints", []):
			if str(candidate.get("id", "")) == id: offer = candidate; break
	if offer.is_empty() or p.owned_blueprints.has(id): return fail(p, "Blueprint is unavailable.")
	var price := int(offer.price)
	if "blueprint_discount" in p.workshop_upgrades: price = price * 9500 / 10000
	var rarity := str(card(id).get("rarity", "common"))
	var newcomer_blueprints := int(p.newcomer_claims.get("blueprint_discount", 0))
	if bool(snapshot.newcomer.get("active", false)) and rarity == "common" and newcomer_blueprints < 3 and not bool(offer.get("newcomer", false)): price = price * 5000 / 10000
	price = _daily_price(snapshot, "blueprint", id, price)
	if int(p.forge_coins) < price: return fail(p, "Not enough Forge Coins.")
	p.forge_coins -= price; p.owned_blueprints[id] = true
	if bool(snapshot.newcomer.get("active", false)) and rarity == "common" and newcomer_blueprints < 3: p.newcomer_claims["blueprint_discount"] = newcomer_blueprints + 1
	return ok(p, {"id":id,"price":price,"shop":"blueprint"})

static func buy_upgrade_card(source: Dictionary, id: String, discount_bps := 0, unix_time := 0) -> Dictionary:
	var p := ensure(source)
	var data: Dictionary = UPGRADE_CARDS.get(id, {})
	if data.is_empty(): return fail(p, "Upgrade Card is unavailable.")
	if unix_time > 0 and int(p.get("newcomer_started_at", 0)) <= 0: p.newcomer_started_at = unix_time
	var price := int(data.get("cost", 0)) * (10000 - clampi(discount_bps, 0, 10000)) / 10000
	if unix_time > 0:
		var snapshot := market_snapshot(p, unix_time)
		price = _daily_price(snapshot, "upgrade", id, price)
		if id == "speed_spool" and bool(snapshot.newcomer.get("active", false)) and not p.newcomer_claims.has("speed_spool"):
			price = price * 6000 / 10000
	if int(p.forge_coins) < price: return fail(p, "Not enough Forge Coins.")
	p.forge_coins -= price; grant_card(p, id)
	if unix_time > 0 and id == "speed_spool" and bool(market_snapshot(p, unix_time).newcomer.get("active", false)): p.newcomer_claims["speed_spool"] = true
	return ok(p, {"id":id,"price":price,"shop":"upgrade_card"})
static func buy_market_card(source: Dictionary, card_id: String, day_key: String) -> Dictionary:
	var p := ensure(source); var offer := {}; for candidate in market_offers(day_key,p): if str(candidate.id) == card_id: offer = candidate
	if offer.is_empty() or int(p.forge_coins) < int(offer.price): return fail(p,"Card is unavailable or unaffordable.")
	p.forge_coins -= int(offer.price); grant_card(p,card_id); return ok(p,{"card_id":card_id,"price":int(offer.price)})
static func buy_market_card_at(source: Dictionary, card_id: String, unix_time: int) -> Dictionary:
	var p := ensure(source); var snapshot := market_snapshot(p, unix_time); var offer := {}
	for candidate in snapshot.cards:
		if str(candidate.get("id", "")) == card_id: offer = candidate; break
	if offer.is_empty(): return fail(p, "Card is unavailable.")
	var price := _daily_price(snapshot, "card", card_id, int(offer.price))
	if int(p.forge_coins) < price: return fail(p, "Not enough Forge Coins.")
	p.forge_coins -= price; grant_card(p, card_id)
	return ok(p, {"id":card_id,"price":price,"shop":"card"})

static func set_wishlist(source: Dictionary, id: String, wanted: bool) -> Dictionary:
	var p := ensure(source)
	if wanted:
		if id in p.wishlist: return ok(p, {"id":id,"wanted":true})
		if p.wishlist.size() >= 5: return fail(p, "Wishlist holds at most five items.")
		p.wishlist.append(id)
	else:
		p.wishlist.erase(id)
	return ok(p, {"id":id,"wanted":wanted})

static func refresh_wishlist_notifications(source: Dictionary, unix_time: int) -> Dictionary:
	var p := ensure(source); var market := market_snapshot(p, unix_time); var visible := {}
	for offer in market.blueprints: visible[str(offer.id)] = true
	for offer in market.cards: visible[str(offer.id)] = true
	for id in p.wishlist:
		if visible.has(str(id)): p.notifications["wishlist:%s" % id] = {"id":id,"unix_time":unix_time}
	return ok(p, {"notifications":p.notifications.duplicate(true)})
static func buy_workshop_upgrade(source: Dictionary, id: String, unix_time := 0) -> Dictionary:
	var p := ensure(source); var upgrade: Dictionary = WORKSHOP_UPGRADES.get(id,{}); if upgrade.is_empty() or id in p.workshop_upgrades: return fail(p,"Upgrade unavailable.")
	if not str(upgrade.get("requires","")).is_empty() and str(upgrade.requires) not in p.workshop_upgrades: return fail(p,"Buy the prerequisite first.")
	if unix_time > 0 and int(p.get("newcomer_started_at", 0)) <= 0: p.newcomer_started_at = unix_time
	var price := int(upgrade.cost)
	if unix_time > 0: price = _daily_price(market_snapshot(p, unix_time), "upgrade", id, price)
	if int(p.forge_coins) < price: return fail(p,"Not enough Forge Coins.")
	p.forge_coins -= price; p.workshop_upgrades.append(id); return ok(p,{"upgrade":id,"price":price})
static func buy_cosmetic(source: Dictionary, id: String, currency := "forge_coins", unix_time := 0) -> Dictionary:
	var p := ensure(source); var data: Dictionary = COSMETICS.get(id, {})
	if data.is_empty() or p.cosmetics.has(id): return fail(p, "Cosmetic is unavailable.")
	if currency not in ["forge_coins", "sparks"]: return fail(p, "Use Forge Coins or Sparks.")
	if unix_time > 0 and int(p.get("newcomer_started_at", 0)) <= 0: p.newcomer_started_at = unix_time
	var price := int(data.get("coins", 0))
	if unix_time > 0: price = _daily_price(market_snapshot(p, unix_time), "cosmetic", id, price)
	if int(p.get(currency, 0)) < price: return fail(p, "Not enough %s." % ("Sparks" if currency == "sparks" else "Forge Coins"))
	p[currency] -= price; p.cosmetics[id] = true
	return ok(p, {"id":id,"currency":currency,"price":price})
static func fake_store_purchase(source: Dictionary, purchase_id: String, product_id: String) -> Dictionary:
	var p := ensure(source)
	if p.fake_store_receipts.has(purchase_id): return ok(p, {"purchase_id":purchase_id,"duplicate":true})
	var bundle: Dictionary = SPARK_BUNDLES.get(product_id, {})
	if bundle.is_empty(): return fail(p, "Local store product is unavailable.")
	p.fake_store_receipts[purchase_id] = product_id; p.sparks += int(bundle.get("sparks", 0))
	return ok(p, {"purchase_id":purchase_id,"sparks":int(bundle.get("sparks", 0)),"provider":"fake_local"})

static func fake_store_purchase_at(source: Dictionary, purchase_id: String, product_id: String, unix_time: int) -> Dictionary:
	var p := ensure(source)
	if int(p.get("newcomer_started_at", 0)) <= 0: p.newcomer_started_at = unix_time
	if p.fake_store_receipts.has(purchase_id): return ok(p, {"purchase_id":purchase_id,"duplicate":true})
	var bundle: Dictionary = SPARK_BUNDLES.get(product_id, {})
	if bundle.is_empty(): return fail(p, "Local store product is unavailable.")
	var sparks := int(bundle.get("sparks", 0))
	var price_cents := int(bundle.get("price_cents", 0))
	var snapshot := market_snapshot(p, unix_time)
	if product_id == "forge_boost" and bool(snapshot.newcomer.get("active", false)) and not p.newcomer_claims.has("forge_boost"):
		price_cents = price_cents * 9000 / 10000
		p.newcomer_claims["forge_boost"] = true
	p.fake_store_receipts[purchase_id] = product_id; p.sparks += sparks
	return ok(p, {"purchase_id":purchase_id,"sparks":sparks,"price_cents":price_cents,"provider":"fake_local"})

static func _daily_price(snapshot: Dictionary, shop: String, id: String, price: int) -> int:
	var deal: Dictionary = snapshot.get("daily_deal", {})
	if str(deal.get("shop", "")) == shop and str(deal.get("id", "")) == id: return price * (10000 - int(deal.get("discount_bps", 2000))) / 10000
	return price
static func buy_paid_season(source: Dictionary) -> Dictionary:
	var p := ensure(source)
	if bool(p.season.get("paid", false)): return ok(p, {"already_owned":true})
	if int(p.sparks) < 1200: return fail(p, "Need 1,200 Sparks for the Season Track.")
	p.sparks -= 1200; p.season.paid = true
	return ok(p, {"price":1200,"currency":"sparks"})
static func buy_pack(source: Dictionary, pack_id: String, entropy: PackedByteArray = PackedByteArray(), unix_time := 0) -> Dictionary:
	var p := ensure(source); var pack: Dictionary = PACKS.get(pack_id,{}); if pack.is_empty(): return fail(p,"Pack is unavailable or unaffordable.")
	if not p.pending_pack_reveal.is_empty(): return fail(p,"Reveal the current pack first.")
	if unix_time > 0 and int(p.get("newcomer_started_at", 0)) <= 0: p.newcomer_started_at = unix_time
	var price := int(pack.price)
	if unix_time > 0:
		var snapshot := market_snapshot(p, unix_time)
		price = _daily_price(snapshot, "pack", pack_id, price)
		if pack_id == "basic" and bool(snapshot.newcomer.get("active", false)) and not p.newcomer_claims.has("basic_pack"):
			price = 0
	if int(p.forge_coins) < price: return fail(p,"Pack is unavailable or unaffordable.")
	var seed := _seed_bytes(entropy,p.rng_nonce)
	var cards := _generate_pack_cards(pack_id, seed)
	var pity := int(p.pack_pity.get(pack_id, 0)) + 1
	var bonus_cards: Array = []
	if pack_id == "basic" and pity >= 51:
		# Rare Reward Pack is a normal five-card pool with exactly one Rare+.
		bonus_cards = _generate_guaranteed_cards(5, _next(seed + 51), "common", "primordial", 1, "rare", false)
		pity = 0
	elif pack_id != "basic" and pity >= 51:
		cards[_lowest_rarity_index(cards)] = _roll_card(_next(seed + 51), "legendary")
	var found_legendary := false
	for id in cards:
		if _rarity_index(str(card(str(id)).get("rarity", "common"))) >= _rarity_index("legendary"): found_legendary = true
	for id in bonus_cards:
		if _rarity_index(str(card(str(id)).get("rarity", "common"))) >= _rarity_index("legendary"): found_legendary = true
	if found_legendary: pity = 0
	p.pack_pity[pack_id] = pity; p.rng_nonce += 1; p.forge_coins -= price
	if unix_time > 0 and pack_id == "basic" and price == 0: p.newcomer_claims["basic_pack"] = true
	for id in cards: grant_card(p, str(id))
	for id in bonus_cards: grant_card(p, str(id))
	p.pending_pack_reveal = {"pack_id":pack_id,"cards":cards,"bonus_cards":bonus_cards,"receipt":"pack-%d" % p.rng_nonce}
	return ok(p,{"pack_id":pack_id,"cards":cards,"bonus_cards":bonus_cards,"pending_reveal":true})
static func clear_pack_reveal(source: Dictionary) -> Dictionary:
	var p := ensure(source)
	var cards: Array = p.pending_pack_reveal.get("cards", [])
	var bonus_cards: Array = p.pending_pack_reveal.get("bonus_cards", [])
	p.pending_pack_reveal = {}
	return ok(p,{"cards":cards.duplicate(),"bonus_cards":bonus_cards.duplicate()})
static func dismantle_card(source: Dictionary, card_id: String, count := 1) -> Dictionary:
	var p := ensure(source); var def := card(card_id); if def.is_empty() or count <= 0 or int(p.owned_cards.get(card_id,0)) < count: return fail(p,"Card cannot be dismantled.")
	for deck in p.decks: if deck.get("cards",[]).count(card_id) > int(p.owned_cards.get(card_id,0))-count: return fail(p,"Dismantling would invalidate a saved deck.")
	p.owned_cards[card_id] -= count; var earned := int(CARD_PRICES.get(str(def.rarity),80)) / 4 * count; p.forge_coins += earned; return ok(p,{"coins":earned})
static func settle_unified_battle(source: Dictionary, result_id: String, _played: Array, victory: bool, _salvage: int, coins := 0) -> Dictionary:
	var p := ensure(source); if p.claim_receipts.has(result_id): return ok(p,{"id":result_id,"duplicate":true})
	p.claim_receipts[result_id] = true; p.forge_coins += maxi(0,coins)
	p.wins.lifetime = int(p.wins.get("lifetime",0)) + (1 if victory else 0)
	p.wins.streak = int(p.wins.get("streak",0)) + 1 if victory else 0
	var battle_xp := 50 if victory else 25
	p.season.xp = int(p.season.get("xp",0)) + battle_xp
	var spool := grant_spool_xp(p, battle_xp)
	var drop := battle_drop(p, result_id, victory)
	p = drop.profile
	return ok(p,{"id":result_id,"duplicate":false,"drop":drop.get("payload", {}),"spool":spool})

static func daily_quests(source: Dictionary, day_key: String) -> Dictionary:
	var p := ensure(source); var state: Dictionary = p.quest_state
	if str(state.get("day_key", "")) == day_key and state.get("quests", []) is Array: return ok(p, {"quests":state.get("quests", []),"rerolls":int(state.get("rerolls", 0))})
	var count := 4 if "daily_quest_slot" in p.workshop_upgrades else 3
	var quests := _generate_quests(day_key, count, 0)
	p.quest_state = {"day_key":day_key,"quests":quests,"rerolls":1,"claimed":[]}
	return ok(p, {"quests":quests,"rerolls":1})
static func reroll_daily_quest(source: Dictionary, day_key: String, quest_index: int) -> Dictionary:
	var p := ensure(source); var generated := daily_quests(p, day_key); p = generated.profile
	var state: Dictionary = p.quest_state
	if int(state.get("rerolls", 0)) <= 0 or quest_index < 0 or quest_index >= (state.get("quests", []) as Array).size(): return fail(p, "No free quest reroll is available.")
	var old: Dictionary = state.quests[quest_index]
	var replacement: Dictionary = _generate_quests(day_key, 1, quest_index + 1)[0]
	if str(replacement.get("objective", "")) == str(old.get("objective", "")): replacement = _generate_quests(day_key + ":again", 1, quest_index + 7)[0]
	state.quests[quest_index] = replacement; state.rerolls = int(state.rerolls) - 1
	return ok(p, {"quest":replacement,"rerolls":state.rerolls})
static func claim_daily_quest(source: Dictionary, day_key: String, quest_id: String) -> Dictionary:
	var p := ensure(source); var generated := daily_quests(p, day_key); p = generated.profile; var state: Dictionary = p.quest_state
	if quest_id in state.claimed: return ok(p, {"id":quest_id,"duplicate":true})
	var quest := {}
	for entry in state.quests:
		if str(entry.get("id", "")) == quest_id: quest = entry; break
	if quest.is_empty(): return fail(p, "Quest is unavailable.")
	if not bool(quest.get("completed", false)): return fail(p, "Quest objective is not complete.")
	var reward: Dictionary = QUEST_REWARDS.get(str(quest.get("tier", "bronze")), QUEST_REWARDS.bronze)
	p.forge_coins += int(reward.coins); p.season.xp += int(reward.xp); var spool := grant_spool_xp(p, int(reward.xp)); state.claimed.append(quest_id)
	var reward_rarity := str(reward.rarity)
	if str(quest.get("tier", "")) == "gold": reward_rarity = "rare" if posmod(_next(_seed(quest_id)), 100) < 25 else "uncommon"
	var awarded := _roll_card(_next(_seed(quest_id)), reward_rarity, reward_rarity); grant_card(p, awarded)
	return ok(p, {"id":quest_id,"coins":int(reward.coins),"xp":int(reward.xp),"card":awarded,"spool":spool})
static func record_quest_progress(source: Dictionary, day_key: String, event_name: String, amount := 1) -> Dictionary:
	var p := ensure(source); var generated := daily_quests(p, day_key); p = generated.profile; var state: Dictionary = p.quest_state
	for index in (state.get("quests", []) as Array).size():
		var quest: Dictionary = state.quests[index]
		var objective := str(quest.get("objective", ""))
		var matches := (event_name == "win" and objective in ["win_1","win_3","win_10_streak"]) or event_name == objective
		if matches and not bool(quest.get("completed", false)):
			quest.progress = mini(int(quest.get("target", 1)), int(quest.get("progress", 0)) + maxi(1, amount))
			quest.completed = int(quest.progress) >= int(quest.get("target", 1))
	return ok(p, {"quests":state.quests.duplicate(true)})
static func academy_three_star_reward(source: Dictionary, receipt_id: String, entropy: PackedByteArray = PackedByteArray()) -> Dictionary:
	var p := ensure(source)
	if p.academy_rewards.has(receipt_id): return ok(p, {"id":receipt_id,"duplicate":true})
	p.academy_rewards[receipt_id] = true
	var seed := _seed_bytes(entropy, p.rng_nonce); p.rng_nonce += 1
	if posmod(seed, 100) >= 30: return ok(p, {"id":receipt_id,"awarded":false})
	var exact_rarity := "common" if posmod(_next(seed), 2) == 0 else "uncommon"
	var awarded := _roll_card(_next(seed), exact_rarity, exact_rarity); grant_card(p, awarded)
	var spool := grant_spool_xp(p, 100); p.season.xp += 100
	return ok(p, {"id":receipt_id,"awarded":true,"card":awarded,"xp":100,"spool":spool})
static func battle_drop(source: Dictionary, receipt_id: String, victory: bool) -> Dictionary:
	var p := ensure(source)
	if p.drop_receipts.has(receipt_id): return ok(p, {"id":receipt_id,"duplicate":true})
	p.drop_receipts[receipt_id] = true
	var streak := int(p.wins.get("streak", 0)); var lifetime := int(p.wins.get("lifetime", 0))
	var base_bps := 50
	if victory:
		base_bps = 300 if streak < 5 else (500 if streak < 10 else (700 if streak < 25 else (1000 if streak < 50 else 1200)))
		base_bps += mini(200, (lifetime / 10) * 5)
	var guaranteed := victory and int(p.wins.get("since_drop", 0)) >= 40
	var roll := posmod(_seed(receipt_id), 10000)
	if not guaranteed and roll >= base_bps:
		p.wins.since_drop = int(p.wins.get("since_drop", 0)) + 1 if victory else 0
		return ok(p, {"id":receipt_id,"dropped":false,"chance_bps":base_bps})
	p.wins.since_drop = 0
	var rarity_roll := posmod(_next(_seed(receipt_id)), 100)
	var rarity := "uncommon" if rarity_roll < 60 else ("rare" if rarity_roll < 90 else ("epic" if rarity_roll < 98 else "legendary"))
	var awarded := _roll_card(_next(_seed(receipt_id)), rarity, rarity); grant_card(p, awarded)
	return ok(p, {"id":receipt_id,"dropped":true,"card":awarded,"rarity":rarity,"guaranteed":guaranteed,"chance_bps":base_bps})
static func ensure_season(source: Dictionary, unix_time: int) -> Dictionary:
	var p := ensure(source)
	if int(p.season.get("started_at", 0)) <= 0:
		p.season.started_at = unix_time
		p.season.ends_at = unix_time + 90 * 86400
	return ok(p, {"started_at":int(p.season.started_at),"ends_at":int(p.season.ends_at)})
static func season_level(p: Dictionary) -> int: return clampi(int(p.get("season", {}).get("xp", 0)) / 1000, 0, 50)
static func claim_season_level(source: Dictionary, level: int, paid_track := false, unix_time := 0) -> Dictionary:
	var p := ensure(source)
	if unix_time > 0:
		var initialized := ensure_season(p, unix_time); p = initialized.profile
		if unix_time >= int(p.season.get("ends_at", 0)): return fail(p, "This Season has ended.")
	if level < 1 or level > season_level(p): return fail(p, "Season level is not unlocked.")
	var key := "%s:%d" % ["paid" if paid_track else "free", level]
	if key in p.season.claimed: return ok(p, {"key":key,"duplicate":true})
	if paid_track and not bool(p.season.get("paid", false)): return fail(p, "Paid Season Track is locked.")
	p.season.claimed.append(key)
	var reward := {"coins":100 if paid_track else 50}
	p.forge_coins += int(reward.coins)
	if level % 5 == 0:
		var pack_id := "forge" if paid_track else "basic"
		var cards := _generate_pack_cards(pack_id, _seed(key))
		for card_id in cards: grant_card(p, card_id)
		reward["pack_id"] = pack_id; reward["cards"] = cards
	if not paid_track and level in [10,20,30,40]: var free_card := _roll_card(_seed(key + ":u"), "uncommon", "uncommon"); grant_card(p, free_card); reward["bonus_card"] = free_card
	if not paid_track and level == 50: var rare_card := _roll_card(_seed(key + ":r"), "rare", "rare"); grant_card(p, rare_card); reward["bonus_card"] = rare_card
	if paid_track and level in [10,20,30,40]:
		var arcane_cards := _generate_pack_cards("arcane", _seed(key + ":arcane"))
		for card_id in arcane_cards: grant_card(p, card_id)
		reward["arcane_cards"] = arcane_cards
	if paid_track and level == 25: p.cosmetics["season-printer-skin"] = true; reward["cosmetic"] = "season-printer-skin"
	if paid_track and level == 50: p.cosmetics["season-card-back"] = true; reward["cosmetic"] = "season-card-back"
	return ok(p, reward)
static func _generate_quests(day_key: String, count: int, salt: int) -> Array:
	var result: Array = []; var seed := _seed(day_key) + salt
	for index in count:
		seed = _next(seed); var roll := posmod(seed, 100); var tier := "bronze" if roll < 50 else ("silver" if roll < 80 else ("gold" if roll < 98 else "legendary"))
		var objectives: Array = QUEST_TEMPLATES[tier]; var objective := str(objectives[posmod(_next(seed), objectives.size())])
		var target := 1
		if objective == "win_3": target = 3
		elif objective == "win_10_streak": target = 10
		elif objective == "destroy_5": target = 5
		result.append({"id":"%s:%d:%d" % [day_key,salt,index],"tier":tier,"objective":objective,"target":target,"progress":0,"completed":false})
	return result
static func apply_printer_nodes(source: Dictionary, desired: Array) -> Dictionary: return fail(ensure(source),"Printer skill nodes were replaced by Workshop Upgrades and Upgrade Cards.")
static func respec_printer(source: Dictionary) -> Dictionary: return fail(ensure(source),"Workshop upgrades are permanent.")
static func build_card(source: Dictionary, _id: String, _node: String) -> Dictionary: return fail(ensure(source),"Card build nodes were removed in v3.")
static func respec_card(source: Dictionary, _id: String) -> Dictionary: return fail(ensure(source),"Card build nodes were removed in v3.")
static func build_effect_label(_id: String, _node: String) -> String: return "Replaced by authored v3 card effects."
static func _roll_card(seed: int, minimum: String, maximum := "primordial") -> String:
	var available: Array = []
	var total_weight := 0
	for rarity in RARITY_ORDER:
		if _rarity_index(rarity) < _rarity_index(minimum) or _rarity_index(rarity) > _rarity_index(maximum): continue
		var weight := int({"common":4500,"uncommon":2500,"rare":1500,"epic":800,"legendary":400,"mythic":200,"prismatic":80,"primordial":20}.get(rarity, 0))
		if weight <= 0: continue
		var cards_of_rarity: Array = []
		for definition in all_cards():
			if str(definition.get("rarity", "")) == rarity: cards_of_rarity.append(definition)
		if not cards_of_rarity.is_empty():
			available.append({"cards":cards_of_rarity,"weight":weight})
			total_weight += weight
	var roll := posmod(seed, maxi(1, total_weight))
	for group in available:
		if roll < int(group.weight):
			var entries: Array = group.cards
			return str(entries[posmod(_next(seed), entries.size())].get("id", ""))
		roll -= int(group.weight)
	return "raw_filament"
static func _pack_cards(seed: int, count: int, minimum: String) -> Array:
	var result: Array = []
	var value := seed
	for _index in count:
		value = _next(value); result.append(_roll_card(value, minimum))
	return result
static func _generate_guaranteed_cards(count: int, seed: int, pool_min: String, pool_max: String, guarantee_count: int, guarantee_min: String, legendary_guarantee: bool) -> Array:
	var cards: Array = []
	var value := seed
	for _index in count:
		value = _next(value); cards.append(_roll_card(value, pool_min, pool_max))
	for index in guarantee_count:
		var lowest := _lowest_rarity_index(cards)
		if _rarity_index(str(card(str(cards[lowest])).get("rarity", "common"))) < _rarity_index(guarantee_min):
			value = _next(value); cards[lowest] = _roll_card(value, guarantee_min, "primordial")
	if legendary_guarantee:
		var legendary_slot := _lowest_rarity_index(cards)
		if _rarity_index(str(card(str(cards[legendary_slot])).get("rarity", "common"))) < _rarity_index("legendary"):
			value = _next(value); cards[legendary_slot] = _roll_card(value, "legendary", "primordial")
	return cards
static func _generate_pack_cards(pack_id: String, seed: int) -> Array:
	var pack: Dictionary = PACKS.get(pack_id, {})
	if pack_id == "basic": return _generate_guaranteed_cards(int(pack.get("count", 5)), seed, "common", str(pack.get("pool_max", "uncommon")), 0, "common", false)
	return _generate_guaranteed_cards(int(pack.get("count", 5)), seed, "common", "primordial", int(pack.get("guaranteed", 0)), str(pack.get("minimum", "common")), bool(pack.get("legendary", false)))
static func _lowest_rarity_index(ids: Array) -> int:
	var chosen := 0; var chosen_rarity := 99
	for index in ids.size():
		var rarity := _rarity_index(str(card(str(ids[index])).get("rarity", "common")))
		if rarity < chosen_rarity: chosen = index; chosen_rarity = rarity
	return chosen
static func _rarity_index(id: String) -> int: return maxi(0,RARITY_ORDER.find(id))
static func _seed(text: String) -> int:
	var n := 17
	for byte in text.to_utf8_buffer(): n = (n * 131 + int(byte)) & 0x7fffffff
	return n
static func _seed_bytes(bytes: PackedByteArray, fallback: int) -> int:
	var n := fallback
	for byte in bytes: n = (n * 257 + int(byte)) & 0x7fffffff
	return n
static func _next(value: int) -> int: return int((value*1103515245+12345)&0x7fffffff)
static func ok(profile: Dictionary, payload: Dictionary) -> Dictionary: return {"ok":true,"profile":profile,"payload":payload}
static func fail(profile: Dictionary, error: String) -> Dictionary: return {"ok":false,"profile":profile,"error":error}
