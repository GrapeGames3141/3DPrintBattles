class_name TeamBattleBot
extends RefCounted

## Deterministic F7 opponent policy.  This module accepts only one checked viewer
## projection and asks Rules to preview every candidate; it never receives State,
## receipts, seeds, or an opposing private hand.

const Data := preload("res://scripts/team_battle/team_battle_data.gd")
const State := preload("res://scripts/team_battle/team_battle_state.gd")
const Rules := preload("res://scripts/team_battle/team_battle_rules.gd")


static func choose_plan(view_value: Variant) -> Dictionary:
	if not view_value is Dictionary:
		return _failure("Bot requires a checked private/public view.")
	var view: Dictionary = view_value
	var baseline := _plan(view.get("revision", -1))
	var baseline_checked := Rules.check_view_plan(view, baseline)
	if not bool(baseline_checked.get("ok", false)):
		return _failure("Bot view is not a legal nonterminal projection.")

	var own: Dictionary = view.own
	var fabrication_id := _highest_unspent(own)
	var fabrication_plan := _plan(int(view.revision), fabrication_id)
	var fabrication_checked := Rules.check_view_plan(view, fabrication_plan)

	# A printer aid is considered first only when it is required for the
	# highest-priority fabrication. Raw precedes Heated when both work.
	if not fabrication_id.is_empty() and not bool(fabrication_checked.get("ok", false)):
		for aid_copy in _aid_copies(own):
			var aided_plan := _plan(int(view.revision), fabrication_id, str(aid_copy.copy_id))
			var aided_checked := Rules.check_view_plan(view, aided_plan)
			if bool(aided_checked.get("ok", false)):
				return {"ok": true, "plan": aided_checked.plan}

	var tactical_candidates := _tactical_candidates(view, fabrication_id)
	if not tactical_candidates.is_empty():
		var first_tactical: Dictionary = tactical_candidates[0]
		var combined := _plan(
			int(view.revision),
			fabrication_id,
			str(first_tactical.get("support_copy_id", "")),
			str(first_tactical.get("equipment_target_id", "")),
			str(first_tactical.get("swap_id", ""))
		)
		var checked := Rules.check_view_plan(view, combined)
		if bool(checked.get("ok", false)):
			return {"ok": true, "plan": checked.plan}

	# Dropping tactical choices preserves the fabrication priority whenever the
	# completed composite was illegal (capacity, target, or resource conflict).
	if bool(fabrication_checked.get("ok", false)):
		return {"ok": true, "plan": fabrication_checked.plan}

	# If fabrication itself cannot be completed, retry the stable tactical order
	# with no fabrication. This includes the F6 no-choice baseline escape.
	var fallback_candidates := _tactical_candidates(view, "")
	for candidate in fallback_candidates:
		var tactical_only := _plan(
			int(view.revision),
			"",
			str(candidate.get("support_copy_id", "")),
			str(candidate.get("equipment_target_id", "")),
			str(candidate.get("swap_id", ""))
		)
		var tactical_checked := Rules.check_view_plan(view, tactical_only)
		if bool(tactical_checked.get("ok", false)):
			return {"ok": true, "plan": tactical_checked.plan}
	return {"ok": true, "plan": baseline_checked.plan}


static func _tactical_candidates(view: Dictionary, fabrication_id: String) -> Array:
	var own: Dictionary = view.own
	var candidates := []
	var swap_id := _low_hp_swap(own)
	if not swap_id.is_empty():
		candidates.append({"swap_id": swap_id})

	for card_id in ["standard_full_suit", "iron_gem"]:
		for copy_value in own.hand:
			var copy: Dictionary = copy_value
			if str(copy.card_id) != card_id:
				continue
			for target_id in Rules.eligible_equipment_targets(view, card_id, fabrication_id):
				var target := _member_by_identity(own, str(target_id))
				if target.is_empty():
					continue
				if card_id == "standard_full_suit" and bool(target.armor_slot):
					continue
				if card_id == "iron_gem" and bool(target.gem_slot):
					continue
				candidates.append({"support_copy_id": copy.copy_id, "equipment_target_id": target_id})

	if _living_attack_forecast(view, fabrication_id):
		for copy_value in own.hand:
			var copy: Dictionary = copy_value
			if str(copy.card_id) == "forge_surge":
				candidates.append({"support_copy_id": copy.copy_id})

	if int(own.filament) < Data.FILAMENT_CAP:
		for aid_copy in _aid_copies(own):
			candidates.append({"support_copy_id": aid_copy.copy_id})
	return candidates


