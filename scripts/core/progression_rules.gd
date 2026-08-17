class_name ProgressionRules
extends RefCounted
## Pure, catalog-validated account transitions. File/network persistence is outside this seam.

const EQUIPMENT_RULES := preload("res://scripts/core/equipment_rules.gd")

const STARTER_DECK_ID := "starter-deck"
const STARTER_DECK: Array[String] = ["raw_filament","raw_filament","raw_filament","raw_filament","raw_filament","heated_spool","heated_spool","heated_spool","reinforced_layer","reinforced_layer","reinforced_layer","quick_patch","quick_patch","arcane_spark","arcane_spark"]
const DAILY_CALIBRATION_LIMIT := 3
const DECK_SLOT_IDS: Array[String] = ["starter-deck", "workshop-deck", "sparring-deck", "guard-line", "rapid-build"]
const DECK_SLOT_NAMES := {"starter-deck":"Starter Filament", "workshop-deck":"Forge Deck", "sparring-deck":"Field Kit", "guard-line":"Guard Line", "rapid-build":"Rapid Build"}
const DECK_NAME_OPTIONS: Array[String] = ["Forge Deck", "Field Kit", "Guard Line", "Rapid Build", "Element Bench", "Masterwork"]
const YARD_DRILLS := {"field_practice":{"name":"Field Practice","xp":12},"team_bond":{"name":"Team Bond","mastery":5},"spool_warmup":{"name":"Spool Warmup","warmup":1}}

static func ensure_fields(source: Dictionary, grant_starter_deck: bool = false) -> Dictionary:
	var p: Dictionary = EQUIPMENT_RULES.ensure_fields(source)
	if not p.has("support_cards"): p.support_cards = {}
	if not p.has("decks"): p.decks = []
	if not p.has("active_deck_id"): p.active_deck_id = ""
	if not p.has("shop"): p.shop = {}
	if not p.has("daily_job_count"): p.daily_job_count = 0
	if not p.has("last_job_day"): p.last_job_day = ""
	if not p.has("last_yard_day"): p.last_yard_day = ""
	if not p.has("yard_choice"): p.yard_choice = ""
	if not p.has("pending_spool_warmup"): p.pending_spool_warmup = 0
	p.pending_spool_warmup = clampi(int(p.get("pending_spool_warmup", 0)), 0, 1)
	if not p.has("creature_mastery") or not p.get("creature_mastery") is Dictionary: p.creature_mastery = {}
	if not p.has("print_history") or not p.get("print_history") is Dictionary: p.print_history = {}
	if not p.print_history.has("creatures") or not p.print_history.get("creatures") is Dictionary: p.print_history.creatures = {}
	for creature in p.get("creatures", []):
		if creature is Dictionary:
			var creature_id := str(creature.get("creature_id", ""))
			if not Catalog.creature(creature_id).is_empty(): p.print_history.creatures[creature_id] = maxi(int(p.print_history.creatures.get(creature_id, 0)), _owned_creature_count(p, creature_id))
	var active_found := false
	for deck in p.decks:
		if str(deck.get("id", "")) == str(p.active_deck_id) and _deck_is_legal(p, deck.get("cards", [])): active_found = true
	if not active_found:
		_ensure_starter_deck(p)
		p.active_deck_id = STARTER_DECK_ID
	if grant_starter_deck: _ensure_starter_deck(p)
	return p

static func migrate(source: Dictionary) -> Dictionary:
	var p := ensure_fields(source, ProfileRules.has_starter(source))
	return p

static func _ensure_starter_deck(p: Dictionary) -> void:
	for card_id in STARTER_DECK:
		p.support_cards[card_id] = maxi(int(p.support_cards.get(card_id, 0)), _count(STARTER_DECK, card_id))
	var has_deck := false
	for deck in p.decks:
		if str(deck.get("id", "")) == STARTER_DECK_ID: has_deck = true
	if not has_deck: p.decks.append({"id":STARTER_DECK_ID,"name":"Starter Filament Deck","cards":STARTER_DECK.duplicate()})
	if str(p.active_deck_id).is_empty(): p.active_deck_id = STARTER_DECK_ID

