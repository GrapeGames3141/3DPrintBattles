class_name ProfileRules
extends RefCounted
## Pure profile transitions: safe to test without FileAccess or autoload state.

const STARTER_IDS: Array[String] = ["cinderpaw", "aquafin", "voltwig"]

static func new_profile() -> Dictionary:
	return {
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
	}

static func migrate(source: Dictionary) -> Dictionary:
	var profile: Dictionary = source.duplicate(true)
	var version: int = int(profile.get("schema_version", 1))
	if version >= Catalog.SCHEMA_VERSION:
		return profile
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
	return profile

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
