class_name TeamBattleProjection
extends RefCounted

## Viewer-safe projection for both settled authority and transient presentation
## snapshots.  It copies only declared scalar fields; no nested authority object is
## duplicated wholesale into a rival view or projected receipt.

const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const State := preload("res://scripts/team_battle/team_battle_state.gd")

const SEAT_KEYS := ["seat_id", "filament", "members", "priority", "active_member_id", "ready_member_ids", "draw_pile", "hand", "discard", "fifo", "original_kit"]
const MEMBER_KEYS := ["identity_id", "member_id", "status", "hp", "landed_attacks", "armor", "armor_slot", "gem_slot"]
const COPY_KEYS := ["copy_id", "card_id"]
const JOB_COMMON_KEYS := ["job_id", "kind", "created_cycle", "work_total", "work_remaining"]
const OPPONENT_KEYS := ["seat_id", "filament", "members", "priority", "active_member_id", "ready_member_ids", "fifo", "hand_count", "draw_pile_count", "discard_count"]

const EVENT_FIELDS := {
	"support_played": ["type", "seat", "card_id", "gain"],
	"printer_aid": ["type", "seat", "card_id", "gain"],
	"fabrication_queued": ["type", "seat", "member_identity_id"],
	"equipment_queued": ["type", "seat", "card_id", "target_identity_id"],
	"print_work": ["type", "seat", "head_before", "work_before", "work_after", "work_total", "kind", "member_identity_id", "target_identity_id", "destination_state"],
	"awaken_ready": ["type", "seat", "member_identity_id", "work_remaining"],
	"companion_entered": ["type", "seat", "member_identity_id", "status"],
	"equipment_fizzled": ["type", "seat", "card_id", "target_identity_id"],
	"equipment_fit": ["type", "seat", "card_id", "target_identity_id"],
	"swap": ["type", "seat", "active_member_id", "reserve_member_id"],
	"surge_armed": ["type", "seat", "card_id"],
	"hold": ["type", "seat", "beat_id"],
	"attack_locked": ["type", "seat", "source_identity_id", "target_identity_id", "damage", "landed_after", "beat_id"],
	"damage": ["type", "seat", "target_identity_id", "beat_id", "hp_before", "hp_after", "armor_before", "armor_after", "damage"],
	"trait_heal": ["type", "seat", "source_identity_id", "hp_before", "hp_after"],
	"trait_filament": ["type", "seat", "source_identity_id", "filament_before", "filament_after"],
	"trait_armor": ["type", "seat", "source_identity_id", "armor_before", "armor_after"],
	"defeat": ["type", "seat", "member_identity_id"],
	"replacement": ["type", "seat", "member_identity_id"],
	"terminal": ["type", "result"],
	"plan_open": ["type", "seat", "filament_before", "filament_after", "drawn"],
}


static func project_state(state_value: Variant, viewer: String) -> Dictionary:
	if viewer not in ["player", "rival"] or not state_value is Dictionary:
		return _failure("Projection state or viewer is invalid.")
	var state: Dictionary = state_value
	if not _has_exact_keys(state, State.STATE_KEYS):
		return _failure("Projection state schema is invalid.")
	if not state.has("seats") or not state.seats is Dictionary or not _has_exact_keys(state.seats, ["player", "rival"]):
		return _failure("Projection seats are invalid.")
	if not state.seats[viewer] is Dictionary:
		return _failure("Projection own seat is invalid.")
	var opponent_id := "rival" if viewer == "player" else "player"
	if not state.seats[opponent_id] is Dictionary:
		return _failure("Projection opponent seat is invalid.")
	var own_result := _project_private_seat(state.seats[viewer], viewer)
	if not bool(own_result.get("ok", false)):
		return own_result
	var opponent_result := _project_opponent_seat(state.seats[opponent_id], opponent_id)
	if not bool(opponent_result.get("ok", false)):
		return opponent_result
	if not _is_integer(state.get("cycle", -1)) or not _is_integer(state.get("revision", -1)) or not _is_integer(state.get("roster_count", -1)) or not _is_integer(state.get("filament_cap", -1)):
		return _failure("Projection state numeric fields are invalid.")
	if not (state.get("result", "") is String):
		return _failure("Projection result is invalid.")
	return {
		"ok": true,
		"view": {
			"view_schema": 1,
			"viewer": viewer,
			"cycle": int(state.cycle),
			"revision": int(state.revision),
			"result": state.result,
			"roster_count": int(state.roster_count),
			"filament_cap": int(state.filament_cap),
			"own": own_result.seat,
			"opponent": opponent_result.seat,
		},
	}


