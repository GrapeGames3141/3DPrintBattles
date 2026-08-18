class_name UnifiedBattleState
extends RefCounted
## Snapshot schema for the 0.7 simultaneous-board ruleset.
const RULES := preload("res://scripts/core/unified_rules.gd")
var seed := 0
var active_seat := 0
var turn := 1
var phase := "play"
var finished := false
var winner := -1
var players: Array = []
var log: Array[String] = []

static func create(player_deck: Array, rival_deck: Array, match_seed: int = 7, player_nodes: Array = [], rival_nodes: Array = [], player_builds: Dictionary = {}, rival_builds: Dictionary = {}) -> UnifiedBattleState:
	var state := UnifiedBattleState.new(); state.seed = match_seed
	state.players = [_player(player_deck, player_nodes, match_seed, player_builds), _player(rival_deck, rival_nodes, match_seed + 17, rival_builds)]
	state.log.append("Play phase: deploy, equip, cast, or refill.")
	return state

static func _player(deck_source: Array, nodes: Array, seed_value: int, builds: Dictionary = {}) -> Dictionary:
	var deck := deck_source.duplicate(); _shuffle(deck, seed_value); _opening_creature_fix(deck, seed_value + 1)
	var hand: Array = []
	for _i in mini(4, deck.size()): hand.append(deck.pop_front())
	var spool := 3
	if "spool_5" in nodes: spool = 5
	if "spool_7" in nodes: spool = 7
	if "spool_10" in nodes: spool = 10
	return {"printer":{"durability":110 if "heated_bed" in nodes else 100,"slow":0},"slots":[null,null,null],"print_job":{},"filament":3,"spool_cap":spool,"collector":0,"collector_cap":8 if "collector_8" in nodes else (5 if "collector_5" in nodes else 3),"melted":0,"nodes":nodes.duplicate(),"card_builds":builds.duplicate(true),"deck":deck,"hand":hand,"discard":[],"debris":[],"played":[],"fatigue":0}

static func _shuffle(values: Array, seed_value: int) -> void:
	var seed_local := seed_value
	for index in range(values.size() - 1, 0, -1):
		seed_local = int((seed_local * 1103515245 + 12345) & 0x7fffffff); var swap_index := seed_local % (index + 1); var hold = values[index]; values[index] = values[swap_index]; values[swap_index] = hold

static func _opening_creature_fix(deck: Array, seed_value: int) -> void:
	var opening: Array = deck.slice(0, mini(4, deck.size()))
	for id in opening:
		if str(RULES.card(str(id)).get("type", "")) == "creature": return
	for index in range(4, deck.size()):
		if str(RULES.card(str(deck[index])).get("type", "")) == "creature":
			var selected := seed_value % 4; var hold = deck[selected]; deck[selected] = deck[index]; deck[index] = hold; return

func player(seat: int) -> Dictionary:
	return players[seat] if seat >= 0 and seat < players.size() else {}
func serialize() -> Dictionary:
	return {"seed":seed,"active_seat":active_seat,"turn":turn,"phase":phase,"finished":finished,"winner":winner,"players":players.duplicate(true),"log":log.duplicate()}
