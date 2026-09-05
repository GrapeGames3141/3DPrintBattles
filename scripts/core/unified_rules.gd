class_name UnifiedRules
extends RefCounted
## Canonical PrintForge Legends v3.2 catalog and profile transitions.
## All costs, odds and timers live here rather than in presentation code.

const VERSION := "3.2.0"
const V3_CATALOG := preload("res://scripts/core/v3_catalog.gd")
const V3_PROFILE_STATE := preload("res://scripts/core/v3_profile_state.gd")
const V3_ECONOMY := preload("res://scripts/core/v3_economy_rules.gd")
const STARTER_IDS: Array[String] = ["cinderpaw", "aquafin", "voltwig"]
const FOUNDER_VERSION := "founder_v1"
const PACK_RETURN_ROUTES := ["workshop", "unified_library", "unified_market", "settings"]
const FOUNDER_PACKS := [
	["starter", "starter", "starter", "starter", "mossmunk", "mossmunk", "mossmunk", "raw_filament", "raw_filament", "heated_spool", "layer_melt", "standard_full_suit", "iron_gem"],
	["starter", "starter", "starter", "starter", "mossmunk", "mossmunk", "mossmunk", "raw_filament", "heated_spool", "print_jam", "spool_drain", "reinforced_full_suit", "counter_strike"],
	["starter", "starter", "starter", "mossmunk", "mossmunk", "raw_filament", "forge_surge", "emergency_reprint_spell", "blueprint_thief", "filament_ring", "print_interrupt", "speed_spool", "reinforced_chassis"],
]
const DECK_SLOTS := [{"id":"starter-deck","name":"Forge Deck"},{"id":"deck-slot-2","name":"Queue Deck"},{"id":"deck-slot-3","name":"Arcane Deck"}]
const RARITY_ORDER := ["common","uncommon","rare","epic","legendary","mythic","prismatic","primordial"]
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
	return ensure({"forge_coins":1000,"sparks":0,"onboarding":{"state":"choose_starter","starter_id":"","founder_version":FOUNDER_VERSION},"decks":[],"active_deck_id":"starter-deck","spool_level":1,"spool_xp":0,"rng_nonce":1})

static func all_cards() -> Array:
	# Every live v3 card is loaded from the shared JSON document. Legacy Catalog
	# remains only for Workshop art/provenance callers outside this rules layer.
	return V3_CATALOG.cards()
static func card(id: String) -> Dictionary:
	return V3_CATALOG.card(id)
static func ensure(source: Dictionary) -> Dictionary:
	var p := V3_PROFILE_STATE.ensure_base(source, VERSION)
	_migrate_equipment_ids(p)
	_migrate_creature_blueprint_ownership(p)
	if str(p.onboarding.get("state", "")) == "complete" and not _founder_incomplete(p):
		var active_deck_is_legal := _active_deck_is_legal(p)
		if _starter_deck_needs_repair(p): _make_starter_deck(p, not active_deck_is_legal, str(p.onboarding.get("starter_id", "cinderpaw")))
		elif not active_deck_is_legal: p.active_deck_id = "starter-deck"
	if not p.decks.is_empty(): _ensure_deck_slots(p)
	return p
static func choose_starter(source: Dictionary, id: String) -> Dictionary:
	var p := ensure(source)
	if str(p.onboarding.get("state", "choose_starter")) != "choose_starter" or id not in STARTER_IDS: return fail(p, "Choose an available starter.")
	var founder := str(p.onboarding.get("founder_version", "")) == FOUNDER_VERSION
	p.onboarding = {"state":"starter_selected","starter_id":id,"founder_version":FOUNDER_VERSION} if founder else {"state":"starter_selected","starter_id":id}
	grant_card(p, id)
	if founder: _make_provisional_starter_deck(p, id)
	return ok(p, {"card_id":id})
static func print_starter(source: Dictionary) -> Dictionary:
	var p := ensure(source); var id := str(p.onboarding.get("starter_id", "")); if str(p.onboarding.get("state", "")) != "starter_selected" or id not in STARTER_IDS: return fail(p,"Choose a starter first.")
	p.onboarding.state = "complete"
	p.printed_models["starter-%s" % id] = {"blueprint_id":id,"source":"starter"}
	if _is_founder(p):
		p.starter_pack_rewards = {"kind":FOUNDER_VERSION,"entitled":3,"opened":0,"kept":0}
		return ok(p,{"creature_id":id,"free":true,"starter_packs":3,"founder":true})
	_make_starter_deck(p, true, id)
	if int(p.starter_pack_rewards.get("entitled", 0)) == 0 and int(p.starter_pack_rewards.get("opened", 0)) == 0:
		p.starter_pack_rewards = {"entitled":3,"opened":0}
		# Replaces the old free Newcomer Shelf pack while retaining its discounts.
		p.newcomer_claims["basic_pack"] = true
	return ok(p,{"creature_id":id,"free":true,"starter_packs":3})
