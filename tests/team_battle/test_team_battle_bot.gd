extends Node

const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const State := preload("res://scripts/team_battle/team_battle_state.gd")
const Rules := preload("res://scripts/team_battle/team_battle_rules.gd")
const Bot := preload("res://scripts/team_battle/team_battle_bot.gd")

var failures: Array[String] = []
var require_count := 0
var completed_groups := 0
const REQUIRED_GROUPS := 5


func require(value: bool, message: String) -> void:
	require_count += 1
	if not value:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	_test_required_aid_and_hand_order()
	_test_swap_and_equipment_policy()
	_test_printing_target_and_fallback()
	_test_view_privacy_and_validation()
	_test_repeatability_and_two_bot_opening()
	require(completed_groups == REQUIRED_GROUPS, "all Bot test groups reach their end marker")
	print("TEAM_BATTLE_BOT groups=%d/%d requires=%d failures=%d" % [completed_groups, REQUIRED_GROUPS, require_count, failures.size()])
	if completed_groups == REQUIRED_GROUPS:
		print("TEAM_BATTLE_BOT failures=%d" % failures.size())
	get_tree().quit(0 if completed_groups == REQUIRED_GROUPS and failures.is_empty() else 1)


func _complete_group() -> void:
	completed_groups += 1


func _production(seed: int = 7) -> Dictionary:
	return State.create_production(
		["cinderpaw", "aquafin", "mossmunk"],
		["cinderpaw", "aquafin", "mossmunk"],
		Data.recommended_kit(),
		Data.recommended_kit(),
		seed,
		true
	)


func _plan(state: Dictionary) -> Dictionary:
	return {
		"expected_revision": int(state.revision),
		"fabrication_id": "",
		"support_copy_id": "",
		"equipment_target_id": "",
		"swap_id": "",
	}


func _member(seat: Dictionary, member_id: String) -> Dictionary:
	for member_value in seat.members:
		var member: Dictionary = member_value
		if str(member.member_id) == member_id:
			return member
	return {}


func _copy_in_hand(seat: Dictionary, card_id: String) -> Dictionary:
	for collection_name in ["hand", "draw_pile", "discard"]:
		var collection: Array = seat[collection_name]
		for index in collection.size():
			var copy: Dictionary = collection[index]
			if str(copy.card_id) == card_id:
				if collection_name != "hand":
					if seat.hand.size() >= Data.HAND_SIZE:
						seat.draw_pile.append(seat.hand.pop_back())
					seat.hand.append(collection.pop_at(index))
				return copy
	return {}


func _move_next_copy_to_hand(seat: Dictionary, card_id: String, excluded_copy_id: String) -> Dictionary:
	for collection_name in ["draw_pile", "discard"]:
		var collection: Array = seat[collection_name]
		for index in collection.size():
			var copy: Dictionary = collection[index]
			if str(copy.card_id) == card_id and str(copy.copy_id) != excluded_copy_id:
				if seat.hand.size() >= Data.HAND_SIZE:
					seat.draw_pile.append(seat.hand.pop_back())
				seat.hand.append(collection.pop_at(index))
				return copy
	return {}


func _first_hand_copy(seat: Dictionary, card_id: String) -> Dictionary:
	for copy_value in seat.hand:
		var copy: Dictionary = copy_value
		if str(copy.card_id) == card_id:
			return copy
	return {}


func _keep_only_hand_card(seat: Dictionary, card_id: String) -> void:
	for index in range(seat.hand.size() - 1, -1, -1):
		var copy: Dictionary = seat.hand[index]
		if str(copy.card_id) != card_id:
			seat.discard.append(seat.hand.pop_at(index))


func _make_active(state: Dictionary, seat_id: String, active_id: String, ready_ids: Array = []) -> void:
	var seat: Dictionary = state.seats[seat_id]
	seat.active_member_id = ""
	seat.ready_member_ids = []
	for member_value in seat.members:
		var member: Dictionary = member_value
		if str(member.member_id) == active_id:
			member.status = State.STATUS_ACTIVE
			seat.active_member_id = member.identity_id
		elif str(member.member_id) in ready_ids:
			member.status = State.STATUS_READY
			seat.ready_member_ids.append(member.identity_id)
		elif member.status != State.STATUS_DEFEATED:
			member.status = State.STATUS_UNSPENT


func _view(state: Dictionary, seat_id: String) -> Dictionary:
	var projected := Rules.view_for_seat(state, seat_id)
	require(bool(projected.get("ok", false)), "Bot fixture creates checked %s view" % seat_id)
	return projected.get("view", {})


