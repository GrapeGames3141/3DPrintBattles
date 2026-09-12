extends Node

## Isolated State/Data coverage.  It deliberately does not preload Rules, Bot,
## or Coordinator so this suite can validate snapshot authority independently.

const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const State := preload("res://scripts/team_battle/team_battle_state.gd")

var failures: Array[String] = []
var require_count := 0
var completed_groups := 0
const REQUIRED_GROUPS := 6


func require(value: bool, message: String) -> void:
	require_count += 1
	if value:
		return
	failures.append(message)
	push_error(message)


func _ready() -> void:
	_test_data_defaults()
	_test_factories_and_openings()
	_test_restore_numbers_and_canonical_data()
	_test_member_occupancy_and_hp()
	_test_fifo_order_and_printing_target()
	_test_terminal_truth()
	require(completed_groups == REQUIRED_GROUPS, "all State test groups must complete before success")
	var suite_complete := completed_groups == REQUIRED_GROUPS
	print("TEAM_BATTLE_STATE groups=%d/%d requires=%d failures=%d" % [completed_groups, REQUIRED_GROUPS, require_count, failures.size()])
	if suite_complete:
		print("TEAM_BATTLE_STATE failures=%d" % failures.size())
	else:
		print("TEAM_BATTLE_STATE incomplete groups=%d/%d" % [completed_groups, REQUIRED_GROUPS])
	get_tree().quit(0 if suite_complete and failures.is_empty() else 1)


func _complete_group() -> void:
	completed_groups += 1


func _kit() -> Array:
	# Valid but intentionally not the recommended 3/2/3/3/4 kit.
	return [
		"raw_filament", "raw_filament", "raw_filament", "raw_filament",
		"heated_spool", "heated_spool",
		"standard_full_suit", "standard_full_suit", "standard_full_suit",
		"iron_gem", "iron_gem", "iron_gem",
		"forge_surge", "forge_surge", "forge_surge",
	]


func _test_data_defaults() -> void:
	var expected_members := {
		"cinderpaw": [34, 7],
		"aquafin": [36, 6],
		"voltwig": [30, 7],
		"mossmunk": [31, 5],
	}
	for member_id in expected_members:
		var stats: Dictionary = Data.member_stats(member_id)
		var expected: Array = expected_members[member_id]
		require(int(stats.hp) == int(expected[0]) and int(stats.attack) == int(expected[1]), "Data pins %s HP and attack" % member_id)
	var expected_supports := ["raw_filament", "heated_spool", "standard_full_suit", "iron_gem", "forge_surge"]
	for card_id in expected_supports:
		require(Data.is_support_eligible(card_id), "Data pins eligible Support %s" % card_id)
	require(Data.FABRICATION_COST == 3 and Data.FILAMENT_REGEN == 2 and Data.MINIMUM_HIT == 1 and Data.ARMOR_CAP == 8, "Data pins fabrication, regeneration, minimum hit, and armor cap")
	require(Data.FULL_SUIT_ARMOR == 8 and Data.IRON_GEM_ATTACK == 2 and Data.SURGE_NUMERATOR == 3 and Data.SURGE_DENOMINATOR == 2, "Data pins Suit, Gem, and Surge effects")
	require(Data.TRAIT_LANDED_INTERVAL == 3 and Data.CINDERPAW_TRAIT_DAMAGE == 2 and Data.AQUAFIN_TRAIT_HEAL == 3 and Data.VOLTWIG_TRAIT_FILAMENT == 1 and Data.MOSSMUNK_TRAIT_ARMOR == 2, "Data pins every-third trait values")
	var counts := {}
	for card_id in Data.recommended_kit():
		counts[card_id] = int(counts.get(card_id, 0)) + 1
	require(int(counts.get("raw_filament", 0)) == 3 and int(counts.get("heated_spool", 0)) == 2 and int(counts.get("standard_full_suit", 0)) == 3 and int(counts.get("iron_gem", 0)) == 3 and int(counts.get("forge_surge", 0)) == 4, "recommended Kit pins 3/2/3/3/4 copies")
	require(Data.TUTORIAL_OPENING == ["raw_filament", "standard_full_suit", "iron_gem", "forge_surge"], "tutorial opening order is exact")
	_complete_group()


