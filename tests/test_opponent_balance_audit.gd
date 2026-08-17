extends Node

const RULES := preload("res://scripts/core/opponent_rules.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var wins := [0, 0, 0]
	var totals := [0, 0, 0]
	var opening_wins := [0, 0]
	var opening_totals := [0, 0]
	var legal := true
	var terminated := true
	var stalls := [0, 0, 0]
	var band_wins := [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]]
	var band_totals := [0, 0, 0, 0, 0]
	for band in range(1, 6):
		for archetype in _archetypes_for_band(band):
			var profile := _profile_for_band(band)
			var player_team: Array = archetype.team
			var player_deck: Array = RULES.deck(str(archetype.deck))
			for pair in range(5):
				var prepared := RULES.prepare_daily(profile, "2026-08-%02d" % (pair + 1 + int(archetype.index) * 5), player_team, player_deck)
				for index in 3:
					var contract: Dictionary = prepared.get("contracts", [])[index]
					if pair == 0:
						print("AUDIT_FIXTURE band=%d archetype=%s contract=%s player_rating=%d target=%d actual=%d team=%s deck=%s" % [band, str(archetype.name), str(contract.get("id", "")), int(contract.get("player_rating", 0)), int(contract.get("target_rating", 0)), int(contract.get("rating", 0)), contract.get("team", []), str(contract.get("deck_role", ""))])
					for opening in [0, 1]:
						# Paired openings must share an identical shuffle/coin-seed fixture;
						# only the explicit opening seat may differ between the two runs.
						var state := BattleState.create(player_team, contract.get("team", []), int(contract.get("spool", 3)), int(contract.get("rival_spool", contract.get("spool", 3))), pair * 17 + index * 2 + int(archetype.index) * 101, player_deck, contract.get("deck", []))
						state.players[1]["filament"] = clampi(int(contract.get("rival_starting_filament", 3)), 3, int(state.players[1].get("spool_cap", 3)))
						state.players[1]["tactics"] = str(contract.get("tactics", ""))
						state.active_player = opening; state.opening_player = opening
						var steps := 0
						while not state.finished and steps < 160:
							var actor: int = state.active_player
							var intent := AIOpponent.choose_intent_for(state, actor, "Craftsman" if actor == 0 else str(contract.get("difficulty", "Apprentice")))
							var result := BattleRules.apply_intent(state, actor, intent)
							if not bool(result.get("ok", false)):
								legal = false
								break
							steps += 1
						if not state.finished: stalls[index] += 1
						terminated = terminated and state.finished
						totals[index] += 1; band_totals[band - 1] += 1
						if state.winner == 0:
							wins[index] += 1; band_wins[band - 1][index] += 1; opening_wins[opening] += 1
						opening_totals[opening] += 1
	require(legal, "all 600 audited AI intents are legal")
	require(terminated, "all 600 audited matches terminate within 160 intents")
	var rates := [wins[0] * 100 / totals[0], wins[1] * 100 / totals[1], wins[2] * 100 / totals[2]]
	var opening_delta := absi(opening_wins[0] * 100 / opening_totals[0] - opening_wins[1] * 100 / opening_totals[1])
	print("AUDIT_OPENING wins=%s totals=%s" % [opening_wins, opening_totals])
	print("BALANCE_AUDIT matches=%d rates=%s opening_delta=%d stalls=%s" % [totals[0] + totals[1] + totals[2], rates, opening_delta, stalls])
	var target_rates := [70, 55, 40]
	for band in range(1, 6):
		var band_rates := [band_wins[band - 1][0] * 100 / 40, band_wins[band - 1][1] * 100 / 40, band_wins[band - 1][2] * 100 / 40]
		print("AUDIT_BAND band=%d rates=%s" % [band, band_rates])
		for contract_index in 3:
			require(absi(int(band_rates[contract_index]) - int(target_rates[contract_index])) <= 15, "band %d contract %d is within 15 points of its published target" % [band, contract_index + 1])
	require(rates[0] >= 65 and rates[0] <= 75, "Apprentice Spar player win rate is within 65-75%")
	require(rates[1] >= 50 and rates[1] <= 60, "Element Circuit player win rate is within 50-60%")
	require(rates[2] >= 35 and rates[2] <= 45, "Masterwork Challenge player win rate is within 35-45%")
	require(opening_delta <= 8, "opening-player win delta remains within 8 points")
	if failures.is_empty(): print("PASS: 600-match deterministic opponent legality and termination audit")
	call_deferred("finish")

func _profile_for_band(band: int) -> Dictionary:
	var profile := ProfileRules.new_profile()
	profile["spool_level"] = band * 2
	profile["solo_campaign"] = {"unlocked_tier":band,"completed_encounter_ids":[],"claimed_reward_ids":[],"best_turn_counts":{}}
	return profile
func _archetypes_for_band(band: int) -> Array:
	var ids := [
		[["cinderpaw"],["voltwig"],["aquafin"],["mossmunk"]],
		[["cinderpaw","aquafin"],["galehopper","sparkotter"],["aquafin","stoneback"],["cinderpaw","voltwig"]],
		[["glassdrake","runestag"],["aurorawing","thunderelk"],["coralisk","ironmaw"],["brambleowl","frostling"]],
		[["coalgriffin","pyraxis","miragefox"],["skyforge","voidmanta","miragefox"],["tidewhale","verdantitan","coalgriffin"],["coalgriffin","tidewhale","skyforge"]],
		[["worldcoil","starloom","voidmanta"],["starloom","voidmanta","worldcoil"],["worldcoil","starloom","voidmanta"],["worldcoil","starloom","voidmanta"]]
	]
	var deck_ids := ["balanced","pressure","guard","control"]
	var names := ["Balanced","Offense","Sustain","Elemental"]
	var suit: String = str(["","standard","reinforced","masterwork","legendary"][band - 1])
	var result: Array = []
	for index in 4:
		var team: Array = []
		for id in ids[band - 1][index]:
			var core := "" if band < 3 else RULES.core_for(str(Catalog.creature(id).get("element", "")))
			team.append({"creature_id":id,"suit_id":suit,"core_id":core})
		result.append({"index":index,"name":names[index],"team":team,"deck":deck_ids[index]})
	return result
func finish() -> void: get_tree().quit(0 if failures.is_empty() else 1)
