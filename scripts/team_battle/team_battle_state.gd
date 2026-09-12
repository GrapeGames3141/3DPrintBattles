class_name TeamBattleState
extends RefCounted

## Snapshot authority for M1.  This file deliberately owns no combat decisions:
## it constructs finite, seat-scoped state and rejects snapshots that cannot be
## reconstructed from TeamBattleData without trusting derived values.

const Data := preload("res://scripts/team_battle/team_battle_data.gd")

const STATUS_UNSPENT := "Unspent"
const STATUS_PRINTING := "Printing"
const STATUS_READY := "Ready"
const STATUS_ACTIVE := "Active"
const STATUS_DEFEATED := "Defeated"
const VALID_STATUSES := [
	STATUS_UNSPENT,
	STATUS_PRINTING,
	STATUS_READY,
	STATUS_ACTIVE,
	STATUS_DEFEATED,
]
const MAX_SEED := 0x7fffffff
## JSON numbers are IEEE-754 doubles.  Above this bound adjacent integer values
## cannot be represented exactly, so they are never valid snapshot integers.
const MAX_SAFE_JSON_INTEGER := 9007199254740991

const STATE_KEYS := [
	"schema_version",
	"roster_count",
	"seed",
	"cycle",
	"revision",
	"filament_cap",
	"result",
	"seats",
	"terminal_receipt",
]
const SEAT_KEYS := [
	"seat_id",
	"filament",
	"members",
	"priority",
	"active_member_id",
	"ready_member_ids",
	"draw_pile",
	"hand",
	"discard",
	"fifo",
	"original_kit",
]
const MEMBER_KEYS := [
	"identity_id",
	"member_id",
	"status",
	"hp",
	"landed_attacks",
	"armor",
	"armor_slot",
	"gem_slot",
]
const COPY_KEYS := ["copy_id", "card_id"]
const JOB_COMMON_KEYS := ["job_id", "kind", "created_cycle", "work_total", "work_remaining"]
const TERMINAL_RECEIPT_KEYS := ["id", "result", "cycle", "revision"]


## Production construction is exact: each seat has three distinct eligible
## companions and an arbitrary eligible fifteen-card Support Kit.
static func create_production(
		player_team: Array,
		rival_team: Array,
		player_kit: Array,
		rival_kit: Array,
		seed: Variant,
		tutorial_opening: bool = false
	) -> Dictionary:
	var seed_result := _validated_seed(seed)
	if not bool(seed_result.ok):
		return seed_result
	var error := Data.validate_production_team(player_team)
	if not error.is_empty():
		return _failure(error)
	error = Data.validate_production_team(rival_team)
	if not error.is_empty():
		return _failure(error)
	error = Data.validate_kit(player_kit)
	if not error.is_empty():
		return _failure(error)
	error = Data.validate_kit(rival_kit)
	if not error.is_empty():
		return _failure(error)
	var normalized_seed := int(seed_result.seed)
	var player := _new_seat("player", player_team, player_kit, normalized_seed, tutorial_opening)
	if not bool(player.ok):
		return player
	var rival_seed := (normalized_seed + 1) & MAX_SEED
	var rival := _new_seat("rival", rival_team, rival_kit, rival_seed, tutorial_opening)
	if not bool(rival.ok):
		return rival
	return _success(_base_state(normalized_seed, 3, player.seat, rival.seat))


## The one-versus-one path is intentionally named test-only.  Production restore
## never accepts this shape; callers must opt into restore_test_1v1 explicitly.
static func create_test_1v1(
		player_member: String,
		rival_member: String,
		player_kit: Array,
		rival_kit: Array,
		seed: Variant,
		tutorial_opening: bool = false
	) -> Dictionary:
	var seed_result := _validated_seed(seed)
	if not bool(seed_result.ok):
		return seed_result
	var error := Data.validate_test_team([player_member])
	if not error.is_empty():
		return _failure(error)
	error = Data.validate_test_team([rival_member])
	if not error.is_empty():
		return _failure(error)
	error = Data.validate_kit(player_kit)
	if not error.is_empty():
		return _failure(error)
	error = Data.validate_kit(rival_kit)
	if not error.is_empty():
		return _failure(error)
	var normalized_seed := int(seed_result.seed)
	var player := _new_seat("player", [player_member], player_kit, normalized_seed, tutorial_opening)
	if not bool(player.ok):
		return player
	var rival_seed := (normalized_seed + 1) & MAX_SEED
	var rival := _new_seat("rival", [rival_member], rival_kit, rival_seed, tutorial_opening)
	if not bool(rival.ok):
		return rival
	return _success(_base_state(normalized_seed, 1, player.seat, rival.seat))