func _production(seed: Variant = 41) -> Dictionary:
	return State.create_production(
		["cinderpaw", "aquafin", "mossmunk"],
		["cinderpaw", "aquafin", "mossmunk"],
		_kit(),
		_kit(),
		seed
	)


func _member(seat: Dictionary, member_id: String) -> Dictionary:
	for member in seat.members:
		if member.member_id == member_id:
			return member
	return {}


func _take_copy(seat: Dictionary, card_id: String) -> Dictionary:
	for pile_name in ["draw_pile", "hand", "discard"]:
		var pile: Array = seat[pile_name]
		for index in pile.size():
			if pile[index].card_id == card_id:
				return pile.pop_at(index)
	return {}


func _test_factories_and_openings() -> void:
	var first := _production(41)
	var second := _production(41)
	var different_seed := _production(42)
	require(bool(first.ok) and bool(second.ok), "production factory accepts a custom eligible 15-card kit")
	if bool(first.ok) and bool(second.ok):
		require(JSON.stringify(first.state) == JSON.stringify(second.state), "seeded construction is deterministic")
		require(bool(State.restore(first.state).ok), "production factory state restores through production path")
	if bool(first.ok) and bool(different_seed.ok):
		require(JSON.stringify(first.state.seats.player.draw_pile) != JSON.stringify(different_seed.state.seats.player.draw_pile), "different finite seeds produce a different shuffled draw order")
	for invalid_seed in [-1, true, 1.5, 1e30]:
		require(not bool(_production(invalid_seed).ok), "production factory rejects invalid seed %s" % str(invalid_seed))

	var tutorial := State.create_production(
		["cinderpaw", "aquafin", "mossmunk"],
		["cinderpaw", "aquafin", "mossmunk"],
		_kit(),
		_kit(),
		41,
		true
	)
	require(bool(tutorial.ok), "tutorial opening accepts a kit containing all four requested Support cards")
	if bool(tutorial.ok):
		var hand_ids := []
		for copy in tutorial.state.seats.player.hand:
			hand_ids.append(copy.card_id)
		for required_card in Data.TUTORIAL_OPENING:
			require(hand_ids.has(required_card), "tutorial opening includes %s" % required_card)

	var missing_tutorial := State.create_production(
		["cinderpaw", "aquafin", "mossmunk"],
		["cinderpaw", "aquafin", "mossmunk"],
		["raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament", "raw_filament"],
		_kit(),
		41,
		true
	)
	require(not bool(missing_tutorial.ok), "tutorial opening rejects a legal kit missing requested opening cards")

	var one_vs_one := State.create_test_1v1("cinderpaw", "aquafin", _kit(), _kit(), 41)
	require(bool(one_vs_one.ok), "named 1v1 factory creates the test-only roster")
	if bool(one_vs_one.ok):
		require(not bool(State.restore(one_vs_one.state).ok), "production restore rejects test-only roster_count one")
		require(bool(State.restore_test_1v1(one_vs_one.state).ok), "test-only restore accepts the named 1v1 shape")
	_complete_group()


