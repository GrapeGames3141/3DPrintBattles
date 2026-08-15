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
	var legacy := {"schema_version":1,"catalog_version":"0.1.0","revision":9,"coins":320,"spool_level":4,"blueprints":["cinderpaw","aquafin"],"creatures":[{"instance_id":"old-cinder","creature_id":"cinderpaw","armor_id":""},{"instance_id":"old-aqua","creature_id":"aquafin","armor_id":""}],"team":["old-aqua"],"armor":[{"armor_instance_id":"old-armor","armor_id":"helm","equipped_to":""}],"discovered":["cinderpaw","aquafin"]}
	var migrated := ProfileRules.migrate(legacy)
	require(int(migrated.schema_version) == Catalog.SCHEMA_VERSION and int(migrated.coins) == 320 and migrated.creatures.size() == 2 and migrated.armor.size() == 1, "schema-one migration preserves inventory and progression")
	require(ProfileRules.has_starter(migrated) and str(migrated.onboarding.starter_id) == "aquafin", "legacy migration completes onboarding without extra grant")
	require(OnboardingState.screen_for_profile(migrated) == "workshop", "migrated profile routes to workshop")
	if failures.is_empty(): print("PASS: profile schema migration, starter permanence, and onboarding UI state")
	call_deferred("_finish")

func _finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