static func print_workshop_model(source: Dictionary, blueprint_id: String, receipt_id := "") -> Dictionary:
	var p := ensure(source)
	if not has_printable_blueprint(p, blueprint_id): return fail(p, "Learn this blueprint before printing it.")
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
	p.owned_cards[card_id] = int(p.owned_cards.get(card_id,0)) + count
	if str(card(card_id).get("type", "")) in ["creature", "equipment"]: p.owned_blueprints[card_id] = true
	return {"card_id":card_id,"count":count}

static func has_printable_blueprint(p: Dictionary, blueprint_id: String) -> bool:
	return bool(p.get("owned_blueprints", {}).get(blueprint_id, false)) and not card(blueprint_id).is_empty()

static func _migrate_creature_blueprint_ownership(p: Dictionary) -> void:
	# Cards and printable licenses now travel together, while printed models and
	# decks remain independent records. Both loops are idempotent.
	for card_id in p.owned_cards.keys():
		if str(card(str(card_id)).get("type", "")) in ["creature", "equipment"] and int(p.owned_cards.get(card_id, 0)) > 0:
			p.owned_blueprints[str(card_id)] = true
	for blueprint_id in p.owned_blueprints.keys():
		if str(card(str(blueprint_id)).get("type", "")) in ["creature", "equipment"] and bool(p.owned_blueprints.get(blueprint_id, false)) and int(p.owned_cards.get(blueprint_id, 0)) <= 0:
			grant_card(p, str(blueprint_id), 1)

static func _migrate_equipment_ids(p: Dictionary) -> void:
	# This is an idempotent catalog alias pass for the initial v3 save namespace,
	# not a migration from the retired 0.7 profile. Merge duplicate ownership
	# deterministically before replacing deck, pre-print, and wishlist references.
	var aliases := {
		"helm":"standard_full_suit", "chest_plate":"reinforced_full_suit", "leg_guards":"reinforced_full_suit",
		"full_suit":"arcane_full_suit", "arcane_plate":"masterwork_full_suit",
		"iron_claw":"iron_gem", "ember_fang":"ember_gem", "frost_shard":"frost_gem",
		"thunder_coil":"storm_gem", "arcane_drill":"arcane_gem",
		"tidal_core":"frost_gem", "arcane_sigil":"arcane_gem"
	}
	for source_id in aliases:
		var target_id := str(aliases[source_id])
		if p.owned_cards.has(source_id):
			p.owned_cards[target_id] = int(p.owned_cards.get(target_id, 0)) + int(p.owned_cards.get(source_id, 0))
			p.owned_cards.erase(source_id)
		if p.owned_blueprints.has(source_id):
			p.owned_blueprints[target_id] = bool(p.owned_blueprints.get(target_id, false)) or bool(p.owned_blueprints.get(source_id, false))
			p.owned_blueprints.erase(source_id)
	for deck in p.decks:
		if not deck is Dictionary or not deck.get("cards", []) is Array: continue
		var normalized: Array = []
		for card_id in deck.cards: normalized.append(str(aliases.get(str(card_id), str(card_id))))
		deck["cards"] = normalized
	var normalized_preprints: Array = []
	for card_id in p.preprints: normalized_preprints.append(str(aliases.get(str(card_id), str(card_id))))
	p.preprints = normalized_preprints
	var normalized_wishlist: Array = []
	for item_id in p.wishlist:
		var normalized_id := str(aliases.get(str(item_id), str(item_id)))
		if normalized_id not in normalized_wishlist: normalized_wishlist.append(normalized_id)
	p.wishlist = normalized_wishlist
	for model_id in p.printed_models:
		var model: Variant = p.printed_models[model_id]
		if model is Dictionary and model.has("blueprint_id"):
			model["blueprint_id"] = str(aliases.get(str(model.get("blueprint_id", "")), str(model.get("blueprint_id", ""))))
	if p.pending_pack_reveal is Dictionary:
		for key in ["cards", "bonus_cards"]:
			if not p.pending_pack_reveal.has(key): continue
			var raw_cards: Variant = p.pending_pack_reveal.get(key, [])
			if not raw_cards is Array: continue
			var normalized_cards: Array = []
			for card_id in raw_cards: normalized_cards.append(str(aliases.get(str(card_id), str(card_id))))
			p.pending_pack_reveal[key] = normalized_cards