func _test_restore_numbers_and_canonical_data() -> void:
	var created := _production()
	require(bool(created.ok), "numeric validation fixture creates")
	if not bool(created.ok):
		return
	var json_roundtrip: Dictionary = JSON.parse_string(JSON.stringify(created.state))
	json_roundtrip.schema_version = 1.0
	json_roundtrip.roster_count = 3.0
	json_roundtrip.seed = 41.0
	json_roundtrip.cycle = 1.0
	json_roundtrip.revision = 0.0
	json_roundtrip.filament_cap = 9.0
	json_roundtrip.seats.player.filament = 5.0
	json_roundtrip.seats.player.members[0].hp = 34.0
	var restored := State.restore(json_roundtrip)
	require(bool(restored.ok), "exact JSON whole floats restore successfully")
	if bool(restored.ok):
		require(typeof(restored.state.seed) == TYPE_INT and typeof(restored.state.seats.player.filament) == TYPE_INT, "restored whole floats are canonicalized to integers")

	var fraction := State.deep_clone(created.state)
	fraction.seats.player.filament = 4.5
	require(not bool(State.restore(fraction).ok), "fractional numeric fields reject")
	var boolean_number := State.deep_clone(created.state)
	boolean_number.seed = true
	require(not bool(State.restore(boolean_number).ok), "boolean numeric fields reject")
	var huge_number := State.deep_clone(created.state)
	huge_number.cycle = 9007199254740992
	require(not bool(State.restore(huge_number).ok), "unsafe JSON integer range rejects")
	var huge_float := State.deep_clone(created.state)
	huge_float.revision = 1e30
	require(not bool(State.restore(huge_float).ok), "huge finite float rejects before integer cast")
	var infinity := State.deep_clone(created.state)
	infinity.cycle = INF
	require(not bool(State.restore(infinity).ok), "infinite numeric fields reject")
	var not_a_number := State.deep_clone(created.state)
	not_a_number.revision = NAN
	require(not bool(State.restore(not_a_number).ok), "NaN numeric fields reject")

	var bad_identity := State.deep_clone(created.state)
	bad_identity.seats.player.members[0].identity_id = "player:member:forged"
	require(not bool(State.restore(bad_identity).ok), "member identity must equal canonical seat/member identity")
	var bad_mapping := State.deep_clone(created.state)
	var copy: Dictionary = bad_mapping.seats.player.hand[0]
	copy.card_id = "heated_spool" if copy.card_id != "heated_spool" else "raw_filament"
	require(not bool(State.restore(bad_mapping).ok), "card copy must match its original-kit index card")
	var duplicate_copy := State.deep_clone(created.state)
	duplicate_copy.seats.player.draw_pile[0] = duplicate_copy.seats.player.hand[0].duplicate(true)
	require(not bool(State.restore(duplicate_copy).ok), "duplicate card copies reject despite matching card totals")
	require(_all_copy_ids(created.state.seats.player).size() == 15, "initial card conservation observes fifteen unique indexed copies")
	_complete_group()


func _test_member_occupancy_and_hp() -> void:
	var created := _production()
	if not bool(created.ok):
		require(false, "occupancy fixture creates")
		return
	var settled := State.deep_clone(created.state)
	var seat: Dictionary = settled.seats.player
	var cinder := _member(seat, "cinderpaw")
	var aqua := _member(seat, "aquafin")
	var moss := _member(seat, "mossmunk")
	cinder.status = State.STATUS_ACTIVE
	aqua.status = State.STATUS_READY
	seat.active_member_id = cinder.identity_id
	seat.ready_member_ids = [aqua.identity_id]
	require(bool(State.restore(settled).ok), "one Active and one exact Ready record restore")

	var duplicate_active := State.deep_clone(settled)
	_member(duplicate_active.seats.player, "mossmunk").status = State.STATUS_ACTIVE
	require(not bool(State.restore(duplicate_active).ok), "two Active records reject")
	var zero_active_hp := State.deep_clone(settled)
	_member(zero_active_hp.seats.player, "cinderpaw").hp = 0
	require(not bool(State.restore(zero_active_hp).ok), "non-defeated Active HP must be positive")
	var duplicate_ready := State.deep_clone(settled)
	_member(duplicate_ready.seats.player, "mossmunk").status = State.STATUS_READY
	duplicate_ready.seats.player.ready_member_ids = [aqua.identity_id, aqua.identity_id]
	require(not bool(State.restore(duplicate_ready).ok), "Ready identity list must be unique and exact")
	var ready_without_active := State.deep_clone(settled)
	_member(ready_without_active.seats.player, "cinderpaw").status = State.STATUS_UNSPENT
	ready_without_active.seats.player.active_member_id = ""
	require(not bool(State.restore(ready_without_active).ok), "Ready records reject when no Active companion exists")
	_complete_group()


