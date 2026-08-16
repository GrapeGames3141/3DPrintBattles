class_name ProfileRules
extends RefCounted

const CAMPAIGN_RULES := preload("res://scripts/core/campaign_rules.gd")
## Pure profile transitions: safe to test without FileAccess or autoload state.

const STARTER_IDS: Array[String] = ["cinderpaw", "aquafin", "voltwig"]

static func new_profile() -> Dictionary:
	return CAMPAIGN_RULES.ensure_fields(AccessibilityRules.ensure_fields(ProgressionRules.ensure_fields({
		"schema_version": Catalog.SCHEMA_VERSION,
		"catalog_version": Catalog.CATALOG_VERSION,
		"revision": 0,
		"next_instance_nonce": 1,
		"coins": 180,
		"xp": 0,
		"spool_level": 3,
		"blueprints": [],
		"creatures": [],
		"armor": [],
		"discovered": [],
		"team": [],
		"onboarding": {"state":"choose_starter", "starter_id":"", "starter_instance_id":""},
		"daily_job_count": 0,
		"last_job_day": "",
		"shop": {},
		"server_revision": 0
	})))

static func migrate(source: Dictionary) -> Dictionary:
	var profile: Dictionary = source.duplicate(true)
	if not profile.has("revision"): profile["revision"] = 0
	var version: int = int(profile.get("schema_version", 1))
	if version >= Catalog.SCHEMA_VERSION:
		profile = normalize_integrity(profile)
		# Signature definitions are catalog-only; preserve every saved ID/value while
		# recording that this local profile now resolves the current catalog version.
		profile["catalog_version"] = Catalog.CATALOG_VERSION
		return CAMPAIGN_RULES.ensure_fields(AccessibilityRules.ensure_fields(ProgressionRules.ensure_fields(profile, has_starter(profile))))
	# Schema 1 granted all three starters. Preserve every inventory record, then mark
	# the legacy account as already onboarded to prevent an extra starter grant.
	if version <= 1:
		if not profile.has("next_instance_nonce"): profile.next_instance_nonce = 1
		if not profile.has("blueprints"): profile.blueprints = []
		if not profile.has("creatures"): profile.creatures = []
		if not profile.has("team"): profile.team = []
		var selected_id := _legacy_starter_id(profile)
		var selected_instance := _legacy_starter_instance(profile, selected_id)
		if not selected_instance.is_empty():
			selected_instance.bound = true
			selected_instance.tradable = false
			selected_instance.source = "starter"
		profile.onboarding = {"state":"complete", "starter_id":selected_id, "starter_instance_id":str(selected_instance.get("instance_id", ""))}
	profile.schema_version = Catalog.SCHEMA_VERSION
	profile.catalog_version = Catalog.CATALOG_VERSION
	profile = normalize_integrity(profile)
	return CAMPAIGN_RULES.ensure_fields(AccessibilityRules.ensure_fields(ProgressionRules.ensure_fields(profile, has_starter(profile))))

## Current-schema saves can still contain interrupted or hand-edited local data.
## This pass is deliberately conservative: it preserves catalog-valid records,
## repairs aliases only when their target is unambiguous, and never grants a
## creature that is not already represented by an owned instance.
static func normalize_integrity(source: Dictionary) -> Dictionary:
	var profile: Dictionary = source.duplicate(true)
	# Bracket writes intentionally handle partial current-schema dictionaries:
	# property syntax reads an absent key before it can establish it.
	if not profile.has("creatures") or not profile.get("creatures") is Array: profile["creatures"] = []
	if not profile.has("team") or not profile.get("team") is Array: profile["team"] = []
	if not profile.has("blueprints") or not profile.get("blueprints") is Array: profile["blueprints"] = []
	if not profile.has("discovered") or not profile.get("discovered") is Array: profile["discovered"] = []
	var cleaned_creatures: Array = []
	var seen_instances := {}
	var by_species := {}
	for raw in profile["creatures"]:
		if not raw is Dictionary: continue
		var creature: Dictionary = raw.duplicate(true)
		var creature_id := str(creature.get("creature_id", ""))
		if Catalog.creature(creature_id).is_empty():
			# `id` is accepted here only as a species alias. It is deliberately
			# never used as an instance alias below, avoiding an ID ambiguity.
			for alias_key in ["species_id", "creature", "species", "id"]:
				var alias_id := str(creature.get(alias_key, ""))
				if not Catalog.creature(alias_id).is_empty():
					creature_id = alias_id
					break
		if Catalog.creature(creature_id).is_empty(): continue
		var instance_id := str(creature.get("instance_id", ""))
		if instance_id.is_empty():
			for alias_key in ["instance", "uid", "instance_key"]:
				var alias_instance := str(creature.get(alias_key, ""))
				if not alias_instance.is_empty():
					instance_id = alias_instance
					break
		if instance_id.is_empty() or seen_instances.has(instance_id): continue
		creature["instance_id"] = instance_id
		creature["creature_id"] = creature_id
		seen_instances[instance_id] = true
		cleaned_creatures.append(creature)
		if not by_species.has(creature_id): by_species[creature_id] = []
		by_species[creature_id].append(instance_id)
	profile["creatures"] = cleaned_creatures
	var onboarding: Dictionary = profile.get("onboarding", {}) if profile.get("onboarding", {}) is Dictionary else {}
	var starter_id := str(onboarding.get("starter_id", ""))
	if not starter_id in STARTER_IDS: starter_id = ""
	var starter_instance_id := str(onboarding.get("starter_instance_id", ""))
	var starter_instance_species := ""
	for creature in cleaned_creatures:
		if str(creature.get("instance_id", "")) == starter_instance_id:
			starter_instance_species = str(creature.get("creature_id", ""))
			break
	if not seen_instances.has(starter_instance_id) or (not starter_id.is_empty() and starter_instance_species != starter_id):
		starter_instance_id = ""
	if starter_id.is_empty() and starter_instance_species in STARTER_IDS:
		starter_id = starter_instance_species
	if starter_id.is_empty() or starter_instance_id.is_empty():
		for creature in cleaned_creatures:
			var candidate_id := str(creature.get("creature_id", ""))
			if candidate_id not in STARTER_IDS: continue
			if starter_id.is_empty() and (bool(creature.get("bound", false)) or str(creature.get("source", "")) == "starter"):
				starter_id = candidate_id
			if candidate_id == starter_id and starter_instance_id.is_empty() and (bool(creature.get("bound", false)) or str(creature.get("source", "")) == "starter" or (by_species.get(candidate_id, []) as Array).size() == 1):
				starter_instance_id = str(creature.get("instance_id", ""))
				break
	if not starter_id.is_empty() and not starter_instance_id.is_empty():
		onboarding["state"] = "complete"
		onboarding["starter_id"] = starter_id
		onboarding["starter_instance_id"] = starter_instance_id
		if not starter_id in profile["blueprints"]: profile["blueprints"].append(starter_id)
		if not starter_id in profile["discovered"]: profile["discovered"].append(starter_id)
	else:
		onboarding["state"] = str(onboarding.get("state", "choose_starter"))
		onboarding["starter_id"] = starter_id
		onboarding["starter_instance_id"] = ""
	profile["onboarding"] = onboarding
	var cleaned_team: Array = []
	var seen_team := {}
	for raw_ref in profile["team"]:
		var reference := str(raw_ref.get("instance_id", raw_ref.get("id", ""))) if raw_ref is Dictionary else str(raw_ref)
		if not seen_instances.has(reference):
			var candidates: Array = by_species.get(reference, [])
			if candidates.size() == 1: reference = str(candidates[0])
		if seen_instances.has(reference) and not seen_team.has(reference) and cleaned_team.size() < 3:
			seen_team[reference] = true
			cleaned_team.append(reference)
	if cleaned_team.is_empty() and not starter_instance_id.is_empty(): cleaned_team.append(starter_instance_id)
	profile["team"] = cleaned_team
	profile["schema_version"] = Catalog.SCHEMA_VERSION
	profile["catalog_version"] = Catalog.CATALOG_VERSION
	return profile