static func _starter_cards(starter_id: String) -> Array:
	var cards: Array = []
	for _copy in 12: cards.append(starter_id)
	for _copy in 8: cards.append("mossmunk")
	# The existing twenty non-creature support cards stay unchanged.
	for id in ["raw_filament","raw_filament","raw_filament","raw_filament","heated_spool","heated_spool","layer_melt","print_jam","spool_drain","forge_surge","emergency_reprint_spell","blueprint_thief","standard_full_suit","reinforced_full_suit","iron_gem","filament_ring","counter_strike","print_interrupt","speed_spool","reinforced_chassis"]: cards.append(id)
	return cards
static func _is_founder(p: Dictionary) -> bool:
	return str(p.get("onboarding", {}).get("founder_version", "")) == FOUNDER_VERSION
static func _founder_incomplete(p: Dictionary) -> bool:
	if not _is_founder(p): return false
	return int(p.get("starter_pack_rewards", {}).get("kept", 0)) < 3
static func _founder_cards(starter_id: String, opened: int) -> Array:
	if opened < 0 or opened >= FOUNDER_PACKS.size(): return []
	var cards: Array = []
	for card_id in FOUNDER_PACKS[opened]: cards.append(starter_id if str(card_id) == "starter" else str(card_id))
	return cards
static func _make_provisional_starter_deck(p: Dictionary, starter_id: String) -> void:
	var decks: Array = []
	var added := false
	for deck in p.decks:
		if deck is Dictionary and str(deck.get("id", "")) == "starter-deck":
			if not added:
				decks.append({"id":"starter-deck","name":"Forge Deck","cards":[starter_id]})
				added = true
			continue
		decks.append(deck)
	if not added: decks.push_front({"id":"starter-deck","name":"Forge Deck","cards":[starter_id]})
	p.decks = decks
	p.active_deck_id = "starter-deck"
	_ensure_deck_slots(p)
static func _starter_deck_needs_repair(p: Dictionary) -> bool:
	var starter_count := 0
	var starter_cards: Array = []
	for deck in p.decks:
		if deck is Dictionary and str(deck.get("id", "")) == "starter-deck":
			starter_count += 1
			if starter_count == 1: starter_cards = deck.get("cards", []) if deck.get("cards", []) is Array else []
	return starter_count != 1 or not deck_reason(p, starter_cards).is_empty()
static func _active_deck_is_legal(p: Dictionary) -> bool:
	for deck in p.decks:
		if deck is Dictionary and str(deck.get("id", "")) == str(p.get("active_deck_id", "starter-deck")):
			var cards: Array = deck.get("cards", []) if deck.get("cards", []) is Array else []
			return deck_reason(p, cards).is_empty()
	return false
static func _make_starter_deck(p: Dictionary, activate_starter := true, starter_id := "cinderpaw") -> void:
	var cards := _starter_cards(starter_id if starter_id in STARTER_IDS else "cinderpaw")
	for id in cards: grant_card(p,id,maxi(0,cards.count(id)-int(p.owned_cards.get(id,0))))
	var normalized_decks: Array = []
	var starter_added := false
	for deck in p.decks:
		if deck is Dictionary and str(deck.get("id", "")) == "starter-deck":
			if not starter_added:
				normalized_decks.append({"id":"starter-deck","name":"Forge Deck","cards":cards.duplicate()})
				starter_added = true
			continue
		normalized_decks.append(deck)
	if not starter_added: normalized_decks.push_front({"id":"starter-deck","name":"Forge Deck","cards":cards.duplicate()})
	p.decks = normalized_decks
	_ensure_deck_slots(p)
	if activate_starter: p.active_deck_id = "starter-deck"
static func _ensure_deck_slots(p: Dictionary) -> void:
	for slot in DECK_SLOTS:
		var found := false
		for deck in p.decks:
			if str(deck.get("id", "")) == str(slot.id): found = true; deck["name"] = str(slot.name)
		if not found: p.decks.append({"id":str(slot.id),"name":str(slot.name),"cards":[]})