static func validate_opponent_public(opponent_value: Variant, expected_seat: String, roster_count: int, committed_revision: int) -> Dictionary:
	if not opponent_value is Dictionary or not _has_exact_keys(opponent_value, OPPONENT_KEYS):
		return _failure("Opponent public schema is invalid.")
	var opponent: Dictionary = opponent_value
	if expected_seat not in ["player", "rival"] or roster_count not in [1, 3] or committed_revision < 0:
		return _failure("Opponent public validation context is invalid.")
	if not opponent.seat_id is String or opponent.seat_id != expected_seat:
		return _failure("Opponent seat identity is invalid.")
	for key in ["filament", "hand_count", "draw_pile_count", "discard_count"]:
		if not _is_integer(opponent[key]) or int(opponent[key]) < 0 or int(opponent[key]) > 15:
			return _failure("Opponent %s is invalid." % key)
	if int(opponent.filament) > Data.FILAMENT_CAP or int(opponent.hand_count) > Data.HAND_SIZE:
		return _failure("Opponent resource bounds are invalid.")
	if not opponent.members is Array or not opponent.priority is Array or not opponent.ready_member_ids is Array or not opponent.fifo is Array:
		return _failure("Opponent collections are invalid.")
	if opponent.members.size() != roster_count or opponent.priority.size() != roster_count or opponent.fifo.size() > Data.FIFO_CAPACITY:
		return _failure("Opponent collection counts are invalid.")
	var members_by_identity := {}
	var ready_ids := []
	var active_ids := []
	for member_value in opponent.members:
		var member_result := _project_member(member_value)
		if not bool(member_result.get("ok", false)):
			return member_result
		var member: Dictionary = member_result.member
		if member.identity_id != "%s:member:%s" % [expected_seat, member.member_id] or members_by_identity.has(member.identity_id):
			return _failure("Opponent member identity is not canonical.")
		members_by_identity[member.identity_id] = member
		if member.status == State.STATUS_READY:
			ready_ids.append(member.identity_id)
		elif member.status == State.STATUS_ACTIVE:
			active_ids.append(member.identity_id)
	if active_ids.size() > 1 or not (opponent.active_member_id is String):
		return _failure("Opponent Active identity is invalid.")
	if str(opponent.active_member_id).is_empty() != active_ids.is_empty() or (not active_ids.is_empty() and str(opponent.active_member_id) != str(active_ids[0])):
		return _failure("Opponent Active status is inconsistent.")
	if opponent.ready_member_ids.size() != ready_ids.size():
		return _failure("Opponent Ready identities are inconsistent.")
	var ready_seen := {}
	for identity_value in opponent.ready_member_ids:
		if not identity_value is String or not members_by_identity.has(identity_value) or ready_seen.has(identity_value) or identity_value not in ready_ids:
			return _failure("Opponent Ready identities are inconsistent.")
		ready_seen[identity_value] = true
	var priority_seen := {}
	for identity_value in opponent.priority:
		if not identity_value is String or not members_by_identity.has(identity_value) or priority_seen.has(identity_value):
			return _failure("Opponent priority is invalid.")
		priority_seen[identity_value] = true
	if priority_seen.size() != roster_count:
		return _failure("Opponent priority is incomplete.")
	for identity_value in opponent.ready_member_ids:
		if not identity_value is String or not members_by_identity.has(identity_value):
			return _failure("Opponent Ready identity is invalid.")
	var queued_equipment := 0
	var job_ids := {}
	var previous_cycle := -1
	var previous_kind_rank := -1
	for job_value in opponent.fifo:
		var job_result := project_public_job(job_value)
		if not bool(job_result.get("ok", false)):
			return job_result
		var job: Dictionary = job_result.job
		if int(job.created_cycle) < 1 or int(job.created_cycle) > committed_revision or int(job.work_total) != 1 or int(job.work_remaining) != 1:
			return _failure("Opponent FIFO job is not a settled job.")
		var kind_rank := 0 if str(job.kind) == "companion" else 1
		if str(job.job_id) != "%s:job:%d:%s" % [expected_seat, int(job.created_cycle), str(job.kind)] or job_ids.has(job.job_id):
			return _failure("Opponent FIFO job identity is invalid.")
		if int(job.created_cycle) < previous_cycle or (int(job.created_cycle) == previous_cycle and kind_rank <= previous_kind_rank):
			return _failure("Opponent FIFO ordering is invalid.")
		job_ids[job.job_id] = true
		previous_cycle = int(job.created_cycle)
		previous_kind_rank = kind_rank
		var referenced_identity := str(job.get("member_identity_id", job.get("target_identity_id", "")))
		if not members_by_identity.has(referenced_identity):
			return _failure("Opponent FIFO target is unknown.")
		if job.kind == "companion":
			if str(members_by_identity[referenced_identity].status) != State.STATUS_PRINTING:
				return _failure("Opponent companion job status is invalid.")
		else:
			queued_equipment += 1
	if int(opponent.hand_count) + int(opponent.draw_pile_count) + int(opponent.discard_count) + queued_equipment != 15:
		return _failure("Opponent Support counts are not conserved.")
	return {"ok": true}