static func deep_clone(state: Dictionary) -> Dictionary:
	return state.duplicate(true)


## Production snapshots are always 3v3.  Validation runs against a deep copy, so
## malformed JSON never mutates the object supplied by the caller.
static func restore(snapshot: Variant) -> Dictionary:
	return _restore_for_roster_count(snapshot, 3)


static func restore_test_1v1(snapshot: Variant) -> Dictionary:
	return _restore_for_roster_count(snapshot, 1)


## View APIs carry the viewer's complete private seat but not an authority state.
## This narrow wrapper lets Rules reject malformed view payloads without cloning the
## private-seat invariants or accepting an unvalidated dictionary.
static func validate_private_seat(seat: Variant, expected_seat: String, roster_count: Variant, revision: Variant) -> Dictionary:
	if expected_seat not in ["player", "rival"]:
		return _failure("Private seat identity is invalid.")
	if not _is_integer(roster_count) or int(roster_count) not in [1, 3]:
		return _failure("Private seat roster count is invalid.")
	if not _is_integer(revision) or int(revision) < 0:
		return _failure("Private seat revision is invalid.")
	if not seat is Dictionary:
		return _failure("Private seat must be a dictionary.")
	var error := _validate_seat(seat, expected_seat, int(roster_count), int(revision))
	if not error.is_empty():
		return _failure(error)
	return {"ok": true}


static func _restore_for_roster_count(snapshot: Variant, expected_roster_count: int) -> Dictionary:
	if not snapshot is Dictionary:
		return _failure("Snapshot must be a dictionary.")
	var candidate: Dictionary = snapshot.duplicate(true)
	var error := _validate_state(candidate, expected_roster_count)
	if not error.is_empty():
		return _failure(error)
	_normalize_state_integers(candidate)
	return _success(candidate)


static func _base_state(seed: int, roster_count: int, player: Dictionary, rival: Dictionary) -> Dictionary:
	return {
		"schema_version": Data.SCHEMA_VERSION,
		"roster_count": roster_count,
		"seed": seed,
		"cycle": 1,
		"revision": 0,
		"filament_cap": Data.FILAMENT_CAP,
		"result": "",
		"seats": {"player": player, "rival": rival},
		"terminal_receipt": {},
	}


static func _new_seat(seat: String, team: Array, kit: Array, seed: int, tutorial_opening: bool) -> Dictionary:
	var copies := []
	for index in kit.size():
		copies.append({
			"copy_id": "%s:card:%02d" % [seat, index],
			"card_id": kit[index],
		})
	_seeded_shuffle(copies, seed)

	var hand := []
	if tutorial_opening:
		for needed in Data.TUTORIAL_OPENING:
			var found := -1
			for index in copies.size():
				if str(copies[index].card_id) == needed:
					found = index
					break
			if found < 0:
				return _failure("Tutorial opening requires %s in this Support Kit." % needed)
			hand.append(copies.pop_at(found))
	else:
		for ignored in Data.HAND_SIZE:
			hand.append(copies.pop_front())

	var members := []
	var priority := []
	for member_id_variant in team:
		var member_id := str(member_id_variant)
		var stats := Data.member_stats(member_id)
		var identity := "%s:member:%s" % [seat, member_id]
		members.append({
			"identity_id": identity,
			"member_id": member_id,
			"status": STATUS_UNSPENT,
			"hp": int(stats.hp),
			"landed_attacks": 0,
			"armor": 0,
			"armor_slot": false,
			"gem_slot": false,
		})
		priority.append(identity)

	return {
		"ok": true,
		"seat": {
			"seat_id": seat,
			"filament": Data.STARTING_FILAMENT,
			"members": members,
			"priority": priority,
			"active_member_id": "",
			"ready_member_ids": [],
			"draw_pile": copies,
			"hand": hand,
			"discard": [],
			"fifo": [],
			"original_kit": kit.duplicate(),
		},
	}


