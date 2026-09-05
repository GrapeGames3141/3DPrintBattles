extends Node

## Simulate a profile written while the affected package exposed no catalog
## cards: progression/decks/receipts exist, but card ownership and printable
## licenses did not.  This is a rule-only upgrade matrix; it must never invent
## currency or duplicate an already recorded Founder receipt.

const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []
var configured_root := ""
var original_profile: Dictionary = {}
var original_compatibility: Dictionary = {}

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _selected() -> Dictionary:
	return RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile

func _printed() -> Dictionary:
	return RULES.print_starter(_selected()).profile

func _opened_and_kept(count: int) -> Dictionary:
	var profile := _printed()
	for _index in count:
		var opened := RULES.claim_next_starter_pack(profile)
		if not bool(opened.get("ok", false)):
			return profile
		var kept := RULES.clear_pack_reveal(opened.profile)
		if not bool(kept.get("ok", false)):
			return profile
		profile = kept.profile
	return profile

func _strip_catalog_grants(source: Dictionary) -> Dictionary:
	var profile := source.duplicate(true)
	profile["owned_cards"] = {}
	profile["owned_blueprints"] = {}
	profile["forge_coins"] = 777
	return profile

func _resume_founder(profile: Dictionary) -> Dictionary:
	var resumed := RULES.ensure(profile)
	if str(resumed.get("onboarding", {}).get("state", "")) == "starter_selected":
		var printed := RULES.print_starter(resumed)
		if not bool(printed.get("ok", false)):
			return resumed
		resumed = printed.profile
	while int(resumed.get("starter_pack_rewards", {}).get("kept", 0)) < 3:
		var pending: Dictionary = resumed.get("pending_pack_reveal", {})
		if not pending.is_empty():
			var kept := RULES.clear_pack_reveal(resumed)
			if not bool(kept.get("ok", false)):
				return resumed
			resumed = kept.profile
			continue
		var opened := RULES.claim_next_starter_pack(resumed)
		if not bool(opened.get("ok", false)):
			return resumed
		resumed = opened.profile
	return resumed

func _protected_signature(profile: Dictionary) -> Dictionary:
	return {"forge_coins":int(profile.get("forge_coins", 0)), "claim_receipts":(profile.get("claim_receipts", {}) as Dictionary).duplicate(true), "decks":(profile.get("decks", []) as Array).duplicate(true), "active_deck_id":str(profile.get("active_deck_id", "")), "printed_models":(profile.get("printed_models", {}) as Dictionary).duplicate(true)}

func _other_slots(profile: Dictionary) -> Array:
	var slots: Array = []
	for deck_variant in profile.get("decks", []):
		if deck_variant is Dictionary and str((deck_variant as Dictionary).get("id", "")) != "starter-deck":
			slots.append((deck_variant as Dictionary).duplicate(true))
	return slots

func _record(case_name: String, check_name: String, value: bool, detail: String) -> bool:
	print("MISSING_GRANT_UPGRADE case=%s check=%s value=%s %s" % [case_name, check_name, value, detail])
	return value

func _assert_case(case_name: String, source: Dictionary) -> void:
	var stripped := _strip_catalog_grants(source)
	var protected_before := _protected_signature(stripped)
	var existing_receipts: Dictionary = (stripped.get("claim_receipts", {}) as Dictionary).duplicate(true)
	var other_slots_before := _other_slots(stripped)
	var resumed := _resume_founder(stripped)
	var active := RULES.active_deck(resumed)
	var rewards: Dictionary = resumed.get("starter_pack_rewards", {})
	var stable := RULES.ensure(resumed)
	var expected_models := int((stripped.get("printed_models", {}) as Dictionary).size()) + (1 if str(stripped.get("onboarding", {}).get("state", "")) == "starter_selected" else 0)
	var old_receipts_preserved := true
	for receipt_id in existing_receipts:
		old_receipts_preserved = old_receipts_preserved and bool((resumed.get("claim_receipts", {}) as Dictionary).get(receipt_id, false))
	var legal_before_restart := active.size() == 40 and RULES.deck_reason(resumed, active).is_empty()
	var legal_after_rule_ensure := RULES.deck_reason(stable, RULES.active_deck(stable)).is_empty()
	_record(case_name, "founder_complete", int(rewards.get("opened", 0)) == 3 and int(rewards.get("kept", 0)) == 3 and (resumed.get("pending_pack_reveal", {}) as Dictionary).is_empty(), "opened=%d kept=%d" % [int(rewards.get("opened", 0)), int(rewards.get("kept", 0))])
	_record(case_name, "legal_before_restart", legal_before_restart, "deck=%d reason=%s" % [active.size(), RULES.deck_reason(resumed, active)])
	_record(case_name, "legal_after_rule_ensure", legal_after_rule_ensure, "deck=%d reason=%s" % [RULES.active_deck(stable).size(), RULES.deck_reason(stable, RULES.active_deck(stable))])
	_record(case_name, "protected", int(resumed.get("forge_coins", -1)) == int(protected_before.get("forge_coins", -2)) and int((resumed.get("printed_models", {}) as Dictionary).size()) == expected_models and old_receipts_preserved and _other_slots(resumed) == other_slots_before, "coins=%d models=%d expected_models=%d" % [int(resumed.get("forge_coins", -1)), int((resumed.get("printed_models", {}) as Dictionary).size()), expected_models])
	require(int(rewards.get("opened", 0)) == 3 and int(rewards.get("kept", 0)) == 3 and (resumed.get("pending_pack_reveal", {}) as Dictionary).is_empty() and legal_before_restart and int(resumed.get("forge_coins", -1)) == int(protected_before.get("forge_coins", -2)) and int((resumed.get("printed_models", {}) as Dictionary).size()) == expected_models and old_receipts_preserved and _other_slots(resumed) == other_slots_before and JSON.stringify(stable) == JSON.stringify(resumed), "%s catalog-missing upgrade resumes Founder exactly once to a legal 40-card deck without changing coins, duplicating models, removing prior receipts, or replacing other slots." % case_name)

