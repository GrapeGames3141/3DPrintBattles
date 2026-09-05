extends Node

## Affected 0.8.7 saves became unusable because its package validation rejected
## an imported card front.  These canonical pre-existing Founder snapshots prove
## the export repair only restores valid catalog access: it must not normalize,
## regrant, repair, or persist an interrupted player journey on load.

const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []
var configured_root := ""
var original_profile: Dictionary = {}
var original_compatibility: Dictionary = {}

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	await _run()

func _founder_selected() -> Dictionary:
	return RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile

func _founder_printed() -> Dictionary:
	return RULES.print_starter(_founder_selected()).profile

func _founder_partials() -> Array:
	var states: Array = []
	var profile := _founder_printed()
	states.append({"name":"printed", "profile":profile.duplicate(true)})
	for receipt_index in 3:
		var opened := RULES.claim_next_starter_pack(profile, PackedByteArray(), "workshop", {"caller":"workshop"})
		if not bool(opened.get("ok", false)):
			break
		profile = opened.profile
		states.append({"name":"opened_%d_pending" % (receipt_index + 1), "profile":profile.duplicate(true)})
		var kept := RULES.clear_pack_reveal(profile)
		if not bool(kept.get("ok", false)):
			break
		profile = kept.profile
		states.append({"name":"opened_%d_kept" % (receipt_index + 1), "profile":profile.duplicate(true)})
	return states

func _customized_complete() -> Dictionary:
	var profile := RULES.new_profile()
	profile = _founder_selected()
	profile = RULES.print_starter(profile).profile
	for _receipt in 3:
		var opened := RULES.claim_next_starter_pack(profile)
		profile = RULES.clear_pack_reveal(opened.profile).profile
	var deck := RULES.active_deck(profile)
	var saved := RULES.save_deck(profile, deck, "deck-slot-2")
	profile = saved.profile
	RULES.grant_card(profile, "mossmunk")
	profile["preprints"] = ["cinderpaw"]
	return profile

func _snapshot(path: String) -> Dictionary:
	return {"exists":FileAccess.file_exists(path), "bytes":FileAccess.get_file_as_bytes(path)}

func _same_snapshot(before: Dictionary, path: String) -> bool:
	return bool(before.get("exists", false)) == FileAccess.file_exists(path) and (before.get("bytes", PackedByteArray()) as PackedByteArray) == FileAccess.get_file_as_bytes(path)

func _json_values_equal(first: Variant, second: Variant) -> bool:
	var first_normalized: Variant = JSON.parse_string(JSON.stringify(first))
	var second_normalized: Variant = JSON.parse_string(JSON.stringify(second))
	return JSON.stringify(first if first_normalized == null else first_normalized) == JSON.stringify(second if second_normalized == null else second_normalized)

func _assert_load_preserves(case_name: String, source: Dictionary) -> void:
	var case_root := configured_root.path_join("deck-export-upgrade-" + case_name)
	var absolute := ProjectSettings.globalize_path(case_root)
	DirAccess.make_dir_recursive_absolute(absolute)
	SaveService.configure_test_paths(case_root)
	GameManager.save_compatibility = {"compatible":true, "state":"ready"}
	GameManager.profile = source.duplicate(true)
	require(SaveService.commit_snapshot(GameManager.profile), "%s fixture writes its isolated pre-upgrade snapshot." % case_name)
	var profile_before := _snapshot(SaveService.profile_path)
	var backup_before := _snapshot(SaveService.profile_backup_path)
	var journal_before := _snapshot(SaveService.journal_path)
	var loaded := SaveService.load_profile()
	require(_json_values_equal(loaded, source), "%s reload reads the exact canonical interrupted/complete Founder JSON values." % case_name)
	GameManager._initialize_loaded_profile(loaded)
	require(GameManager.save_compatibility.get("state", "") == "ready" and _json_values_equal(GameManager.profile, source) and _same_snapshot(profile_before, SaveService.profile_path) and _same_snapshot(backup_before, SaveService.profile_backup_path) and _same_snapshot(journal_before, SaveService.journal_path), "%s valid catalog startup preserves profile JSON values, snapshot bytes, backup, and journal without migration or writes." % case_name)

func _assert_semantic_migration_persists() -> void:
	var case_root := configured_root.path_join("deck-export-upgrade-semantic-migration")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(case_root))
	SaveService.configure_test_paths(case_root)
	var source := _founder_selected()
	source.erase("spool_level")
	GameManager.profile = source.duplicate(true)
	require(SaveService.commit_snapshot(GameManager.profile), "Semantic migration fixture writes its isolated old-shape snapshot.")
	var profile_before := _snapshot(SaveService.profile_path)
	var loaded := SaveService.load_profile()
	GameManager._initialize_loaded_profile(loaded)
	require(int(GameManager.profile.get("spool_level", 0)) == 1 and not _same_snapshot(profile_before, SaveService.profile_path) and _same_snapshot(profile_before, SaveService.profile_backup_path), "A real missing-field migration publishes canonical spool level and persists exactly the semantic JSON change with the old snapshot preserved as backup.")

func _run() -> void:
	configured_root = SaveService.profile_path.get_base_dir().replace("\\", "/")
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	if not configured_root.begins_with(evidence_root + "/"):
		require(false, "Deck export upgrade fixtures require the pre-autoload E: QA root before writing saved-profile cases.")
		_finish()
		return
	original_profile = GameManager.profile.duplicate(true)
	original_compatibility = GameManager.save_compatibility.duplicate(true)
	_assert_load_preserves("starter_selected", _founder_selected())
	for entry_variant in _founder_partials():
		var entry: Dictionary = entry_variant
		_assert_load_preserves(str(entry.get("name", "partial")), entry.get("profile", {}) as Dictionary)
	_assert_load_preserves("complete_custom_slot", _customized_complete())
	_assert_semantic_migration_persists()
	_finish()

func _finish() -> void:
	if not configured_root.is_empty():
		SaveService.configure_test_paths(configured_root)
	GameManager.profile = original_profile
	GameManager.save_compatibility = original_compatibility
	if failures.is_empty():
		print("PASS: deck export upgrade Founder snapshots preserve exactly on valid-catalog load")
	get_tree().quit(0 if failures.is_empty() else 1)
