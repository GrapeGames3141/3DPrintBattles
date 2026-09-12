extends Node

## Rules-only deterministic coverage.  Bot and Coordinator are intentionally not
## loaded here: Plans must be checked against the same State authority directly.

const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const State := preload("res://scripts/team_battle/team_battle_state.gd")
const Rules := preload("res://scripts/team_battle/team_battle_rules.gd")

var failures: Array[String] = []
var require_count := 0
var completed_groups := 0
const REQUIRED_GROUPS := 7


func require(value: bool, message: String) -> void:
	require_count += 1
	if value:
		return
	failures.append(message)
	push_error(message)


func _ready() -> void:
	_test_checked_plans_and_atomicity()
	_test_supports_fifo_and_conservation()
	_test_combat_traits_and_terminal_draw()
	_test_swap_replacement_and_empty_field()
	_test_receipts_and_privacy()
	_test_test_only_one_vs_one()
	_test_edge_case_regressions()
	require(completed_groups == REQUIRED_GROUPS, "all core test groups must reach their end marker")
	var suite_complete := completed_groups == REQUIRED_GROUPS
	print("TEAM_BATTLE_CORE groups=%d/%d requires=%d failures=%d" % [completed_groups, REQUIRED_GROUPS, require_count, failures.size()])
	if suite_complete:
		print("TEAM_BATTLE_CORE failures=%d" % failures.size())
	else:
		print("TEAM_BATTLE_CORE incomplete groups=%d/%d" % [completed_groups, REQUIRED_GROUPS])
	get_tree().quit(0 if suite_complete and failures.is_empty() else 1)


func _complete_group() -> void:
	completed_groups += 1


func _production(tutorial: bool = true) -> Dictionary:
	return State.create_production(
		["cinderpaw", "aquafin", "mossmunk"],
		["cinderpaw", "aquafin", "mossmunk"],
		Data.recommended_kit(),
		Data.recommended_kit(),
		17,
		tutorial
	)


func _plan(state: Dictionary, fabrication_id: String = "", support_copy_id: String = "", equipment_target_id: String = "", swap_id: String = "") -> Dictionary:
	return {
		"expected_revision": int(state.revision),
		"fabrication_id": fabrication_id,
		"support_copy_id": support_copy_id,
		"equipment_target_id": equipment_target_id,
		"swap_id": swap_id,
	}


func _member(seat: Dictionary, member_id: String) -> Dictionary:
	for member_value in seat.members:
		var member: Dictionary = member_value
		if member.member_id == member_id:
			return member
	return {}


func _copy_in_hand(seat: Dictionary, card_id: String) -> String:
	for copy_value in seat.hand:
		var copy: Dictionary = copy_value
		if copy.card_id == card_id:
			return copy.copy_id
	if seat.hand.size() >= Data.HAND_SIZE:
		seat.draw_pile.append(seat.hand.pop_back())
	for pile_name in ["draw_pile", "discard"]:
		var pile: Array = seat[pile_name]
		for index in pile.size():
			var copy: Dictionary = pile[index]
			if copy.card_id == card_id:
				seat.hand.append(pile.pop_at(index))
				return copy.copy_id
	return ""


func _take_copy(seat: Dictionary, card_id: String) -> Dictionary:
	for pile_name in ["hand", "draw_pile", "discard"]:
		var pile: Array = seat[pile_name]
		for index in pile.size():
			var copy: Dictionary = pile[index]
			if copy.card_id == card_id:
				return pile.pop_at(index)
	return {}


func _equipment_job(seat_id: String, created_cycle: int, card_copy: Dictionary, target_identity_id: String) -> Dictionary:
	return {
		"job_id": "%s:job:%d:equipment" % [seat_id, created_cycle],
		"kind": "equipment",
		"created_cycle": created_cycle,
		"work_total": 1,
		"work_remaining": 1,
		"target_identity_id": target_identity_id,
		"card_copy": card_copy,
	}


func _move_all_cards_to_discard(seat: Dictionary) -> void:
	for pile_name in ["hand", "draw_pile"]:
		var pile: Array = seat[pile_name]
		while not pile.is_empty():
			seat.discard.append(pile.pop_front())


func _make_active(state: Dictionary, seat_id: String, active_id: String = "cinderpaw", ready_id: String = "") -> void:
	var seat: Dictionary = state.seats[seat_id]
	var active := _member(seat, active_id)
	active.status = State.STATUS_ACTIVE
	seat.active_member_id = active.identity_id
	seat.ready_member_ids = []
	if not ready_id.is_empty():
		var ready := _member(seat, ready_id)
		ready.status = State.STATUS_READY
		seat.ready_member_ids = [ready.identity_id]


