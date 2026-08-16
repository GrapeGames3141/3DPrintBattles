extends Node
## Export-boundary regression: battle static scripts must run from immutable
## preloaded catalog constants without requiring either application autoload.

const BATTLE_CATALOG := preload("res://scripts/battle/battle_catalog.gd")
const BATTLE_STATE := preload("res://scripts/battle/battle_state.gd")
const BATTLE_RULES := preload("res://scripts/battle/battle_rules.gd")
const AI := preload("res://scripts/battle/ai_opponent.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	for path in ["res://scripts/battle/battle_state.gd", "res://scripts/battle/battle_unit_runtime.gd", "res://scripts/battle/battle_rules.gd", "res://scripts/battle/ai_opponent.gd"]:
		var source := FileAccess.get_file_as_string(path)
		require(not source.contains("Catalog.") and not source.contains("ProgressionRules."), "%s has no Catalog or ProgressionRules global boundary" % path.get_file())
	var player_entries: Array = [{"creature_id":"cinderpaw"}, {"species_id":"brambleowl", "armor_id":"helm"}, {"id":"verdantitan"}]
	var rival_entries: Array = [{"species":"mossmunk"}]
	var state: BattleState = BATTLE_STATE.create(player_entries, rival_entries, 4, 3, 42, BATTLE_STATE.STARTER_LOADOUT)
	require(state.validation_error(true).is_empty(), "static accessor builds valid player and rival teams")
	var player_ids: Array[String] = []
	for unit in state.players[0].get("team", []): player_ids.append(str(unit.get("id", "")))
	require(player_ids == ["cinderpaw", "brambleowl", "verdantitan"] and str(state.players[0].team[1].get("armor_id", "")) == "helm", "three-unit canonical order and equipped armor survive static construction")
	require(int(state.players[0].team[1].get("max_hp", 0)) == int(BATTLE_CATALOG.creature("brambleowl").get("hp", 0)) + int(BATTLE_CATALOG.armor("helm").get("hp", 0)), "static armor lookup applies catalog maximum HP")
	var card_result: Dictionary = BATTLE_RULES.apply_intent(state, 0, {"type":"card", "card_id":"raw_filament"})
	require(bool(card_result.get("ok", false)) and int(state.players[0].get("filament", 0)) == 4, "static support-card lookup resolves an in-hand card")
	var defend_result: Dictionary = BATTLE_RULES.apply_intent(state, 0, {"type":"defend"})
	require(bool(defend_result.get("ok", false)) and state.active_player == 1, "opening player can yield through static rules")
	var ai_intent: Dictionary = AI.choose_intent(state, "Craftsman")
	var ai_result: Dictionary = BATTLE_RULES.apply_intent(state, 1, ai_intent)
	require(bool(ai_result.get("ok", false)), "static AI chooses and applies a legal rival intent")
	var signature_result: Dictionary = BATTLE_RULES.apply_intent(state, 0, {"type":"ability"})
	require(bool(signature_result.get("ok", false)) and not signature_result.get("signature", {}).is_empty(), "static signature lookup resolves Cinderpaw's authored ability")
	var first_match := run_match()
	var second_match := run_match()
	require(bool(first_match.get("finished", false)) and int(first_match.get("turns", 0)) <= 120, "static catalog deterministic match reaches a bounded result")
	require(first_match == second_match, "static battle/AI match is deterministic for the same seed")
	if failures.is_empty(): print("PASS: static battle catalog builds, normalizes, rules, cards, signatures, AI, and deterministic completion without app autoloads")
	call_deferred("finish")

func run_match() -> Dictionary:
	var state: BattleState = BATTLE_STATE.create(["cinderpaw", "brambleowl", "verdantitan"], ["mossmunk"], 4, 3, 42, BATTLE_STATE.STARTER_LOADOUT)
	var used_signature := false
	var guard := 0
	while not state.finished and guard < 120:
		guard += 1
		var intent: Dictionary = {"type":"end_turn"}
		if state.active_player == 1:
			intent = AI.choose_intent(state, "Master")
		elif state.turn == 1 and state.opening_player == 0:
			intent = {"type":"defend"}
		elif not used_signature and int(state.active_unit(0).get("filament", 0)) >= int(state.active_unit(0).get("ability_cost", 99)):
			intent = {"type":"ability"}
			used_signature = true
		else:
			intent = {"type":"attack"}
		var result: Dictionary = BATTLE_RULES.apply_intent(state, state.active_player, intent)
		if not bool(result.get("ok", false)):
			BATTLE_RULES.apply_intent(state, state.active_player, {"type":"defend"})
	return {"finished":state.finished, "winner":state.winner, "turns":state.turn, "signature":used_signature, "log":state.log.duplicate()}

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