## Strictly validates an already-redacted job.  Public views and receipt events
## must never submit raw `card_copy` dictionaries here.
static func project_public_job(job_value: Variant) -> Dictionary:
	if not job_value is Dictionary:
		return _failure("Public FIFO job is invalid.")
	var job: Dictionary = job_value
	if not job.has("kind") or not job.kind is String or job.kind not in ["companion", "equipment"]:
		return _failure("Public FIFO kind is invalid.")
	var expected := JOB_COMMON_KEYS.duplicate()
	if job.kind == "companion":
		expected.append("member_identity_id")
	else:
		expected.append("target_identity_id")
		expected.append("card_id")
	if not _has_exact_keys(job, expected):
		return _failure("Public FIFO job fields are invalid.")
	if not job.job_id is String or not _is_integer(job.created_cycle) or not _is_integer(job.work_total) or not _is_integer(job.work_remaining):
		return _failure("Public FIFO common fields are invalid.")
	if int(job.work_total) < 1 or int(job.work_remaining) < 0 or int(job.work_remaining) > int(job.work_total):
		return _failure("Public FIFO work is invalid.")
	var output := {
		"job_id": job.job_id,
		"kind": job.kind,
		"created_cycle": int(job.created_cycle),
		"work_total": int(job.work_total),
		"work_remaining": int(job.work_remaining),
	}
	if job.kind == "companion":
		if not job.member_identity_id is String:
			return _failure("Public companion identity is invalid.")
		output["member_identity_id"] = job.member_identity_id
	else:
		if not job.target_identity_id is String or not job.card_id is String or job.card_id not in ["standard_full_suit", "iron_gem"]:
			return _failure("Public equipment job is invalid.")
		output["target_identity_id"] = job.target_identity_id
		output["card_id"] = job.card_id
	return {"ok": true, "job": output}


## Reusable by internal forecast code after validating the raw authority job.
static func public_job_from_private(job_value: Variant) -> Dictionary:
	return _project_public_job(job_value)


static func project_events(events_value: Variant) -> Dictionary:
	if not events_value is Array:
		return _failure("Receipt events are invalid.")
	var projected := []
	for event_value in events_value:
		if not event_value is Dictionary:
			return _failure("Receipt event is invalid.")
		var event: Dictionary = event_value
		if not event.has("type") or not event.type is String or not EVENT_FIELDS.has(event.type):
			return _failure("Receipt event type is invalid.")
		var allowed: Array = EVENT_FIELDS[event.type]
		if not _has_exact_keys(event, allowed):
			return _failure("Receipt event fields are invalid.")
		var output := {"type": event.type}
		for key in allowed:
			if key == "type":
				continue
			if key == "head_before":
				var head_result := project_public_job(event[key])
				if not bool(head_result.get("ok", false)):
					return head_result
				output[key] = head_result.job
			elif not _is_event_scalar(key, event[key]):
				return _failure("Receipt event scalar %s is invalid." % key)
			else:
				output[key] = event[key]
		projected.append(output)
	return {"ok": true, "events": projected}


