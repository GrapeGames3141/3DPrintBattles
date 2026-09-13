class_name TeamPrototypeBattleSeating
extends RefCounted
## One priority-ordered projection for the fixed three-record seat.

static func project(seat: Dictionary) -> Dictionary:
	var active_id := str(seat.get("active_member_id", ""))
	var by_identity := {}
	var source_order: Array = []
	for value in seat.get("members", []):
		if not value is Dictionary:
			continue
		var member: Dictionary = value
		var identity := str(member.get("identity_id", ""))
		if identity.is_empty() or identity == active_id:
			continue
		by_identity[identity] = member
		source_order.append(identity)
	var ordered: Array = []
	for value in seat.get("priority", []):
		var identity := str(value)
		if by_identity.has(identity) and not ordered.has(identity):
			ordered.append(identity)
	for value in source_order:
		var identity := str(value)
		if not ordered.has(identity):
			ordered.append(identity)
	var docket: Dictionary = {}
	if active_id.is_empty() and ordered.size() == 3:
		for desired in ["Printing", "Unspent", "Defeated"]:
			for value in ordered:
				var candidate: Dictionary = by_identity[str(value)]
				if str(candidate.get("status", "")) == desired:
					docket = candidate
					ordered.erase(value)
					break
			if not docket.is_empty():
				break
		if docket.is_empty() and not ordered.is_empty():
			var fallback_id := str(ordered.pop_front())
			docket = by_identity[fallback_id]
	var bays: Array = []
	for value in ordered:
		if bays.size() == 2:
			break
		bays.append(by_identity[str(value)])
	return {"active_id":active_id, "docket":docket, "bays":bays}
