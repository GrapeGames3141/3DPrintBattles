class_name LocalBattleAuthority
extends RefCounted
## Pure revisioned local authority. UI submits intents and never mutates state directly.

var state: BattleState
var revision := 0

static func create(player_team: Array, rival_team: Array, player_deck: Array, seed: int = 20260814) -> LocalBattleAuthority:
	var authority := LocalBattleAuthority.new()
	authority.state = BattleState.create(player_team, rival_team, 3, 3, seed, player_deck, BattleState.STARTER_LOADOUT)
	authority.state.match_id = "local-%08d" % seed
	return authority

func submit(request: Dictionary) -> Dictionary:
	var seat := int(request.get("seat", -1))
	if seat < 0 or seat > 1: return _reject("Choose a valid local seat.")
	if int(request.get("expected_revision", -1)) != revision: return _reject("This local match has advanced. Ready the current turn.")
	if seat != state.active_player: return _reject("It is the other player’s turn.")
	var intent = request.get("intent", {})
	if not intent is Dictionary: return _reject("Choose a valid battle action.")
	var before := state.serialize()
	var result := BattleRules.apply_intent(state, seat, intent)
	if not bool(result.get("ok", false)):
		# The rules reject without mutation; restoring keeps the authority promise explicit.
		state = _state_from_snapshot(before)
		return _reject(str(result.get("error", "That action is unavailable.")))
	revision += 1
	return {"ok":true,"revision":revision,"event":{"seat":seat,"type":str(intent.get("type", "")),"result":result.duplicate(true)},"snapshot":state.serialize().duplicate(true)}

func snapshot() -> Dictionary:
	return {"revision":revision,"snapshot":state.serialize().duplicate(true)}

func _reject(message: String) -> Dictionary:
	return {"ok":false,"error":message,"revision":revision,"snapshot":state.serialize().duplicate(true)}

func _state_from_snapshot(snapshot: Dictionary) -> BattleState:
	return BattleState.from_snapshot(snapshot)