static func _project_private_seat(seat_value: Variant, expected_seat: String) -> Dictionary:
	if not seat_value is Dictionary or not _has_exact_keys(seat_value, SEAT_KEYS):
		return _failure("Private seat schema is invalid.")
	var seat: Dictionary = seat_value
	if not seat.seat_id is String or seat.seat_id != expected_seat or not _is_integer(seat.filament) or int(seat.filament) < 0:
		return _failure("Private seat identity or filament is invalid.")
	if not seat.members is Array or not seat.priority is Array or not seat.ready_member_ids is Array or not seat.draw_pile is Array or not seat.hand is Array or not seat.discard is Array or not seat.fifo is Array or not seat.original_kit is Array:
		return _failure("Private seat collections are invalid.")
	var members := []
	for member_value in seat.members:
		var member_result := _project_member(member_value)
		if not bool(member_result.get("ok", false)):
			return member_result
		members.append(member_result.member)
	var cards_result := _project_cards(seat.draw_pile, seat.hand, seat.discard)
	if not bool(cards_result.get("ok", false)):
		return cards_result
	var jobs := []
	for job_value in seat.fifo:
		var job_result := _project_private_job(job_value)
		if not bool(job_result.get("ok", false)):
			return job_result
		jobs.append(job_result.job)
	for identity_value in seat.priority + seat.ready_member_ids:
		if not identity_value is String:
			return _failure("Private seat identity list is invalid.")
	if not seat.active_member_id is String:
		return _failure("Private seat Active identity is invalid.")
	for card_id in seat.original_kit:
		if not card_id is String or not Data.is_support_eligible(card_id):
			return _failure("Private original Kit is invalid.")
	return {"ok": true, "seat": {
		"seat_id": seat.seat_id,
		"filament": int(seat.filament),
		"members": members,
		"priority": seat.priority.duplicate(),
		"active_member_id": seat.active_member_id,
		"ready_member_ids": seat.ready_member_ids.duplicate(),
		"draw_pile": cards_result.draw_pile,
		"hand": cards_result.hand,
		"discard": cards_result.discard,
		"fifo": jobs,
		"original_kit": seat.original_kit.duplicate(),
	}}


static func _project_opponent_seat(seat_value: Variant, expected_seat: String) -> Dictionary:
	var private_result := _project_private_seat(seat_value, expected_seat)
	if not bool(private_result.get("ok", false)):
		return private_result
	var seat: Dictionary = private_result.seat
	var public_jobs := []
	for job_value in seat.fifo:
		var job_result := _project_public_job(job_value)
		if not bool(job_result.get("ok", false)):
			return job_result
		public_jobs.append(job_result.job)
	return {"ok": true, "seat": {
		"seat_id": seat.seat_id,
		"filament": seat.filament,
		"members": seat.members,
		"priority": seat.priority,
		"active_member_id": seat.active_member_id,
		"ready_member_ids": seat.ready_member_ids,
		"fifo": public_jobs,
		"hand_count": seat.hand.size(),
		"draw_pile_count": seat.draw_pile.size(),
		"discard_count": seat.discard.size(),
	}}


static func _project_member(member_value: Variant) -> Dictionary:
	if not member_value is Dictionary or not _has_exact_keys(member_value, MEMBER_KEYS):
		return _failure("Presentation member schema is invalid.")
	var member: Dictionary = member_value
	if not member.identity_id is String or not member.member_id is String or not Data.is_member_eligible(member.member_id) or not member.status is String or member.status not in State.VALID_STATUSES:
		return _failure("Presentation member identity or status is invalid.")
	for key in ["hp", "landed_attacks", "armor"]:
		if not _is_integer(member[key]) or int(member[key]) < 0:
			return _failure("Presentation member %s is invalid." % key)
	if not member.armor_slot is bool or not member.gem_slot is bool:
		return _failure("Presentation member gear is invalid.")
	return {"ok": true, "member": {
		"identity_id": member.identity_id,
		"member_id": member.member_id,
		"status": member.status,
		"hp": int(member.hp),
		"landed_attacks": int(member.landed_attacks),
		"armor": int(member.armor),
		"armor_slot": member.armor_slot,
		"gem_slot": member.gem_slot,
	}}


