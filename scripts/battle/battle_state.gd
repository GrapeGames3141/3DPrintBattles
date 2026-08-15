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
		team.append(normalize_unit({"id":def.id,"name":def.name,"element":def.element,"hp":max_hp,"max_hp":max_hp,"attack":def.attack,"speed":clampi(int(def.speed) + speed_bonus, 1, 99),"cost":def.cost,"ability":def.ability,"ability_cost":def.ability_cost,"cooldown":def.cooldown,"cooldown_remaining":0,"armor":armor_bonus,"armor_id":str(armor_def.get("id", "")),"armor_name":str(armor_def.get("name", "")),"shield":0,"attack_buff":0,"attack_debuff":0,"ability_lock_turns":0,"cooling":false}))
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
	state.normalize_runtime()
	return state

## Legacy/local snapshots may only carry an ID and changing combat fields. Fill the
## stable catalog contract without inventing a unit for an invalid empty team.
static func normalize_unit(unit: Dictionary) -> Dictionary:
	if unit.is_empty(): return unit
	var creature_id := str(unit.get("id", unit.get("creature_id", unit.get("species_id", ""))))
	var definition: Dictionary = Catalog.creature(creature_id)
	if definition.is_empty(): return unit
	# Legacy instances can retain an equipped armor ID while omitting the combat
	# fields that were materialized when the match began. Build those defaults
	# from the same catalog path as make_team(), but never overwrite a real
	# runtime value supplied by a current snapshot.
	var armor_id := str(unit.get("armor_id", unit.get("equipped_armor_id", "")))
	var armor_definition: Dictionary = ProgressionRules.armor_def(armor_id)
	var armor_hp: int = clampi(int(armor_definition.get("hp", 0)), 0, 100)
	var armor_speed: int = clampi(int(armor_definition.get("speed", 0)), -10, 10)
	var armor_guard: int = clampi(int(armor_definition.get("armor", 0)), 0, 10)
	var default_max_hp: int = clampi(int(definition.get("hp", 1)) + armor_hp, 1, 999)
	var default_speed: int = clampi(int(definition.get("speed", 0)) + armor_speed, 1, 99)
	unit["id"] = creature_id
	unit["name"] = str(unit.get("name", definition.get("name", creature_id)))
	unit["element"] = str(unit.get("element", definition.get("element", "Unknown")))
	var max_hp: int = maxi(1, int(unit.get("max_hp", unit.get("max_health", unit.get("maxHp", default_max_hp)))))
	unit["max_hp"] = max_hp
	unit["hp"] = clampi(int(unit.get("hp", unit.get("health", unit.get("current_hp", max_hp)))), 0, max_hp)
	unit["attack"] = maxi(0, int(unit.get("attack", unit.get("attack_power", unit.get("power", definition.get("attack", 0))))))
	unit["speed"] = maxi(0, int(unit.get("speed", default_speed)))
	unit["cost"] = maxi(0, int(unit.get("cost", unit.get("filament_cost", definition.get("cost", 0)))))
	unit["ability"] = str(unit.get("ability", unit.get("signature", definition.get("ability", "Signature"))))
	unit["ability_cost"] = maxi(0, int(unit.get("ability_cost", unit.get("signature_cost", definition.get("ability_cost", 0)))))
	unit["cooldown"] = maxi(0, int(unit.get("cooldown", unit.get("ability_cooldown", definition.get("cooldown", 0)))))
	unit["cooldown_remaining"] = maxi(0, int(unit.get("cooldown_remaining", unit.get("cooldown_left", 0))))
	unit["armor"] = maxi(0, int(unit.get("armor", unit.get("guard", armor_guard))))
	unit["armor_id"] = armor_id
	unit["armor_name"] = str(unit.get("armor_name", armor_definition.get("name", "")))
	unit["shield"] = maxi(0, int(unit.get("shield", 0)))
	unit["attack_buff"] = int(unit.get("attack_buff", 0))
	unit["attack_debuff"] = maxi(0, int(unit.get("attack_debuff", 0)))
	unit["ability_lock_turns"] = maxi(0, int(unit.get("ability_lock_turns", 0)))
	unit["cooling"] = bool(unit.get("cooling", false))
	unit["status"] = str(unit.get("status", "ready"))
	return unit

func normalize_runtime() -> void:
	for player_data in players:
		if not player_data is Dictionary: continue
		var team_value = player_data.get("team", [])
		if not team_value is Array: continue
		for entry in team_value:
			if entry is Dictionary: normalize_unit(entry)

func active_unit(player: int) -> Dictionary:
	normalize_runtime()
	if player < 0 or player >= players.size(): return {}
	var player_data = players[player]
	if not player_data is Dictionary: return {}
	var team_value = player_data.get("team", [])
	var active_index: int = int(player_data.get("active", 0))
	if not team_value is Array or active_index < 0 or active_index >= team_value.size(): return {}
	var unit = team_value[active_index]
	return normalize_unit(unit) if unit is Dictionary else {}

func serialize() -> Dictionary:
	return {"match_id":match_id,"turn":turn,"active_player":active_player,"opening_player":opening_player,"finished":finished,"winner":winner,"players":players,"log":log,"seed":seed,"reward_claimed":reward_claimed}