static func deck_reason(p: Dictionary, cards: Array) -> String:
	if _founder_incomplete(p): return "Keep all three Founder packs before editing or activating a deck."
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
	for type in ["creature", "equipment"]:
		var slots := 8 if type == "creature" else 4
		for _i in slots:
			seed = _next(seed); var candidates: Array = []; for definition in all_cards(): if str(definition.get("type", "")) == type and RARITY_ORDER.find(str(definition.get("rarity", "common"))) <= max_index: candidates.append(definition)
			if candidates.is_empty(): continue
			# A 0.2% deterministic injection ignores the level gate for this slot.
			# Equipment currently has no primordial definition, so an empty injection
			# pool must retain the eligible pool rather than silently removing a slot.
			if posmod(seed, 10000) < 20:
				var primordial: Array = []
				for definition in all_cards():
					if str(definition.get("type", "")) == type and str(definition.get("rarity", "")) == "primordial": primordial.append(definition)
				if not primordial.is_empty(): candidates = primordial
			var item: Dictionary = candidates[posmod(seed, candidates.size())]
			result.append({"id":str(item.get("id", "")),"price":int(BLUEPRINT_PRICES.get(str(item.get("rarity", "common")),50)),"epoch":day_key,"type":type})
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
	var priced_packs: Dictionary = {}
	for pack_id in PACKS:
		var pack: Dictionary = (PACKS[pack_id] as Dictionary).duplicate(true)
		var effective_price := _daily_price({"daily_deal":daily}, "pack", str(pack_id), int(pack.get("price", 0)))
		if str(pack_id) == "basic" and bool(newcomer.get("active", false)) and not p.newcomer_claims.has("basic_pack"):
			effective_price = 0
		pack["effective_price"] = effective_price
		priced_packs[str(pack_id)] = pack
	if bool(newcomer.get("active", false)):
		var newcomer_blueprints: Array = []
		for creature in Catalog.CREATURES:
			if str(creature.get("rarity", "")) == "common": newcomer_blueprints.append({"id":str(creature.get("id", "")),"price":int(BLUEPRINT_PRICES.common) / 2,"newcomer":true})
		newcomer["blueprints"] = newcomer_blueprints.slice(0, 3)
	return {"blueprint_epoch":blueprint_key,"card_epoch":card_key,"daily_deal_epoch":deal_epoch,"blueprints":blueprints,"cards":cards,"daily_deal":daily,"packs":priced_packs,"workshop_upgrades":WORKSHOP_UPGRADES.duplicate(true),"upgrade_cards":UPGRADE_CARDS.duplicate(true),"cosmetics":COSMETICS.duplicate(true),"newcomer":newcomer}

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
	if offer.is_empty() or has_printable_blueprint(p, id): return fail(p, "Blueprint is unavailable.")
	var price := int(offer.price)
	if "blueprint_discount" in p.workshop_upgrades: price = price * 9500 / 10000
	var rarity := str(card(id).get("rarity", "common"))
	var newcomer_blueprints := int(p.newcomer_claims.get("blueprint_discount", 0))
	if bool(snapshot.newcomer.get("active", false)) and rarity == "common" and newcomer_blueprints < 3 and not bool(offer.get("newcomer", false)): price = price * 5000 / 10000
	price = _daily_price(snapshot, "blueprint", id, price)
	if not V3_ECONOMY.spend(p, "forge_coins", price): return fail(p, "Not enough Forge Coins.")
	p.owned_blueprints[id] = true
	if str(card(id).get("type", "")) in ["creature", "equipment"] and int(p.owned_cards.get(id, 0)) <= 0: grant_card(p, id)
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
	if not V3_ECONOMY.spend(p, "forge_coins", price): return fail(p, "Not enough Forge Coins.")
	grant_card(p, id)
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
	if not V3_ECONOMY.spend(p, "forge_coins", price): return fail(p, "Not enough Forge Coins.")
	grant_card(p, card_id)
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
	if not V3_ECONOMY.spend(p, "forge_coins", price): return fail(p,"Not enough Forge Coins.")
	p.workshop_upgrades.append(id); return ok(p,{"upgrade":id,"price":price})