func _test_required_aid_and_hand_order() -> void:
	var created := _production(3)
	require(bool(created.ok), "required-aid fixture creates")
	if not bool(created.ok):
		return
	var state: Dictionary = created.state
	state.seats.player.filament = 2
	var raw_copy := _copy_in_hand(state.seats.player, "raw_filament")
	var view := _view(state, "player")
	var chosen := Bot.choose_plan(view)
	require(bool(chosen.ok), "Bot returns a Plan when required aid is available")
	if bool(chosen.ok):
		require(str(chosen.plan.fabrication_id) == "player:member:cinderpaw" and str(chosen.plan.support_copy_id) == str(raw_copy.copy_id), "Bot selects highest fabrication plus Raw before Heated when Raw makes it affordable")
		require(bool(Rules.check_view_plan(view, chosen.plan).ok), "required-aid Bot Plan is resubmittable through Rules")

	var tie_state: Dictionary = _production(4).state
	_make_active(tie_state, "player", "cinderpaw")
	_make_active(tie_state, "rival", "cinderpaw")
	var first_suit := _copy_in_hand(tie_state.seats.player, "standard_full_suit")
	var second_suit := _move_next_copy_to_hand(tie_state.seats.player, "standard_full_suit", str(first_suit.get("copy_id", "")))
	require(not first_suit.is_empty() and not second_suit.is_empty(), "hand-index tie fixture exposes two Suit copies")
	if not first_suit.is_empty() and not second_suit.is_empty():
		var first_index: int = tie_state.seats.player.hand.find(first_suit)
		var second_index: int = tie_state.seats.player.hand.find(second_suit)
		if second_index < first_index:
			tie_state.seats.player.hand.swap_at(first_index, second_index)
		var tie_view := _view(tie_state, "player")
		var tie_plan := Bot.choose_plan(tie_view)
		var first_suit_in_hand := _first_hand_copy(tie_state.seats.player, "standard_full_suit")
		require(bool(tie_plan.ok) and str(tie_plan.plan.support_copy_id) == str(first_suit_in_hand.copy_id), "equipment ties resolve by current hand index")
	_complete_group()


func _test_swap_and_equipment_policy() -> void:
	var created := _production(9)
	require(bool(created.ok), "swap fixture creates")
	if not bool(created.ok):
		return
	var swap_state: Dictionary = created.state
	_make_active(swap_state, "player", "cinderpaw", ["aquafin"])
	_make_active(swap_state, "rival", "cinderpaw")
	_member(swap_state.seats.player, "cinderpaw").hp = 17
	var swap_plan := Bot.choose_plan(_view(swap_state, "player"))
	require(bool(swap_plan.ok) and str(swap_plan.plan.swap_id) == "player:member:aquafin", "low-HP Active swaps to highest-priority stronger Ready companion")

	var second_ready_state: Dictionary = _production(91).state
	_make_active(second_ready_state, "player", "cinderpaw", ["aquafin", "mossmunk"])
	_make_active(second_ready_state, "rival", "cinderpaw")
	_member(second_ready_state.seats.player, "cinderpaw").hp = 17
	_member(second_ready_state.seats.player, "aquafin").hp = 10
	_member(second_ready_state.seats.player, "mossmunk").hp = 31
	var second_ready_plan := Bot.choose_plan(_view(second_ready_state, "player"))
	require(bool(second_ready_plan.ok) and str(second_ready_plan.plan.swap_id).is_empty(), "Bot does not skip the highest-priority Ready reserve to swap with a later healthier reserve")

	var moss_state: Dictionary = _production(10).state
	_make_active(moss_state, "player", "mossmunk")
	_make_active(moss_state, "rival", "cinderpaw")
	var moss := _member(moss_state.seats.player, "mossmunk")
	moss.armor = Data.MOSSMUNK_TRAIT_ARMOR
	moss.armor_slot = false
	var suit_copy := _copy_in_hand(moss_state.seats.player, "standard_full_suit")
	var moss_plan := Bot.choose_plan(_view(moss_state, "player"))
	require(bool(moss_plan.ok) and str(moss_plan.plan.support_copy_id) == str(suit_copy.copy_id) and str(moss_plan.plan.equipment_target_id) == str(moss.identity_id), "trait armor without a Suit slot still selects Full Suit")
	_complete_group()