static func _seeded_shuffle(values: Array, seed: int) -> void:
	# Integer-only LCG avoids engine-global RNG and keeps replay order stable.
	var value := seed & MAX_SEED
	for index in range(values.size() - 1, 0, -1):
		value = int((value * 1103515245 + 12345) & MAX_SEED)
		var other := value % (index + 1)
		var temporary = values[index]
		values[index] = values[other]
		values[other] = temporary


static func _validate_state(state: Dictionary, expected_roster_count: int) -> String:
	if not _has_exact_keys(state, STATE_KEYS):
		return "Snapshot has unknown or missing top-level fields."
	if not _is_integer(state.schema_version) or int(state.schema_version) != Data.SCHEMA_VERSION:
		return "Snapshot schema version is invalid."
	if not _is_integer(state.roster_count) or int(state.roster_count) != expected_roster_count:
		return "Snapshot roster count is invalid for this restore path."
	if not _is_valid_seed(state.seed):
		return "Snapshot seed is invalid."
	if not _is_integer(state.cycle) or int(state.cycle) < 1:
		return "Snapshot cycle is invalid."
	if not _is_integer(state.revision) or int(state.revision) < 0:
		return "Snapshot revision is invalid."
	if not _is_integer(state.filament_cap) or int(state.filament_cap) != Data.FILAMENT_CAP:
		return "Snapshot filament cap is invalid."
	if not state.result is String or state.result not in ["", "Win", "Loss", "Draw"]:
		return "Snapshot terminal result is invalid."
	if not state.seats is Dictionary or not _has_exact_keys(state.seats, ["player", "rival"]):
		return "Snapshot seats are invalid."
	if not state.terminal_receipt is Dictionary:
		return "Snapshot terminal receipt is invalid."

	for seat_id in ["player", "rival"]:
		var seat_value: Variant = state.seats[seat_id]
		if not seat_value is Dictionary:
			return "Snapshot seat %s is invalid." % seat_id
		var error := _validate_seat(seat_value, seat_id, expected_roster_count, int(state.revision))
		if not error.is_empty():
			return error

	var player_all_defeated := _seat_is_all_defeated(state.seats.player)
	var rival_all_defeated := _seat_is_all_defeated(state.seats.rival)
	var expected_result := ""
	if player_all_defeated and rival_all_defeated:
		expected_result = "Draw"
	elif rival_all_defeated:
		expected_result = "Win"
	elif player_all_defeated:
		expected_result = "Loss"
	if state.result != expected_result:
		return "Snapshot result does not match defeated seats."

	if state.result.is_empty():
		if not state.terminal_receipt.is_empty():
			return "Nonterminal snapshot must not retain a terminal receipt."
		if int(state.revision) >= MAX_SAFE_JSON_INTEGER:
			return "Nonterminal revision cannot advance safely."
		if int(state.cycle) != int(state.revision) + 1:
			return "Nonterminal cycle and revision are inconsistent."
	else:
		var receipt_error := _validate_terminal_receipt(state)
		if not receipt_error.is_empty():
			return receipt_error
		if int(state.cycle) != int(state.revision):
			return "Terminal cycle and revision are inconsistent."
	return ""


