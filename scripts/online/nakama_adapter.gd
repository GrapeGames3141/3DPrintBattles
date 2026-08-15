class_name NakamaAdapter
extends RefCounted
## Boundary only. Nakama SDK is intentionally optional for the offline vertical slice.
signal connected
signal canonical_state_received(state: Dictionary)
var online := false
func authenticate_steam(_ticket: PackedByteArray) -> Dictionary:
	return {"ok":false,"error":"Nakama SDK is not installed in this offline build."}
func submit_intent(intent: Dictionary) -> void:
	# Production transport sends {match_id, intent, expected_revision}; never accepts client results.
	push_warning("Online adapter unavailable; intent not sent: %s" % intent)
