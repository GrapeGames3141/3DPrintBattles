class_name EquipmentRules
extends RefCounted
## Atomic inventory transitions for complete suits and optional socketed Cores.

const DEFINITIONS := preload("res://scripts/core/armor_core_definitions.gd")

static func ensure_fields(source: Dictionary) -> Dictionary:
	var p := source.duplicate(true)
	for key in ["suit_blueprints", "core_blueprints", "suits", "cores"]:
		if not p.has(key) or not (p.get(key, []) is Array): p[key] = []
	if not p.has("print_history") or not (p.get("print_history", {}) is Dictionary): p["print_history"] = {}
	for key in ["suits", "cores"]:
		if not p["print_history"].has(key) or not (p["print_history"].get(key, {}) is Dictionary): p["print_history"][key] = {}
	return p

static func learn_suit(source: Dictionary, tier_id: String) -> Dictionary:
	var p := ensure_fields(source); var suit := DEFINITIONS.suit_definition(tier_id)
	if suit.is_empty() or tier_id in p["suit_blueprints"]: return _fail(p, "That full-suit blueprint is unavailable.")
	if int(p.get("coins", 0)) < int(suit.blueprint): return _fail(p, "Not enough Forge Coins.")
	p["coins"] = int(p.get("coins", 0)) - int(suit.blueprint); p["suit_blueprints"].append(tier_id)
	return _ok(p, {"tier_id":tier_id,"price":int(suit.blueprint)})

static func print_suit(source: Dictionary, tier_id: String) -> Dictionary:
	var p := ensure_fields(source); var suit := DEFINITIONS.suit_definition(tier_id)
	if suit.is_empty() or not tier_id in p["suit_blueprints"]: return _fail(p, "Learn this full-suit blueprint first.")
	if int(p.get("coins", 0)) < int(suit.print): return _fail(p, "Not enough Forge Coins.")
	var instance_id := _next_id(p, "suit-%s" % tier_id)
	p["coins"] = int(p.get("coins", 0)) - int(suit.print); p["suits"].append({"suit_instance_id":instance_id,"tier_id":tier_id,"equipped_to":"","socketed_core_id":""})
	p["print_history"]["suits"][tier_id] = int(p["print_history"]["suits"].get(tier_id, 0)) + 1
	return _ok(p, {"tier_id":tier_id,"suit_instance_id":instance_id,"price":int(suit.print)})

static func learn_core(source: Dictionary, core_id: String) -> Dictionary:
	var p := ensure_fields(source); var core := DEFINITIONS.core_blueprint_definition(core_id)
	if core.is_empty() or core_id in p["core_blueprints"]: return _fail(p, "That Core blueprint is unavailable.")
	if int(p.get("coins", 0)) < int(core.blueprint): return _fail(p, "Not enough Forge Coins.")
	p["coins"] = int(p.get("coins", 0)) - int(core.blueprint); p["core_blueprints"].append(core_id)
	return _ok(p, {"core_id":core_id,"price":int(core.blueprint)})

static func print_core(source: Dictionary, core_id: String) -> Dictionary:
	var p := ensure_fields(source); var core := DEFINITIONS.core_blueprint_definition(core_id)
	if core.is_empty() or not core_id in p["core_blueprints"]: return _fail(p, "Learn this Core blueprint first.")
	if int(p.get("coins", 0)) < int(core.print): return _fail(p, "Not enough Forge Coins.")
	var instance_id := _next_id(p, "core-%s" % core_id)
	p["coins"] = int(p.get("coins", 0)) - int(core.print); p["cores"].append({"core_instance_id":instance_id,"core_id":core_id,"socketed_to":""})
	p["print_history"]["cores"][core_id] = int(p["print_history"]["cores"].get(core_id, 0)) + 1
	return _ok(p, {"core_id":core_id,"core_instance_id":instance_id,"price":int(core.print)})

static func equip_suit(source: Dictionary, creature_id: String, suit_id: String) -> Dictionary:
	var p := ensure_fields(source); var creature := _creature(p, creature_id); var suit := _suit(p, suit_id)
	if creature.is_empty() or suit.is_empty(): return _fail(p, "That companion or full suit is unavailable.")
	var old_owner := str(suit.get("equipped_to", ""))
	if not old_owner.is_empty():
		var owner := _creature(p, old_owner)
		if not owner.is_empty(): owner.suit_instance_id = ""
	for other in p["suits"]:
		if str(other.get("equipped_to", "")) == creature_id: other.equipped_to = ""
	creature.suit_instance_id = suit_id; suit.equipped_to = creature_id
	return _ok(p, {"creature_instance_id":creature_id,"suit_instance_id":suit_id,"previous_owner":old_owner})

