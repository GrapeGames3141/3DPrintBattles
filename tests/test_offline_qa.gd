extends Node
## Deterministic compatibility, offline-combat, and desktop asset-budget evidence.

const MAIN := preload("res://scenes/main.tscn")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	test_schema_compatibility()
	await test_read_only_ui()
	test_presenters()
	test_deterministic_simulation()
	test_asset_budget()
	if failures.is_empty(): print("PASS: offline save compatibility, presenters, deterministic simulation, and asset budget")
	call_deferred("finish")

func test_schema_compatibility() -> void:
	for version in range(1, Catalog.SCHEMA_VERSION + 1):
		var fixture := representative_profile(version)
		var migrated := ProfileRules.migrate(fixture)
		require(int(migrated.get("schema_version", 0)) == Catalog.SCHEMA_VERSION, "schema %d migrates to the supported checkpoint" % version)
		require(int(migrated.get("coins", 0)) == 321 and str(migrated.get("team", [""])[0]) == "legacy-cinder" and migrated.get("creatures", []).size() == 1, "schema %d preserves representative currency, inventory, and team" % version)
		require(migrated.has("suits") and migrated.has("cores"), "schema %d supplies current suit/Core containers" % version)
		var active_cards := ProgressionRules.active_deck(migrated)
		require(active_cards.size() == 15 and str(migrated.get("active_deck_id", "")) == ProgressionRules.STARTER_DECK_ID, "schema %d has a legal active deck after migration" % version)
		require(int(migrated.get("settings", {}).get("text_scale_bps", 0)) in AccessibilityRules.TEXT_SCALES and migrated.get("settings", {}).has("master_bps"), "schema %d preserves or supplies valid accessibility/audio settings" % version)
		require(migrated.get("solo_campaign", {}).has("unlocked_tier") and migrated.get("solo_campaign", {}).has("best_turn_counts"), "schema %d has a valid campaign state" % version)
		var expected_mastery: int = 7 if version >= 5 else 0
		require(int(migrated.get("creature_mastery", {}).get("legacy-cinder", 0)) == expected_mastery, "schema %d preserves available mastery and defaults absent mastery" % version)
		var expected_prints: int = 3 if version >= 6 else 1
		require(int(migrated.get("print_history", {}).get("creatures", {}).get("cinderpaw", 0)) == expected_prints, "schema %d preserves creature print history" % version)
		if version >= 6:
			require(str(migrated.get("shop", {}).get("day_key", "")) == "2026-08-14" and int(migrated.get("daily_job_count", 0)) == 2, "schema %d preserves shop and daily-job metadata" % version)
		require(ProfileRules.migrate(migrated) == migrated, "schema %d migration is idempotent" % version)
	var future := representative_profile(Catalog.SCHEMA_VERSION + 5)
	future["future_only"] = {"keep":true}
	var compatibility := ProfileRules.compatibility(future)
	require(not bool(compatibility.get("compatible", true)) and str(compatibility.get("state", "")) == "future_schema", "future schema receives explicit compatibility block")
	require(ProfileRules.migrate(future) == future, "future schema is never migrated or downgraded")
	var root := "E:/CodexCache/printforge-offline-qa-test-save"
	DirAccess.make_dir_recursive_absolute(root)
	for path in [root.path_join("profile.json"), root.path_join("profile.tmp.json"), root.path_join("profile.backup.json"), root.path_join("profile.backup.tmp.json"), root.path_join("journal.jsonl")]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	var prior_profile := GameManager.profile.duplicate(true)
	var prior_status := GameManager.save_compatibility.duplicate(true)
	SaveService.configure_test_paths(root)
	SaveService.commit_snapshot(future)
	var future_loaded := SaveService.load_profile()
	print("FUTURE_SAVE path=%s exists=%s" % [SaveService.profile_path, FileAccess.file_exists(SaveService.profile_path)])
	var before_bytes := FileAccess.get_file_as_string(SaveService.profile_path)
	GameManager._initialize_loaded_profile(future_loaded)
	require(GameManager.is_save_read_only(), "GameManager starts future save in read-only mode")
	require(GameManager.profile == future_loaded and bool(GameManager.profile.get("future_only", {}).get("keep", false)), "GameManager preserves the loaded future save dictionary verbatim in memory")
	require(not GameManager.choose_starter("cinderpaw") and FileAccess.get_file_as_string(SaveService.profile_path) == before_bytes, "read-only future save refuses mutation without overwriting bytes")
	GameManager.profile = prior_profile
	GameManager.save_compatibility = prior_status
	SaveService.reset_paths()