static func _project_cards(draw_value: Variant, hand_value: Variant, discard_value: Variant) -> Dictionary:
	var result := {"draw_pile": [], "hand": [], "discard": []}
	for entry in [["draw_pile", draw_value], ["hand", hand_value], ["discard", discard_value]]:
		var key := str(entry[0])
		var cards_value: Variant = entry[1]
		if not cards_value is Array:
			return _failure("Private card collection is invalid.")
		for copy_value in cards_value:
			var copy_result := _project_copy(copy_value)
			if not bool(copy_result.get("ok", false)):
				return copy_result
			result[key].append(copy_result.copy)
	return {"ok": true, "draw_pile": result.draw_pile, "hand": result.hand, "discard": result.discard}


static func _project_copy(copy_value: Variant) -> Dictionary:
	if not copy_value is Dictionary or not _has_exact_keys(copy_value, COPY_KEYS):
		return _failure("Presentation Support copy schema is invalid.")
	var copy: Dictionary = copy_value
	if not copy.copy_id is String or not copy.card_id is String or not Data.is_support_eligible(copy.card_id):
		return _failure("Presentation Support copy is invalid.")
	return {"ok": true, "copy": {"copy_id": copy.copy_id, "card_id": copy.card_id}}


static func _project_private_job(job_value: Variant) -> Dictionary:
	if not job_value is Dictionary:
		return _failure("Presentation FIFO job is invalid.")
	var job: Dictionary = job_value
	if not job.has("kind") or not job.kind is String or job.kind not in ["companion", "equipment"]:
		return _failure("Presentation FIFO kind is invalid.")
	var expected := JOB_COMMON_KEYS.duplicate()
	if job.kind == "companion":
		expected.append("member_identity_id")
	else:
		expected.append("target_identity_id")
		expected.append("card_copy")
	if not _has_exact_keys(job, expected):
		return _failure("Presentation FIFO job fields are invalid.")
	if not job.job_id is String or not _is_integer(job.created_cycle) or not _is_integer(job.work_total) or not _is_integer(job.work_remaining):
		return _failure("Presentation FIFO common fields are invalid.")
	if int(job.work_total) < 1 or int(job.work_remaining) < 0 or int(job.work_remaining) > int(job.work_total):
		return _failure("Presentation FIFO work is invalid.")
	var output := {
		"job_id": job.job_id,
		"kind": job.kind,
		"created_cycle": int(job.created_cycle),
		"work_total": int(job.work_total),
		"work_remaining": int(job.work_remaining),
	}
	if job.kind == "companion":
		if not job.member_identity_id is String:
			return _failure("Presentation companion job identity is invalid.")
		output["member_identity_id"] = job.member_identity_id
	else:
		if not job.target_identity_id is String:
			return _failure("Presentation equipment job target is invalid.")
		var copy_result := _project_copy(job.card_copy)
		if not bool(copy_result.get("ok", false)):
			return copy_result
		output["target_identity_id"] = job.target_identity_id
		output["card_copy"] = copy_result.copy
	return {"ok": true, "job": output}


static func _project_public_job(job_value: Variant) -> Dictionary:
	var private_result := _project_private_job(job_value)
	if not bool(private_result.get("ok", false)):
		return private_result
	var job: Dictionary = private_result.job
	var output := {
		"job_id": job.job_id,
		"kind": job.kind,
		"created_cycle": job.created_cycle,
		"work_total": job.work_total,
		"work_remaining": job.work_remaining,
	}
	if job.kind == "companion":
		output["member_identity_id"] = job.member_identity_id
	else:
		output["target_identity_id"] = job.target_identity_id
		output["card_id"] = job.card_copy.card_id
	return {"ok": true, "job": output}


static func _is_event_scalar(key: String, value: Variant) -> bool:
	if key in ["seat", "card_id", "member_identity_id", "target_identity_id", "source_identity_id", "status", "active_member_id", "reserve_member_id", "beat_id", "result", "kind", "destination_state"]:
		return value is String
	if key == "drawn":
		return value is bool
	return _is_integer(value)


static func _has_exact_keys(record: Dictionary, expected: Array) -> bool:
	if record.size() != expected.size():
		return false
	for key in record.keys():
		if key not in expected:
			return false
	return true


static func _is_integer(value: Variant) -> bool:
	return value is int and not (value is bool)


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