static func _validate_seat(seat: Dictionary, expected_seat: String, roster_count: int, committed_revision: int) -> String:
	if not _has_exact_keys(seat, SEAT_KEYS):
		return "Seat has unknown or missing fields."
	if not seat.seat_id is String or seat.seat_id != expected_seat:
		return "Seat identity is invalid."
	if not _is_integer(seat.filament) or int(seat.filament) < 0 or int(seat.filament) > Data.FILAMENT_CAP:
		return "Seat filament is invalid."
	if not seat.members is Array or seat.members.size() != roster_count:
		return "Seat roster count is invalid."

	var identities := {}
	var member_records := {}
	var member_ids := {}
	var ready_from_status := {}
	var active_identity := ""
	for member_value in seat.members:
		var member_error := _validate_member(member_value, expected_seat)
		if not member_error.is_empty():
			return member_error
		var member: Dictionary = member_value
		var identity: String = member.identity_id
		if identities.has(identity) or member_ids.has(member.member_id):
			return "Seat member IDs must be unique."
		identities[identity] = true
		member_records[identity] = member
		member_ids[member.member_id] = true
		if member.status == STATUS_READY:
			ready_from_status[identity] = true
		if member.status == STATUS_ACTIVE:
			if not active_identity.is_empty():
				return "Seat has more than one Active companion."
			active_identity = identity

	if not seat.priority is Array or seat.priority.size() != roster_count:
		return "Seat priority is invalid."
	var priority_seen := {}
	for identity_value in seat.priority:
		if not identity_value is String or not identities.has(identity_value) or priority_seen.has(identity_value):
			return "Seat priority is not a unique roster permutation."
		priority_seen[identity_value] = true

	if not seat.active_member_id is String or seat.active_member_id != active_identity:
		return "Seat Active status does not match Active identity."
	if not seat.ready_member_ids is Array or seat.ready_member_ids.size() != ready_from_status.size():
		return "Seat Ready identities are invalid."
	var ready_seen := {}
	for identity_value in seat.ready_member_ids:
		if not identity_value is String or not ready_from_status.has(identity_value) or ready_seen.has(identity_value):
			return "Seat Ready identities are not an exact unique Ready set."
		ready_seen[identity_value] = true
	if ready_from_status.size() > 2:
		return "Seat has too many Ready companions."
	if not ready_from_status.is_empty() and active_identity.is_empty():
		return "Ready companions require an Active companion at a settled boundary."

	return _validate_cards(seat, expected_seat, member_records, committed_revision)


static func _validate_member(member: Variant, expected_seat: String) -> String:
	if not member is Dictionary or not _has_exact_keys(member, MEMBER_KEYS):
		return "Member has unknown or missing fields."
	if not member.member_id is String or not Data.is_member_eligible(member.member_id):
		return "Member ID is invalid."
	var expected_identity := "%s:member:%s" % [expected_seat, member.member_id]
	if not member.identity_id is String or member.identity_id != expected_identity:
		return "Member identity is not canonical."
	if not member.status is String or member.status not in VALID_STATUSES:
		return "Member status is invalid."
	var base_hp := int(Data.member_stats(member.member_id).hp)
	if not _is_integer(member.hp) or int(member.hp) < 0 or int(member.hp) > base_hp:
		return "Member HP is invalid."
	if not _is_integer(member.landed_attacks) or int(member.landed_attacks) < 0:
		return "Member landed attack count is invalid."
	if not _is_integer(member.armor) or int(member.armor) < 0 or int(member.armor) > Data.ARMOR_CAP:
		return "Member armor is invalid."
	if not member.armor_slot is bool or not member.gem_slot is bool:
		return "Member gear slots are invalid."
	if member.status == STATUS_DEFEATED:
		if int(member.hp) != 0:
			return "Defeated member HP must be zero."
	else:
		if int(member.hp) <= 0:
			return "Non-defeated member HP must be positive."
	if member.status in [STATUS_UNSPENT, STATUS_PRINTING]:
		if int(member.hp) != base_hp or int(member.landed_attacks) != 0 or int(member.armor) != 0:
			return "Unspent and Printing members must retain base state."
		if bool(member.armor_slot) or bool(member.gem_slot):
			return "Unspent and Printing members cannot retain gear."
	return ""


static func _validate_cards(seat: Dictionary, expected_seat: String, members: Dictionary, committed_revision: int) -> String:
	for collection_key in ["draw_pile", "hand", "discard", "fifo", "original_kit"]:
		if not seat[collection_key] is Array:
			return "Seat %s collection is invalid." % collection_key
	if seat.original_kit.size() != 15:
		return "Original Support Kit must contain exactly fifteen cards."
	if seat.hand.size() > Data.HAND_SIZE:
		return "Hand exceeds the four-card limit."
	if seat.fifo.size() > Data.FIFO_CAPACITY:
		return "FIFO exceeds capacity."

	var expected_cards := {}
	for index in seat.original_kit.size():
		var card_id_value: Variant = seat.original_kit[index]
		if not card_id_value is String or not Data.is_support_eligible(card_id_value):
			return "Original Support Kit contains an ineligible card."
		expected_cards["%s:card:%02d" % [expected_seat, index]] = card_id_value

	var observed_copies := {}
	for collection_key in ["draw_pile", "hand", "discard"]:
		for copy_value in seat[collection_key]:
			var copy_error := _validate_card_copy(copy_value, expected_cards, observed_copies)
			if not copy_error.is_empty():
				return copy_error

	var printing_job_counts := {}
	var job_ids := {}
	var job_kinds := {}
	var fifo_order := {"cycle": 0, "kind": ""}
	for job_value in seat.fifo:
		var job_error := _validate_job(
			job_value,
			expected_seat,
			members,
			expected_cards,
			observed_copies,
			printing_job_counts,
			job_ids,
			job_kinds,
			fifo_order,
			committed_revision
		)
		if not job_error.is_empty():
			return job_error

	for identity in members:
		var member: Dictionary = members[identity]
		var companion_jobs := int(printing_job_counts.get(identity, 0))
		if member.status == STATUS_PRINTING and companion_jobs != 1:
			return "Every Printing companion needs exactly one FIFO companion job."
		if member.status != STATUS_PRINTING and companion_jobs != 0:
			return "Only Printing companions may own FIFO companion jobs."
	if observed_copies.size() != expected_cards.size():
		return "Support copy conservation failed."
	return ""