func _test_printing_target_and_fallback() -> void:
	var created := _production(12)
	require(bool(created.ok), "printing target fixture creates")
	if not bool(created.ok):
		return
	var state: Dictionary = created.state
	var suit_copy := _copy_in_hand(state.seats.player, "standard_full_suit")
	var plan := Bot.choose_plan(_view(state, "player"))
	require(bool(plan.ok) and str(plan.plan.fabrication_id) == "player:member:cinderpaw" and str(plan.plan.support_copy_id) == str(suit_copy.copy_id) and str(plan.plan.equipment_target_id) == "player:member:cinderpaw", "bot locks Suit to its same-Plan Printing fabrication target")

	var blocked_state: Dictionary = _production(13).state
	blocked_state.seats.player.filament = 2
	var raw := _copy_in_hand(blocked_state.seats.player, "raw_filament")
	if not raw.is_empty():
		blocked_state.seats.player.hand.erase(raw)
		blocked_state.seats.player.discard.append(raw)
	var blocked_plan := Bot.choose_plan(_view(blocked_state, "player"))
	require(bool(blocked_plan.ok) and str(blocked_plan.plan.fabrication_id).is_empty() and str(blocked_plan.plan.support_copy_id).is_empty(), "when fabrication cannot afford and no aid is present, Bot returns the legal no-choice baseline")

	var first_tactical_state: Dictionary = _production(14).state
	_make_active(first_tactical_state, "player", "cinderpaw")
	_make_active(first_tactical_state, "rival", "cinderpaw")
	first_tactical_state.seats.player.filament = 4
	var first_tactical_plan := Bot.choose_plan(_view(first_tactical_state, "player"))
	require(bool(first_tactical_plan.ok) and str(first_tactical_plan.plan.fabrication_id) == "player:member:aquafin" and str(first_tactical_plan.plan.support_copy_id).is_empty(), "an unaffordable first Suit plus fabrication drops tactical and keeps fabrication rather than selecting lower-priority spare aid")

	var surge_state: Dictionary = _production(15).state
	_keep_only_hand_card(surge_state.seats.player, "forge_surge")
	_make_active(surge_state, "rival", "cinderpaw")
	var surge_plan := Bot.choose_plan(_view(surge_state, "player"))
	require(bool(surge_plan.ok) and str(surge_plan.plan.fabrication_id) == "player:member:cinderpaw" and not str(surge_plan.plan.support_copy_id).is_empty(), "Surge is selected when the known same-Plan fabrication and a public rival Active will both contact")

	var no_target_state: Dictionary = State.deep_clone(surge_state)
	_make_active(no_target_state, "rival", "")
	var no_target_plan := Bot.choose_plan(_view(no_target_state, "player"))
	require(bool(no_target_plan.ok) and str(no_target_plan.plan.fabrication_id) == "player:member:cinderpaw" and str(no_target_plan.plan.support_copy_id).is_empty(), "without a known rival Active or completing public head, Bot does not arm Surge for a HOLD")
	_complete_group()


func _test_view_privacy_and_validation() -> void:
	var created := _production(17)
	require(bool(created.ok), "privacy fixture creates")
	if not bool(created.ok):
		return
	var state: Dictionary = created.state
	_make_active(state, "player", "cinderpaw", ["aquafin", "mossmunk"])
	_make_active(state, "rival", "cinderpaw")
	state.seats.player.priority = ["player:member:mossmunk", "player:member:aquafin", "player:member:cinderpaw"]
	state.seats.player.ready_member_ids = ["player:member:mossmunk", "player:member:aquafin"]
	var view := _view(state, "rival")
	var chosen := Bot.choose_plan(view)
	require(bool(chosen.ok), "Bot accepts a valid public opponent with priority-ordered Ready IDs")
	var before := JSON.stringify(view)
	Bot.choose_plan(view)
	require(JSON.stringify(view) == before, "Bot does not mutate its public/private input view")
	var malformed := view.duplicate(true)
	malformed.opponent["hand"] = []
	require(not bool(Bot.choose_plan(malformed).ok), "Bot rejects malformed public opponent private fields")
	var terminal_state: Dictionary = State.deep_clone(state)
	for member_value in terminal_state.seats.rival.members:
		var member: Dictionary = member_value
		member.status = State.STATUS_DEFEATED
		member.hp = 0
	terminal_state.seats.rival.active_member_id = ""
	terminal_state.seats.rival.ready_member_ids = []
	terminal_state.result = "Win"
	terminal_state.cycle = 1
	terminal_state.revision = 1
	terminal_state.terminal_receipt = {"id": "terminal:17:1", "result": "Win", "cycle": 1, "revision": 1}
	require(not bool(Bot.choose_plan(_view(terminal_state, "rival")).ok), "Bot rejects terminal view input")
	_complete_group()


func _test_repeatability_and_two_bot_opening() -> void:
	var created := _production(21)
	require(bool(created.ok), "two-Bot opening fixture creates")
	if not bool(created.ok):
		return
	var state: Dictionary = created.state
	var player_view := _view(state, "player")
	var rival_view := _view(state, "rival")
	var player_first := Bot.choose_plan(player_view)
	var player_second := Bot.choose_plan(player_view)
	var rival_plan := Bot.choose_plan(rival_view)
	require(bool(player_first.ok) and bool(player_second.ok) and bool(rival_plan.ok), "both Bots create Plans from opening views before authority Run")
	if bool(player_first.ok) and bool(player_second.ok) and bool(rival_plan.ok):
		require(JSON.stringify(player_first.plan) == JSON.stringify(player_second.plan), "Bot selection is repeatable for the same view")
		var result := Rules.run_cycle(state, player_first.plan, rival_plan.plan)
		require(bool(result.ok), "two independently projected Bot Plans run together through Rules")
	_complete_group()