static func remove_suit(source: Dictionary, creature_id: String) -> Dictionary:
	var p := ensure_fields(source); var creature := _creature(p, creature_id)
	var suit_id := str(creature.get("suit_instance_id", "")) if not creature.is_empty() else ""
	if creature.is_empty() or suit_id.is_empty(): return _fail(p, "That companion has no full suit to remove.")
	var suit := _suit(p, suit_id); creature.suit_instance_id = ""
	if not suit.is_empty(): suit.equipped_to = ""
	return _ok(p, {"creature_instance_id":creature_id,"suit_instance_id":suit_id})

static func socket_core(source: Dictionary, suit_id: String, core_id: String) -> Dictionary:
	var p := ensure_fields(source); var suit := _suit(p, suit_id); var core := _core(p, core_id)
	if suit.is_empty() or core.is_empty(): return _fail(p, "That full suit or Core is unavailable.")
	var displaced := str(suit.get("socketed_core_id", ""))
	if not displaced.is_empty():
		var old_core := _core(p, displaced)
		if not old_core.is_empty(): old_core.socketed_to = ""
	var prior_suit_id := str(core.get("socketed_to", ""))
	if not prior_suit_id.is_empty():
		var prior_suit := _suit(p, prior_suit_id)
		if not prior_suit.is_empty(): prior_suit.socketed_core_id = ""
	suit.socketed_core_id = core_id; core.socketed_to = suit_id
	return _ok(p, {"suit_instance_id":suit_id,"core_instance_id":core_id,"displaced_core_instance_id":displaced,"previous_suit_instance_id":prior_suit_id})

static func remove_core(source: Dictionary, suit_id: String) -> Dictionary:
	var p := ensure_fields(source); var suit := _suit(p, suit_id)
	var core_id := str(suit.get("socketed_core_id", "")) if not suit.is_empty() else ""
	if suit.is_empty() or core_id.is_empty(): return _fail(p, "That full suit has no Core to remove.")
	var core := _core(p, core_id); suit.socketed_core_id = ""
	if not core.is_empty(): core.socketed_to = ""
	return _ok(p, {"suit_instance_id":suit_id,"core_instance_id":core_id})

static func suit_loadout(p: Dictionary, creature_id: String) -> Dictionary:
	var clean := ensure_fields(p); var creature := _creature(clean, creature_id)
	var suit := _suit(clean, str(creature.get("suit_instance_id", ""))) if not creature.is_empty() else {}
	if suit.is_empty() or str(suit.get("equipped_to", "")) != creature_id: return {"tier_id":"","core_id":"","suit_instance_id":""}
	var core := _core(clean, str(suit.get("socketed_core_id", "")))
	return {"tier_id":str(suit.get("tier_id", "")),"core_id":str(core.get("core_id", "")) if str(core.get("socketed_to", "")) == str(suit.get("suit_instance_id", "")) else "","suit_instance_id":str(suit.get("suit_instance_id", ""))}

static func _next_id(p: Dictionary, prefix: String) -> String:
	var nonce := maxi(1, int(p.get("next_instance_nonce", 1))); p["next_instance_nonce"] = nonce + 1
	return "%s-%d" % [prefix, nonce]
static func _creature(p: Dictionary, id: String) -> Dictionary:
	for row in p.get("creatures", []): if row is Dictionary and str(row.get("instance_id", "")) == id: return row
	return {}
static func _suit(p: Dictionary, id: String) -> Dictionary:
	for row in p.get("suits", []): if row is Dictionary and str(row.get("suit_instance_id", "")) == id: return row
	return {}
static func _core(p: Dictionary, id: String) -> Dictionary:
	for row in p.get("cores", []): if row is Dictionary and str(row.get("core_instance_id", "")) == id: return row
	return {}
static func _ok(profile: Dictionary, payload: Dictionary) -> Dictionary: return {"ok":true,"profile":profile,"payload":payload}
static func _fail(profile: Dictionary, error: String) -> Dictionary: return {"ok":false,"profile":profile,"error":error}
