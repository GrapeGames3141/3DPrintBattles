class_name M9TestProfileFactory
extends RefCounted

## Test-only setup for routes that require a legal 40-card deck.  This follows the
## real Founder transactions instead of bypassing the onboarding guarantee.
const RULES := preload("res://scripts/core/unified_rules.gd")

static func founder_ready(starter_id := "cinderpaw") -> Dictionary:
	var profile: Dictionary = RULES.new_profile()
	profile = RULES.choose_starter(profile, starter_id).profile
	profile = RULES.print_starter(profile).profile
	for _receipt in 3:
		var opened := RULES.claim_next_starter_pack(profile)
		if not bool(opened.get("ok", false)): return profile
		profile = RULES.clear_pack_reveal(opened.profile).profile
	return profile