func representative_profile(version: int) -> Dictionary:
	# The fixtures intentionally add fields only once that generation of local
	# profile could plausibly have written them. Earlier profiles exercise the
	# defaults/derivation path rather than masquerading as a current profile.
	var profile := {"schema_version":version, "catalog_version":"released", "revision":11, "coins":321, "xp":88, "spool_level":4, "blueprints":["cinderpaw"], "discovered":["cinderpaw"], "creatures":[{"instance_id":"legacy-cinder", "creature_id":"cinderpaw", "bound":true, "tradable":false, "source":"starter", "suit_instance_id":""}], "suits":[], "cores":[], "team":["legacy-cinder"]}
	if version >= 2:
		profile["onboarding"] = {"state":"complete", "starter_id":"cinderpaw", "starter_instance_id":"legacy-cinder"}
	if version >= 3:
		profile["support_cards"] = _starter_card_counts()
		profile["decks"] = [{"id":ProgressionRules.STARTER_DECK_ID, "name":"Starter Filament Deck", "cards":ProgressionRules.STARTER_DECK.duplicate()}]
		profile["active_deck_id"] = ProgressionRules.STARTER_DECK_ID
	if version >= 4:
		profile["settings"] = {"text_scale_bps":12500, "high_contrast":true, "reduced_motion":false, "ai_difficulty":"Master", "master_bps":2500, "music_bps":3500, "sfx_bps":5000}
	if version >= 5:
		profile["solo_campaign"] = {"unlocked_tier":2, "completed_encounter_ids":["first_layers_1"], "claimed_reward_ids":["first_layers_1"], "best_turn_counts":{"first_layers_1":8}}
		profile["creature_mastery"] = {"legacy-cinder":7, "stale":99}
	if version >= 6:
		profile["print_history"] = {"creatures":{"cinderpaw":3}, "suits":{"standard":2}, "cores":{}}
		profile["shop"] = {"day_key":"2026-08-14", "offers":[]}
		profile["daily_job_count"] = 2
		profile["last_job_day"] = "2026-08-14"
		profile["last_yard_day"] = "2026-08-14"
		profile["yard_choice"] = "field_practice"
	return profile

func _starter_card_counts() -> Dictionary:
	var counts := {}
	for card_id in ProgressionRules.STARTER_DECK: counts[card_id] = int(counts.get(card_id, 0)) + 1
	return counts

func test_read_only_ui() -> void:
	var prior_profile := GameManager.profile.duplicate(true)
	var prior_status := GameManager.save_compatibility.duplicate(true)
	GameManager.profile = representative_profile(Catalog.SCHEMA_VERSION + 1)
	GameManager.save_compatibility = ProfileRules.compatibility(GameManager.profile)
	var before_profile := GameManager.profile.duplicate(true)
	var before_revision := int(GameManager.profile.get("revision", -1))
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	var recovery := main.find_child("M3RecoveryLedger", true, false) as Control
	var title := main.find_child("RecoveryPlayerTitle", true, false) as Label
	var explanation := main.find_child("RecoveryPlayerExplanation", true, false) as Label
	var protection := main.find_child("RecoveryProtectionIndicator", true, false) as Label
	var ceremony_found := false
	for candidate in main.find_children("*", "Label", true, false):
		if (candidate as Label).text.contains("AWAKENING CEREMONY"): ceremony_found = true
	var forbidden_actions := ["TitleContinue", "TitleNewMaker", "TitleSettings", "TitleConfirmNewMaker", "TitleCancelNewMaker", "RecoveryBack"]
	var no_navigation := true
	for action_name in forbidden_actions:
		no_navigation = no_navigation and main.find_child(action_name, true, false) == null
	require(recovery != null and title != null and title.text == "NEWER WORKSHOP RECORD" and explanation != null and explanation.text.to_lower().contains("newer printforge") and explanation.text.to_lower().contains("update") and protection != null and protection.text.contains("READ-ONLY") and not ceremony_found and no_navigation and main.find_child("WorkshopFullBleed", true, false) == null and GameManager.profile == before_profile and int(GameManager.profile.get("revision", -1)) == before_revision, "future-save uses the truthful physical recovery ledger with newer-version/read-only copy, no onboarding or navigation actions, no Workshop route, and zero mutation")
	main.queue_free()
	GameManager.profile = prior_profile
	GameManager.save_compatibility = prior_status

func test_presenters() -> void:
	var heal := {"effect":"heal", "amount":6}
	var debuff := {"effect":"debuff", "amount":2}
	require(SupportCardPresenter.effect_text(heal) == "Restore 6 HP" and SupportCardPresenter.target_text(heal) == "Your active print" and SupportCardPresenter.target_text(debuff) == "Foe active print", "support-card presenter gives catalog effect and target text")
	var state := BattleState.create(["cinderpaw"], ["mossmunk"], 3, 3, 2)
	var feedback := BattleFeedbackPresenter.format(state, "attack", "Impact: battle action resolved.")
	require(feedback.contains("Outcome: Attack") and feedback.contains("Cue: battle action resolved."), "battle-feedback presenter preserves explicit outcome and caption")

func test_deterministic_simulation() -> void:
	var first := simulate_roster()
	var second := simulate_roster()
	require(first == second, "same deterministic offline simulation seed and catalog order reproduce aggregate results")
	require(int(first.get("matches", 0)) == Catalog.CREATURES.size() * 3 and int(first.get("legal_actions", 0)) > 0 and int(first.get("terminated", 0)) == int(first.get("matches", 0)) and int(first.get("attacks", 0)) > 0 and int(first.get("abilities", 0)) > 0, "simulation covers all catalog creatures and all AI difficulties with bounded legal attacks and signatures")
	print("OFFLINE_SIM %s" % JSON.stringify(first))