func _assert_game_manager_reload(case_name: String, source: Dictionary) -> void:
	var case_root := configured_root.path_join("missing-grant-game-manager-" + case_name)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(case_root))
	SaveService.configure_test_paths(case_root)
	GameManager.save_compatibility = {"compatible":true, "state":"ready"}
	GameManager.profile = _strip_catalog_grants(source)
	require(SaveService.commit_snapshot(GameManager.profile), "%s GameManager fixture writes the affected-profile shape." % case_name)
	GameManager._initialize_loaded_profile(SaveService.load_profile())
	if str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected":
		require(GameManager.print_selected_starter(), "%s GameManager uses the one legitimate First Print transition." % case_name)
	while int(GameManager.profile.get("starter_pack_rewards", {}).get("kept", 0)) < 3:
		var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {})
		var advanced: Dictionary = GameManager.claim_pending_pack_reveal_result() if not pending.is_empty() else GameManager.claim_next_starter_pack("workshop")
		if not bool(advanced.get("ok", false)):
			require(false, "%s GameManager cannot resume the next lawful Founder transaction: %s" % [case_name, str(advanced.get("error", ""))])
			return
	var after_final_keep := GameManager.profile.duplicate(true)
	var duplicate_keep := GameManager.claim_pending_pack_reveal_result()
	require(not bool(duplicate_keep.get("ok", false)) and JSON.stringify(GameManager.profile) == JSON.stringify(after_final_keep), "%s duplicate final Keep cannot regrant cards or mutate the completed Founder profile." % case_name)
	var before_restart := GameManager.profile.duplicate(true)
	var active_before := RULES.active_deck(before_restart)
	var reason_before := RULES.deck_reason(before_restart, active_before)
	GameManager._initialize_loaded_profile(SaveService.load_profile())
	var active_after := RULES.active_deck(GameManager.profile)
	var reason_after := RULES.deck_reason(GameManager.profile, active_after)
	_record(case_name, "game_manager_before_restart", reason_before.is_empty(), "deck=%d reason=%s" % [active_before.size(), reason_before])
	_record(case_name, "game_manager_after_restart", reason_after.is_empty(), "deck=%d reason=%s" % [active_after.size(), reason_after])
	require(reason_before.is_empty() and active_before.size() == 40 and reason_after.is_empty() and active_after.size() == 40, "%s final Keep immediately applies the existing completed-Founder deck repair and remains legal after real GameManager reload." % case_name)

func _assert_final_keep_storage_rejection() -> void:
	var case_root := configured_root.path_join("missing-grant-final-keep-rejection")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(case_root))
	SaveService.configure_test_paths(case_root)
	GameManager.save_compatibility = {"compatible":true, "state":"ready"}
	GameManager.profile = _strip_catalog_grants(_opened_and_kept(2))
	require(SaveService.commit_snapshot(GameManager.profile), "Final-Keep rejection fixture writes the affected two-Keep profile.")
	var opened := GameManager.claim_next_starter_pack("workshop")
	require(bool(opened.get("ok", false)) and not (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty(), "Final-Keep rejection fixture reaches the one pending final Founder receipt.")
	if not failures.is_empty():
		SaveService.configure_test_paths(configured_root)
		return
	var before_rejection := JSON.stringify(GameManager.profile)
	var before_revision := int(GameManager.profile.get("revision", 0))
	var blocked_root := configured_root.path_join("missing-grant-final-keep-blocked")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(configured_root))
	var blocker := FileAccess.open(ProjectSettings.globalize_path(blocked_root), FileAccess.WRITE)
	require(blocker != null, "Final-Keep rejection fixture creates its isolated storage blocker.")
	if blocker != null:
		blocker.store_string("Final Founder Keep persistence rejection seam")
		blocker.close()
	SaveService.configure_test_paths(blocked_root)
	var rejected := GameManager.claim_pending_pack_reveal_result()
	require(not bool(rejected.get("ok", false)) and not SaveService.last_commit_error.is_empty() and JSON.stringify(GameManager.profile) == before_rejection and int(GameManager.profile.get("revision", 0)) == before_revision, "Failed final Keep publishes no repaired ownership, revision, or duplicate Founder grant.")
	SaveService.configure_test_paths(configured_root)
	if FileAccess.file_exists(ProjectSettings.globalize_path(blocked_root)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(blocked_root))

func _ready() -> void:
	configured_root = SaveService.profile_path.get_base_dir().replace("\\", "/")
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	if not configured_root.begins_with(evidence_root + "/"):
		require(false, "Missing-grant upgrade matrix requires the pre-autoload E: QA root before GameManager save/reload coverage.")
		get_tree().quit(1)
		return
	original_profile = GameManager.profile.duplicate(true)
	original_compatibility = GameManager.save_compatibility.duplicate(true)
	_assert_case("starter_selected", _selected())
	_assert_case("one_kept_partial", _opened_and_kept(1))
	_assert_case("all_three_kept", _opened_and_kept(3))
	_assert_game_manager_reload("starter_selected", _selected())
	_assert_game_manager_reload("one_kept_partial", _opened_and_kept(1))
	_assert_final_keep_storage_rejection()
	SaveService.configure_test_paths(configured_root)
	GameManager.profile = original_profile
	GameManager.save_compatibility = original_compatibility
	if failures.is_empty():
		print("PASS: catalog-missing Founder upgrade snapshots resume to legal exact decks")
	get_tree().quit(0 if failures.is_empty() else 1)