func _state_is_valid(state: Dictionary, message: String) -> bool:
	var restored := State.restore(state)
	require(bool(restored.ok), message)
	return bool(restored.ok)


func _stage(receipt: Dictionary, stage_name: String) -> Dictionary:
	for stage_value in receipt.stages:
		var stage: Dictionary = stage_value
		if stage.name == stage_name:
			return stage
	return {}


func _contains_copy_id(seat: Dictionary, copy_id: String) -> bool:
	for pile_name in ["draw_pile", "hand", "discard"]:
		for copy_value in seat[pile_name]:
			if str(copy_value.copy_id) == copy_id:
				return true
	for job_value in seat.fifo:
		var job: Dictionary = job_value
		if job.kind == "equipment" and str(job.card_copy.copy_id) == copy_id:
			return true
	return false


func _test_checked_plans_and_atomicity() -> void:
	var created := _production()
	if not bool(created.ok):
		require(false, "production Rules fixture creates")
		return
	var state: Dictionary = created.state
	var player_cinder := _member(state.seats.player, "cinderpaw")
	var rival_cinder := _member(state.seats.rival, "cinderpaw")
	var raw_copy_id := _copy_in_hand(state.seats.player, "raw_filament")
	var legal := _plan(state, player_cinder.identity_id, raw_copy_id)
	var checked := Rules.validate_plan(state, "player", legal)
	require(bool(checked.ok), "valid production fabrication plus Raw Plan checks")
	if bool(checked.ok):
		require(str(checked.plan.fabrication_id) == player_cinder.identity_id and int(checked.forecast.aid_gain) == 2, "checked public Plan retains canonical fabrication and aid arithmetic")
		require(not checked.forecast.one_work_completion.is_empty() and str(checked.forecast.one_work_completion.member_identity_id) == player_cinder.identity_id and str(checked.forecast.one_work_completion.destination_state) == "Active", "empty FIFO forecast identifies the queued companion and its Active destination")
		var round_trip := Rules.run_cycle(state, checked.plan, _plan(state, rival_cinder.identity_id))
		require(bool(round_trip.ok), "returned public Plan round-trips through Run without internal metadata")
		if bool(round_trip.ok):
			var result_stage := _stage(round_trip.receipt, "Result")
			var plan_stage := _stage(round_trip.receipt, "Plan")
			require(int(result_stage.snapshot.seats.player.filament) == 4 and int(result_stage.snapshot.cycle) == 1, "Raw plus fabrication Result records post-spend filament four in Cycle 1")
			require(int(plan_stage.snapshot.seats.player.filament) == 6 and int(plan_stage.snapshot.cycle) == 2, "Plan snapshot applies regeneration after the Result snapshot")

	var before := JSON.stringify(state)
	var stale := _plan(state, player_cinder.identity_id)
	stale.expected_revision = 99
	var failed := Rules.run_cycle(state, stale, _plan(state, rival_cinder.identity_id))
	require(not bool(failed.ok) and JSON.stringify(state) == before, "stale half of a composite Plan rejects atomically")
	var unknown := legal.duplicate(true)
	unknown["printerHP"] = 1
	require(not bool(Rules.validate_plan(state, "player", unknown).ok), "unknown Plan keys reject")
	var support_and_swap := legal.duplicate(true)
	support_and_swap.swap_id = "player:member:aquafin"
	require(not bool(Rules.validate_plan(state, "player", support_and_swap).ok), "Support plus swap rejects")
	var target_without_equipment := _plan(state)
	target_without_equipment.equipment_target_id = player_cinder.identity_id
	require(not bool(Rules.validate_plan(state, "player", target_without_equipment).ok), "equipment target without equipment rejects")
	_complete_group()


