extends Node
## M11 authority pacing gate. This follows the launched unified Trial route and
## checked coordinator path; it is intentionally not a balance simulator.

const FOUNDER := preload("res://tests/m9_test_profile_factory.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
const COORDINATOR := preload("res://scripts/battle/unified_battle_cycle_coordinator.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")

const STARTERS := ["cinderpaw", "aquafin", "voltwig"]
const OPENERS := [0, 1]
const LAUNCHER_SEEDS := [11, 23, 37, 53, 71]
const MAX_INTENTS := 4096
const RIVAL_UI_BUDGET := 48

var failures: Array[String] = []
var records: Array = []
var original_profile: Dictionary = {}

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _multiset(values: Array) -> Array:
	var result: Array = []
	for value in values: result.append(str(value))
	result.sort()
	return result

func _snapshot_sha256(state: UnifiedBattleState) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(JSON.stringify(state.serialize()).to_utf8_buffer())
	return digest.finish().hex_encode()

func _founder_deck(starter: String) -> Dictionary:
	var profile: Dictionary = FOUNDER.founder_ready(starter)
	var deck: Array = []
	for entry in profile.get("decks", []):
		if entry is Dictionary and str((entry as Dictionary).get("id", "")) == str(profile.get("active_deck_id", "starter-deck")):
			deck = (entry as Dictionary).get("cards", []).duplicate()
	return {"profile":profile, "deck":deck}

func _launch(starter: String, opener: int, launcher_seed: int) -> Dictionary:
	var founder := _founder_deck(starter)
	var profile: Dictionary = founder.get("profile", {})
	var deck: Array = founder.get("deck", [])
	var deck_reason := RULES.deck_reason(profile, deck)
	if deck.size() != 40 or not deck_reason.is_empty(): return {"ok":false, "status":"founder_deck_invalid", "deck_reason":deck_reason}
	GameManager.profile = profile.duplicate(true)
	var requested := {"encounter_id":"first_layers_1", "result_id":"m11-pacing-%s-%d-%d" % [starter, opener, launcher_seed]}
	var resolved: Dictionary = GameManager._resolve_unified_opponent("trial", requested)
	if not bool(resolved.get("ok", false)): return {"ok":false, "status":"route_resolution_rejected", "error":str(resolved.get("error", ""))}
	var expected_rival: Array = GameManager._unified_rival_deck(resolved.get("setup", {}), deck)
	var launch: Dictionary = GameManager.create_unified_battle("trial", {"encounter_id":"first_layers_1", "result_id":"m11-pacing-%s-%d-%d" % [starter, opener, launcher_seed]}, launcher_seed)
	if not bool(launch.get("ok", false)): return {"ok":false, "status":"launch_rejected", "error":str(launch.get("error", ""))}
	var state: UnifiedBattleState = launch.get("battle", null)
	if state == null: return {"ok":false, "status":"launch_missing_state"}
	var player_cards: Array = state.player(0).hand.duplicate()
	player_cards.append_array(state.player(0).deck)
	if _multiset(player_cards) != _multiset(deck): return {"ok":false, "status":"player_deck_mismatch"}
	# Assert the launch against the exact resolved Trial deck/preprint source, not
	# merely that a rival happened to exist.
	var rival_cards: Array = state.player(1).hand.duplicate()
	rival_cards.append_array(state.player(1).deck)
	for unit in state.player(1).slots:
		if unit is Dictionary: rival_cards.append(str((unit as Dictionary).get("card_id", "")))
	if _multiset(rival_cards) != _multiset(expected_rival): return {"ok":false, "status":"rival_route_mismatch"}
	state.starting_seat = opener
	state.active_seat = opener
	var coordinator := COORDINATOR.new()
	coordinator.configure(state, 0)
	return {"ok":true, "coordinator":coordinator, "state":state, "authority_seed":int(state.seed)}

func _attack_observation(state: UnifiedBattleState, seat: int, intent: Dictionary) -> Dictionary:
	if str(intent.get("type", "")) != "attack": return {}
	var source_slot := int(intent.get("slot", -1))
	var attacker = state.player(seat).slots[source_slot] if source_slot >= 0 and source_slot < 3 else null
	var defender_seat := 1 - seat
	var printer: Dictionary = state.player(defender_seat).get("printer", {})
	return {"actor":seat, "source_slot":source_slot, "target_slot":int(intent.get("target", -2)), "neutral_printer_damage":BATTLE._damage(attacker.duplicate(true), {}) if attacker is Dictionary else 0, "printer_before_hp":int(printer.get("hp", 0)), "printer_before_max_hp":int(printer.get("max_hp", 0))}

func _trace_item(state: UnifiedBattleState, intent: Dictionary, receipt: Dictionary, attack_before: Dictionary = {}) -> Dictionary:
	var trace := {"revision":int(state.revision), "turn":int(state.turn), "active":int(state.active_seat), "phase":str(state.phase), "intent":intent.duplicate(true), "receipt_kind":str(receipt.get("kind", "")), "hp":[int(state.player(0).printer.hp), int(state.player(1).printer.hp)], "snapshot_sha256":_snapshot_sha256(state)}
	if not attack_before.is_empty():
		var target_printer: Dictionary = state.player(1 - int(attack_before.get("actor", 0))).get("printer", {})
		trace["attack"] = attack_before.duplicate(true)
		trace["attack"]["defeated"] = bool(receipt.get("defeated", false))
		trace["attack"]["printer_target"] = bool(receipt.get("printer_target", false))
		trace["attack"]["actual_damage"] = int(receipt.get("damage", 0))
		trace["attack"]["printer_after_hp"] = int(target_printer.get("hp", 0))
		trace["attack"]["printer_after_max_hp"] = int(target_printer.get("max_hp", 0))
	return trace

func _run_case(starter: String, opener: int, launcher_seed: int) -> Dictionary:
	var launched := _launch(starter, opener, launcher_seed)
	if not bool(launched.get("ok", false)):
		return {"starter":starter, "opener":opener, "launcher_seed":launcher_seed, "status":str(launched.get("status", "launch_failed")), "error":str(launched.get("error", launched.get("deck_reason", "")))}
	var coordinator: UnifiedBattleCycleCoordinator = launched.get("coordinator", null)
	var state: UnifiedBattleState = launched.get("state", null)
	var accepted := 0
	var attacks := 0
	var defender_hits := 0
	var printer_hits := 0
	var damage_defender := 0
	var damage_printer := 0
	var completed_rounds := 0
	var started_by_key := {}
	var seat_started := [0, 0]
	var seat_completed := [0, 0]
	var owned_actions := [0, 0]
	var max_owned_actions := [0, 0]
	var trace: Array = []
	var status := ""
	var overrun_at_31 := false
	while not state.finished and accepted < MAX_INTENTS:
		if int(state.turn) >= 31: overrun_at_31 = true
		var seat := int(state.active_seat)
		if seat == 1 and owned_actions[seat] >= RIVAL_UI_BUDGET:
			status = "ui_step_budget_exhausted"
			break
		var before_phase := str(state.phase)
		var before_turn := int(state.turn)
		var before_active := seat
		var intent: Dictionary = coordinator.next_ai_intent(seat)
		if intent.is_empty():
			status = "pending_stall" if not state.pending.is_empty() else "no_legal_intent"
			break
		var attack_before := _attack_observation(state, seat, intent)
		var submitted := coordinator.submit_checked(coordinator.envelope(seat, intent), coordinator.generation)
		if not bool(submitted.get("ok", false)):
			status = "rejected_intent"
			trace.append({"rejected":intent, "error":str(submitted.get("error", "")), "revision":int(state.revision)})
			break
		accepted += 1
		owned_actions[seat] += 1
		max_owned_actions[seat] = maxi(max_owned_actions[seat], owned_actions[seat])
		if before_phase == "draw" and str(intent.get("type", "")) == "advance_phase":
			var turn_key := "%d:%d" % [before_turn, seat]
			if not started_by_key.has(turn_key):
				started_by_key[turn_key] = true
				seat_started[seat] += 1
		var receipt: Dictionary = submitted.get("receipt", {}) if submitted.get("receipt", {}) is Dictionary else {}
		if str(receipt.get("kind", "")) == "attack":
			attacks += 1
			var damage := int(receipt.get("damage", 0))
			if bool(receipt.get("printer_target", false)):
				printer_hits += 1
				damage_printer += damage
			else:
				defender_hits += 1
				damage_defender += damage
		trace.append(_trace_item(state, intent, receipt, attack_before))
		if not receipt.is_empty():
			if not coordinator.acknowledge_presentation(coordinator.generation):
				status = "presentation_ack_failed"
				break
		if before_phase == "collect" and str(state.phase) == "draw" and int(state.active_seat) != before_active:
			seat_completed[before_active] += 1
			owned_actions[before_active] = 0
			if int(state.active_seat) == int(state.starting_seat): completed_rounds += 1
		if int(state.revision) != accepted:
			status = "revision_mismatch"
			break
	if status.is_empty():
		if state.finished:
			var hp0 := int(state.player(0).printer.hp)
			var hp1 := int(state.player(1).printer.hp)
			status = "printer_zero" if (hp0 <= 0) != (hp1 <= 0) and int(state.winner) == (1 if hp0 <= 0 else 0) else "invalid_terminal"
		elif accepted >= MAX_INTENTS:
			status = "stalemate_or_guard_exhausted"
	if overrun_at_31 and status == "printer_zero": status = "terminated_late"
	return {"starter":starter, "opener":opener, "launcher_seed":launcher_seed, "authority_seed":int(launched.get("authority_seed", 0)), "status":status, "pacing_overrun_at_31":overrun_at_31, "rounds_started":int(state.turn), "rounds_completed":completed_rounds, "seat_turns_started":seat_started, "seat_turns_completed":seat_completed, "accepted_intents":accepted, "max_intents_per_seat_turn":max_owned_actions, "attacks":attacks, "defender_hits":defender_hits, "printer_hits":printer_hits, "damage_defender":damage_defender, "damage_printer":damage_printer, "winner":int(state.winner), "final_hp":[int(state.player(0).printer.hp), int(state.player(1).printer.hp)], "terminal_revision":int(state.revision), "final_snapshot_sha256":_snapshot_sha256(state), "trace":trace}

func _quantile(values: Array, index: int) -> int:
	var ordered := values.duplicate()
	ordered.sort()
	return int(ordered[index]) if not ordered.is_empty() else 0

func _aggregate(cases: Array) -> Dictionary:
	var rounds: Array = []
	var completed: Array = []
	var intents: Array = []
	var attacks: Array = []
	var defender_hits: Array = []
	var printer_hits: Array = []
	var max_seat_actions: Array = []
	var damage_defender: Array = []
	var damage_printer: Array = []
	for entry in cases:
		rounds.append(int(entry.get("rounds_started", 0)))
		completed.append(int(entry.get("rounds_completed", 0)))
		intents.append(int(entry.get("accepted_intents", 0)))
		attacks.append(int(entry.get("attacks", 0)))
		defender_hits.append(int(entry.get("defender_hits", 0)))
		printer_hits.append(int(entry.get("printer_hits", 0)))
		damage_defender.append(int(entry.get("damage_defender", 0)))
		damage_printer.append(int(entry.get("damage_printer", 0)))
		var per_seat: Array = entry.get("max_intents_per_seat_turn", [])
		max_seat_actions.append(maxi(int(per_seat[0]) if per_seat.size() > 0 else 0, int(per_seat[1]) if per_seat.size() > 1 else 0))
	var summary := {}
	var metrics := {"rounds_started":rounds, "rounds_completed":completed, "accepted_intents":intents, "attacks":attacks, "defender_hits":defender_hits, "printer_hits":printer_hits, "damage_defender":damage_defender, "damage_printer":damage_printer, "max_intents_per_seat_turn":max_seat_actions}
	for metric in metrics:
		var values: Array = metrics[metric] if metrics[metric] is Array else []
		values.sort()
		summary[metric] = {"min":int(values.front()), "median":(int(values[14]) + int(values[15])) / 2.0, "p95":int(values[28]), "max":int(values.back())}
	return summary

func _no_fatigue_regression() -> bool:
	var state := STATE.create([], [], 11)
	state.starting_seat = 0
	state.active_seat = 0
	var hp_before := [int(state.player(0).printer.hp), int(state.player(1).printer.hp)]
	var first := BATTLE.apply_intent(state, 0, {"type":"advance_phase"})
	var main := BATTLE.apply_intent(state, 0, {"type":"advance_phase"})
	var print := BATTLE.apply_intent(state, 0, {"type":"advance_phase"})
	var attack := BATTLE.apply_intent(state, 0, {"type":"advance_phase"})
	var collect := BATTLE.apply_intent(state, 0, {"type":"advance_phase"})
	var second := BATTLE.apply_intent(state, 1, {"type":"advance_phase"})
	return bool(first.get("ok", false)) and bool(main.get("ok", false)) and bool(print.get("ok", false)) and bool(attack.get("ok", false)) and bool(collect.get("ok", false)) and bool(second.get("ok", false)) and hp_before == [int(state.player(0).printer.hp), int(state.player(1).printer.hp)] and not state.finished and int(state.winner) == -1

func _ready() -> void:
	original_profile = GameManager.profile.duplicate(true)
	for starter in STARTERS:
		for opener in OPENERS:
			for launcher_seed in LAUNCHER_SEEDS:
				records.append(_run_case(starter, opener, launcher_seed))
	var repeat: Array = []
	for starter in STARTERS:
		for opener in OPENERS:
			for launcher_seed in LAUNCHER_SEEDS:
				repeat.append(_run_case(starter, opener, launcher_seed))
	GameManager.profile = original_profile
	var deterministic := JSON.stringify(records) == JSON.stringify(repeat)
	var summary := _aggregate(records)
	var all_printer_zero := true
	for entry in records:
		all_printer_zero = all_printer_zero and str(entry.get("status", "")) == "printer_zero" and int(entry.get("rounds_started", 99)) <= 30
	var median_rounds := float((summary.get("rounds_started", {}) as Dictionary).get("median", 0.0))
	require(records.size() == 30, "Pacing matrix runs exactly three Founder starters, two openers, and five launcher seeds.")
	require(_no_fatigue_regression(), "Empty-deck Draws never damage a printer or synthesize a terminal result.")
	require(deterministic, "The repeated 30-case checked coordinator matrix has byte-equivalent authority traces.")
	require(all_printer_zero, "Every M11 pacing case reaches an actual printer-zero terminal by round 30.")
	require(median_rounds >= 12.0 and median_rounds <= 22.0, "M11 pacing median rounds remain within the approved 12-22 envelope.")
	var output := {"contract":"M11 unified pacing authority matrix", "cases":records, "summary":summary, "deterministic_repeat":deterministic, "no_fatigue":_no_fatigue_regression(), "pass":failures.is_empty()}
	var qa_root := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-save-root="): qa_root = argument.trim_prefix("--qa-save-root=")
	if not qa_root.is_empty():
		DirAccess.make_dir_recursive_absolute(qa_root)
		var report := FileAccess.open(qa_root.path_join("m11-pacing-results.json"), FileAccess.WRITE)
		if report != null: report.store_string(JSON.stringify(output, "\t")); report.close()
	if failures.is_empty(): print("PASS: M11 unified 30-case pacing matrix")
	get_tree().quit(0 if failures.is_empty() else 1)
