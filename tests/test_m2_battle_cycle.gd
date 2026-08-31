extends Node

const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")
const COORDINATOR := preload("res://scripts/battle/unified_battle_cycle_coordinator.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func fresh() -> UnifiedBattleCycleCoordinator:
	var deck: Array = []
	for _i in 40: deck.append("cinderpaw")
	var state = STATE.create(deck, deck, 8)
	state.starting_seat = 0; state.active_seat = 0; state.phase = "draw"; state.turn = 1
	var coordinator = COORDINATOR.new(); coordinator.configure(state, 0)
	return coordinator

func _ready() -> void:
	var coordinator := fresh()
	var state = coordinator.state
	var before := state.serialize()
	var stale := coordinator.submit_checked({"seat":0,"expected_revision":99,"intent":{"type":"advance_phase"}})
	require(not bool(stale.ok) and before == state.serialize(), "Stale envelope is rejected without authority mutation.")
	var wrong := coordinator.submit_checked({"seat":1,"expected_revision":0,"intent":{"type":"advance_phase"}})
	require(not bool(wrong.ok) and before == state.serialize(), "Wrong-seat envelope is rejected without authority mutation.")
	var draw := coordinator.enter_plan_if_needed(0)
	require(bool(draw.ok) and state.phase == "main" and state.revision == 1, "Plan auto-entry advances Draw exactly once.")
	coordinator.acknowledge_presentation(coordinator.generation)
	# A later lever pull must own a different callback generation.  The stale
	# continuation cannot submit or alter the authority that belongs to pull two.
	var cycle_generation := coordinator.start_run_cycle(0)
	var first_cycle_token := int(cycle_generation.get("generation", -1))
	require(bool(cycle_generation.ok) and first_cycle_token > 0, "The first Run Cycle owns a concrete callback generation.")
	coordinator.acknowledge_presentation(first_cycle_token)
	state.phase = "main"; coordinator.cycle_active = false
	var next_cycle := coordinator.start_run_cycle(0)
	var before_stale_cycle := state.serialize()
	require(bool(next_cycle.ok) and coordinator.generation != first_cycle_token and not bool(coordinator.advance_run_cycle(0, first_cycle_token).ok) and before_stale_cycle == state.serialize(), "A prior Run Cycle token is rejected byte-identically after a new lever pull.")
	coordinator.acknowledge_presentation(coordinator.generation)
	state.phase = "main"; coordinator.cycle_active = false
	state.player(0).hand = ["cinderpaw"]
	var play_revision: int = int(state.revision)
	var play := coordinator.submit_checked(coordinator.envelope(0, {"type":"play_card","card_id":"cinderpaw"}), coordinator.generation)
	require(bool(play.ok) and state.revision == play_revision + 1 and state.player(0).queue.size() == 1, "One accepted envelope increments revision once and queues print.")
	coordinator.acknowledge_presentation(coordinator.generation)
	var cycle := coordinator.start_run_cycle(0)
	require(bool(cycle.ok) and state.phase == "print", "Run Cycle starts by advancing Main to Print.")
	coordinator.acknowledge_presentation(coordinator.generation)
	var print := coordinator.advance_run_cycle(0, coordinator.generation)
	require(bool(print.ok) and str(state.pending.get("kind", "")) == "place", "Run Cycle pauses for a required placement.")
	var expired := coordinator.submit_required_decision(0, {"type":"place_completed","slot":0,"mode":"attack"}, coordinator.generation + 1)
	require(not bool(expired.ok) and str(state.pending.get("kind", "")) == "place", "Expired generation cannot submit a placement.")
	var public := state.public_snapshot(0)
	require(not public.players[1].has("hand") and not public.players[1].has("deck") and int(public.players[1].get("hand_count", -1)) >= 0, "Public snapshot redacts rival hand and deck identity.")
	var restored = STATE.from_snapshot(state.serialize())
	require(restored.serialize() == state.serialize(), "Full snapshot recovery is exact.")
	var token := coordinator.generation
	coordinator.invalidate_generation()
	require(token != coordinator.generation and not coordinator.cycle_active, "Generation invalidation cancels stale cycle work.")
	var finished_cycle := fresh(); finished_cycle.state.finished = true; var finished_before := finished_cycle.state.serialize()
	var finished_advance := finished_cycle.advance_run_cycle(0, finished_cycle.generation)
	require(bool(finished_advance.get("ok", false)) and bool(finished_advance.get("complete", false)) and finished_before == finished_cycle.state.serialize(), "An already-finished authority completes Run Cycle idempotently without a fabricated error or mutation.")
	var rejected_cycle := fresh(); rejected_cycle.enter_plan_if_needed(0); rejected_cycle.acknowledge_presentation(rejected_cycle.generation); rejected_cycle.cycle_active = true
	var rejected_before := rejected_cycle.state.serialize()
	var rejected_step := rejected_cycle.advance_run_cycle(1, rejected_cycle.generation)
	require(not bool(rejected_step.get("ok", false)) and not rejected_cycle.cycle_active and rejected_before == rejected_cycle.state.serialize() and bool(rejected_cycle.start_run_cycle(0).get("ok", false)), "A rejected standard cycle step stops automation byte-identically while a fresh checked Run Cycle can retry.")
	var unknown_cycle := fresh(); unknown_cycle.state.phase = "unknown"; unknown_cycle.cycle_active = true; var unknown_before := unknown_cycle.state.serialize()
	var unknown_step := unknown_cycle.advance_run_cycle(0, unknown_cycle.generation)
	require(not bool(unknown_step.get("ok", false)) and not unknown_cycle.cycle_active and unknown_before == unknown_cycle.state.serialize(), "Unknown standard phases stop the cycle without authority mutation.")
	var attack_coordinator := fresh()
	attack_coordinator.state.phase = "attack"; attack_coordinator.state.turn = 2
	attack_coordinator.state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); attack_coordinator.state.player(0).slots[0].statuses["attack_lock"] = 1
	attack_coordinator.state.player(0).slots[1] = STATE._unit(RULES.card("aquafin")); attack_coordinator.state.player(1).slots[0] = STATE._unit(RULES.card("cinderpaw"))
	var next := attack_coordinator._next_attack(0)
	require(int(next.get("slot", -1)) == 1, "Run Cycle skips attack-locked units instead of submitting rejected attacks.")
	attack_coordinator.state.player(0).slots[0].statuses.erase("attack_lock")
	attack_coordinator._attack_cursor = 0; attack_coordinator.set_transient_focus(0)
	next = attack_coordinator._next_attack(0)
	require(int(next.get("slot", -1)) == 0 and int(next.get("target", -1)) == 0, "Legal transient focus takes precedence over the lowest rival slot.")
	var order_coordinator := fresh(); order_coordinator.state.phase = "attack"; order_coordinator.state.turn = 2
	for slot in 3: order_coordinator.state.player(0).slots[slot] = STATE._unit(RULES.card("cinderpaw"))
	var order: Array[int] = []
	for _index in 3: order.append(int(order_coordinator._next_attack(0).get("slot", -1)))
	require(order == [0, 1, 2], "Run Cycle attacks eligible friendly slots in deterministic 0→1→2 order.")
	order_coordinator.state.player(1).slots = [null, null, null]; order_coordinator._attack_cursor = 0; order_coordinator.set_transient_focus(2)
	require(int(order_coordinator._next_attack(0).get("target", -2)) == -1, "An invalid focus falls back to the rival printer after all rival slots are empty.")
	var receipt_attack := fresh(); receipt_attack.state.phase = "attack"; receipt_attack.state.turn = 2
	receipt_attack.state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); receipt_attack.state.player(1).slots[0] = STATE._unit(RULES.card("aquafin")); receipt_attack.state.player(1).slots[0].armor_hp = 999
	var armor_attack := receipt_attack.submit_checked(receipt_attack.envelope(0, {"type":"attack","slot":0,"target":0}), receipt_attack.generation)
	require(bool(armor_attack.ok) and int((armor_attack.receipt as Dictionary).get("damage", -1)) == int((armor_attack.result as Dictionary).get("damage", -2)) and int((armor_attack.receipt as Dictionary).get("armor_before", -1)) == 999 and int((armor_attack.receipt as Dictionary).get("armor_after", 999)) < 999, "Attack receipt uses authoritative damage and public armor before/after even when armor absorbs all HP loss.")
	var defeat_attack := fresh(); defeat_attack.state.phase = "attack"; defeat_attack.state.turn = 2; defeat_attack.state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); defeat_attack.state.player(1).slots[0] = STATE._unit(RULES.card("aquafin")); defeat_attack.state.player(1).slots[0].hp = 1
	var defeat_result := defeat_attack.submit_checked(defeat_attack.envelope(0, {"type":"attack","slot":0,"target":0}), defeat_attack.generation)
	require(bool(defeat_result.ok) and bool((defeat_result.receipt as Dictionary).get("defeated", false)) and (defeat_attack.state.player(1).slots[0] == null), "Authoritative unit defeat receipt retains the public defender then records removal.")
	var printer_attack := fresh(); printer_attack.state.phase = "attack"; printer_attack.state.turn = 2; printer_attack.state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); printer_attack.state.player(1).slots = [null, null, null]
	var printer_result := printer_attack.submit_checked(printer_attack.envelope(0, {"type":"attack","slot":0,"target":-1}), printer_attack.generation)
	require(bool(printer_result.ok) and bool((printer_result.receipt as Dictionary).get("printer_target", false)) and int((printer_result.receipt as Dictionary).get("printer_hp_after", 2000)) < int((printer_result.receipt as Dictionary).get("printer_hp_before", 0)), "Printer-target receipt reports authoritative before/after printer HP.")
	require(not JSON.stringify(armor_attack.receipt).contains("hand") and not JSON.stringify(armor_attack.receipt).contains("deck") and not JSON.stringify(armor_attack.receipt).contains("trap"), "Public presentation receipts contain no private hand, deck, or trap identity.")
	var print_coordinator := fresh(); print_coordinator.state.phase = "print"; print_coordinator.state.turn = 2
	print_coordinator.state.player(0).queue = [{"card_id":"cinderpaw","remaining":1,"target":-1,"cost":70},{"card_id":"cinderpaw","remaining":1,"target":-1,"cost":70}]
	var duplicate_print := print_coordinator.submit_checked(print_coordinator.envelope(0, {"type":"advance_phase"}), print_coordinator.generation)
	var print_receipt: Dictionary = duplicate_print.get("receipt", {}) if duplicate_print.get("receipt", {}) is Dictionary else {}
	require(bool(duplicate_print.ok) and bool(print_receipt.get("completed", false)) and int(print_receipt.get("completed_count", 0)) == 1 and str(print_receipt.get("pending", "")) == "place", "Duplicate FIFO heads report a truthful completed print and placement pause.")
	require(print_coordinator.state.player(0).queue.size() == 1, "Creature placement pause truthfully bounds a Print cycle to one FIFO completion.")
	var partial_print := fresh(); partial_print.state.phase = "print"; partial_print.state.turn = 2; partial_print.state.player(0).queue = [{"card_id":"cinderpaw","remaining":3,"target":-1,"cost":70}]
	var partial_result := partial_print.submit_checked(partial_print.envelope(0, {"type":"advance_phase"}), partial_print.generation)
	require(bool(partial_result.ok) and not bool((partial_result.receipt as Dictionary).get("completed", true)) and int((partial_result.receipt as Dictionary).get("remaining_after", -1)) == 2, "Partial print receipts retain a truthful surviving queue-head remaining count.")
	require(int(print_receipt.get("serial", -1)) > int((armor_attack.receipt as Dictionary).get("serial", -1)) or int(print_receipt.get("serial", -1)) == 1, "Each coordinator emits a unique monotonically increasing receipt serial.")
	var overflow_coordinator := fresh()
	overflow_coordinator.state.phase = "collect"
	overflow_coordinator.state.player(0).hand = ["cinderpaw", "cinderpaw", "cinderpaw", "cinderpaw", "cinderpaw", "cinderpaw", "cinderpaw", "cinderpaw", "cinderpaw", "cinderpaw"]
	var overflow_revision := overflow_coordinator.state.revision
	var overflow_result := overflow_coordinator.submit_required_decision(0, {"type":"discard_overflow","card_ids":["cinderpaw","cinderpaw"]}, overflow_coordinator.generation)
	require(bool(overflow_result.ok) and overflow_coordinator.state.revision == overflow_revision + 1 and overflow_coordinator.state.player(0).hand.size() == 8, "Duplicate hand occurrences discard through Collect exactly once.")
	overflow_coordinator.acknowledge_presentation(overflow_coordinator.generation)
	var collect_result := overflow_coordinator.advance_run_cycle(0, overflow_coordinator.generation)
	require(bool(collect_result.ok) and overflow_coordinator.state.phase == "draw", "Exact overflow discard resumes the separate Collect advance.")
	var attach_coordinator := fresh(); attach_coordinator.state.phase = "print"; attach_coordinator.state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); attach_coordinator.state.player(0).holding = [{"card_id":"standard_full_suit","target":0}]; attach_coordinator.state.pending = {"kind":"attach","seat":0,"card_id":"standard_full_suit","holding_index":0}
	var attach_result := attach_coordinator.submit_required_decision(0, {"type":"attach_completed","slot":0}, attach_coordinator.generation)
	require(bool(attach_result.ok) and attach_coordinator.state.pending.is_empty() and attach_coordinator.state.player(0).holding.is_empty(), "Pending compatible equipment attachment submits once and resumes the print cycle.")
	var ai_coordinator := fresh(); ai_coordinator.state.active_seat = 1; ai_coordinator.state.phase = "draw"; var ai_before := ai_coordinator.state.revision
	var ai_intent := ai_coordinator.next_ai_intent(1)
	var ai_step := ai_coordinator.submit_checked(ai_coordinator.envelope(1, ai_intent), ai_coordinator.generation) if not ai_intent.is_empty() else {}
	require(not ai_intent.is_empty() and bool(ai_step.get("ok", false)) and ai_coordinator.state.revision == ai_before + 1, "AI exposes and resolves one bounded checked intent rather than replaying a whole turn.")
	# Repeated one-intent queries can progress a rival turn, but must do so inside a
	# finite safety bound rather than using the retired whole-turn replay helper.
	var loop_coordinator := fresh(); loop_coordinator.state.active_seat = 1; loop_coordinator.state.phase = "draw"
	var accepted_steps := 0
	for _step in 48:
		if loop_coordinator.state.finished or int(loop_coordinator.state.active_seat) != 1: break
		loop_coordinator.acknowledge_presentation(loop_coordinator.generation)
		var next_intent := loop_coordinator.next_ai_intent(1)
		if next_intent.is_empty(): break
		var next_step := loop_coordinator.submit_checked(loop_coordinator.envelope(1, next_intent), loop_coordinator.generation)
		if not bool(next_step.get("ok", false)): break
		accepted_steps += 1
	require(accepted_steps > 0 and accepted_steps <= 48 and (loop_coordinator.state.finished or int(loop_coordinator.state.active_seat) != 1), "Deterministic one-intent AI progression completes or hands off inside the fixed safety bound.")
	if failures.is_empty(): print("PASS: M2 checked battle cycle coordinator")
	get_tree().quit(0 if failures.is_empty() else 1)