func _test_supports_fifo_and_conservation() -> void:
	var created := _production()
	if not bool(created.ok):
		require(false, "Support fixture creates")
		return
	var state: Dictionary = created.state
	_make_active(state, "player")
	_make_active(state, "rival")
	if not _state_is_valid(state, "manually activated support fixture remains a valid State"):
		return

	for aid_card in ["raw_filament", "heated_spool"]:
		var aid_state: Dictionary = State.deep_clone(state)
		var aid_copy_id := _copy_in_hand(aid_state.seats.player, aid_card)
		var aid_result := Rules.run_cycle(aid_state, _plan(aid_state, "", aid_copy_id), _plan(aid_state))
		require(bool(aid_result.ok), "%s resolves as a finite immediate Support" % aid_card)
		if bool(aid_result.ok):
			require(_contains_copy_id(aid_result.state.seats.player, aid_copy_id), "%s copy remains conserved after discard" % aid_card)
			var aid_result_stage := _stage(aid_result.receipt, "Result")
			var aid_plan_stage := _stage(aid_result.receipt, "Plan")
			var expected_post_aid := 7 if aid_card == "raw_filament" else 8
			require(int(aid_result_stage.snapshot.seats.player.filament) == expected_post_aid and int(aid_plan_stage.snapshot.seats.player.filament) == Data.FILAMENT_CAP, "%s Result preserves exact aid math before Plan regeneration" % aid_card)

	var suit_state: Dictionary = State.deep_clone(state)
	var suit_copy_id := _copy_in_hand(suit_state.seats.player, "standard_full_suit")
	var cinder := _member(suit_state.seats.player, "cinderpaw")
	var suit_result := Rules.run_cycle(suit_state, _plan(suit_state, "", suit_copy_id, cinder.identity_id), _plan(suit_state))
	require(bool(suit_result.ok), "Standard Full Suit resolves through the FIFO")
	if bool(suit_result.ok):
		var fit_stage := _stage(suit_result.receipt, "Enter/Fit")
		var suited := _member(suit_result.state.seats.player, "cinderpaw")
		require(int(_member(fit_stage.snapshot.seats.player, "cinderpaw").armor) == Data.FULL_SUIT_ARMOR and bool(suited.armor_slot), "Suit fits to exactly eight before same-cycle combat")
		require(int(suited.armor) == 1, "automatic rival Cinderpaw hit consumes seven fitted Suit armor")
		suited.armor = 3
		var repeated_state: Dictionary = suit_result.state
		var second_suit_copy_id := _copy_in_hand(repeated_state.seats.player, "standard_full_suit")
		var repeated_result := Rules.run_cycle(repeated_state, _plan(repeated_state, "", second_suit_copy_id, suited.identity_id), _plan(repeated_state))
		require(bool(repeated_result.ok), "repeated Standard Full Suit Run resolves")
		if bool(repeated_result.ok):
			var repeat_fit_stage := _stage(repeated_result.receipt, "Enter/Fit")
			require(int(_member(repeat_fit_stage.snapshot.seats.player, "cinderpaw").armor) == Data.FULL_SUIT_ARMOR and int(_member(repeated_result.state.seats.player, "cinderpaw").armor) == 1, "repeated Suit refreshes to eight before automatic combat rather than stacking")

	var gem_state: Dictionary = State.deep_clone(state)
	var gem_copy_id := _copy_in_hand(gem_state.seats.player, "iron_gem")
	var gem_target := _member(gem_state.seats.player, "cinderpaw")
	var gem_result := Rules.run_cycle(gem_state, _plan(gem_state, "", gem_copy_id, gem_target.identity_id), _plan(gem_state))
	require(bool(gem_result.ok), "Iron Gem Run resolves")
	if bool(gem_result.ok):
		require(bool(_member(gem_result.state.seats.player, "cinderpaw").gem_slot), "Iron Gem fits one persistent +2 attack slot")
		var second_gem_copy_id := _copy_in_hand(gem_result.state.seats.player, "iron_gem")
		var repeat_gem_result := Rules.run_cycle(gem_result.state, _plan(gem_result.state, "", second_gem_copy_id, gem_target.identity_id), _plan(gem_result.state))
		require(bool(repeat_gem_result.ok), "repeated Iron Gem Run resolves")
		if bool(repeat_gem_result.ok):
			var repeat_lock := _stage(repeat_gem_result.receipt, "AttackLock")
			var player_damage := 0
			for event_value in repeat_lock.events:
				var event: Dictionary = event_value
				if event.type == "attack_locked" and event.seat == "player":
					player_damage = int(event.damage)
			require(bool(_member(repeat_gem_result.state.seats.player, "cinderpaw").gem_slot) and player_damage == 9, "repeated Gem stays one +2 slot instead of stacking")

	var queue_state: Dictionary = _production().state
	var queued_cinder := _member(queue_state.seats.player, "cinderpaw")
	var queued_suit_copy_id := _copy_in_hand(queue_state.seats.player, "standard_full_suit")
	var queued_result := Rules.run_cycle(queue_state, _plan(queue_state, queued_cinder.identity_id, queued_suit_copy_id, queued_cinder.identity_id), _plan(queue_state, _member(queue_state.seats.rival, "cinderpaw").identity_id))
	require(bool(queued_result.ok), "companion plus equipment creates a legal two-job FIFO Plan")
	if bool(queued_result.ok):
		var queued_state: Dictionary = queued_result.state
		var printed := _member(queued_state.seats.player, "cinderpaw")
		printed.status = State.STATUS_DEFEATED
		printed.hp = 0
		queued_state.seats.player.active_member_id = ""
		var fizzle_result := Rules.run_cycle(queued_state, _plan(queued_state), _plan(queued_state))
		require(bool(fizzle_result.ok), "defeated target may resolve its FIFO equipment fizzle")
		if bool(fizzle_result.ok):
			require(fizzle_result.state.seats.player.fifo.is_empty(), "fizzled equipment leaves FIFO")
	_complete_group()