static func purchase_creature_blueprint(source: Dictionary, creature_id: String) -> Dictionary:
	var p := ensure_fields(source)
	var creature := Catalog.creature(creature_id)
	if creature.is_empty() or creature_id in p.blueprints: return _fail(p, "Blueprint is unavailable.")
	var price: int = int(Catalog.rarity(str(creature.rarity)).blueprint)
	if not _can_pay(p, price): return _fail(p, "Not enough Forge Coins.")
	p.coins = int(p.coins) - price; p.blueprints.append(creature_id)
	if not creature_id in p.discovered: p.discovered.append(creature_id)
	return _ok(p, {"creature_id":creature_id,"price":price})

static func print_creature(source: Dictionary, creature_id: String) -> Dictionary:
	var p := ensure_fields(source)
	var creature := Catalog.creature(creature_id)
	if creature.is_empty() or not creature_id in p.blueprints: return _fail(p, "Learn this creature blueprint first.")
	var price: int = int(Catalog.rarity(str(creature.rarity)).print)
	if not _can_pay(p, price): return _fail(p, "Not enough Forge Coins.")
	var instance_id := _next_id(p, creature_id)
	p.coins = int(p.coins) - price
	p.creatures.append({"instance_id":instance_id,"creature_id":creature_id,"suit_instance_id":"","bound":false,"tradable":true,"source":"printed"})
	p.print_history.creatures[creature_id] = int(p.print_history.creatures.get(creature_id, 0)) + 1
	return _ok(p, {"creature_id":creature_id,"instance_id":instance_id,"price":price})

static func learn_suit_blueprint(source: Dictionary, tier_id: String) -> Dictionary: return EQUIPMENT_RULES.learn_suit(source, tier_id)
static func print_suit(source: Dictionary, tier_id: String) -> Dictionary: return EQUIPMENT_RULES.print_suit(source, tier_id)
static func equip_suit(source: Dictionary, creature_id: String, suit_id: String) -> Dictionary: return EQUIPMENT_RULES.equip_suit(source, creature_id, suit_id)
static func remove_suit(source: Dictionary, creature_id: String) -> Dictionary: return EQUIPMENT_RULES.remove_suit(source, creature_id)
static func learn_core_blueprint(source: Dictionary, core_id: String) -> Dictionary: return EQUIPMENT_RULES.learn_core(source, core_id)
static func print_core(source: Dictionary, core_id: String) -> Dictionary: return EQUIPMENT_RULES.print_core(source, core_id)
static func socket_core(source: Dictionary, suit_id: String, core_id: String) -> Dictionary: return EQUIPMENT_RULES.socket_core(source, suit_id, core_id)
static func remove_core(source: Dictionary, suit_id: String) -> Dictionary: return EQUIPMENT_RULES.remove_core(source, suit_id)

static func save_team(source: Dictionary, instance_ids: Array) -> Dictionary:
	var p := ensure_fields(source)
	if instance_ids.size() < 1 or instance_ids.size() > 3: return _fail(p, "A team needs one to three unique printed creatures.")
	var seen := {}
	for instance_id in instance_ids:
		var key := str(instance_id)
		if seen.has(key) or _creature(p, key).is_empty(): return _fail(p, "Team members must be unique owned creature instances.")
		seen[key] = true
	p.team = instance_ids.duplicate()
	return _ok(p, {"team":p.team.duplicate()})

static func save_deck(source: Dictionary, cards: Array, deck_id: String = STARTER_DECK_ID) -> Dictionary:
	return save_deck_slot(source, cards, deck_id)

static func save_deck_slot(source: Dictionary, cards: Array, deck_id: String) -> Dictionary:
	var p := ensure_fields(source)
	if not deck_id in DECK_SLOT_IDS: return _fail(p, "Choose one of the five Forge deck slots.")
	if cards.size() != 15: return _fail(p, "A support deck needs exactly 15 cards.")
	var needed := {}
	for card in cards:
		var card_id := str(card)
		if card_def(card_id).is_empty(): return _fail(p, "Deck contains an unknown support card.")
		needed[card_id] = int(needed.get(card_id, 0)) + 1
	for card_id in needed:
		if int(needed[card_id]) > int(p.support_cards.get(card_id, 0)): return _fail(p, "Deck uses more cards than you own.")
	var replaced := false
	for deck in p.decks:
		if str(deck.get("id", "")) == deck_id: deck.cards = cards.duplicate(); replaced = true
	if not replaced: p.decks.append({"id":deck_id,"name":str(DECK_SLOT_NAMES.get(deck_id, "Forge Deck")),"cards":cards.duplicate()})
	p.active_deck_id = deck_id
	return _ok(p, {"deck_id":deck_id,"cards":cards.duplicate()})

