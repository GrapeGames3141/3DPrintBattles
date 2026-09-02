extends Node

## Repeated/stale Back calls are deliberately exercised against the real central
## dispatcher. None of these routes may turn an exit request into a save, grant,
## settlement, or a second Forge transition.
const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	await _run()
	if failures.is_empty(): print("PASS: M8 Back transaction atomicity")
	get_tree().quit(0 if failures.is_empty() else 1)

func _mount() -> Control:
	var view := SubViewport.new(); view.size = Vector2i(576, 1024); view.size_2d_override = Vector2i(576, 1024); view.size_2d_override_stretch = true; view.disable_3d = true; add_child(view)
	var canvas := Control.new(); canvas.size = Vector2(576, 1024); view.add_child(canvas)
	var main := MAIN.instantiate(); canvas.add_child(main); main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	return main

func _run() -> void:
	var selected: Dictionary = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	GameManager.profile = RULES.print_starter(selected).profile
	var main := await _mount()
	# Accepted Forge: the first Back pauses to caller, stale second Back must not
	# advance/cancel/commit the same authoritative sequence.
	main.screen = "workshop"; main.open_printer("cinderpaw"); main.begin_printer(); main.advance_printer_for_test(4200); await get_tree().process_frame
	var sequence: Variant = main.printer_sequence; var progress := int(main.printer_sequence.progress_bps)
	var accepted_profile := JSON.stringify(GameManager.profile)
	main.dispatch_back(); await get_tree().process_frame; main.dispatch_back(); await get_tree().process_frame
	require(main.printer_sequence == sequence and int(main.printer_sequence.progress_bps) == progress and JSON.stringify(GameManager.profile) == accepted_profile, "M8 repeated active Forge Back neither cancels nor completes/grants a second transaction.")
	# Exercise the production orientation rebuild path while an accepted job is
	# foregrounded. The same sequence object/generation must survive a real resize,
	# then a stale deferred presentation token must be ignored after route replacement.
	main.size = Vector2(720, 1280); main.notification(Control.NOTIFICATION_RESIZED); await get_tree().process_frame
	require(main.printer_sequence == sequence and int(main.printer_sequence.progress_bps) == progress, "M8 orientation rebuild during active Forge keeps the exact accepted job/progress without a partial commit.")
	main.screen = "workshop"; main.render(); main.call_deferred("_return_from_forge_idle"); await get_tree().process_frame
	require(main.screen == "workshop" and main.printer_sequence == sequence and int(main.printer_sequence.progress_bps) == progress and JSON.stringify(GameManager.profile) == accepted_profile, "M8 stale deferred Forge return after route replacement cannot cancel or duplicate the accepted job.")
	# Dirty Deck: second Android Back cancels the Stay docket rather than saving,
	# discarding, or silently leaving the draft.
	main.screen = "unified_deck"; main.m3_deck_loaded_slot_id = main.m3_deck_edit_slot_id; main.unified_deck_draft = ["cinderpaw"]; main.m3_saved_preprint_draft = []; main.unified_preprint_draft = []; main.m3_pending_deck_slot_id = "__back__"; main.render(); await get_tree().process_frame
	main.dispatch_back(); await get_tree().process_frame
	require(main.screen == "unified_deck" and main.m3_pending_deck_slot_id.is_empty() and main.unified_deck_draft == ["cinderpaw"] and JSON.stringify(GameManager.profile) == accepted_profile, "M8 dirty-deck Android Back means Stay with no persistence or draft loss.")
	# Market confirmation repeated cancellation remains local and has no purchase.
	main.screen = "unified_market"; main.m3_market_confirmation = {"category":"blueprints", "id":"mossmunk", "price":99}; main.render(); await get_tree().process_frame
	var market_profile := JSON.stringify(GameManager.profile)
	main.dispatch_back(); await get_tree().process_frame; main.dispatch_back(); await get_tree().process_frame
	require(main.screen == "workshop" and JSON.stringify(GameManager.profile) == market_profile, "M8 repeated Market Back only cancels the confirmation then exits; no purchase transaction occurs.")
	# Result error is stable, while a committed receipt exits exactly once.
	main.screen = "m3_result"; main.m3_result_state = "error"; main.dispatch_back(); await get_tree().process_frame
	require(main.screen == "m3_result" and JSON.stringify(GameManager.profile) == market_profile, "M8 error result Back cannot fabricate a settlement.")
	main.battle_mode = "training"; main.m3_result_state = "committed"; main.dispatch_back(); await get_tree().process_frame; main.dispatch_back(); await get_tree().process_frame
	require(main.screen == "workshop" and JSON.stringify(GameManager.profile) == market_profile, "M8 committed result repeated Back leaves once without duplicate settlement/grant.")
	# Exercise the real persistence boundary rather than a mock: a regular file
	# used as SaveService's parent makes the candidate temp snapshot unavailable.
	# A failed, repeated authority call must leave profile/revision untouched.
	var prior_profile: Dictionary = GameManager.profile.duplicate(true)
	var blocked_root := ProjectSettings.globalize_path("user://m8_atomicity_unavailable")
	DirAccess.make_dir_recursive_absolute(blocked_root)
	var blocker_path := blocked_root.path_join("not_a_directory")
	var blocker := FileAccess.open(blocker_path, FileAccess.WRITE)
	if blocker != null:
		blocker.store_string("M8 persistence rejection seam")
		blocker.close()
	SaveService.configure_test_paths(blocker_path)
	GameManager.profile = RULES.new_profile()
	var rejected_before := JSON.stringify(GameManager.profile)
	var first_rejected := GameManager.choose_starter("cinderpaw")
	# Resize at the real persistence boundary before the repeated call. The profile
	# candidate is still unpublished because SaveService rejects the snapshot.
	main.size = Vector2(576, 1024); main.notification(Control.NOTIFICATION_RESIZED); await get_tree().process_frame
	var second_rejected := GameManager.choose_starter("cinderpaw")
	require(not first_rejected and not second_rejected and not SaveService.last_commit_error.is_empty() and JSON.stringify(GameManager.profile) == rejected_before and int(GameManager.profile.get("revision", 0)) == 0, "M8 real unavailable-storage rejection leaves the candidate profile/revision unchanged across repeated authority calls.")
	SaveService.configure_unified_playtest_paths()
	GameManager.profile = prior_profile
	DirAccess.remove_absolute(blocker_path)
	DirAccess.remove_absolute(blocked_root)
	# Dirty deck Save is now a composed candidate transition: an invalid second
	# Pre-Print validation may not publish the otherwise-valid deck half.
	var active_cards: Array = []
	for deck in GameManager.profile.get("decks", []):
		if str(deck.get("id", "")) == str(GameManager.profile.get("active_deck_id", "starter-deck")):
			active_cards = (deck.get("cards", []) as Array).duplicate()
	var combined_before := JSON.stringify(GameManager.profile)
	var combined_revision := int(GameManager.profile.get("revision", 0))
	require(not GameManager.save_unified_deck_and_preprints(active_cards, ["raw_filament"], str(GameManager.profile.get("active_deck_id", "starter-deck"))) and JSON.stringify(GameManager.profile) == combined_before and int(GameManager.profile.get("revision", 0)) == combined_revision, "M8 dirty Deck Save rejects an invalid second Pre-Print validation atomically with no deck-first persistence.")
	# A second, independent unavailable-storage seam proves that a *fully valid*
	# composed candidate still cannot publish either half when its one snapshot fails.
	var combined_blocked_root := ProjectSettings.globalize_path("user://m8_combined_save_unavailable")
	DirAccess.make_dir_recursive_absolute(combined_blocked_root)
	var combined_blocker_path := combined_blocked_root.path_join("not_a_directory")
	var combined_blocker := FileAccess.open(combined_blocker_path, FileAccess.WRITE)
	if combined_blocker != null:
		combined_blocker.store_string("M8 valid combined save rejection seam")
		combined_blocker.close()
	SaveService.configure_test_paths(combined_blocker_path)
	var valid_before := JSON.stringify(GameManager.profile)
	var valid_revision := int(GameManager.profile.get("revision", 0))
	require(not GameManager.save_unified_deck_and_preprints(active_cards, [], str(GameManager.profile.get("active_deck_id", "starter-deck"))) and not SaveService.last_commit_error.is_empty() and JSON.stringify(GameManager.profile) == valid_before and int(GameManager.profile.get("revision", 0)) == valid_revision, "M8 valid combined Deck/Pre-Print candidate persistence rejection leaves profile and revision unchanged.")
	SaveService.configure_unified_playtest_paths()
	DirAccess.remove_absolute(combined_blocker_path)
	DirAccess.remove_absolute(combined_blocked_root)
	require(GameManager.save_unified_deck_and_preprints(active_cards, [], str(GameManager.profile.get("active_deck_id", "starter-deck"))) and int(GameManager.profile.get("revision", 0)) == combined_revision + 1, "M8 dirty Deck Save commits a legal deck and Pre-Print candidate exactly once.")
	# A genuine battle callback uses the coordinator generation token. Replacing the
	# route invalidates that token, so replaying the actual deferred continuation
	# cannot settle/grant a newer or absent battle.
	main.battle = preload("res://scripts/battle/unified_battle_state.gd").create(["cinderpaw"], ["aquafin"], 9)
	main.battle_mode = "trial_first_layers"; main.unified_battle_coordinator.configure(main.battle, 0)
	var stale_generation := int(main.unified_battle_coordinator.generation)
	var battle_before := var_to_str(main.battle.serialize())
	var stale_profile := JSON.stringify(GameManager.profile)
	main.screen = "workshop"; main._leave_unified_battle(); main.call_deferred("_continue_unified_run_cycle", stale_generation); await get_tree().process_frame
	require(main.screen == "workshop" and main.battle == null and JSON.stringify(GameManager.profile) == stale_profile and battle_before.length() > 0, "M8 route replacement invalidates the real battle generation so a stale cycle callback cannot settle, grant, or restore battle state.")
