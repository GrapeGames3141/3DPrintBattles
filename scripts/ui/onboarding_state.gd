class_name OnboardingState
extends RefCounted
## Small pure UI seam for onboarding state tests and scene routing.

static func screen_for_profile(profile: Dictionary) -> String:
	return "workshop" if ProfileRules.has_starter(profile) else "onboarding"

static func can_confirm(profile: Dictionary, candidate_id: String) -> bool:
	return not ProfileRules.has_starter(profile) and candidate_id in ProfileRules.STARTER_IDS
