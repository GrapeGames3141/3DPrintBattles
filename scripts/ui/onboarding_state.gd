class_name OnboardingState
extends RefCounted
## Small pure UI seam for onboarding state tests and scene routing.

static func screen_for_profile(profile: Dictionary) -> String:
	return "onboarding" if str(profile.get("onboarding", {}).get("state", "choose_starter")) == "choose_starter" else "workshop"

static func can_confirm(profile: Dictionary, candidate_id: String) -> bool:
	return str(profile.get("onboarding", {}).get("state", "choose_starter")) == "choose_starter" and candidate_id in ProfileRules.STARTER_IDS
