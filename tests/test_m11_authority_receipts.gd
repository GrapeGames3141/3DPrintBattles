extends Node

const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const BATTLE := preload("res://scripts/battle/unified_battle_rules.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")
const COORDINATOR := preload("res://scripts/battle/unified_battle_cycle_coordinator.gd")
const AI := preload("res://scripts/battle/unified_ai_opponent.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func fresh() -> UnifiedBattleCycleCoordinator:
	var deck: Array = []
	for _index in 40: deck.append("cinderpaw")
	var state := STATE.create(deck, deck, 311)
	state.starting_seat = 0; state.active_seat = 0; state.phase = "main"; state.turn = 2
	var coordinator := COORDINATOR.new()
	coordinator.configure(state, 0)
	return coordinator

func _legacy_snapshot() -> Dictionary:
	var legacy := fresh().state.serialize()
	legacy["schema"] = "v3.1"
	for seat in 2:
		legacy.players[seat].printer = {"hp":2000, "max_hp":2000}
	return legacy

func _event(events: Array, name: String, job_id: String) -> Dictionary:
	for item in events:
		if item is Dictionary and str((item as Dictionary).get("event", "")) == name and str((item as Dictionary).get("job_id", "")) == job_id: return item
	return {}

func _ready() -> void:
	var base := fresh().state
	require(int(base.player(0).printer.hp) == 200 and int(base.player(1).printer.max_hp) == 200, "M11 battles begin at 200 printer HP.")
	base.player(0).hand = ["reinforced_chassis"]
	var chassis := BATTLE.apply_intent(base, 0, {"type":"play_card", "card_id":"reinforced_chassis"})
	require(bool(chassis.ok) and int(base.player(0).printer.hp) == 250 and int(base.player(0).printer.max_hp) == 250, "Reinforced Chassis adds exactly 50 current and maximum HP.")

	var legacy := _legacy_snapshot()
	legacy.players[0].printer = {"hp":1, "max_hp":2000}
	legacy.players[1].installed_upgrades = ["reinforced_chassis", "reinforced_chassis", "reinforced_chassis"]
	legacy.players[1].printer = {"hp":2499, "max_hp":3500}
	legacy.players[0].queue = [{"card_id":"iron_gem", "remaining":2, "target":2, "cost":40}]
	legacy.players[0].holding = [{"card_id":"standard_full_suit", "target":1}]
	var adapted := STATE.recover_snapshot(legacy)
	var adapted_snapshot: Dictionary = adapted.get("snapshot", {})
	require(bool(adapted.ok) and str(adapted_snapshot.get("schema", "")) == "v3.2" and int(adapted_snapshot.players[0].printer.hp) == 1 and int(adapted_snapshot.players[0].printer.max_hp) == 200 and int(adapted_snapshot.players[1].printer.hp) == 250 and int(adapted_snapshot.players[1].printer.max_hp) == 350, "Legacy 2000-scale printer HP adapts once with ceiling arithmetic and stacked Chassis support.")
	require(int(adapted_snapshot.players[0].queue[0].target) == -1 and int(adapted_snapshot.players[0].holding[0].target) == -1 and not str(adapted_snapshot.players[0].queue[0].job_id).is_empty() and not str(adapted_snapshot.players[0].holding[0].job_id).is_empty(), "Legacy queued and held gear retire recipient authority while retaining stable print identity.")
	var repeated := STATE.recover_snapshot(adapted_snapshot)
	require(bool(repeated.ok) and int((repeated.snapshot as Dictionary).players[1].printer.max_hp) == 350, "An adapted snapshot is never divided twice.")
	var chassis_scales_ok := true
	for chassis_count in 6:
		for hp in [2000 + chassis_count * 500, 1999 + chassis_count * 500, 1, 0]:
			var chassis_legacy := _legacy_snapshot()
			for _index in chassis_count: chassis_legacy.players[0].installed_upgrades.append("reinforced_chassis")
			chassis_legacy.players[0].printer = {"hp":hp, "max_hp":2000 + chassis_count * 500}
			var chassis_adapted := STATE.recover_snapshot(chassis_legacy)
			var expected_max := 200 + chassis_count * 50
			var expected_hp := 0 if hp == 0 else clampi(ceili(float(hp) / 10.0), 1, expected_max)
			chassis_scales_ok = chassis_scales_ok and bool(chassis_adapted.ok) and int((chassis_adapted.snapshot as Dictionary).players[0].printer.max_hp) == expected_max and int((chassis_adapted.snapshot as Dictionary).players[0].printer.hp) == expected_hp
	require(chassis_scales_ok, "Legacy full, damaged, one-HP, and zero-HP printer values adapt across all zero-to-five Chassis counts.")
	var legacy_pending := _legacy_snapshot()
	legacy_pending.players[0].staging = [STATE._unit(RULES.card("aquafin"))]
	legacy_pending.pending = {"kind":"place", "seat":0, "unit":STATE._unit(RULES.card("aquafin")), "from_staging":true}
	var pending_adapted := STATE.recover_snapshot(legacy_pending)
	require(bool(pending_adapted.ok) and (pending_adapted.snapshot as Dictionary).pending.is_empty() and str((pending_adapted.snapshot as Dictionary).players[0].slots[0].card_id) == "aquafin" and ((pending_adapted.snapshot as Dictionary).players[0].staging as Array).is_empty(), "Legacy placement decisions auto-deploy once and retire their staging owner.")
	var recovery_coordinator := fresh()
	var recovery_before := recovery_coordinator.state.serialize()
	var malformed := recovery_before.duplicate(true); malformed.players = "broken"
	var rejected := recovery_coordinator.recover(malformed)
	require(not bool(rejected.ok) and recovery_coordinator.state.serialize() == recovery_before, "Malformed recovery rejects without replacing live authority state.")
	var malformed_nested_ok := true
	for corrupt in [{"hand":"bad"}, {"slots":[{},null,null]}, {"trap":{"card_id":"cinderpaw"}}, {"log":[2]}, {"printer":{"hp":199.5,"max_hp":200}}, {"print_job_serial":-1}]:
		var nested := recovery_before.duplicate(true)
		for key in corrupt: nested.players[0][key] = corrupt[key] if key not in ["log", "print_job_serial"] else nested.players[0].get(key, null)
		if corrupt.has("log"): nested.log = corrupt.log
		if corrupt.has("print_job_serial"): nested.print_job_serial = corrupt.print_job_serial
		malformed_nested_ok = malformed_nested_ok and not bool(recovery_coordinator.recover(nested).ok) and recovery_coordinator.state.serialize() == recovery_before
	require(malformed_nested_ok, "Malformed nested containers, fractional health, and unsafe job serials reject without corrupting the configured authority.")

	var creature := fresh()
	creature.state.player(0).hand = ["cinderpaw"]
	var guard_play := creature.submit_checked(creature.envelope(0, {"type":"play_card", "card_id":"cinderpaw", "mode":"guard"}), creature.generation)
	creature.acknowledge_presentation(creature.generation)
	creature.state.phase = "print"
	var guard_print := creature.submit_checked(creature.envelope(0, {"type":"advance_phase"}), creature.generation)
	require(bool(guard_play.ok) and bool(guard_print.ok) and str(creature.state.player(0).slots[0].mode) == "defense" and str((guard_print.receipt as Dictionary).get("print_events", [])[0].get("event", "")) == "complete" and str((guard_print.receipt as Dictionary).get("deployments", [])[0].get("event", "")) == "deployed", "Completed creatures auto-deploy leftmost with an optional queued Guard stance.")

	var carry := fresh()
	carry.state.phase = "print"; carry.state.player(0).installed_upgrades = ["speed_spool"]
	carry.state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw"))
	carry.state.player(0).queue = [{"card_id":"standard_full_suit", "remaining":1, "target":-1, "cost":40, "job_id":"gear-1"}, {"card_id":"cinderpaw", "remaining":3, "target":-1, "cost":70, "job_id":"creature-2"}]
	var gear_print := carry.submit_checked(carry.envelope(0, {"type":"advance_phase"}), carry.generation)
	carry.acknowledge_presentation(carry.generation)
	var gear_attach := carry.submit_required_decision(0, {"type":"attach_completed", "slot":0}, carry.generation)
	carry.acknowledge_presentation(carry.generation)
	require(bool(gear_print.ok) and str(carry.state.pending.get("kind", "")) == "" and bool(gear_attach.ok) and int(carry.state.player(0).queue[0].remaining) == 2 and carry.state.phase == "attack" and int(((gear_attach.receipt as Dictionary).get("print_events", [])[0] as Dictionary).get("remaining_after", -1)) == 2, "Fitting resumes exactly the saved one-work carryover and emits its authoritative partial work receipt.")
	var cancelled := fresh()
	cancelled.state.player(0).queue = [{"card_id":"cinderpaw", "remaining":2, "target":-1, "cost":70, "job_id":"cancel-job"}]
	var cancel_result := cancelled.submit_checked(cancelled.envelope(0, {"type":"cancel_queue", "queue_index":0}), cancelled.generation)
	require(bool(cancel_result.ok) and (cancel_result.receipt as Dictionary).is_empty(), "Queue cancellation is a refund action, never a print completion or awakening receipt.")

	var held := fresh()
	held.state.phase = "print"
	for slot in 3:
		held.state.player(0).slots[slot] = STATE._unit(RULES.card("cinderpaw"))
		held.state.player(0).slots[slot].equipment["gem"] = {"card_id":"iron_gem"}
	held.state.player(0).queue = [{"card_id":"iron_gem", "remaining":1, "target":-1, "cost":40, "job_id":"held-gem"}]
	var held_print := held.submit_checked(held.envelope(0, {"type":"advance_phase"}), held.generation)
	require(bool(held_print.ok) and held.state.pending.is_empty() and str(held.state.player(0).holding[0].job_id) == "held-gem", "Printable gear without a compatible creature stays held and does not block remaining authority work.")

	var multi := fresh()
	multi.state.phase = "print"; multi.state.player(0).installed_upgrades = ["turbo_spool"]
	multi.state.player(0).queue = [{"card_id":"cinderpaw", "remaining":1, "target":-1, "cost":70, "job_id":"job-a"}, {"card_id":"cinderpaw", "remaining":5, "target":-1, "cost":70, "job_id":"job-b"}]
	var multi_result := multi.submit_checked(multi.envelope(0, {"type":"advance_phase"}), multi.generation)
	var multi_events: Array = (multi_result.receipt as Dictionary).get("print_events", [])
	var multi_deployments: Array = (multi_result.receipt as Dictionary).get("deployments", [])
	require(bool(multi_result.ok) and not _event(multi_events, "complete", "job-a").is_empty() and not _event(multi_deployments, "deployed", "job-a").is_empty() and int(_event(multi_events, "partial", "job-b").get("remaining_after", -1)) == 3, "A single Print receipt names both a completed job and the later partial FIFO job by stable identity.")
	var duplicate_work := fresh()
	duplicate_work.state.phase = "print"; duplicate_work.state.player(0).installed_upgrades = ["turbo_spool"]
	duplicate_work.state.player(0).queue = [{"card_id":"cinderpaw", "remaining":1, "target":-1, "cost":70, "job_id":"same-a"}, {"card_id":"cinderpaw", "remaining":1, "target":-1, "cost":70, "job_id":"same-b"}]
	duplicate_work.state.player(1).trap = {"card_id":"print_interrupt"}
	var duplicate_result := duplicate_work.submit_checked(duplicate_work.envelope(0, {"type":"advance_phase"}), duplicate_work.generation)
	var duplicate_events: Array = (duplicate_result.receipt as Dictionary).get("print_events", [])
	require(bool(duplicate_result.ok) and str(_event(duplicate_events, "interrupted", "same-a").get("event", "")) == "interrupted" and str(_event(duplicate_events, "complete", "same-b").get("event", "")) == "complete", "Duplicate card IDs classify print interruption by stable job identity, not graveyard card counts.")
	var staged_contact := fresh()
	staged_contact.state.phase = "attack"; staged_contact.state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw"))
	staged_contact.state.player(1).slots[0] = STATE._unit(RULES.card("aquafin")); staged_contact.state.player(1).slots[0].hp = 1
	staged_contact.state.player(1).staging = [{"unit":STATE._unit(RULES.card("voltwig")), "job_id":"staged-voltwig"}]
	var staged_attack := staged_contact.submit_checked(staged_contact.envelope(0, {"type":"attack", "slot":0, "target":0}), staged_contact.generation)
	var staged_deployments: Array = (staged_attack.receipt as Dictionary).get("deployments", [])
	require(bool(staged_attack.ok) and bool((staged_attack.receipt as Dictionary).get("defeated", false)) and int((staged_attack.receipt as Dictionary).get("armor_after", -1)) == 0 and str(staged_contact.state.player(1).slots[0].job_id) == "staged-voltwig" and not staged_deployments.is_empty() and str(staged_deployments[0].job_id) == "staged-voltwig", "A field opening auto-deploys staged work without replacing the defeated defender in attack receipt identity.")
	var contact_chain := fresh()
	contact_chain.state.phase = "attack"; contact_chain.state.turn = 2
	contact_chain.state.player(0).slots[0] = STATE._unit(RULES.card("cinderpaw")); contact_chain.state.player(0).slots[1] = STATE._unit(RULES.card("cinderpaw"))
	contact_chain.state.player(1).slots[0] = STATE._unit(RULES.card("aquafin")); contact_chain.state.player(1).slots[0].hp = 3
	contact_chain.state.player(1).staging = [{"unit":STATE._unit(RULES.card("voltwig")), "job_id":"contact-voltwig"}]
	var chain_first := BATTLE.apply_intent(contact_chain.state, 0, {"type":"attack", "slot":0, "target":0})
	var replacement_hp := int(contact_chain.state.player(1).slots[0].hp)
	var chain_second := BATTLE.apply_intent(contact_chain.state, 0, {"type":"attack", "slot":1, "target":0})
	require(bool(chain_first.ok) and replacement_hp == int(RULES.card("voltwig").hp) and bool(chain_second.ok), "A kill defers staged deployment through its full attack/ability chain, then exposes the replacement only to the next attacker.")

	var forecast_coordinator := fresh()
	forecast_coordinator.state.player(0).queue = [{"card_id":"cinderpaw", "remaining":1, "target":-1, "cost":70, "job_id":"forecast-job"}]
	forecast_coordinator.state.player(1).trap = {"card_id":"print_interrupt"}
	var forecast := forecast_coordinator.public_next_cycle_forecast()
	var forecast_text := JSON.stringify(forecast)
	require(bool(forecast.available) and str((forecast.expected_completions as Array)[0].job_id) == "forecast-job" and bool(forecast.hidden_interrupt_possible) and not forecast_text.contains("print_interrupt") and not forecast_text.contains("hand") and not forecast_text.contains("deck"), "Forecast exposes public queue work and qualifies hidden interrupts without private identities.")
	forecast_coordinator.state.player(0).queue_paused = 1
	var paused_forecast := forecast_coordinator.public_next_cycle_forecast()
	forecast_coordinator.state.player(0).queue_paused = 0; forecast_coordinator.set_transient_focus(0); forecast_coordinator.state.player(1).slots[0] = STATE._unit(RULES.card("aquafin"))
	var focused_forecast := forecast_coordinator.public_next_cycle_forecast()
	forecast_coordinator.cycle_active = true
	var locked_forecast := forecast_coordinator.public_next_cycle_forecast()
	require((paused_forecast.expected_completions as Array).is_empty() and bool(paused_forecast.print_paused) and str(focused_forecast.target_priority) == "focus defender" and not bool(locked_forecast.available), "Forecast respects known print pause, focus priority, and active-cycle locks without mutating authority.")
	var forecast_order := fresh()
	forecast_order.state.player(0).installed_upgrades = ["turbo_spool"]
	forecast_order.state.player(0).slots = [null, null, STATE._unit(RULES.card("cinderpaw"))]
	forecast_order.state.player(0).queue = [{"card_id":"cinderpaw", "remaining":1, "mode":"defense", "job_id":"guard-job"}, {"card_id":"aquafin", "remaining":1, "mode":"attack", "job_id":"attack-job"}]
	var order_forecast := forecast_order.public_next_cycle_forecast()
	var order_attacks: Array = order_forecast.get("friendly_attack_order", [])
	require(order_attacks.size() == 2 and int(order_attacks[0].slot) == 1 and int(order_attacks[1].slot) == 2 and str(order_attacks[0].job_id) == "attack-job", "Forecast seats every known completed creature by queued stance and reports only sorted eligible Attack anchors.")

	var ai_state := fresh().state
	ai_state.active_seat = 1; ai_state.phase = "main"; ai_state.player(1).hand = ["standard_full_suit"]
	var ai_gear := AI.next_legal_intent(ai_state, 1)
	require(str(ai_gear.get("type", "")) == "play_card" and not ai_gear.has("target"), "AI queues printable gear without selecting a pre-print recipient.")
	var ring_state := fresh().state
	ring_state.player(0).hand = ["filament_ring"]
	var ring := BATTLE.apply_intent(ring_state, 0, {"type":"play_card", "card_id":"filament_ring"})
	require(bool(ring.ok) and ring_state.player(0).queue.is_empty() and bool(ring_state.player(0).filament_ring_active), "Filament Ring remains an immediate battle effect.")
	if failures.is_empty(): print("PASS: M11 authority migration, queue, receipt, and forecast coverage")
	get_tree().quit(0 if failures.is_empty() else 1)