func _test_combat_traits_and_terminal_draw() -> void:
	var created := _production()
	if not bool(created.ok):
		require(false, "combat fixture creates")
		return
	var state: Dictionary = created.state
	_make_active(state, "player")
	_make_active(state, "rival")
	var player_cinder := _member(state.seats.player, "cinderpaw")
	var rival_cinder := _member(state.seats.rival, "cinderpaw")
	player_cinder.hp = 7
	player_cinder.landed_attacks = 2
	player_cinder.gem_slot = true
	var surge_copy_id := _copy_in_hand(state.seats.player, "forge_surge")
	var surge_result := Rules.run_cycle(state, _plan(state, "", surge_copy_id), _plan(state))
	require(bool(surge_result.ok), "Forge Surge combat fixture resolves")
	if bool(surge_result.ok):
		var attack_stage := _stage(surge_result.receipt, "AttackLock")
		var cinder_damage := -1
		for event_value in attack_stage.events:
			var event: Dictionary = event_value
			if event.type == "attack_locked" and event.seat == "player":
				cinder_damage = int(event.damage)
		require(cinder_damage == 15, "third Cinderpaw Gem plus Surge lock is exactly fifteen before lethal return damage")
		require(_member(surge_result.state.seats.rival, "cinderpaw").hp == 19, "same-beat locked Cinderpaw hit applies despite source defeat")

	var draw_state: Dictionary = _production().state
	for seat_id in ["player", "rival"]:
		var seat: Dictionary = draw_state.seats[seat_id]
		_make_active(draw_state, seat_id)
		_member(seat, "cinderpaw").hp = 7
		for defeated_id in ["aquafin", "mossmunk"]:
			var defeated := _member(seat, defeated_id)
			defeated.status = State.STATUS_DEFEATED
			defeated.hp = 0
	require(_state_is_valid(draw_state, "third-member simultaneous Draw fixture restores"), "Draw fixture validates before Rules")
	var draw_result := Rules.run_cycle(draw_state, _plan(draw_state), _plan(draw_state))
	require(bool(draw_result.ok) and draw_result.state.result == "Draw", "simultaneous final third-member KO settles Draw once")
	if bool(draw_result.ok):
		require(int(draw_result.state.cycle) == int(draw_result.state.revision) and draw_result.state.terminal_receipt.result == "Draw", "Draw terminal state has matching receipt and revision")
		require(not bool(Rules.validate_plan(draw_result.state, "player", _plan(draw_result.state)).ok), "terminal State rejects further Plan validation")
		var terminal_view := Rules.view_for_seat(draw_result.state, "player")
		if bool(terminal_view.ok):
			require(not bool(Rules.check_view_plan(terminal_view.view, _plan(draw_result.state)).ok), "terminal public view rejects further Plan preview")
		require(not bool(Rules.run_cycle(draw_result.state, _plan(draw_result.state), _plan(draw_result.state)).ok), "terminal State rejects another Run")
	_complete_group()


