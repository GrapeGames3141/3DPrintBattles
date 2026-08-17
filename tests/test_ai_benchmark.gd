extends Node
var failures: Array[String] = []
func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)
func _ready() -> void:
	var wins := [0, 0]; var legal := true
	for seed in range(100):
		var team := [{"creature_id":"cinderpaw"},{"creature_id":"aquafin"}]
		var state := BattleState.create(team, team, 5, 5, seed, BattleState.STARTER_LOADOUT, BattleState.STARTER_LOADOUT)
		var steps := 0
		while not state.finished and steps < 160:
			var actor := state.active_player
			var intent := AIOpponent.choose_intent_for(state, actor, "Craftsman")
			var result := BattleRules.apply_intent(state, actor, intent)
			if not bool(result.get("ok", false)): legal = false; break
			steps += 1
		if state.finished: wins[state.winner] += 1
	require(legal, "symmetric seat-zero and seat-one intents are legal")
	var delta := absi(wins[0] - wins[1])
	require(delta <= 12, "symmetric paired benchmark remains near 50/50")
	var overdrive := BattleState.create([{"creature_id":"cinderpaw"}], [{"creature_id":"cinderpaw"}], 5, 5, 777, BattleState.STARTER_LOADOUT, BattleState.STARTER_LOADOUT)
	overdrive.active_player = 1; overdrive.turn = 3
	overdrive.players[1]["tactics"] = "overdrive"
	overdrive.players[1]["filament"] = 5
	overdrive.players[1]["hand"] = ["arcane_spark"]
	overdrive.players[1]["discard"] = []
	var before := overdrive.serialize()
	var setup_intent := AIOpponent.choose_intent(overdrive, "Master")
	require(overdrive.serialize() == before, "Overdrive intent selection does not mutate serialized battle state")
	require(str(setup_intent.get("type", "")) == "card", "Overdrive selects one useful setup card before normal Master evaluation")
	var setup_result := BattleRules.apply_intent(overdrive, 1, setup_intent)
	require(bool(setup_result.get("ok", false)) and not (overdrive.players[1].get("discard", []) as Array).is_empty(), "successful Overdrive card application enters the authoritative discard")
	var followup_intent := AIOpponent.choose_intent(overdrive, "Master")
	require(str(followup_intent.get("type", "")) != "card", "Overdrive selects at most one setup card after successful application")
	print("AI_BENCHMARK wins=%s delta=%d" % [wins, delta])
	call_deferred("finish")
func finish() -> void: get_tree().quit(0 if failures.is_empty() else 1)
