extends Node

var failures: Array[String] = []

func require(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var fresh := ProfileRules.new_profile()
	require(int(fresh.schema_version) == Catalog.SCHEMA_VERSION, "new profile uses current schema")
	require(int(fresh.coins) == 180 and fresh.blueprints.is_empty() and fresh.creatures.is_empty() and fresh.team.is_empty(), "new profile begins with coins only and no starter inventory")
	require(OnboardingState.screen_for_profile(fresh) == "onboarding", "new profile routes to onboarding")
	require(not OnboardingState.can_confirm(fresh, "mossmunk") and OnboardingState.can_confirm(fresh, "cinderpaw"), "onboarding confirmation accepts only Forge Trio choices")
	var selected := ProfileRules.choose_starter(fresh, "aquafin")
	require(bool(selected.ok), "valid starter selection succeeds")
	var chosen: Dictionary = selected.profile
	require(ProfileRules.has_starter(chosen) and str(chosen.onboarding.starter_id) == "aquafin", "starter selection completes onboarding")
	require(chosen.blueprints.size() == 1 and str(chosen.blueprints[0]) == "aquafin" and chosen.creatures.size() == 1 and chosen.team.size() == 1, "starter selection grants exactly one blueprint, bound instance, and training team")
	var instance: Dictionary = chosen.creatures[0]
	require(bool(instance.bound) and not bool(instance.tradable) and str(instance.source) == "starter", "starter instance is permanently bound and nontradable")
	var second := ProfileRules.choose_starter(chosen, "voltwig")
	require(not bool(second.ok) and second.profile.creatures.size() == 1, "starter selection refuses later changes and duplicate grants")
	# Migration is intentionally limited to clean/current-shape saves for this
	# checkpoint. Older piece-equipment saves are deferred rather than revived.
	var legacy := {"schema_version":1,"catalog_version":"0.1.0","revision":9,"coins":320,"spool_level":4,"blueprints":["cinderpaw","aquafin"],"creatures":[{"instance_id":"old-cinder","creature_id":"cinderpaw","suit_instance_id":""},{"instance_id":"old-aqua","creature_id":"aquafin","suit_instance_id":""}],"team":["old-aqua"],"suits":[],"cores":[],"discovered":["cinderpaw","aquafin"]}
	var migrated := ProfileRules.migrate(legacy)
	require(int(migrated.schema_version) == Catalog.SCHEMA_VERSION and int(migrated.coins) == 320 and migrated.creatures.size() == 2 and migrated.suits.is_empty() and migrated.cores.is_empty(), "schema-one migration preserves current inventory and progression")
	require(ProfileRules.has_starter(migrated) and str(migrated.onboarding.starter_id) == "aquafin", "legacy migration completes onboarding without extra grant")
	require(OnboardingState.screen_for_profile(migrated) == "workshop", "migrated profile routes to workshop")
	var repairable: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	var starter_instance: Dictionary = repairable.creatures[0]
	starter_instance.erase("creature_id")
	starter_instance.species_id = "cinderpaw"
	repairable.team = ["cinderpaw", "missing", "cinderpaw", "extra"]
	repairable.onboarding.starter_instance_id = ""
	var repaired := ProfileRules.migrate(repairable)
	var repaired_loadout := ProfileRules.team_loadout(repaired)
	require(str(repaired.creatures[0].creature_id) == "cinderpaw" and str(repaired.onboarding.starter_instance_id) == str(starter_instance.instance_id) and repaired.team == [str(starter_instance.instance_id)] and repaired_loadout.size() == 1 and str(repaired_loadout[0].creature_id) == "cinderpaw", "current-schema integrity repair restores a uniquely provable starter alias and deduplicated team")
	require(ProfileRules.migrate(repaired) == repaired, "current-schema integrity repair is idempotent")
	var irreparable := ProfileRules.new_profile()
	irreparable.onboarding = {"state":"complete", "starter_id":"not_a_catalog_creature", "starter_instance_id":"bad"}
	irreparable.creatures = [{"instance_id":"bad", "creature_id":"not_a_catalog_creature"}]
	irreparable.team = ["bad"]
	var blocked := ProfileRules.migrate(irreparable)
	require(ProfileRules.team_loadout(blocked).is_empty() and blocked.team.is_empty(), "irreparable current-schema ownership is safely blocked without invented inventory")
	if failures.is_empty(): print("PASS: profile schema migration, starter permanence, and onboarding UI state")
	call_deferred("_finish")

func _finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