static func _aid_copies(own: Dictionary) -> Array:
	var raw := []
	var heated := []
	for copy_value in own.hand:
		var copy: Dictionary = copy_value
		if str(copy.card_id) == "raw_filament":
			raw.append(copy)
		elif str(copy.card_id) == "heated_spool":
			heated.append(copy)
	return raw + heated


static func _highest_unspent(own: Dictionary) -> String:
	for identity_value in own.priority:
		var member := _member_by_identity(own, str(identity_value))
		if not member.is_empty() and str(member.status) == State.STATUS_UNSPENT:
			return str(member.identity_id)
	return ""


static func _low_hp_swap(own: Dictionary) -> String:
	var active := _member_by_identity(own, str(own.active_member_id))
	if active.is_empty() or str(active.status) != State.STATUS_ACTIVE:
		return ""
	var base_hp := int(Data.member_stats(str(active.member_id)).get("hp", 0))
	if int(active.hp) * 2 > base_hp:
		return ""
	for identity_value in own.priority:
		var ready := _member_by_identity(own, str(identity_value))
		if not ready.is_empty() and str(ready.status) == State.STATUS_READY:
			if int(ready.hp) + int(ready.armor) > int(active.hp) + int(active.armor):
				return str(ready.identity_id)
			return ""
	return ""


static func _living_attack_forecast(view: Dictionary, fabrication_id: String) -> bool:
	return _own_can_attack_now_or_after_head(view.own, fabrication_id) and _opponent_can_attack_now_or_after_head(view.opponent)


static func _own_can_attack_now_or_after_head(own: Dictionary, fabrication_id: String) -> bool:
	if _seat_can_attack_now_or_after_head(own):
		return true
	if fabrication_id.is_empty() or not str(own.active_member_id).is_empty() or not own.fifo.is_empty():
		return false
	var selected := _member_by_identity(own, fabrication_id)
	return not selected.is_empty() and str(selected.status) == State.STATUS_UNSPENT and int(selected.hp) > 0


static func _seat_can_attack_now_or_after_head(seat: Dictionary) -> bool:
	var active := _member_by_identity(seat, str(seat.active_member_id))
	if not active.is_empty() and str(active.status) == State.STATUS_ACTIVE and int(active.hp) > 0:
		return true
	return _head_completes_living_companion(seat.members, seat.fifo, str(seat.active_member_id))


static func _opponent_can_attack_now_or_after_head(opponent: Dictionary) -> bool:
	var active_id := str(opponent.active_member_id)
	for member_value in opponent.members:
		var member: Dictionary = member_value
		if str(member.identity_id) == active_id and str(member.status) == State.STATUS_ACTIVE and int(member.hp) > 0:
			return true
	return _head_completes_living_companion(opponent.members, opponent.fifo, active_id)


static func _head_completes_living_companion(members: Array, fifo: Array, active_id: String) -> bool:
	if not active_id.is_empty() or fifo.is_empty():
		return false
	var head_value: Variant = fifo[0]
	if not head_value is Dictionary:
		return false
	var head: Dictionary = head_value
	if str(head.get("kind", "")) != "companion" or int(head.get("work_remaining", 2)) > 1:
		return false
	var member_id := str(head.get("member_identity_id", ""))
	for member_value in members:
		var member: Dictionary = member_value
		if str(member.identity_id) == member_id:
			return str(member.status) == State.STATUS_PRINTING and int(member.hp) > 0
	return false


static func _member_by_identity(seat: Dictionary, identity_id: String) -> Dictionary:
	for member_value in seat.members:
		var member: Dictionary = member_value
		if str(member.identity_id) == identity_id:
			return member
	return {}


static func _plan(revision: Variant, fabrication_id: String = "", support_copy_id: String = "", equipment_target_id: String = "", swap_id: String = "") -> Dictionary:
	return {
		"expected_revision": revision,
		"fabrication_id": fabrication_id,
		"support_copy_id": support_copy_id,
		"equipment_target_id": equipment_target_id,
		"swap_id": swap_id,
	}


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "error": message}