static func _validate_job(
		job_value: Variant,
		expected_seat: String,
		members: Dictionary,
		expected_cards: Dictionary,
		observed_copies: Dictionary,
		printing_job_counts: Dictionary,
		job_ids: Dictionary,
		job_kinds: Dictionary,
		fifo_order: Dictionary,
		committed_revision: int
	) -> String:
	if not job_value is Dictionary:
		return "FIFO job is invalid."
	var job: Dictionary = job_value
	if not job.has("kind") or not job.kind is String or job.kind not in ["companion", "equipment"]:
		return "FIFO job kind is invalid."
	var allowed_keys := JOB_COMMON_KEYS.duplicate()
	if job.kind == "companion":
		allowed_keys.append("member_identity_id")
	else:
		allowed_keys.append("target_identity_id")
		allowed_keys.append("card_copy")
	if not _has_exact_keys(job, allowed_keys):
		return "FIFO job has unknown or missing fields."
	if not _is_integer(job.created_cycle) or int(job.created_cycle) < 1 or int(job.created_cycle) > committed_revision:
		return "FIFO job created cycle is invalid."
	if not _is_integer(job.work_total) or int(job.work_total) != 1:
		return "FIFO job work total is invalid."
	if not _is_integer(job.work_remaining) or int(job.work_remaining) != 1:
		return "FIFO job work remaining is invalid."
	var expected_job_id := "%s:job:%d:%s" % [expected_seat, int(job.created_cycle), job.kind]
	if not job.job_id is String or job.job_id != expected_job_id or job_ids.has(job.job_id):
		return "FIFO job ID is invalid or duplicated."
	var kind_key := "%d:%s" % [int(job.created_cycle), job.kind]
	if job_kinds.has(kind_key):
		return "Only one FIFO job of each kind may be created in a cycle."
	var previous_cycle := int(fifo_order.cycle)
	var previous_kind := str(fifo_order.kind)
	if int(job.created_cycle) < previous_cycle:
		return "FIFO jobs must be ordered by created cycle."
	if int(job.created_cycle) == previous_cycle and previous_kind == "equipment" and job.kind == "companion":
		return "FIFO companion work must precede equipment from the same cycle."
	job_ids[job.job_id] = true
	job_kinds[kind_key] = true
	fifo_order.cycle = int(job.created_cycle)
	fifo_order.kind = job.kind

	if job.kind == "companion":
		if not job.member_identity_id is String or not members.has(job.member_identity_id):
			return "FIFO companion target is invalid."
		var member: Dictionary = members[job.member_identity_id]
		if member.status != STATUS_PRINTING:
			return "FIFO companion job must own a Printing companion."
		printing_job_counts[job.member_identity_id] = int(printing_job_counts.get(job.member_identity_id, 0)) + 1
		return ""

	if not job.target_identity_id is String or not members.has(job.target_identity_id):
		return "FIFO equipment target is invalid."
	var target: Dictionary = members[job.target_identity_id]
	var target_status := str(target.get("status", ""))
	var target_identity := str(job.get("target_identity_id", ""))
	var target_is_printing_head: bool = target_status == STATUS_PRINTING and int(printing_job_counts.get(target_identity, 0)) == 1
	if target.status not in [STATUS_ACTIVE, STATUS_READY, STATUS_DEFEATED] and not target_is_printing_head:
		return "FIFO equipment target must be Active, Ready, defeated, or an earlier Printing head."
	var copy_error := _validate_card_copy(job.card_copy, expected_cards, observed_copies)
	if not copy_error.is_empty():
		return copy_error
	if str(job.card_copy.card_id) not in ["standard_full_suit", "iron_gem"]:
		return "FIFO equipment must be a Suit or Gem copy."
	return ""


