extends Node

const CAMPAIGN_RULES := preload("res://scripts/core/campaign_rules.gd")
const SAVE_ROOT := "E:/CodexCache/printforge-validation/campaign-rules-reload-isolated"
const SAVE_FILES: Array[String] = ["profile.json", "profile.tmp.json", "profile.backup.json", "profile.backup.tmp.json", "journal.jsonl"]

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	require(Catalog.WORKSHOP_TRIAL_TIERS.size() == 5, "five Workshop Trial tiers are authored")
	var encounter_total := 0
	for tier in Catalog.WORKSHOP_TRIAL_TIERS:
		var encounters: Array = tier.get("encounters", [])
		require(encounters.size() == 4 and bool(encounters[3].get("boss", false)) and (encounters[3].get("team", []) as Array).size() == 3, "each tier has three normal encounters and a three-member boss")
		encounter_total += encounters.size()
		for encounter in encounters:
			for creature_id in encounter.get("team", []): require(not Catalog.creature(str(creature_id)).is_empty(), "trial rivals use existing catalog creatures")
	require(encounter_total == 20, "twenty authored Workshop Trial encounters exist")
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile["coins"] = 500
	var blueprint := ProgressionRules.purchase_creature_blueprint(profile, "mossmunk")
	profile = blueprint["profile"]
	var printed := ProgressionRules.print_creature(profile, "mossmunk")
	profile = printed["profile"]
	var starter_id := str(profile["creatures"][0].get("instance_id", ""))
	var moss_id := str(profile["creatures"][1].get("instance_id", ""))
	profile["team"] = [starter_id, moss_id]
	profile["creature_mastery"] = {starter_id:3, "stale-instance":99}
	var migrated := ProfileRules.migrate(profile)
	require(int(migrated.get("schema_version", 0)) == Catalog.SCHEMA_VERSION and int(migrated.get("creature_mastery", {}).get(starter_id, 0)) == 3 and not migrated.get("creature_mastery", {}).has("stale-instance"), "current-schema migration preserves owned mastery and prunes only stale instance entries")
	var schema_four: Dictionary = profile.duplicate(true)
	schema_four["schema_version"] = 4
	schema_four.erase("solo_campaign")
	schema_four.erase("creature_mastery")
	var legacy_migrated := ProfileRules.migrate(schema_four)
	require(int(legacy_migrated.get("coins", 0)) == int(schema_four.get("coins", 0)) and legacy_migrated.get("creatures", []) == schema_four.get("creatures", []) and legacy_migrated.get("team", []) == schema_four.get("team", []) and legacy_migrated.get("solo_campaign", {}).has("unlocked_tier") and legacy_migrated.has("creature_mastery"), "schema-four migration adds campaign fields without losing inventory, team, or currency")
	var locked := CAMPAIGN_RULES.encounter_state(migrated, "first_layers_2")
	require(bool(locked.get("ok", false)) and not bool(locked.get("unlocked", true)), "encounters unlock sequentially within a tier")
	var first := CAMPAIGN_RULES.encounter_state(migrated, "first_layers_1")
	require(bool(first.get("unlocked", false)) and int(first.get("reward", {}).get("coins", 0)) == 30 and int(first.get("reward", {}).get("xp", 0)) == 25 and int(first.get("reward", {}).get("mastery", 0)) == 3, "tier-one normal reward curve is deterministic")
	var coins_before: int = int(migrated["coins"])
	var claimed := CAMPAIGN_RULES.claim_victory(migrated, "first_layers_1", 9)
	require(bool(claimed.get("ok", false)), "first clear claims atomically")
	var rewarded: Dictionary = claimed["profile"]
	require(int(rewarded["coins"]) == coins_before + 30 and int(rewarded.get("creature_mastery", {}).get(starter_id, 0)) == 6 and int(rewarded.get("creature_mastery", {}).get(moss_id, 0)) == 3, "first clear rewards coins and per-instance current-team mastery")
	var improved := CAMPAIGN_RULES.claim_victory(rewarded, "first_layers_1", 3)
	require(bool(improved.get("ok", false)) and not bool(improved.get("payload", {}).get("first_clear", true)) and bool(improved.get("payload", {}).get("best_improved", false)) and int(improved["profile"]["solo_campaign"]["best_turn_counts"]["first_layers_1"]) == 3 and int(improved["profile"]["coins"]) == int(rewarded["coins"]), "completed replay improves best turns without repeating rewards")
	var duplicate := CAMPAIGN_RULES.claim_victory(improved["profile"], "first_layers_1", 12)
	require(bool(duplicate.get("ok", false)) and not bool(duplicate.get("payload", {}).get("first_clear", true)) and not bool(duplicate.get("payload", {}).get("best_improved", true)) and int(duplicate["profile"]["coins"]) == int(rewarded["coins"]) and int(duplicate["profile"].get("creature_mastery", {}).get(starter_id, 0)) == 6, "equal or worse replay is a no-op with duplicate reward immunity")
	var chain: Dictionary = rewarded
	for encounter_id in ["first_layers_2", "first_layers_3", "first_layers_boss"]:
		var result := CAMPAIGN_RULES.claim_victory(chain, encounter_id, 8)
		require(bool(result.get("ok", false)), "sequential first-tier encounter %s claims" % encounter_id)
		chain = result["profile"]
	require(int(chain.get("solo_campaign", {}).get("unlocked_tier", 0)) == 2, "boss claim unlocks exactly the next tier")
	var boss_reward := CAMPAIGN_RULES.reward_for(Catalog.workshop_trial_encounter("first_layers_boss"))
	require(int(boss_reward.get("coins", 0)) == 80 and int(boss_reward.get("xp", 0)) == 50 and int(boss_reward.get("mastery", 0)) == 7, "boss reward curve is deterministic")
	var boss := Catalog.workshop_trial_encounter("first_layers_boss")
	var battle := BattleState.create(ProfileRules.team_loadout(chain), boss.get("team", []), 3, int(boss.get("spool", 3)), 12, ProgressionRules.active_deck(chain))
	require(battle.validation_error(true).is_empty() and battle.players[1].team.size() == 3, "trial battle uses the authored boss team and spool")
	DirAccess.make_dir_recursive_absolute(SAVE_ROOT)
	for filename in SAVE_FILES:
		var path := SAVE_ROOT.path_join(filename)
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	SaveService.configure_test_paths(SAVE_ROOT)
	SaveService.commit_snapshot(chain)
	var reloaded := SaveService.load_profile()
	require(reloaded.get("team", []) == chain.get("team", []) and "first_layers_boss" in reloaded.get("solo_campaign", {}).get("completed_encounter_ids", []) and "first_layers_boss" in reloaded.get("solo_campaign", {}).get("claimed_reward_ids", []) and int(reloaded.get("creature_mastery", {}).get(starter_id, 0)) == int(chain.get("creature_mastery", {}).get(starter_id, -1)) and int(reloaded.get("creature_mastery", {}).get(moss_id, 0)) == int(chain.get("creature_mastery", {}).get(moss_id, -1)), "campaign save reload preserves team, completion, claimed rewards, and per-instance mastery")
	SaveService.reset_paths()
	if failures.is_empty(): print("PASS: Workshop Trial campaign unlocks, rewards, mastery, and authored teams")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
