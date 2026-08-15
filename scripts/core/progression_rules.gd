class_name ProgressionRules
extends RefCounted
## Pure, catalog-validated account transitions. File/network persistence is outside this seam.

const STARTER_DECK_ID := "starter-deck"
const STARTER_DECK: Array[String] = ["raw_filament","raw_filament","raw_filament","raw_filament","raw_filament","heated_spool","heated_spool","heated_spool","reinforced_layer","reinforced_layer","reinforced_layer","quick_patch","quick_patch","arcane_spark","arcane_spark"]
const DAILY_CALIBRATION_LIMIT := 3
const DECK_SLOT_IDS: Array[String] = ["starter-deck", "workshop-deck", "sparring-deck"]
const DECK_SLOT_NAMES := {"starter-deck":"Starter Filament", "workshop-deck":"Workshop Patterns", "sparring-deck":"Sparring Patterns"}

static func ensure_fields(source: Dictionary, grant_starter_deck: bool = false) -> Dictionary:
	var p: Dictionary = source.duplicate(true)
	if not p.has("armor_blueprints"): p.armor_blueprints = []
	if not p.has("support_cards"): p.support_cards = {}
	if not p.has("decks"): p.decks = []
	if not p.has("active_deck_id"): p.active_deck_id = ""
	if not p.has("shop"): p.shop = {}
	if not p.has("daily_job_count"): p.daily_job_count = 0
	if not p.has("last_job_day"): p.last_job_day = ""
	if not p.has("last_yard_day"): p.last_yard_day = ""
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
	p.creatures.append({"instance_id":instance_id,"creature_id":creature_id,"armor_id":"","bound":false,"tradable":true,"source":"printed"})
	return _ok(p, {"creature_id":creature_id,"instance_id":instance_id,"price":price})

static func learn_armor_blueprint(source: Dictionary, armor_id: String) -> Dictionary:
	var p := ensure_fields(source)
	var armor := armor_def(armor_id)
	if armor.is_empty() or armor_id in p.armor_blueprints: return _fail(p, "Armor blueprint is unavailable.")
	var price: int = int(armor.blueprint)
	if not _can_pay(p, price): return _fail(p, "Not enough Forge Coins.")
	p.coins = int(p.coins) - price; p.armor_blueprints.append(armor_id)
	return _ok(p, {"armor_id":armor_id,"price":price})

static func print_armor(source: Dictionary, armor_id: String) -> Dictionary:
	var p := ensure_fields(source)
	var armor := armor_def(armor_id)
	if armor.is_empty() or not armor_id in p.armor_blueprints: return _fail(p, "Learn this armor blueprint first.")
	var price: int = int(armor.print)
	if not _can_pay(p, price): return _fail(p, "Not enough Forge Coins.")
	var instance_id := _next_id(p, "armor-%s" % armor_id)
	p.coins = int(p.coins) - price; p.armor.append({"armor_instance_id":instance_id,"armor_id":armor_id,"equipped_to":""})
	return _ok(p, {"armor_id":armor_id,"armor_instance_id":instance_id,"price":price})

static func equip_armor(source: Dictionary, creature_instance_id: String, armor_instance_id: String) -> Dictionary:
	var p := ensure_fields(source)
	var creature := _creature(p, creature_instance_id); var armor := _armor(p, armor_instance_id)
	if creature.is_empty() or armor.is_empty() or not str(armor.equipped_to).is_empty(): return _fail(p, "That creature or armor is not ready to equip.")
	for existing in p.armor:
		if str(existing.get("equipped_to", "")) == creature_instance_id: existing.equipped_to = ""
	creature.armor_id = str(armor.armor_id); armor.equipped_to = creature_instance_id
	return _ok(p, {"creature_instance_id":creature_instance_id,"armor_instance_id":armor_instance_id})

static func unequip_armor(source: Dictionary, creature_instance_id: String) -> Dictionary:
	var p := ensure_fields(source)
	var creature := _creature(p, creature_instance_id)
	if creature.is_empty() or str(creature.get("armor_id", "")).is_empty(): return _fail(p, "That creature has no armor to remove.")
	for armor in p.armor:
		if str(armor.get("equipped_to", "")) == creature_instance_id: armor.equipped_to = ""
	creature.armor_id = ""
	return _ok(p, {"creature_instance_id":creature_instance_id})

