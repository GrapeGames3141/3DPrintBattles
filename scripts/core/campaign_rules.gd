class_name CampaignRules
extends RefCounted
## Pure Workshop Trial progression. Rewards are resolved from authored catalog
## encounter IDs and current owned instance IDs; no combat stat is modified.

static func ensure_fields(source: Dictionary) -> Dictionary:
	var p: Dictionary = source.duplicate(true)
	var campaign: Dictionary = p.get("solo_campaign", {}) if p.get("solo_campaign", {}) is Dictionary else {}
	campaign["unlocked_tier"] = clampi(int(campaign.get("unlocked_tier", 1)), 1, Catalog.WORKSHOP_TRIAL_TIERS.size())
	for key in ["completed_encounter_ids", "claimed_reward_ids"]:
		if not campaign.has(key) or not campaign.get(key, []) is Array: campaign[key] = []
		campaign[key] = _unique_known_ids(campaign[key])
	if not campaign.has("best_turn_counts") or not campaign.get("best_turn_counts", {}) is Dictionary: campaign["best_turn_counts"] = {}
	p["solo_campaign"] = campaign
	var raw_mastery: Variant = p.get("creature_mastery", {})
	if not raw_mastery is Dictionary: raw_mastery = {}
	p["creature_mastery"] = raw_mastery
	var owned := {}
	for creature in p.get("creatures", []):
		if creature is Dictionary:
			var instance_id := str(creature.get("instance_id", ""))
			if not instance_id.is_empty(): owned[instance_id] = true
	var mastery := {}
	for instance_id in raw_mastery:
		var key_id := str(instance_id)
		if owned.has(key_id): mastery[key_id] = maxi(0, int(raw_mastery.get(instance_id, 0)))
	p["creature_mastery"] = mastery
	return p

static func encounter_state(source: Dictionary, encounter_id: String) -> Dictionary:
	var p := ensure_fields(source)
	var encounter := Catalog.workshop_trial_encounter(encounter_id)
	if encounter.is_empty(): return {"ok":false,"profile":p,"error":"That Workshop Trial encounter is unavailable."}
	var campaign: Dictionary = p["solo_campaign"]
	var tier_number: int = int(encounter["tier"])
	var index: int = _encounter_index(encounter_id, tier_number)
	var unlocked := tier_number <= int(campaign["unlocked_tier"])
	if index > 0:
		var previous: Dictionary = Catalog.workshop_trial_tier(tier_number).get("encounters", [])[index - 1]
		unlocked = unlocked and str(previous.get("id", "")) in campaign["completed_encounter_ids"]
	var completed: bool = encounter_id in campaign["completed_encounter_ids"]
	var claimed: bool = encounter_id in campaign["claimed_reward_ids"]
	return {"ok":true,"profile":p,"encounter":encounter,"unlocked":unlocked,"completed":completed,"claimed":claimed,"reward":reward_for(encounter)}

static func reward_for(encounter: Dictionary) -> Dictionary:
	var tier: int = clampi(int(encounter.get("tier", 1)), 1, Catalog.WORKSHOP_TRIAL_TIERS.size())
	if bool(encounter.get("boss", false)):
		return {"coins":60 + 20 * tier,"xp":35 + 15 * tier,"mastery":5 + 2 * tier}
	return {"coins":20 + 10 * tier,"xp":15 + 10 * tier,"mastery":2 + tier}

static func claim_victory(source: Dictionary, encounter_id: String, turns: int) -> Dictionary:
	var state := encounter_state(source, encounter_id)
	var p: Dictionary = state["profile"]
	if not bool(state.get("ok", false)): return state
	if not bool(state["unlocked"]): return _fail(p, "Clear the earlier Workshop Trial encounters first.")
	if bool(state["claimed"]):
		var prior_best: int = int(p["solo_campaign"]["best_turn_counts"].get(encounter_id, 0))
		var replay_turns := maxi(1, turns)
		if prior_best > 0 and replay_turns < prior_best:
			p["solo_campaign"]["best_turn_counts"][encounter_id] = replay_turns
			return {"ok":true,"profile":p,"payload":{"encounter_id":encounter_id,"reward":{"coins":0,"xp":0,"mastery":0},"mastery_instance_ids":[],"spool_gained":0,"turns":replay_turns,"first_clear":false,"best_improved":true}}
		return {"ok":true,"profile":p,"payload":{"encounter_id":encounter_id,"reward":{"coins":0,"xp":0,"mastery":0},"mastery_instance_ids":[],"spool_gained":0,"turns":prior_best,"first_clear":false,"best_improved":false}}
	var encounter: Dictionary = state["encounter"]
	var reward: Dictionary = state["reward"]
	p["coins"] = int(p.get("coins", 0)) + int(reward["coins"])
	var xp_result := ProgressionRules.grant_xp(p, int(reward["xp"]))
	p = xp_result["profile"]
	var campaign: Dictionary = p["solo_campaign"]
	campaign["completed_encounter_ids"].append(encounter_id)
	campaign["claimed_reward_ids"].append(encounter_id)
	var previous_best := int(campaign["best_turn_counts"].get(encounter_id, 0))
	var safe_turns := maxi(1, turns)
	campaign["best_turn_counts"][encounter_id] = safe_turns if previous_best <= 0 else mini(previous_best, safe_turns)
	if bool(encounter.get("boss", false)):
		campaign["unlocked_tier"] = mini(Catalog.WORKSHOP_TRIAL_TIERS.size(), maxi(int(campaign["unlocked_tier"]), int(encounter["tier"]) + 1))
	var mastery_ids := _current_team_instance_ids(p)
	for instance_id in mastery_ids:
		p["creature_mastery"][instance_id] = int(p["creature_mastery"].get(instance_id, 0)) + int(reward["mastery"])
	p["solo_campaign"] = campaign
	p = ensure_fields(p)
	return {"ok":true,"profile":p,"payload":{"encounter_id":encounter_id,"reward":reward,"mastery_instance_ids":mastery_ids,"spool_gained":int(xp_result["payload"].get("spool_gained", 0)),"turns":safe_turns,"first_clear":true,"best_improved":true}}

static func mastery_for(source: Dictionary, instance_id: String) -> int:
	var p := ensure_fields(source)
	return maxi(0, int(p.get("creature_mastery", {}).get(instance_id, 0)))

static func _current_team_instance_ids(p: Dictionary) -> Array:
	var owned := {}
	for creature in p.get("creatures", []):
		if creature is Dictionary: owned[str(creature.get("instance_id", ""))] = true
	var result: Array = []
	for instance_id in p.get("team", []):
		var id := str(instance_id)
		if owned.has(id) and not id in result: result.append(id)
	return result

static func _unique_known_ids(values: Array) -> Array:
	var result: Array = []
	for value in values:
		var id := str(value)
		if Catalog.workshop_trial_encounter(id).is_empty() or id in result: continue
		result.append(id)
	return result

static func _encounter_index(encounter_id: String, tier_number: int) -> int:
	var encounters: Array = Catalog.workshop_trial_tier(tier_number).get("encounters", [])
	for index in encounters.size():
		if str(encounters[index].get("id", "")) == encounter_id: return index
	return -1

static func _fail(profile: Dictionary, error: String) -> Dictionary:
	return {"ok":false,"profile":profile,"error":error}