static func create_deck(source: Dictionary, deck_id: String, name: String) -> Dictionary:
	var p := ensure_fields(source)
	if not deck_id in DECK_SLOT_IDS or deck_id == STARTER_DECK_ID: return _fail(p, "That Forge deck slot is unavailable.")
	if not name in DECK_NAME_OPTIONS: return _fail(p, "Choose an approved Forge deck label.")
	for deck in p.decks:
		if str(deck.get("id", "")) == deck_id: return _fail(p, "That deck slot already exists.")
	if p.decks.size() >= DECK_SLOT_IDS.size(): return _fail(p, "All five Forge deck slots are in use.")
	p.decks.append({"id":deck_id,"name":name,"cards":[]})
	return _ok(p, {"deck_id":deck_id,"name":name})

static func duplicate_deck(source: Dictionary, source_id: String, target_id: String) -> Dictionary:
	var p := ensure_fields(source)
	if not target_id in DECK_SLOT_IDS or target_id == STARTER_DECK_ID: return _fail(p, "Choose an empty Forge deck slot.")
	for deck in p.decks:
		if str(deck.get("id", "")) == target_id: return _fail(p, "That deck slot already exists.")
	var cards := active_deck_for_id(p, source_id)
	if not _deck_is_legal(p, cards): return _fail(p, "Only a legal saved deck can be duplicated.")
	p.decks.append({"id":target_id,"name":str(DECK_SLOT_NAMES.get(target_id, "Forge Deck")),"cards":cards})
	return _ok(p, {"source_id":source_id,"deck_id":target_id})

static func rename_deck(source: Dictionary, deck_id: String, name: String) -> Dictionary:
	var p := ensure_fields(source)
	if not name in DECK_NAME_OPTIONS: return _fail(p, "Choose an approved Forge deck label.")
	for deck in p.decks:
		if str(deck.get("id", "")) == deck_id:
			deck.name = name
			return _ok(p, {"deck_id":deck_id,"name":name})
	return _fail(p, "That saved deck is unavailable.")

static func delete_deck(source: Dictionary, deck_id: String) -> Dictionary:
	var p := ensure_fields(source)
	if deck_id == STARTER_DECK_ID: return _fail(p, "The starter deck cannot be deleted.")
	var kept: Array = []; var found := false
	for deck in p.decks:
		if str(deck.get("id", "")) == deck_id: found = true
		else: kept.append(deck)
	if not found: return _fail(p, "That saved deck is unavailable.")
	p.decks = kept
	if str(p.active_deck_id) == deck_id:
		p.active_deck_id = STARTER_DECK_ID
		if active_deck_for_id(p, STARTER_DECK_ID).is_empty(): _ensure_starter_deck(p)
	return _ok(p, {"deck_id":deck_id})

static func select_deck(source: Dictionary, deck_id: String) -> Dictionary:
	var p := ensure_fields(source)
	for deck in p.decks:
		if str(deck.get("id", "")) == deck_id and _deck_is_legal(p, deck.get("cards", [])):
			p.active_deck_id = deck_id
			return _ok(p, {"deck_id":deck_id})
	return _fail(p, "That saved deck is not ready to select.")

static func active_deck(p: Dictionary) -> Array:
	return active_deck_for_id(p, str(p.get("active_deck_id", "")))

static func active_deck_for_id(p: Dictionary, deck_id: String) -> Array:
	for deck in p.get("decks", []):
		if str(deck.get("id", "")) == deck_id and deck.get("cards", []) is Array: return deck.get("cards", []).duplicate()
	return []