static func team_loadout(source: Dictionary) -> Array:
	var profile := normalize_integrity(source)
	var by_instance := {}
	for creature in profile.get("creatures", []):
		if creature is Dictionary: by_instance[str(creature.get("instance_id", ""))] = creature
	var result: Array = []
	for instance_id in profile.get("team", []):
		var creature = by_instance.get(str(instance_id), {})
		if not creature is Dictionary: continue
		var creature_id := str(creature.get("creature_id", ""))
		if Catalog.creature(creature_id).is_empty(): continue
		result.append({"creature_id":creature_id, "armor_id":str(creature.get("armor_id", ""))})
	return result

static func choose_starter(source: Dictionary, creature_id: String) -> Dictionary:
	var profile := migrate(source)
	if str(profile.get("onboarding", {}).get("state", "choose_starter")) == "complete":
		return {"ok":false, "error":"Your starter is already permanently chosen.", "profile":profile}
	if not creature_id in STARTER_IDS:
		return {"ok":false, "error":"Choose one of the three Forge Trio starters.", "profile":profile}
	var definition := Catalog.creature(creature_id)
	if definition.is_empty():
		return {"ok":false, "error":"Starter definition is unavailable.", "profile":profile}
	var nonce: int = int(profile.get("next_instance_nonce", 1))
	var instance_id := "starter-%s-%d" % [creature_id, nonce]
	profile.next_instance_nonce = nonce + 1
	if not creature_id in profile.blueprints: profile.blueprints.append(creature_id)
	if not creature_id in profile.discovered: profile.discovered.append(creature_id)
	profile.creatures.append({"instance_id":instance_id, "creature_id":creature_id, "armor_id":"", "bound":true, "tradable":false, "source":"starter"})
	profile.team = [instance_id]
	profile.onboarding = {"state":"complete", "starter_id":creature_id, "starter_instance_id":instance_id}
	profile = CAMPAIGN_RULES.ensure_fields(AccessibilityRules.ensure_fields(ProgressionRules.ensure_fields(profile, true)))
	profile.schema_version = Catalog.SCHEMA_VERSION
	profile.catalog_version = Catalog.CATALOG_VERSION
	return {"ok":true, "profile":profile, "instance_id":instance_id}

static func has_starter(profile: Dictionary) -> bool:
	return str(profile.get("onboarding", {}).get("state", "")) == "complete" and not str(profile.get("onboarding", {}).get("starter_instance_id", "")).is_empty()

static func _legacy_starter_id(profile: Dictionary) -> String:
	for instance_id in profile.get("team", []):
		for creature in profile.get("creatures", []):
			if str(creature.get("instance_id", "")) == str(instance_id) and str(creature.get("creature_id", "")) in STARTER_IDS:
				return str(creature.creature_id)
	for creature in profile.get("creatures", []):
		if str(creature.get("creature_id", "")) in STARTER_IDS: return str(creature.creature_id)
	return "cinderpaw"

static func _legacy_starter_instance(profile: Dictionary, starter_id: String) -> Dictionary:
	for creature in profile.get("creatures", []):
		if str(creature.get("creature_id", "")) == starter_id: return creature
	return {}