static func buy_cosmetic(source: Dictionary, id: String, currency := "forge_coins", unix_time := 0) -> Dictionary:
	var p := ensure(source); var data: Dictionary = COSMETICS.get(id, {})
	if data.is_empty() or p.cosmetics.has(id): return fail(p, "Cosmetic is unavailable.")
	if currency not in ["forge_coins", "sparks"]: return fail(p, "Use Forge Coins or Sparks.")
	if unix_time > 0 and int(p.get("newcomer_started_at", 0)) <= 0: p.newcomer_started_at = unix_time
	var price := int(data.get("coins", 0))
	if unix_time > 0: price = _daily_price(market_snapshot(p, unix_time), "cosmetic", id, price)
	if not V3_ECONOMY.spend(p, currency, price): return fail(p, "Not enough %s." % ("Sparks" if currency == "sparks" else "Forge Coins"))
	p.cosmetics[id] = true
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
	return V3_ECONOMY.daily_price(snapshot, shop, id, price)
static func buy_paid_season(source: Dictionary) -> Dictionary:
	var p := ensure(source)
	if bool(p.season.get("paid", false)): return ok(p, {"already_owned":true})
	if int(p.sparks) < 1200: return fail(p, "Need 1,200 Sparks for the Season Track.")
	p.sparks -= 1200; p.season.paid = true
	return ok(p, {"price":1200,"currency":"sparks"})
static func buy_pack(source: Dictionary, pack_id: String, entropy: PackedByteArray = PackedByteArray(), unix_time := 0, return_route := "workshop", return_context: Dictionary = {}, expected_price: int = -1) -> Dictionary:
	var p := ensure(source); var pack: Dictionary = PACKS.get(pack_id,{}); if pack.is_empty(): return fail(p,"Pack is unavailable or unaffordable.")
	if not p.pending_pack_reveal.is_empty(): return fail(p,"Reveal the current pack first.")
	var price := int(pack.price)
	if unix_time > 0:
		var snapshot := market_snapshot(p, unix_time)
		price = _daily_price(snapshot, "pack", pack_id, price)
		if pack_id == "basic" and bool(snapshot.newcomer.get("active", false)) and not p.newcomer_claims.has("basic_pack"):
			price = 0
	if expected_price >= 0 and expected_price != price:
		return {"ok":false, "profile":p, "error":"The pack price changed. Review the current offer before buying.", "price_changed":true, "effective_price":price}
	if unix_time > 0 and int(p.get("newcomer_started_at", 0)) <= 0: p.newcomer_started_at = unix_time
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
	var return_presentation := _pack_return_presentation(return_route, return_context)
	p.pending_pack_reveal = {"pack_id":pack_id,"cards":cards,"bonus_cards":bonus_cards,"receipt":"pack-%d" % p.rng_nonce,"return_route":return_presentation.route,"return_context":return_presentation.context,"effective_price":price}
	return ok(p,{"pack_id":pack_id,"cards":cards,"bonus_cards":bonus_cards,"pending_reveal":true})

static func claim_next_starter_pack(source: Dictionary, entropy: PackedByteArray = PackedByteArray(), return_route := "unified_library", return_context: Dictionary = {}) -> Dictionary:
	var p := ensure(source)
	var rewards: Dictionary = p.get("starter_pack_rewards", {})
	var opened := int(rewards.get("opened", 0)); var entitled := int(rewards.get("entitled", 0))
	if _is_founder(p):
		return _claim_next_founder_pack(p, rewards, opened, entitled, return_route, return_context)
	if str(p.get("onboarding", {}).get("state", "")) != "complete" or entitled != 3 or opened >= entitled:
		return fail(p, "No starter packs are waiting.")
	if not p.pending_pack_reveal.is_empty(): return fail(p, "Reveal the current pack first.")
	var receipt := "starter-basic-%d" % (opened + 1)
	if p.claim_receipts.has(receipt): return fail(p, "That starter pack was already claimed.")
	# Same deterministic Basic card generation and pity behavior as a paid pack,
	# but no cost or duplicate Newcomer Shelf grant.
	var seed := _seed_bytes(entropy, p.rng_nonce)
	var cards := _generate_pack_cards("basic", seed)
	var pity := int(p.pack_pity.get("basic", 0)) + 1
	var bonus_cards: Array = []
	if pity >= 51:
		bonus_cards = _generate_guaranteed_cards(5, _next(seed + 51), "common", "primordial", 1, "rare", false)
		pity = 0
	var found_legendary := false
	for card_id in cards + bonus_cards:
		if _rarity_index(str(card(str(card_id)).get("rarity", "common"))) >= _rarity_index("legendary"): found_legendary = true
	if found_legendary: pity = 0
	p.pack_pity["basic"] = pity; p.rng_nonce += 1
	p.claim_receipts[receipt] = true; rewards["opened"] = opened + 1; p.starter_pack_rewards = rewards
	for card_id in cards: grant_card(p, str(card_id))
	for card_id in bonus_cards: grant_card(p, str(card_id))
	var return_presentation := _pack_return_presentation(return_route, return_context)
	p.pending_pack_reveal = {"pack_id":"basic","cards":cards,"bonus_cards":bonus_cards,"receipt":receipt,"starter_reward":true,"starter_opened":opened + 1,"return_route":return_presentation.route,"return_context":return_presentation.context}
	return ok(p,{"pack_id":"basic","cards":cards,"bonus_cards":bonus_cards,"receipt":receipt,"pending_reveal":true,"starter_opened":opened + 1})