static func calibration_pattern(day_key: String, attempt: int) -> Array:
	var seed := _day_seed(day_key) + attempt * 97
	var result: Array = []
	for index in 3:
		seed = _next_seed(seed + index * 31)
		result.append(20 + (seed % 7) * 10)
	return result

static func calibration_performance(targets: Array, values: Array) -> int:
	if targets.size() != 3 or values.size() != 3: return 0
	var distance := 0
	for index in 3: distance += absi(clampi(int(values[index]), 0, 100) - clampi(int(targets[index]), 0, 100))
	return clampi(100 - (distance * 100) / 300, 0, 100)

static func complete_calibration(source: Dictionary, day_key: String, performance: int) -> Dictionary:
	var p := ensure_fields(source)
	if not _valid_day(day_key): return _fail(p, "Use a valid calibration day.")
	var count: int = int(p.daily_job_count) if str(p.last_job_day) == day_key else 0
	if count >= DAILY_CALIBRATION_LIMIT: return _fail(p, "Calibration is complete for today. Return tomorrow for a fresh pattern.")
	var reward: int = clampi(8 + clampi(performance, 0, 100) / 5, 8, 28)
	p.last_job_day = day_key; p.daily_job_count = count + 1; p.coins = int(p.coins) + reward
	return _ok(p, {"day_key":day_key,"performance":clampi(performance, 0, 100),"reward":reward,"count":int(p.daily_job_count),"limit":DAILY_CALIBRATION_LIMIT})

static func visit_print_yard(source: Dictionary, day_key: String, drill_id: String = "field_practice") -> Dictionary:
	var p := ensure_fields(source)
	if not _valid_day(day_key): return _fail(p, "Use a valid Print Yard day.")
	if str(p.last_yard_day) == day_key: return _fail(p, "The Print Yard companions have already shared today's filament lesson.")
	if not YARD_DRILLS.has(drill_id): return _fail(p, "Choose one of today's three Print Yard drills.")
	if p.creatures.is_empty(): return _fail(p, "Print a companion before visiting the Print Yard.")
	var payload := {"day_key":day_key,"drill_id":drill_id,"xp":0,"mastery":0,"warmup":0,"spool_gained":0}
	if drill_id == "field_practice":
		var xp_result := grant_xp(p, 12); p = xp_result.profile; payload["xp"] = 12; payload["spool_gained"] = int(xp_result.payload.spool_gained)
	elif drill_id == "team_bond":
		var team_ids := _team_instance_ids(p)
		if team_ids.is_empty(): return _fail(p, "Choose a saved training team before Team Bond.")
		for instance_id in team_ids: p.creature_mastery[instance_id] = int(p.creature_mastery.get(instance_id, 0)) + 5
		payload["mastery"] = 5; payload["team_instance_ids"] = team_ids
	else:
		if int(p.get("spool_level", 3)) <= 3: return _fail(p, "Requires spool capacity 4+.")
		p.pending_spool_warmup = 1
		payload["warmup"] = int(p.pending_spool_warmup)
	p.last_yard_day = day_key
	p.yard_choice = drill_id
	return _ok(p, payload)

static func consume_spool_warmup(source: Dictionary) -> Dictionary:
	var p := ensure_fields(source)
	var bonus := clampi(int(p.get("pending_spool_warmup", 0)), 0, 1)
	if bonus <= 0: return _ok(p, {"bonus":0})
	p.pending_spool_warmup = 0
	return _ok(p, {"bonus":bonus})

static func grant_xp(source: Dictionary, amount: int) -> Dictionary:
	var p := ensure_fields(source)
	if amount <= 0: return _fail(p, "XP rewards must be positive.")
	var levels := 0
	p.xp = int(p.xp) + amount
	while int(p.spool_level) < 10 and int(p.xp) >= int(p.spool_level) * 100:
		p.xp = int(p.xp) - int(p.spool_level) * 100
		p.spool_level = int(p.spool_level) + 1
		levels += 1
	return _ok(p, {"xp":amount,"spool_gained":levels,"next_threshold":int(p.spool_level) * 100})

