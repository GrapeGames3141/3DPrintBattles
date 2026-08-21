class_name ReviewBuildRules
extends RefCounted
## Pure review-only economy seam. Production callers pass false and get no change.

const REVIEW_COIN_FLOOR := 5000

static func apply_coin_floor(source: Dictionary, review_enabled: bool) -> Dictionary:
	var profile: Dictionary = source.duplicate(true)
	if not review_enabled or int(profile.get("forge_coins", 0)) >= REVIEW_COIN_FLOOR:
		return {"ok":false, "profile":profile, "payload":{}}
	var before: int = int(profile.get("forge_coins", 0))
	profile.forge_coins = REVIEW_COIN_FLOOR
	return {"ok":true, "profile":profile, "payload":{"before":before, "after":REVIEW_COIN_FLOOR}}