static func _validate_card_copy(copy_value: Variant, expected_cards: Dictionary, observed_copies: Dictionary) -> String:
	if not copy_value is Dictionary or not _has_exact_keys(copy_value, COPY_KEYS):
		return "Support copy has unknown or missing fields."
	var copy: Dictionary = copy_value
	if not copy.copy_id is String or not expected_cards.has(copy.copy_id):
		return "Support copy ID is invalid."
	if not copy.card_id is String or copy.card_id != expected_cards[copy.copy_id]:
		return "Support copy card does not match its original-kit index."
	if observed_copies.has(copy.copy_id):
		return "Support copy appears more than once."
	observed_copies[copy.copy_id] = true
	return ""


static func _validate_terminal_receipt(state: Dictionary) -> String:
	var receipt: Dictionary = state.terminal_receipt
	if not _has_exact_keys(receipt, TERMINAL_RECEIPT_KEYS):
		return "Terminal receipt has unknown or missing fields."
	if not receipt.id is String or receipt.id != "terminal:%d:%d" % [int(state.seed), int(state.cycle)]:
		return "Terminal receipt ID is invalid."
	if not receipt.result is String or receipt.result != state.result:
		return "Terminal receipt result is invalid."
	if not _is_integer(receipt.cycle) or int(receipt.cycle) != int(state.cycle):
		return "Terminal receipt cycle is invalid."
	if not _is_integer(receipt.revision) or int(receipt.revision) != int(state.revision):
		return "Terminal receipt revision is invalid."
	return ""


static func _seat_is_all_defeated(seat: Dictionary) -> bool:
	for member in seat.members:
		if member.status != STATUS_DEFEATED:
			return false
	return true


static func _normalize_state_integers(state: Dictionary) -> void:
	# JSON parsers often materialize whole numbers as floats.  Validation above
	# accepts only finite exact integers, then this copy is normalized for rules.
	for key in ["schema_version", "roster_count", "seed", "cycle", "revision", "filament_cap"]:
		state[key] = int(state[key])
	for seat_id in ["player", "rival"]:
		var seat: Dictionary = state.seats[seat_id]
		seat.filament = int(seat.filament)
		for member in seat.members:
			member.hp = int(member.hp)
			member.landed_attacks = int(member.landed_attacks)
			member.armor = int(member.armor)
		for job in seat.fifo:
			job.created_cycle = int(job.created_cycle)
			job.work_total = int(job.work_total)
			job.work_remaining = int(job.work_remaining)
	if not state.result.is_empty():
		state.terminal_receipt.cycle = int(state.terminal_receipt.cycle)
		state.terminal_receipt.revision = int(state.terminal_receipt.revision)


static func _has_exact_keys(record: Dictionary, allowed_keys: Array) -> bool:
	if record.size() != allowed_keys.size():
		return false
	for key in record.keys():
		if key not in allowed_keys:
			return false
	return true


static func _is_integer(value: Variant) -> bool:
	if value is bool:
		return false
	if value is int:
		return value >= -MAX_SAFE_JSON_INTEGER and value <= MAX_SAFE_JSON_INTEGER
	if not value is float:
		return false
	return is_finite(value) and abs(value) <= MAX_SAFE_JSON_INTEGER and value == floor(value)


static func _is_valid_seed(value: Variant) -> bool:
	return _is_integer(value) and int(value) >= 0 and int(value) <= MAX_SEED


static func _validated_seed(seed: Variant) -> Dictionary:
	if not _is_valid_seed(seed):
		return _failure("Seed must be a nonnegative 31-bit integer.")
	return {"ok": true, "seed": int(seed)}


static func _success(state: Dictionary) -> Dictionary:
	return {"ok": true, "state": state.duplicate(true)}


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