static func training_opponent(day_key: String, player_team: Array = []) -> Array:
	if not _valid_day(day_key): return ["mossmunk"]
	var seed: int = 0
	for byte in day_key.to_utf8_buffer(): seed = (seed * 31 + int(byte)) % 2147483647
	var used := {}; var result: Array = []
	var target_count := clampi(player_team.size(), 1, 3)
	for _slot in target_count:
		seed = _next_seed(seed)
		var creature: Dictionary = Catalog.CREATURES[seed % Catalog.CREATURES.size()]
		while used.has(str(creature.id)):
			seed = _next_seed(seed); creature = Catalog.CREATURES[seed % Catalog.CREATURES.size()]
		used[str(creature.id)] = true; result.append(str(creature.id))
	return result

static func daily_shop(source: Dictionary, day_key: String) -> Dictionary:
	var p := ensure_fields(source)
	if not _valid_day(day_key): return {"ok":false,"error":"Use a YYYY-MM-DD shop day.","profile":p,"offers":[]}
	var offers := _rotation(day_key)
	p.shop = {"day_key":day_key,"offers":offers}
	return {"ok":true,"profile":p,"offers":offers}

static func buy_shop_offer(source: Dictionary, day_key: String, offer_id: String) -> Dictionary:
	var shop := daily_shop(source, day_key)
	if not bool(shop.ok): return shop
	for offer in shop.offers:
		if str(offer.offer_id) != offer_id: continue
		match str(offer.kind):
			"creature_blueprint": return purchase_creature_blueprint(shop.profile, str(offer.item_id))
			"suit_blueprint": return learn_suit_blueprint(shop.profile, str(offer.item_id))
			"core_blueprint": return learn_core_blueprint(shop.profile, str(offer.item_id))
			"support_card": return buy_support_card(shop.profile, str(offer.item_id), int(offer.price))
	return _fail(shop.profile, "That shop offer is unavailable.")

static func buy_support_card(source: Dictionary, card_id: String, price: int = -1) -> Dictionary:
	var p := ensure_fields(source); var card := card_def(card_id)
	if card.is_empty(): return _fail(p, "Support card is unavailable.")
	var final_price: int = support_price(card) if price < 0 else price
	if not _can_pay(p, final_price): return _fail(p, "Not enough Forge Coins.")
	p.coins = int(p.coins) - final_price; p.support_cards[card_id] = int(p.support_cards.get(card_id, 0)) + 1
	return _ok(p, {"card_id":card_id,"price":final_price})

static func _rotation(day_key: String) -> Array:
	var seed: int = 0
	for byte in day_key.to_utf8_buffer(): seed = (seed * 31 + int(byte)) % 2147483647
	var used := {}; var offers: Array = []
	for slot in 3:
		seed = _next_seed(seed); var creature: Dictionary = Catalog.CREATURES[seed % Catalog.CREATURES.size()]
		while used.has("c:%s" % creature.id): seed = _next_seed(seed); creature = Catalog.CREATURES[seed % Catalog.CREATURES.size()]
		used["c:%s" % creature.id] = true; offers.append({"offer_id":"%s-c%d" % [day_key,slot],"kind":"creature_blueprint","item_id":creature.id,"name":creature.name,"price":int(Catalog.rarity(creature.rarity).blueprint)})
	for slot in 2:
		seed = _next_seed(seed); var suit: Dictionary = Catalog.SUITS[seed % Catalog.SUITS.size()]
		while used.has("s:%s" % suit.id): seed = _next_seed(seed); suit = Catalog.SUITS[seed % Catalog.SUITS.size()]
		used["s:%s" % suit.id] = true; offers.append({"offer_id":"%s-s%d" % [day_key,slot],"kind":"suit_blueprint","item_id":suit.id,"name":suit.name,"price":int(suit.blueprint)})
	for slot in 2:
		seed = _next_seed(seed); var core: Dictionary = Catalog.CORE_BLUEPRINTS[seed % Catalog.CORE_BLUEPRINTS.size()]
		while used.has("k:%s" % core.id): seed = _next_seed(seed); core = Catalog.CORE_BLUEPRINTS[seed % Catalog.CORE_BLUEPRINTS.size()]
		used["k:%s" % core.id] = true; offers.append({"offer_id":"%s-k%d" % [day_key,slot],"kind":"core_blueprint","item_id":core.id,"name":core.name,"price":int(core.blueprint)})
	for slot in 2:
		seed = _next_seed(seed); var card: Dictionary = Catalog.SUPPORT_CARDS[seed % Catalog.SUPPORT_CARDS.size()]
		while used.has("s:%s" % card.id): seed = _next_seed(seed); card = Catalog.SUPPORT_CARDS[seed % Catalog.SUPPORT_CARDS.size()]
		used["s:%s" % card.id] = true; offers.append({"offer_id":"%s-s%d" % [day_key,slot],"kind":"support_card","item_id":card.id,"name":card.name,"price":support_price(card)})
	return offers