func _test_fifo_order_and_printing_target() -> void:
	var created := _production()
	if not bool(created.ok):
		require(false, "FIFO fixture creates")
		return
	var legal := State.deep_clone(created.state)
	legal.cycle = 2
	legal.revision = 1
	var seat: Dictionary = legal.seats.player
	var cinder := _member(seat, "cinderpaw")
	cinder.status = State.STATUS_PRINTING
	var suit_copy := _take_copy(seat, "standard_full_suit")
	require(not suit_copy.is_empty(), "FIFO fixture can remove an indexed Suit copy from a card collection")
	if suit_copy.is_empty():
		return
	var companion_job := {
		"job_id": "player:job:1:companion",
		"kind": "companion",
		"created_cycle": 1,
		"work_total": 1,
		"work_remaining": 1,
		"member_identity_id": cinder.identity_id,
	}
	var equipment_job := {
		"job_id": "player:job:1:equipment",
		"kind": "equipment",
		"created_cycle": 1,
		"work_total": 1,
		"work_remaining": 1,
		"target_identity_id": cinder.identity_id,
		"card_copy": suit_copy,
	}
	seat.fifo = [companion_job, equipment_job]
	require(bool(State.restore(legal).ok), "same-cycle companion then Suit may target its earlier Printing FIFO head")
	var uncommitted_cycle := State.deep_clone(legal)
	uncommitted_cycle.cycle = 1
	uncommitted_cycle.revision = 0
	require(not bool(State.restore(uncommitted_cycle).ok), "initial cycle cannot restore a job created before its first commit")
	var future_job := State.deep_clone(legal)
	for job in future_job.seats.player.fifo:
		job.created_cycle = 2
		job.job_id = "player:job:2:%s" % str(job.kind)
	require(not bool(State.restore(future_job).ok), "FIFO job cannot be created after the settled revision")

	var reverse_order := State.deep_clone(legal)
	reverse_order.seats.player.fifo = [equipment_job.duplicate(true), companion_job.duplicate(true)]
	require(not bool(State.restore(reverse_order).ok), "same-cycle equipment before companion rejects")
	var unspent_target := State.deep_clone(legal)
	unspent_target.seats.player.fifo[1].target_identity_id = _member(unspent_target.seats.player, "aquafin").identity_id
	require(not bool(State.restore(unspent_target).ok), "equipment cannot target an Unspent companion")
	_complete_group()


func _test_terminal_truth() -> void:
	var created := _production()
	if not bool(created.ok):
		require(false, "terminal fixture creates")
		return
	var terminal := State.deep_clone(created.state)
	for member in terminal.seats.player.members:
		member.status = State.STATUS_DEFEATED
		member.hp = 0
	terminal.revision = 1
	terminal.cycle = 1
	terminal.result = "Loss"
	terminal.terminal_receipt = {
		"id": "terminal:%d:%d" % [terminal.seed, terminal.cycle],
		"result": "Loss",
		"cycle": terminal.cycle,
		"revision": terminal.revision,
	}
	require(bool(State.restore(terminal).ok), "terminal loss requires matching defeated seat, receipt, and revision")
	var wrong_result := State.deep_clone(terminal)
	wrong_result.result = ""
	wrong_result.terminal_receipt = {}
	require(not bool(State.restore(wrong_result).ok), "terminal result must match all-defeated seat truth")
	var wrong_receipt := State.deep_clone(terminal)
	wrong_receipt.terminal_receipt.id = "terminal:forged"
	require(not bool(State.restore(wrong_receipt).ok), "terminal receipt requires canonical ID and state values")
	var overflow_boundary := State.deep_clone(created.state)
	overflow_boundary.revision = 9007199254740991
	overflow_boundary.cycle = 9007199254740991
	require(not bool(State.restore(overflow_boundary).ok), "nonterminal revision boundary rejects unsupported next cycle")
	_complete_group()


func _all_copy_ids(seat: Dictionary) -> Dictionary:
	var ids := {}
	for pile_name in ["draw_pile", "hand", "discard"]:
		for copy in seat[pile_name]:
			ids[copy.copy_id] = true
	for job in seat.fifo:
		if job.kind == "equipment":
			ids[job.card_copy.copy_id] = true
	return ids
