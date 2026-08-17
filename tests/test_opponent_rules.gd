extends Node

const RULES := preload("res://scripts/core/opponent_rules.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").get("profile", {})
	var printed := ProgressionRules.purchase_creature_blueprint(profile, "aquafin")
	profile = ProgressionRules.print_creature(printed.get("profile", {}), "aquafin").get("profile", {})
	profile["team"] = [str(profile["creatures"][0].get("instance_id", "")), str(profile["creatures"][1].get("instance_id", ""))]
	var lineup := ProfileRules.team_loadout(profile)
	var first := RULES.prepare_daily(profile, "2026-08-17", lineup)
	require(bool(first.get("ok", false)) and first.get("contracts", []).size() == 3, "three daily contracts are generated")
	var frozen := RULES.prepare_daily(first.get("profile", {}), "2026-08-17", [{"creature_id":"worldcoil"}])
	require(frozen.get("contracts", []) == first.get("contracts", []), "daily contracts freeze after first preparation")
	for contract in first.get("contracts", []):
		require((contract.get("team", []) as Array).size() == 2 and (contract.get("deck", []) as Array).size() == 15, "contract has legal team size and deck")
		var ids: Dictionary = {}
		for entry in contract.get("team", []):
			ids[str(entry.get("creature_id", ""))] = true
		require(ids.size() == (contract.get("team", []) as Array).size(), "contract team has no duplicates")
	var diversity_profile := profile.duplicate(true)
	diversity_profile["spool_level"] = 5
	diversity_profile["solo_campaign"] = {"unlocked_tier":3}
	var three_unit_player := [{"creature_id":"cinderpaw"}, {"creature_id":"mossmunk"}, {"creature_id":"aquafin"}]
	var diverse_daily := RULES.prepare_daily(diversity_profile, "2026-08-22", three_unit_player)
	var lineup_keys: Dictionary = {}
	var rival_teams: Array = []
	for contract in diverse_daily.get("contracts", []):
		var ids: Array[String] = []
		for entry in contract.get("team", []): ids.append(str(entry.get("creature_id", "")))
		ids.sort()
		var key := ",".join(ids)
		lineup_keys[key] = true
		rival_teams.append(ids)
	require(lineup_keys.size() == 3, "daily contracts never repeat an identical creature lineup when alternatives are legal")
	for left in rival_teams.size():
		for right in range(left + 1, rival_teams.size()):
			var overlap := 0
			for creature_id in rival_teams[left]:
				if creature_id in rival_teams[right]: overlap += 1
			require(overlap <= 1, "three-unit daily rival lineups prefer at most one reused creature")
	var claimed := RULES.claim_victory(first.get("profile", {}), "apprentice_spar", "2026-08-17")
	require(bool(claimed.get("ok", false)) and bool(claimed.get("payload", {}).get("first_clear", false)), "first daily victory claims reward")
	var replay := RULES.claim_victory(claimed.get("profile", {}), "apprentice_spar", "2026-08-17")
	require(bool(replay.get("ok", false)) and not bool(replay.get("payload", {}).get("first_clear", true)) and int(replay.get("payload", {}).get("reward", {}).get("coins", -1)) == 0, "daily replay reward is idempotent")
	var contract: Dictionary = first.get("contracts", [])[0]
	var seat_zero := BattleState.create(lineup, contract.get("team", []), 3, int(contract.get("spool", 3)), 4, RULES.deck("balanced"), contract.get("deck", []))
	seat_zero.active_player = 0; seat_zero.opening_player = 0
	var player_intent := AIOpponent.choose_intent_for(seat_zero, 0, "Craftsman")
	require(bool(BattleRules.apply_intent(seat_zero, 0, player_intent).get("ok", false)), "seat-zero simulation intent is legal on a mirrored complete snapshot")
	if failures.is_empty(): print("PASS: deterministic frozen daily contracts, legal loadouts, and idempotent rewards")
	call_deferred("finish")

func finish() -> void: get_tree().quit(0 if failures.is_empty() else 1)
