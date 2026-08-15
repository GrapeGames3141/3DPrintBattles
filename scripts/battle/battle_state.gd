class_name BattleState
extends RefCounted
## Pure mutable combat state; canonical serialization is safe to send to an authority.
var match_id := "local"
var turn: int = 1
var active_player: int = 0
var opening_player: int = 0
var finished: bool = false
var winner: int = -1
var players: Array = []
var log: Array[String] = []
var seed: int = 0
var reward_claimed: bool = false

const STARTER_LOADOUT: Array[String] = [
	"raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament",
	"heated_spool", "heated_spool", "heated_spool",
	"reinforced_layer", "reinforced_layer", "reinforced_layer",
	"quick_patch", "quick_patch", "arcane_spark", "arcane_spark"
]

static func make_team(creature_ids: Array, spool_cap: int, supplied_deck: Array = []) -> Dictionary:
	var team: Array = []
	for entry in creature_ids:
		var creature_id := str(entry.get("creature_id", "")) if entry is Dictionary else str(entry)
		var armor_id := str(entry.get("armor_id", "")) if entry is Dictionary else ""
		var def := Catalog.creature(creature_id)
		if def.is_empty(): continue
		var armor_def: Dictionary = ProgressionRules.armor_def(armor_id)
		var hp_bonus: int = clampi(int(armor_def.get("hp", 0)), 0, 100)
		var speed_bonus: int = clampi(int(armor_def.get("speed", 0)), -10, 10)
		var armor_bonus: int = clampi(int(armor_def.get("armor", 0)), 0, 10)
		var max_hp: int = clampi(int(def.hp) + hp_bonus, 1, 999)
		team.append({"id":def.id,"name":def.name,"element":def.element,"hp":max_hp,"max_hp":max_hp,"attack":def.attack,"speed":clampi(int(def.speed) + speed_bonus, 1, 99),"cost":def.cost,"ability":def.ability,"ability_cost":def.ability_cost,"cooldown":def.cooldown,"cooldown_remaining":0,"armor":armor_bonus,"armor_id":str(armor_def.get("id", "")),"armor_name":str(armor_def.get("name", "")),"shield":0,"attack_buff":0,"attack_debuff":0,"ability_lock_turns":0,"cooling":false})
	var deck: Array[String] = supplied_deck.duplicate() if _valid_supplied_deck(supplied_deck) else STARTER_LOADOUT.duplicate()
	var hand: Array[String] = []
	for draw_index in 4:
		hand.append(deck.pop_front())
	return {"team":team,"active":0,"filament":mini(3, spool_cap),"spool_cap":spool_cap,"hand":hand,"deck":deck,"switch_discount":0,"passed_turns":0}

static func _valid_supplied_deck(deck: Array) -> bool:
	if deck.size() != 15: return false
	for card_id in deck:
		if Catalog.support_card(str(card_id)).is_empty(): return false
	return true

static func create(player_team: Array, opponent_team: Array, player_cap: int, opponent_cap: int, match_seed: int = 42, player_deck: Array = [], opponent_deck: Array = []) -> BattleState:
	var state := BattleState.new()
	state.seed = match_seed
	state.players = [make_team(player_team, player_cap, player_deck), make_team(opponent_team, opponent_cap, opponent_deck)]
	state.active_player = 0 if match_seed % 2 == 0 else 1
	state.opening_player = state.active_player
	state.log.append("Coin flip: %s goes first." % ("You" if state.active_player == 0 else "Rival"))
	return state

func active_unit(player: int) -> Dictionary:
	return players[player].team[players[player].active]

func serialize() -> Dictionary:
	return {"match_id":match_id,"turn":turn,"active_player":active_player,"opening_player":opening_player,"finished":finished,"winner":winner,"players":players,"log":log,"seed":seed,"reward_claimed":reward_claimed}
