class_name V3ProfileState
extends RefCounted
## Profile-shape boundary for the canonical v3 save namespace. Gameplay and
## catalog migrations remain in UnifiedRules, which exposes this via its
## compatibility facade to existing callers.

static func ensure_base(source: Dictionary, catalog_version: String) -> Dictionary:
	var profile := source.duplicate(true)
	profile["schema_version"] = 31
	profile["catalog_version"] = catalog_version
	for key in ["owned_cards","owned_blueprints","printed_models","gear_loadouts","market_epochs","quest_state","pack_pity","drop_receipts","claim_receipts","cosmetics","entitlements","notifications","season_receipts","newcomer_claims","unified_settlements","starter_pack_rewards"]:
		if not profile.has(key) or not profile.get(key) is Dictionary: profile[key] = {}
	for key in ["workshop_upgrades","preprints","decks","wishlist"]:
		if not profile.has(key) or not profile.get(key) is Array: profile[key] = []
	if not profile.has("forge_coins"): profile["forge_coins"] = int(profile.get("coins", 1000))
	if not profile.has("sparks"): profile["sparks"] = 0
	if not profile.has("revision"): profile["revision"] = 0
	if not profile.has("unified_launch_sequence"): profile["unified_launch_sequence"] = 0
	if not profile.has("rng_nonce"): profile["rng_nonce"] = 1
	if not profile.has("spool_level"): profile["spool_level"] = 1
	profile.spool_level = clampi(int(profile.spool_level), 1, 100)
	if not profile.has("spool_xp"): profile["spool_xp"] = 0
	if not profile.has("wins"): profile["wins"] = {"streak":0,"lifetime":0,"since_drop":0}
	if not profile.has("season"): profile["season"] = {"id":"season-v3-1","xp":0,"paid":false,"claimed":[],"started_at":0,"ends_at":0}
	if not profile.season.has("started_at"): profile.season.started_at = 0
	if not profile.season.has("ends_at"): profile.season.ends_at = 0
	if not profile.has("newcomer_started_at"): profile["newcomer_started_at"] = 0
	if not profile.has("academy_rewards"): profile["academy_rewards"] = {}
	if not profile.has("fake_store_receipts"): profile["fake_store_receipts"] = {}
	if not profile.has("pending_pack_reveal"): profile["pending_pack_reveal"] = {}
	# Only the first-print transition creates this entitlement. Existing complete
	# saves gain an empty stable record during migration, never retroactive packs.
	if not profile.starter_pack_rewards.has("entitled"): profile.starter_pack_rewards["entitled"] = 0
	if not profile.starter_pack_rewards.has("opened"): profile.starter_pack_rewards["opened"] = 0
	if not profile.has("active_deck_id"): profile["active_deck_id"] = "starter-deck"
	if not profile.has("onboarding") or not profile.onboarding is Dictionary: profile["onboarding"] = {"state":"choose_starter","starter_id":""}
	return profile
