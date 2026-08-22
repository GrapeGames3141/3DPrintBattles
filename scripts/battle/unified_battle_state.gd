class_name UnifiedBattleState
extends RefCounted
## PrintForge Legends v3.1 immutable-snapshot battle state.  The fields in this
## class are deliberately plain data so the local authority and a future server
## can replay the same seeded match without UI nodes.

const RULES := preload("res://scripts/core/unified_rules.gd")
const PHASES := ["draw", "main", "print", "attack", "collect"]
var schema := "v3.1"
var revision := 0
var seed := 0
var starting_seat := 0
var active_seat := 0
var turn := 1
var phase := "draw"
var finished := false
var winner := -1
var pending: Dictionary = {}
var players: Array = []
var log: Array[String] = []

static func create(player_deck: Array, rival_deck: Array, match_seed: int = 7, player_upgrades: Array = [], rival_upgrades: Array = [], player_preprints: Array = [], rival_preprints: Array = [], player_workshop: Dictionary = {}, rival_workshop: Dictionary = {}) -> UnifiedBattleState:
	var state := UnifiedBattleState.new()
	state.seed = match_seed
	state.starting_seat = _next(match_seed) & 1
	state.active_seat = state.starting_seat
	state.players = [
		_player(player_deck, _next(match_seed + 11), player_upgrades, player_preprints, player_workshop),
		_player(rival_deck, _next(match_seed + 29), rival_upgrades, rival_preprints, rival_workshop)
	]
	state.log.append("Draw phase: %s begins." % ("Player 1" if state.active_seat == 0 else "Player 2"))
	return state

static func _player(deck_source: Array, seed_value: int, installed: Array, preprints: Array, workshop: Dictionary) -> Dictionary:
	var deck: Array = []
	for card_id in deck_source:
		if not RULES.card(str(card_id)).is_empty(): deck.append(str(card_id))
	_shuffle(deck, seed_value)
	var field: Array = [null, null, null]
	# Pre-prints consume the matching deck copies before the opening hand. Invalid
	# selections are ignored here; deck/pre-print validation rejects them earlier.
	for index in mini(3, preprints.size()):
		var card_id := str(preprints[index])
		if not deck.has(card_id): continue
		var card := RULES.card(card_id)
		if str(card.get("type", "")) != "creature": continue
		deck.erase(card_id)
		field[index] = _unit(card, true)
	var hand: Array = []
	for _i in mini(5, deck.size()): hand.append(deck.pop_front())
	var workshop_upgrades: Array = workshop.get("workshop_upgrades", []) if workshop.get("workshop_upgrades", []) is Array else []
	var capacity := 400
	if "spool_capacity_i" in workshop_upgrades: capacity = 500
	if "spool_capacity_ii" in workshop_upgrades: capacity = 700
	return {
		"printer":{"hp":2000,"max_hp":2000}, "slots":field, "queue":[], "staging":[], "holding":[], "filament_ring_active":false,
		"filament":200, "filament_max":capacity, "trap":{}, "deck":deck, "hand":hand,
		"graveyard":[], "scrap":[], "installed_upgrades":installed.duplicate(), "upgrade_plays":0,
		"emergency_reprints":installed.count("emergency_reprint_upgrade"), "preprints":preprints.duplicate(), "draw_count":0, "played":[]
	}

static func _unit(card: Dictionary, preprinted := false) -> Dictionary:
	return {"card_id":str(card.get("id", "")), "name":str(card.get("name", "Print")), "rarity":str(card.get("rarity", "common")), "element":str(card.get("element", "Arcane")), "bend":int(card.get("bend_score", card.get("bend", 0))), "base_hp":int(card.get("hp", 1)), "hp":int(card.get("hp", 1)), "armor_hp":0, "mode":"defense" if preprinted else "attack", "ready":not preprinted, "preprinted":preprinted, "mode_changed":false, "attacked":false, "equipment":{"armor":{},"gem":{}}, "statuses":{}, "ability_cooldown":0, "equipment_cost":0}

static func _next(value: int) -> int:
	return int((value * 1103515245 + 12345) & 0x7fffffff)
static func _shuffle(values: Array, seed_value: int) -> void:
	var value := seed_value
	for index in range(values.size() - 1, 0, -1):
		value = _next(value); var other := value % (index + 1); var item = values[index]; values[index] = values[other]; values[other] = item
func player(seat: int) -> Dictionary:
	return players[seat] if seat >= 0 and seat < players.size() else {}
func serialize() -> Dictionary:
	return {"schema":schema,"revision":revision,"seed":seed,"starting_seat":starting_seat,"active_seat":active_seat,"turn":turn,"phase":phase,"finished":finished,"winner":winner,"pending":pending.duplicate(true),"players":players.duplicate(true),"log":log.duplicate()}
func public_snapshot(viewer_seat: int = -1) -> Dictionary:
	var snapshot := serialize()
	for seat in 2:
		if seat != viewer_seat:
			(snapshot.players[seat] as Dictionary).erase("hand")
			(snapshot.players[seat] as Dictionary).erase("deck")
			(snapshot.players[seat] as Dictionary)["hand_count"] = int(player(seat).hand.size())
			if not (snapshot.players[seat] as Dictionary).get("trap", {}).is_empty(): (snapshot.players[seat] as Dictionary)["trap"] = {"set":true}
	return snapshot