static func reassign_armor(source: Dictionary, creature_instance_id: String, armor_instance_id: String) -> Dictionary:
	var p := ensure_fields(source)
	var creature := _creature(p, creature_instance_id); var armor := _armor(p, armor_instance_id)
	if creature.is_empty() or armor.is_empty(): return _fail(p, "That creature or armor is unavailable.")
	var previous_owner := str(armor.get("equipped_to", ""))
	if not previous_owner.is_empty():
		var old_owner := _creature(p, previous_owner)
		if not old_owner.is_empty(): old_owner.armor_id = ""
	for other in p.armor:
		if str(other.get("equipped_to", "")) == creature_instance_id: other.equipped_to = ""
	creature.armor_id = str(armor.armor_id); armor.equipped_to = creature_instance_id
	return _ok(p, {"creature_instance_id":creature_instance_id,"armor_instance_id":armor_instance_id,"previous_owner":previous_owner})

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
	if not deck_id in DECK_SLOT_IDS: return _fail(p, "Choose one of the three Forge deck slots.")
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

static func select_deck(source: Dictionary, deck_id: String) -> Dictionary:
	var p := ensure_fields(source)
	for deck in p.decks:
		if str(deck.get("id", "")) == deck_id and _deck_is_legal(p, deck.get("cards", [])):
			p.active_deck_id = deck_id
			return _ok(p, {"deck_id":deck_id})
	return _fail(p, "That saved deck is not ready to select.")

static func active_deck(p: Dictionary) -> Array:
	for deck in p.get("decks", []):
		if str(deck.get("id", "")) == str(p.get("active_deck_id", "")): return deck.get("cards", []).duplicate()
	return []

static func complete_calibration(source: Dictionary, day_key: String, performance: int) -> Dictionary:
	var p := ensure_fields(source)
	if not _valid_day(day_key): return _fail(p, "Use a valid calibration day.")
	var count: int = int(p.daily_job_count) if str(p.last_job_day) == day_key else 0
	if count >= DAILY_CALIBRATION_LIMIT: return _fail(p, "Calibration is complete for today. Return tomorrow for a fresh pattern.")
	var reward: int = clampi(8 + clampi(performance, 0, 100) / 5, 8, 28)
	p.last_job_day = day_key; p.daily_job_count = count + 1; p.coins = int(p.coins) + reward
	return _ok(p, {"day_key":day_key,"performance":clampi(performance, 0, 100),"reward":reward,"count":int(p.daily_job_count),"limit":DAILY_CALIBRATION_LIMIT})

static func visit_print_yard(source: Dictionary, day_key: String) -> Dictionary:
	var p := ensure_fields(source)
	if not _valid_day(day_key): return _fail(p, "Use a valid Print Yard day.")
	if str(p.last_yard_day) == day_key: return _fail(p, "The Print Yard companions have already shared today's filament lesson.")
	if p.creatures.is_empty(): return _fail(p, "Print a companion before visiting the Print Yard.")
	var xp_reward: int = mini(12, 4 + p.creatures.size() * 2)
	var xp_result := grant_xp(p, xp_reward)
	p = xp_result.profile
	p.last_yard_day = day_key
	return _ok(p, {"day_key":day_key,"xp":xp_reward,"companions":p.creatures.size(),"spool_gained":int(xp_result.payload.spool_gained)})

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
			"armor_blueprint": return learn_armor_blueprint(shop.profile, str(offer.item_id))
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
		seed = _next_seed(seed); var armor: Dictionary = Catalog.ARMOR[seed % Catalog.ARMOR.size()]
		while used.has("a:%s" % armor.id): seed = _next_seed(seed); armor = Catalog.ARMOR[seed % Catalog.ARMOR.size()]
		used["a:%s" % armor.id] = true; offers.append({"offer_id":"%s-a%d" % [day_key,slot],"kind":"armor_blueprint","item_id":armor.id,"name":armor.name,"price":int(armor.blueprint)})
	for slot in 2:
		seed = _next_seed(seed); var card: Dictionary = Catalog.SUPPORT_CARDS[seed % Catalog.SUPPORT_CARDS.size()]
		while used.has("s:%s" % card.id): seed = _next_seed(seed); card = Catalog.SUPPORT_CARDS[seed % Catalog.SUPPORT_CARDS.size()]
		used["s:%s" % card.id] = true; offers.append({"offer_id":"%s-s%d" % [day_key,slot],"kind":"support_card","item_id":card.id,"name":card.name,"price":support_price(card)})
	return offers

static func _next_seed(seed: int) -> int:
	return int((seed * 1103515245 + 12345) % 2147483647)
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
	for armor in Catalog.ARMOR:
		if str(armor.id) == id: return armor.duplicate(true)
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
static func _ok(p: Dictionary, payload: Dictionary) -> Dictionary:
	return {"ok":true,"profile":p,"payload":payload}
static func _fail(p: Dictionary, error: String) -> Dictionary:
	return {"ok":false,"profile":p,"error":error}