static func _claim_next_founder_pack(p: Dictionary, rewards: Dictionary, opened: int, entitled: int, return_route: String, return_context: Dictionary) -> Dictionary:
	if str(p.get("onboarding", {}).get("state", "")) != "complete" or str(rewards.get("kind", "")) != FOUNDER_VERSION or entitled != 3 or opened >= entitled:
		return fail(p, "No Founder packs are waiting.")
	if int(rewards.get("kept", 0)) != opened: return fail(p, "Keep the current Founder receipt before opening another.")
	if not p.pending_pack_reveal.is_empty(): return fail(p, "Reveal the current pack first.")
	var receipt := "founder-v1-%d" % (opened + 1)
	if p.claim_receipts.has(receipt): return fail(p, "That Founder receipt was already claimed.")
	var starter_id := str(p.get("onboarding", {}).get("starter_id", ""))
	var cards := _founder_cards(starter_id, opened)
	if starter_id not in STARTER_IDS or cards.size() != 13: return fail(p, "Founder receipt contents are unavailable.")
	p.claim_receipts[receipt] = true
	for card_id in cards: grant_card(p, card_id)
	for deck in p.decks:
		if deck is Dictionary and str(deck.get("id", "")) == "starter-deck": deck["cards"].append_array(cards)
	rewards["opened"] = opened + 1
	p.starter_pack_rewards = rewards
	var return_presentation := _pack_return_presentation(return_route, return_context)
	p.pending_pack_reveal = {"pack_id":"founder","cards":cards,"bonus_cards":[],"receipt":receipt,"starter_reward":true,"founder_reward":true,"starter_opened":opened + 1,"return_route":return_presentation.route,"return_context":return_presentation.context}
	return ok(p,{"pack_id":"founder","cards":cards,"bonus_cards":[],"receipt":receipt,"pending_reveal":true,"starter_opened":opened + 1})

static func _pack_return_presentation(route: String, context: Dictionary) -> Dictionary:
	var safe_route := route if route in PACK_RETURN_ROUTES else "workshop"
	# Receipt ownership persists only a small, typed caller hint.  UI-local state
	# such as selection or arbitrary dictionaries never enters the profile.
	var safe_context := {"caller":safe_route}
	if context.get("caller", "") is String and str(context.get("caller", "")) in PACK_RETURN_ROUTES:
		safe_context["caller"] = str(context.get("caller", ""))
	return {"route":safe_route,"context":safe_context}
static func clear_pack_reveal(source: Dictionary) -> Dictionary:
	var p := ensure(source)
	if p.pending_pack_reveal.is_empty(): return fail(p, "There is no pack receipt waiting to keep.")
	var cards: Array = p.pending_pack_reveal.get("cards", [])
	var bonus_cards: Array = p.pending_pack_reveal.get("bonus_cards", [])
	var final_founder_keep := false
	if bool(p.pending_pack_reveal.get("founder_reward", false)):
		var rewards: Dictionary = p.get("starter_pack_rewards", {})
		if int(rewards.get("kept", 0)) >= int(rewards.get("opened", 0)): return fail(p, "That Founder receipt was already kept.")
		rewards["kept"] = int(rewards.get("kept", 0)) + 1
		p.starter_pack_rewards = rewards
		final_founder_keep = str(rewards.get("kind", "")) == FOUNDER_VERSION and int(rewards.get("entitled", 0)) == 3 and int(rewards.get("kept", 0)) == 3
	p.pending_pack_reveal = {}
	# The existing complete-Founder repair stays unavailable while a receipt is
	# pending. Once the final Keep is acknowledged, apply that idempotent repair
	# in this same candidate so an affected exported save needs no restart before
	# its already-earned 40-card deck is legal.
	if final_founder_keep: p = ensure(p)
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
