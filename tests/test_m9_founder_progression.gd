extends Node

const RULES := preload("res://scripts/core/unified_rules.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _starter_deck(profile: Dictionary) -> Array:
	for deck in profile.get("decks", []):
		if deck is Dictionary and str(deck.get("id", "")) == "starter-deck": return (deck.get("cards", []) as Array).duplicate()
	return []

func _ready() -> void:
	for starter_id in RULES.STARTER_IDS:
		var profile := RULES.new_profile()
		require(str(profile.onboarding.get("founder_version", "")) == RULES.FOUNDER_VERSION, "%s fresh profile is marked Founder only at creation" % starter_id)
		var chosen := RULES.choose_starter(profile, starter_id)
		profile = chosen.profile
		require(bool(chosen.ok) and _starter_deck(profile) == [starter_id] and int(profile.owned_cards.get(starter_id, 0)) == 1 and bool(profile.owned_blueprints.get(starter_id, false)), "%s choice creates the one-card provisional licensed deck" % starter_id)
		var printed := RULES.print_starter(profile)
		profile = printed.profile
		require(bool(printed.ok) and _starter_deck(profile).size() == 1 and int(profile.starter_pack_rewards.get("opened", -1)) == 0 and int(profile.starter_pack_rewards.get("kept", -1)) == 0 and not RULES.deck_reason(profile, _starter_deck(profile)).is_empty(), "%s first print creates no hidden starter cards and keeps deck activation gated" % starter_id)
		var before_rng := int(profile.rng_nonce)
		var before_coins := int(profile.forge_coins)
		var before_spool_xp := int(profile.spool_xp)
		var before_season_xp := int((profile.get("season", {}) as Dictionary).get("xp", 0))
		for receipt_index in 3:
			var before_cards := _starter_deck(profile).duplicate()
			var opened := RULES.claim_next_starter_pack(profile)
			require(bool(opened.ok) and (opened.payload.get("cards", []) as Array).size() == 13 and str(opened.profile.pending_pack_reveal.get("receipt", "")) == "founder-v1-%d" % (receipt_index + 1), "%s Founder receipt %d commits the exact thirteen-card pending receipt" % [starter_id, receipt_index + 1])
			profile = opened.profile
			require(_starter_deck(profile).size() == 14 + receipt_index * 13 and int(profile.starter_pack_rewards.get("opened", 0)) == receipt_index + 1 and int(profile.starter_pack_rewards.get("kept", 0)) == receipt_index, "%s Founder receipt %d atomically appends deck and opened count" % [starter_id, receipt_index + 1])
			if receipt_index == 0:
				var duplicate_open := RULES.claim_next_starter_pack(profile)
				require(not bool(duplicate_open.ok) and duplicate_open.profile == profile, "%s cannot open a second Founder receipt before Keep without mutating the committed first receipt" % starter_id)
			var reloaded := RULES.ensure(profile)
			require(reloaded.pending_pack_reveal == profile.pending_pack_reveal and _starter_deck(reloaded) == _starter_deck(profile), "%s Founder receipt %d survives reload without repair or reroll" % [starter_id, receipt_index + 1])
			var kept := RULES.clear_pack_reveal(reloaded)
			profile = kept.profile
			require(bool(kept.ok) and _starter_deck(profile).size() == before_cards.size() + 13 and int(profile.starter_pack_rewards.get("kept", 0)) == receipt_index + 1 and (profile.get("pending_pack_reveal", {}) as Dictionary).is_empty(), "%s Founder Keep %d changes only acknowledgement and pending state" % [starter_id, receipt_index + 1])
			var duplicate_keep := RULES.clear_pack_reveal(profile)
			require(not bool(duplicate_keep.ok) and duplicate_keep.profile == profile, "%s Founder Keep %d is exactly once" % [starter_id, receipt_index + 1])
		require(_starter_deck(profile).size() == 40 and RULES.deck_reason(profile, _starter_deck(profile)).is_empty() and _starter_deck(profile).count(starter_id) == 12 and _starter_deck(profile).count("mossmunk") == 8 and int(profile.rng_nonce) == before_rng and int(profile.forge_coins) == before_coins and int(profile.spool_xp) == before_spool_xp and int((profile.get("season", {}) as Dictionary).get("xp", 0)) == before_season_xp, "%s reaches the exact legal Founder 40 with no RNG, coins, or XP mutation" % starter_id)
		var fourth := RULES.claim_next_starter_pack(profile)
		require(not bool(fourth.ok) and _starter_deck(profile).size() == 40, "%s cannot claim a fourth Founder pack" % starter_id)
	var legacy := RULES.ensure({"onboarding":{"state":"complete","starter_id":"cinderpaw"},"owned_cards":{"cinderpaw":12,"mossmunk":8},"decks":[]})
	require(str(legacy.onboarding.get("founder_version", "")).is_empty() and int(legacy.starter_pack_rewards.get("entitled", 0)) == 0, "Unmarked legacy saves stay outside the Founder flow.")
	var legacy_in_progress := RULES.ensure({"onboarding":{"state":"starter_selected","starter_id":"cinderpaw"},"owned_cards":{"cinderpaw":1},"decks":[]})
	require(str(legacy_in_progress.onboarding.get("founder_version", "")).is_empty() and int(legacy_in_progress.owned_cards.get("cinderpaw", 0)) == 1, "Unmarked legacy first-print saves retain their original in-progress bytes without a retroactive Founder marker.")
	var every_offer_has_slots := true
	for seed in 80:
		var offers := RULES.blueprint_offers("m9-offers-%d" % seed, 1)
		var creatures := 0
		var equipment := 0
		for offer in offers:
			if str(offer.get("type", "")) == "creature": creatures += 1
			if str(offer.get("type", "")) == "equipment": equipment += 1
		every_offer_has_slots = every_offer_has_slots and creatures == 8 and equipment == 4
	require(every_offer_has_slots, "Daily blueprint offers retain exactly eight creature and four equipment slots, including primordial-injection seeds with no equipment primordial pool.")
	var licensed_every_printable := true
	for definition in RULES.all_cards():
		if str(definition.get("type", "")) in ["creature", "equipment"]:
			var ownership := RULES.new_profile()
			RULES.grant_card(ownership, str(definition.get("id", "")))
			licensed_every_printable = licensed_every_printable and RULES.has_printable_blueprint(ownership, str(definition.get("id", "")))
	require(licensed_every_printable, "Every catalog creature and equipment first ownership creates its printable license.")
	if failures.is_empty(): print("PASS: M9 Founder starter progression")
	get_tree().quit(0 if failures.is_empty() else 1)