func _test_swap_replacement_and_empty_field() -> void:
	var created := _production()
	if not bool(created.ok):
		require(false, "swap fixture creates")
		return
	var swap_state: Dictionary = State.deep_clone(created.state)
	_make_active(swap_state, "player", "cinderpaw", "aquafin")
	_make_active(swap_state, "rival")
	var aqua := _member(swap_state.seats.player, "aquafin")
	var cinder := _member(swap_state.seats.player, "cinderpaw")
	cinder.hp = 30
	cinder.armor = 5
	cinder.armor_slot = true
	cinder.gem_slot = true
	var swap_result := Rules.run_cycle(swap_state, _plan(swap_state, "", "", "", aqua.identity_id), _plan(swap_state))
	require(bool(swap_result.ok), "same identity Ready-to-Active swap resolves")
	if bool(swap_result.ok):
		var player: Dictionary = swap_result.state.seats.player
		require(player.active_member_id == aqua.identity_id and _member(player, "cinderpaw").status == State.STATUS_READY, "swap preserves identities and moves prior Active to reserve")
		var swap_back_result := Rules.run_cycle(swap_result.state, _plan(swap_result.state, "", "", "", cinder.identity_id), _plan(swap_result.state))
		if bool(swap_back_result.ok):
			var swap_back_stage := _stage(swap_back_result.receipt, "Swap")
			var returned_cinder := _member(swap_back_stage.snapshot.seats.player, "cinderpaw")
			require(returned_cinder.identity_id == cinder.identity_id and int(returned_cinder.hp) == 30 and int(returned_cinder.armor) == 5 and bool(returned_cinder.gem_slot), "repeat swap back preserves Cinderpaw identity, HP, armor, and Gem before combat")

	var replace_state: Dictionary = State.deep_clone(created.state)
	_make_active(replace_state, "player", "cinderpaw", "aquafin")
	_make_active(replace_state, "rival")
	_member(replace_state.seats.player, "cinderpaw").hp = 7
	var replace_result := Rules.run_cycle(replace_state, _plan(replace_state), _plan(replace_state))
	require(bool(replace_result.ok), "defeated Active replacement fixture resolves")
	if bool(replace_result.ok):
		require(replace_result.state.seats.player.active_member_id == _member(replace_result.state.seats.player, "aquafin").identity_id, "highest priority Ready reserve auto-replaces defeated Active")

	var replenish_state: Dictionary = _production().state
	replenish_state.seats.player.filament = 2
	var no_choice := Rules.validate_plan(replenish_state, "player", _plan(replenish_state))
	require(bool(no_choice.ok) and str(no_choice.plan.fabrication_id).is_empty() and str(no_choice.forecast.default_fabrication_reason) == "default_need_filament", "empty Active unaffordable default permits only a no-choice Run")
	var explicit_blocked := Rules.validate_plan(replenish_state, "player", _plan(replenish_state, _member(replenish_state.seats.player, "cinderpaw").identity_id))
	require(not bool(explicit_blocked.ok), "explicit unaffordable fabrication rejects atomically")
	_complete_group()


func _test_receipts_and_privacy() -> void:
	var created := _production()
	if not bool(created.ok):
		require(false, "receipt fixture creates")
		return
	var state: Dictionary = created.state
	var player_cinder := _member(state.seats.player, "cinderpaw")
	var rival_cinder := _member(state.seats.rival, "cinderpaw")
	var result := Rules.run_cycle(state, _plan(state, player_cinder.identity_id), _plan(state, rival_cinder.identity_id))
	require(bool(result.ok), "receipt fixture resolves a first fabrication")
	if bool(result.ok):
		var print_stage := _stage(result.receipt, "Print")
		var awaken_stage := _stage(result.receipt, "Awaken")
		var enter_stage := _stage(result.receipt, "Enter/Fit")
		require(not print_stage.is_empty() and _member(print_stage.snapshot.seats.player, "cinderpaw").status == State.STATUS_PRINTING, "Print snapshot keeps the head as Printing before work")
		require(not awaken_stage.is_empty() and int(awaken_stage.snapshot.seats.player.fifo[0].work_remaining) == 0 and _member(awaken_stage.snapshot.seats.player, "cinderpaw").status == State.STATUS_PRINTING, "Awaken snapshot keeps completed head and does not expose premature Active")
		require(not enter_stage.is_empty() and _member(enter_stage.snapshot.seats.player, "cinderpaw").status == State.STATUS_ACTIVE, "Enter snapshot moves the same identity to Active")
		var rival_view_result := Rules.view_for_seat(result.state, "rival")
		require(bool(rival_view_result.ok), "rival public view projects")
		if bool(rival_view_result.ok):
			var rival_view: Dictionary = rival_view_result.view
			var serialized_view := JSON.stringify(rival_view)
			require(not serialized_view.contains("player:card:") and not serialized_view.contains("\"seed\""), "opponent view omits player card copy IDs and seed")
			var projected := Rules.project_receipt(result.receipt, "rival")
			require(bool(projected.ok) and not JSON.stringify(projected.receipt).contains("player:card:"), "receipt projection redacts nested private card copies")
			var opponent_private_field := rival_view.duplicate(true)
			opponent_private_field.opponent["hand"] = []
			require(not bool(Rules.check_view_plan(opponent_private_field, _plan(result.state)).ok), "opponent public view rejects leaked private hand fields")
			var sentinel_event_receipt: Dictionary = result.receipt.duplicate(true)
			var sentinel_queue_stage := _stage(sentinel_event_receipt, "Queue")
			sentinel_queue_stage.events[0]["privatefield"] = "sentinel"
			require(not bool(Rules.project_receipt(sentinel_event_receipt, "rival").ok), "receipt projection rejects unknown event fields rather than copying them")
			var sentinel_head_receipt: Dictionary = result.receipt.duplicate(true)
			var sentinel_print_stage := _stage(sentinel_head_receipt, "Print")
			sentinel_print_stage.events[0].head_before["privatefield"] = "sentinel"
			require(not bool(Rules.project_receipt(sentinel_head_receipt, "rival").ok), "receipt projection rejects unknown head fields")
			var sentinel_member_receipt: Dictionary = result.receipt.duplicate(true)
			var sentinel_member_stage := _stage(sentinel_member_receipt, "Print")
			sentinel_member_stage.snapshot.seats.player.members[0]["privatefield"] = "sentinel"
			require(not bool(Rules.project_receipt(sentinel_member_receipt, "rival").ok), "receipt projection rejects unknown nested member fields")
			var malformed_own := rival_view.duplicate(true)
			malformed_own.own = {}
			require(not bool(Rules.check_view_plan(malformed_own, _plan(result.state)).ok), "malformed empty own-view rejects without authority access")
			require(Rules.eligible_equipment_targets(malformed_own, "standard_full_suit").is_empty(), "malformed own-view exposes no equipment targets")
			var malformed_schema := rival_view.duplicate(true)
			malformed_schema.view_schema = 99
			require(not bool(Rules.check_view_plan(malformed_schema, _plan(result.state)).ok), "wrong view schema rejects without script error")
	_complete_group()