func simulate_roster() -> Dictionary:
	var totals := {"matches":0, "terminated":0, "turns":0, "legal_actions":0, "attacks":0, "abilities":0, "cards":0, "player_wins":0, "rival_wins":0, "min_turns":9999, "max_turns":0, "by_difficulty":{}}
	var difficulties := ["Apprentice", "Craftsman", "Master"]
	for index in Catalog.CREATURES.size():
		var player_id := str(Catalog.CREATURES[index].id)
		var rival_id := str(Catalog.CREATURES[(index + 7) % Catalog.CREATURES.size()].id)
		for difficulty in difficulties:
			if not totals.by_difficulty.has(difficulty): totals.by_difficulty[difficulty] = {"matches":0, "player_wins":0, "rival_wins":0, "turns":0, "min_turns":9999, "max_turns":0, "attacks":0, "abilities":0, "cards":0}
			var difficulty_stats: Dictionary = totals.by_difficulty[difficulty]
			var state := BattleState.create([player_id], [rival_id], 6, 6, 200 + index)
			var steps := 0
			while not state.finished and steps < 140:
				var intent: Dictionary = _player_intent(state) if state.active_player == 0 else AIOpponent.choose_intent(state, difficulty)
				var result := BattleRules.apply_intent(state, state.active_player, intent)
				require(bool(result.get("ok", false)), "%s %s emits a legal deterministic intent" % [player_id, difficulty])
				totals.legal_actions = int(totals.legal_actions) + 1
				var kind := str(intent.get("type", ""))
				if kind == "attack": totals.attacks = int(totals.attacks) + 1
				elif kind == "ability": totals.abilities = int(totals.abilities) + 1
				elif kind == "card": totals.cards = int(totals.cards) + 1
				if kind == "attack": difficulty_stats.attacks = int(difficulty_stats.attacks) + 1
				elif kind == "ability": difficulty_stats.abilities = int(difficulty_stats.abilities) + 1
				elif kind == "card": difficulty_stats.cards = int(difficulty_stats.cards) + 1
				steps += 1
			totals.matches = int(totals.matches) + 1
			totals.turns = int(totals.turns) + steps
			totals.min_turns = mini(int(totals.min_turns), steps); totals.max_turns = maxi(int(totals.max_turns), steps)
			difficulty_stats.matches = int(difficulty_stats.matches) + 1; difficulty_stats.turns = int(difficulty_stats.turns) + steps; difficulty_stats.min_turns = mini(int(difficulty_stats.min_turns), steps); difficulty_stats.max_turns = maxi(int(difficulty_stats.max_turns), steps)
			if state.finished:
				totals.terminated = int(totals.terminated) + 1
				if state.winner == 0: totals.player_wins = int(totals.player_wins) + 1; difficulty_stats.player_wins = int(difficulty_stats.player_wins) + 1
				else: totals.rival_wins = int(totals.rival_wins) + 1; difficulty_stats.rival_wins = int(difficulty_stats.rival_wins) + 1
	for difficulty in difficulties:
		var stats: Dictionary = totals.by_difficulty[difficulty]
		stats["average_turns_bps"] = (int(stats.turns) * 10000) / maxi(1, int(stats.matches))
	totals["average_turns_bps"] = (int(totals.turns) * 10000) / maxi(1, int(totals.matches))
	return totals

func _player_intent(state: BattleState) -> Dictionary:
	if state.turn <= 2: return {"type":"end_turn"}
	var unit := state.active_unit(0)
	if int(state.players[0].get("filament", 0)) >= int(unit.get("ability_cost", 99)) and int(unit.get("cooldown_remaining", 0)) == 0 and not bool(unit.get("cooling", false)) and int(unit.get("ability_lock_turns", 0)) == 0:
		return {"type":"ability"}
	return {"type":"attack"}

func test_asset_budget() -> void:
	var decoded_bytes := 0
	var live_nodes := 0
	for definition in Catalog.CREATURES:
		for path in [str(definition.get("sprite_sheet", "")), str(definition.get("raw_print", ""))]:
			var texture := ResourceLoader.load(path) as Texture2D
			require(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "runtime asset loads for budget: %s" % path)
			if texture != null: decoded_bytes += texture.get_width() * texture.get_height() * 4
		live_nodes += 2
	# This intentionally generous decoded-source ceiling is a deterministic desktop
	# QA guard, not a wall-clock performance claim.
	require(decoded_bytes <= 360 * 1024 * 1024 and live_nodes == Catalog.CREATURES.size() * 2, "catalog art decoded budget stays within 360 MiB (%d bytes, %d source nodes)" % [decoded_bytes, live_nodes])
	print("ASSET_BUDGET decoded_bytes=%d source_nodes=%d budget_bytes=%d" % [decoded_bytes, live_nodes, 360 * 1024 * 1024])

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
