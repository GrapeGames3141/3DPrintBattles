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
		# Launch callers may carry older catalog aliases or a canonical string.  The
		# runtime owns one tolerant conversion boundary instead of silently dropping
		# a valid species because its key changed between profile/UI/battle layers.
		var creature_id := creature_id_from_entry(entry)
		var armor_id := armor_id_from_entry(entry)
		var def := Catalog.creature(creature_id)
		if def.is_empty(): continue
		var armor_def: Dictionary = ProgressionRules.armor_def(armor_id)
		var hp_bonus: int = clampi(int(armor_def.get("hp", 0)), 0, 100)
		var speed_bonus: int = clampi(int(armor_def.get("speed", 0)), -10, 10)
		var armor_bonus: int = clampi(int(armor_def.get("armor", 0)), 0, 10)
		var max_hp: int = clampi(int(def.hp) + hp_bonus, 1, 999)
		team.append(normalize_unit({"id":def.id,"name":def.name,"element":def.element,"hp":max_hp,"max_hp":max_hp,"attack":def.attack,"speed":clampi(int(def.speed) + speed_bonus, 1, 99),"cost":def.cost,"ability":def.ability,"ability_cost":def.ability_cost,"cooldown":def.cooldown,"cooldown_remaining":0,"armor":armor_bonus,"armor_id":str(armor_def.get("id", "")),"armor_name":str(armor_def.get("name", "")),"shield":0,"attack_buff":0,"attack_debuff":0,"ability_lock_turns":0,"cooling":false}))
	var deck: Array[String] = supplied_deck.duplicate() if _valid_supplied_deck(supplied_deck) else STARTER_LOADOUT.duplicate()
	var hand: Array[String] = []
	for draw_index in 4:
		hand.append(deck.pop_front())
	return {"team":team,"active":0,"filament":mini(3, spool_cap),"spool_cap":spool_cap,"hand":hand,"deck":deck,"switch_discount":0,"switch_discount_turns":0,"passed_turns":0}

static func creature_id_from_entry(entry) -> String:
	if entry is Dictionary:
		for key in ["creature_id", "id", "species_id", "creature", "species"]:
			var candidate := str(entry.get(key, ""))
			if not Catalog.creature(candidate).is_empty(): return candidate
		return ""
	var candidate := str(entry)
	return candidate if not Catalog.creature(candidate).is_empty() else ""

static func armor_id_from_entry(entry) -> String:
	if not entry is Dictionary: return ""
	for key in ["armor_id", "armor", "armor_definition_id"]:
		var candidate := str(entry.get(key, ""))
		if not ProgressionRules.armor_def(candidate).is_empty(): return candidate
	return ""

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
	# make_team() already emits normalized catalog-backed entries. Snapshot and
	# authority boundaries call normalize_runtime() separately for legacy data.
	return state

## Legacy/local snapshots may only carry an ID and changing combat fields. Fill the
## stable catalog contract without inventing a unit for an invalid empty team.
static func normalize_unit(unit: Dictionary) -> Dictionary:
	return BattleUnitRuntime.from_dictionary(unit).to_dictionary()

static func from_snapshot(snapshot: Dictionary) -> BattleState:
	var restored := BattleState.new()
	restored.match_id = str(snapshot.get("match_id", "local"))
	restored.turn = maxi(1, int(snapshot.get("turn", 1)))
	restored.active_player = clampi(int(snapshot.get("active_player", 0)), 0, 1)
	restored.opening_player = clampi(int(snapshot.get("opening_player", restored.active_player)), 0, 1)
	restored.finished = bool(snapshot.get("finished", false))
	restored.winner = int(snapshot.get("winner", -1))
	var raw_players = snapshot.get("players", [])
	restored.players = raw_players.duplicate(true) if raw_players is Array else []
	var raw_log = snapshot.get("log", [])
	if raw_log is Array:
		for entry in raw_log:
			restored.log.append(str(entry))
	restored.seed = int(snapshot.get("seed", 0))
	restored.reward_claimed = bool(snapshot.get("reward_claimed", false))
	restored.normalize_runtime()
	return restored

func normalize_runtime() -> void:
	for player_data in players:
		if not player_data is Dictionary: continue
		var team_value = player_data.get("team", [])
		if not team_value is Array: continue
		for index in team_value.size():
			var entry = team_value[index]
			if entry is Dictionary: team_value[index] = normalize_unit(entry)

func active_unit(player: int) -> Dictionary:
	if player < 0 or player >= players.size(): return {}
	var player_data = players[player]
	if not player_data is Dictionary: return {}
	var team_value = player_data.get("team", [])
	var active_index: int = int(player_data.get("active", 0))
	if not team_value is Array or active_index < 0 or active_index >= team_value.size(): return {}
	var unit = team_value[active_index]
	return unit if unit is Dictionary else {}

func validation_error(require_ready := false) -> String:
	if players.size() != 2: return "Battle setup is missing a complete pair of teams."
	for player in [0, 1]:
		var unit := active_unit(player)
		if unit.is_empty() or Catalog.creature(str(unit.get("id", ""))).is_empty():
			return "Battle setup has an invalid %s team." % ("player" if player == 0 else "rival")
		if int(unit.get("max_hp", 0)) <= 0:
			return "Battle setup has invalid %s vitality data." % ("player" if player == 0 else "rival")
		if require_ready and int(unit.get("hp", 0)) <= 0:
			return "Battle setup has no ready %s print." % ("player" if player == 0 else "rival")
		var player_data = players[player]
		if not player_data is Dictionary or int(player_data.get("spool_cap", 0)) <= 0:
			return "Battle setup is missing %s filament data." % ("player" if player == 0 else "rival")
	return ""

func serialize() -> Dictionary:
	return {"match_id":match_id,"turn":turn,"active_player":active_player,"opening_player":opening_player,"finished":finished,"winner":winner,"players":players,"log":log,"seed":seed,"reward_claimed":reward_claimed}