func _test_edge_case_regressions() -> void:
	var absorbed_state: Dictionary = _production().state
	_make_active(absorbed_state, "player")
	_make_active(absorbed_state, "rival")
	_member(absorbed_state.seats.rival, "cinderpaw").armor = Data.FULL_SUIT_ARMOR
	_member(absorbed_state.seats.rival, "cinderpaw").armor_slot = true
	var absorbed_result := Rules.run_cycle(absorbed_state, _plan(absorbed_state), _plan(absorbed_state))
	require(bool(absorbed_result.ok), "fully absorbed hit fixture resolves")
	if bool(absorbed_result.ok):
		require(int(_member(absorbed_result.state.seats.player, "cinderpaw").landed_attacks) == 1 and int(_member(absorbed_result.state.seats.rival, "cinderpaw").hp) == 34, "absorbed legal hit advances landed counter without HP damage")

	var aqua_state: Dictionary = _production().state
	_make_active(aqua_state, "player", "aquafin")
	_make_active(aqua_state, "rival")
	var aqua := _member(aqua_state.seats.player, "aquafin")
	aqua.hp = 35
	aqua.landed_attacks = 2
	aqua.armor = Data.FULL_SUIT_ARMOR
	aqua.armor_slot = true
	var aqua_result := Rules.run_cycle(aqua_state, _plan(aqua_state), _plan(aqua_state))
	require(bool(aqua_result.ok), "Aquafin clamp fixture resolves")
	if bool(aqua_result.ok):
		var aqua_traits := _stage(aqua_result.receipt, "Traits")
		var aqua_heal := {}
		for event_value in aqua_traits.events:
			var event: Dictionary = event_value
			if event.type == "trait_heal" and event.seat == "player":
				aqua_heal = event
		require(int(aqua_heal.get("hp_before", -1)) == 35 and int(aqua_heal.get("hp_after", -1)) == 36 and int(_member(aqua_result.state.seats.player, "aquafin").hp) == 36, "Aquafin at 35 HP with Suit armor heals exactly to the 36 HP cap")
	var aqua_death_state: Dictionary = _production().state
	_make_active(aqua_death_state, "player", "aquafin")
	_make_active(aqua_death_state, "rival")
	var dying_aqua := _member(aqua_death_state.seats.player, "aquafin")
	dying_aqua.hp = 7
	dying_aqua.landed_attacks = 2
	var aqua_death_result := Rules.run_cycle(aqua_death_state, _plan(aqua_death_state), _plan(aqua_death_state))
	require(bool(aqua_death_result.ok) and _member(aqua_death_result.state.seats.player, "aquafin").status == State.STATUS_DEFEATED and int(_member(aqua_death_result.state.seats.player, "aquafin").hp) == 0, "Aquafin never resurrects after a lethal third landed hit")

	var volt_created := State.create_production(
		["voltwig", "cinderpaw", "mossmunk"],
		["cinderpaw", "aquafin", "mossmunk"],
		Data.recommended_kit(),
		Data.recommended_kit(),
		31,
		true
	)
	require(bool(volt_created.ok), "Voltwig trait fixture creates a valid production roster")
	if bool(volt_created.ok):
		var volt_state: Dictionary = volt_created.state
		_make_active(volt_state, "player", "voltwig")
		_make_active(volt_state, "rival")
		var volt := _member(volt_state.seats.player, "voltwig")
		volt.hp = 7
		volt.landed_attacks = 2
		volt_state.seats.player.filament = 4
		var volt_result := Rules.run_cycle(volt_state, _plan(volt_state), _plan(volt_state))
		require(bool(volt_result.ok), "lethal Voltwig trait Run resolves")
		if bool(volt_result.ok):
			var volt_traits := _stage(volt_result.receipt, "Traits")
			var volt_gain := {}
			for event_value in volt_traits.events:
				var event: Dictionary = event_value
				if event.type == "trait_filament" and event.seat == "player":
					volt_gain = event
			require(int(volt_gain.get("filament_before", -1)) == 4 and int(volt_gain.get("filament_after", -1)) == 5 and _member(volt_result.state.seats.player, "voltwig").status == State.STATUS_DEFEATED and int(volt_result.state.seats.player.filament) == 7, "lethal Voltwig third hit gains 4 to 5 before regeneration and ends Cycle 2 at 7")
			var volt_cap_state: Dictionary = State.deep_clone(volt_state)
			volt_cap_state.seats.player.filament = Data.FILAMENT_CAP
			var volt_cap_member := _member(volt_cap_state.seats.player, "voltwig")
			volt_cap_member.status = State.STATUS_ACTIVE
			volt_cap_member.hp = 7
			volt_cap_member.landed_attacks = 2
			volt_cap_state.seats.player.active_member_id = volt_cap_member.identity_id
			var volt_cap_result := Rules.run_cycle(volt_cap_state, _plan(volt_cap_state), _plan(volt_cap_state))
			require(bool(volt_cap_result.ok), "Voltwig cap fixture resolves")
			if bool(volt_cap_result.ok):
				var volt_cap_traits := _stage(volt_cap_result.receipt, "Traits")
				var volt_cap_gain := {}
				for event_value in volt_cap_traits.events:
					var event: Dictionary = event_value
					if event.type == "trait_filament" and event.seat == "player":
						volt_cap_gain = event
				require(int(volt_cap_gain.get("filament_before", -1)) == Data.FILAMENT_CAP and int(volt_cap_gain.get("filament_after", -1)) == Data.FILAMENT_CAP and int(volt_cap_result.state.seats.player.filament) == Data.FILAMENT_CAP, "Voltwig trait gain clamps independently at filament cap nine")

	var moss_state: Dictionary = _production().state
	_make_active(moss_state, "player", "mossmunk")
	_make_active(moss_state, "rival")
	_member(moss_state.seats.player, "mossmunk").landed_attacks = 2
	var moss_result := Rules.run_cycle(moss_state, _plan(moss_state), _plan(moss_state))
	require(bool(moss_result.ok) and int(_member(moss_result.state.seats.player, "mossmunk").armor) == Data.MOSSMUNK_TRAIT_ARMOR and not bool(_member(moss_result.state.seats.player, "mossmunk").armor_slot), "Mossmunk trait armor does not occupy the Suit slot")

	var full_queue_state: Dictionary = _production().state
	full_queue_state.cycle = 4
	full_queue_state.revision = 3
	var full_player: Dictionary = full_queue_state.seats.player
	var defeated_cinder := _member(full_player, "cinderpaw")
	defeated_cinder.status = State.STATUS_DEFEATED
	defeated_cinder.hp = 0
	full_player.active_member_id = ""
	full_player.ready_member_ids = []
	var full_suit_a := _take_copy(full_player, "standard_full_suit")
	var full_gem := _take_copy(full_player, "iron_gem")
	var full_suit_b := _take_copy(full_player, "standard_full_suit")
	full_player.fifo = [
		_equipment_job("player", 1, full_suit_a, defeated_cinder.identity_id),
		_equipment_job("player", 2, full_gem, defeated_cinder.identity_id),
		_equipment_job("player", 3, full_suit_b, defeated_cinder.identity_id),
	]
	_make_active(full_queue_state, "rival")
	var full_no_choice := Rules.validate_plan(full_queue_state, "player", _plan(full_queue_state))
	require(bool(full_no_choice.ok) and str(full_no_choice.plan.fabrication_id).is_empty() and str(full_no_choice.forecast.default_fabrication_reason) == "default_capacity_blocked", "full FIFO empty-field Plan permits a no-choice work escape")
	var full_run := Rules.run_cycle(full_queue_state, _plan(full_queue_state), _plan(full_queue_state))
	require(bool(full_run.ok), "full FIFO no-choice Run advances")
	if bool(full_run.ok):
		require(full_run.state.seats.player.fifo.size() == 2 and int(_member(full_run.state.seats.rival, "cinderpaw").landed_attacks) == 0, "full FIFO Run advances exactly one head with no carry and both sides HOLD without a target")
		var now_legal_default := Rules.validate_plan(full_run.state, "player", _plan(full_run.state))
		require(bool(now_legal_default.ok) and str(now_legal_default.plan.fabrication_id) == _member(full_run.state.seats.player, "aquafin").identity_id, "default fabrication becomes selected once one FIFO slot is free")

	var selected_illegal_default: Dictionary = _production().state
	selected_illegal_default.seats.player.filament = 2
	var surge_copy_id := _copy_in_hand(selected_illegal_default.seats.player, "forge_surge")
	require(not bool(Rules.validate_plan(selected_illegal_default, "player", _plan(selected_illegal_default, "", surge_copy_id)).ok), "selected Support plus an illegal required default rejects rather than silently dropping a choice")
	var raw_copy_id := _copy_in_hand(selected_illegal_default.seats.player, "raw_filament")
	var aid_default := Rules.validate_plan(selected_illegal_default, "player", _plan(selected_illegal_default, "", raw_copy_id))
	require(bool(aid_default.ok) and not str(aid_default.plan.fabrication_id).is_empty(), "selected aid plus newly affordable default fabrication resolves together")

	var exhaustion_state: Dictionary = _production().state
	_make_active(exhaustion_state, "player")
	_make_active(exhaustion_state, "rival")
	_move_all_cards_to_discard(exhaustion_state.seats.player)
	_move_all_cards_to_discard(exhaustion_state.seats.rival)
	var exhaustion_result := Rules.run_cycle(exhaustion_state, _plan(exhaustion_state), _plan(exhaustion_state))
	require(bool(exhaustion_result.ok) and exhaustion_result.state.seats.player.hand.is_empty() and exhaustion_result.state.seats.player.draw_pile.is_empty() and exhaustion_result.state.seats.player.discard.size() == 15, "finite exhausted 15-card Kit does not reshuffle and never exceeds the four-card hand")
	var refabrication_state: Dictionary = _production().state
	var first_cinder := _member(refabrication_state.seats.player, "cinderpaw")
	var rival_first_cinder := _member(refabrication_state.seats.rival, "cinderpaw")
	var first_print := Rules.run_cycle(refabrication_state, _plan(refabrication_state, first_cinder.identity_id), _plan(refabrication_state, rival_first_cinder.identity_id))
	if bool(first_print.ok):
		require(not bool(Rules.validate_plan(first_print.state, "player", _plan(first_print.state, first_cinder.identity_id)).ok), "deployed identity cannot be fabricated a second time")
	_complete_group()