static func _next_seed(seed: int) -> int:
	return int((seed * 1103515245 + 12345) % 2147483647)
static func _day_seed(day_key: String) -> int:
	var seed := 0
	for byte in day_key.to_utf8_buffer(): seed = (seed * 31 + int(byte)) % 2147483647
	return seed
static func _valid_day(day: String) -> bool:
	if day.length() != 10 or day[4] != "-" or day[7] != "-": return false
	var compact := day.replace("-", "")
	if not compact.is_valid_int(): return false
	var year := int(day.substr(0, 4)); var month := int(day.substr(5, 2)); var date := int(day.substr(8, 2))
	if year < 1 or month < 1 or month > 12 or date < 1: return false
	var month_lengths := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var days: int = int(month_lengths[month - 1])
	if month == 2 and (year % 400 == 0 or (year % 4 == 0 and year % 100 != 0)): days = 29
	return date <= days

static func _deck_is_legal(p: Dictionary, cards: Array) -> bool:
	if cards.size() != 15: return false
	var needed := {}
	for card in cards:
		var id := str(card)
		if card_def(id).is_empty(): return false
		needed[id] = int(needed.get(id, 0)) + 1
	for id in needed:
		if int(needed[id]) > int(p.support_cards.get(id, 0)): return false
	return true
static func support_price(card: Dictionary) -> int:
	return 15 + int(card.cost) * 5
static func armor_def(id: String) -> Dictionary:
	for suit in Catalog.SUITS:
		if str(suit.id) == id: return suit.duplicate(true)
	return {}
static func card_def(id: String) -> Dictionary:
	for card in Catalog.SUPPORT_CARDS:
		if str(card.id) == id: return card.duplicate(true)
	return {}
static func _count(values: Array, id: String) -> int:
	var total: int = 0
	for value in values:
		if value == id: total += 1
	return total
static func _can_pay(p: Dictionary, price: int) -> bool:
	return price >= 0 and int(p.get("coins", 0)) >= price
static func _next_id(p: Dictionary, prefix: String) -> String:
	var nonce: int = int(p.get("next_instance_nonce", 1)); p.next_instance_nonce = nonce + 1
	return "%s-%d" % [prefix, nonce]
static func _creature(p: Dictionary, id: String) -> Dictionary:
	for row in p.creatures:
		if str(row.get("instance_id", "")) == id: return row
	return {}
static func _armor(p: Dictionary, id: String) -> Dictionary:
	for row in p.armor:
		if str(row.get("armor_instance_id", "")) == id: return row
	return {}
static func _owned_creature_count(p: Dictionary, creature_id: String) -> int:
	var count := 0
	for row in p.get("creatures", []):
		if row is Dictionary and str(row.get("creature_id", "")) == creature_id: count += 1
	return count
static func _owned_armor_count(p: Dictionary, armor_id: String) -> int:
	var count := 0
	for row in p.get("armor", []):
		if row is Dictionary and str(row.get("armor_id", "")) == armor_id: count += 1
	return count
static func _team_instance_ids(p: Dictionary) -> Array:
	var owned := {}; for row in p.get("creatures", []): if row is Dictionary: owned[str(row.get("instance_id", ""))] = true
	var result: Array = []
	for value in p.get("team", []):
		var instance_id := str(value)
		if owned.has(instance_id) and not instance_id in result: result.append(instance_id)
	return result
static func _ok(p: Dictionary, payload: Dictionary) -> Dictionary:
	return {"ok":true,"profile":p,"payload":payload}
static func _fail(p: Dictionary, error: String) -> Dictionary:
	return {"ok":false,"profile":p,"error":error}