func _test_test_only_one_vs_one() -> void:
	var created := State.create_test_1v1("cinderpaw", "aquafin", Data.recommended_kit(), Data.recommended_kit(), 23, true)
	require(bool(created.ok), "named 1v1 State fixture creates")
	if not bool(created.ok):
		return
	var state: Dictionary = created.state
	var player_cinder := _member(state.seats.player, "cinderpaw")
	var rival_aqua := _member(state.seats.rival, "aquafin")
	var production_attempt := Rules.run_cycle(state, _plan(state, player_cinder.identity_id), _plan(state, rival_aqua.identity_id))
	require(not bool(production_attempt.ok), "production Rules path rejects test-only 1v1 State")
	var test_result := Rules.run_cycle(state, _plan(state, player_cinder.identity_id), _plan(state, rival_aqua.identity_id), true)
	require(bool(test_result.ok) and int(test_result.state.roster_count) == 1, "explicit Rules test_1v1 path resolves the same checked core")
	var final_draw := State.create_test_1v1("cinderpaw", "cinderpaw", Data.recommended_kit(), Data.recommended_kit(), 29, true)
	if bool(final_draw.ok):
		var draw_state: Dictionary = final_draw.state
		_make_active(draw_state, "player")
		_make_active(draw_state, "rival")
		_member(draw_state.seats.player, "cinderpaw").hp = 7
		_member(draw_state.seats.rival, "cinderpaw").hp = 7
		var final_draw_result := Rules.run_cycle(draw_state, _plan(draw_state), _plan(draw_state), true)
		require(bool(final_draw_result.ok) and final_draw_result.state.result == "Draw", "test-only 1v1 simultaneous final KO settles Draw exactly once")
	_complete_group()
