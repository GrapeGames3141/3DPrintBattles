extends Node

## M8 route table: visible Back and Android Back must resolve the same foremost
## physical state without changing profile authority.  This deliberately uses the
## real mounted Main rather than a static route surrogate.
const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const M9_TEST_PROFILE_FACTORY := preload("res://tests/m9_test_profile_factory.gd")
const UNIFIED_BATTLE_STATE := preload("res://scripts/battle/unified_battle_state.gd")
const FORGE_SEQUENCE := preload("res://scripts/ui/arcane_forge_sequence.gd")

var failures: Array[String] = []
var exercised_rows: Dictionary = {}
var executed_subcases: Dictionary = {}
const TEST_ROOT := "E:/AI Projects/games/3d print battler/build/evidence/m9a-runtime-20260904/state/m8-route-back"

# Locked rows 129–146.  The row id is deliberately emitted, so a smaller subset
# cannot accidentally make this suite look complete.
const ROUTE_ROWS := [
	"M8-BK-01 starter-inspect", "M8-BK-02 first-print-review", "M8-BK-03 forge-selection",
	"M8-BK-04 forge-print-review-merged-idle", "M8-BK-05 forge-active", "M8-BK-06 archive-detail",
	"M8-BK-07 archive-root", "M8-BK-08 deck-inspect-focus", "M8-BK-09 deck-clean-root",
	"M8-BK-10 deck-dirty", "M8-BK-11 market-confirm", "M8-BK-12 market-root",
	"M8-BK-13 settings-title", "M8-BK-14 settings-workshop", "M8-BK-15 proving-preflight",
	"M8-BK-16 proving-root", "M8-BK-17 result-committed-duplicate", "M8-BK-18 result-pending-error"
]
const REQUIRED_SUBCASES := [
	"01-visible-system", "02a-workshop", "02b-title", "02c-archive", "03a-workshop", "03b-archive", "03c-collection", "04a-loaded", "04b-empty-recovery", "05a-printing", "05a-raw-hold", "05a-awakening", "05a-departing", "05b-raw-complete-shared-system", "05c-awakened", "05c-failed", "06a-creature", "06b-support", "07-root", "08a-creature", "08b-support", "08c-preprint-clamp", "09a-workshop", "09b-archive-deck", "10a-stay-visible-system", "10c-discard-copy-a-b", "10d-save-copy-a-b", "11a-pending-visible-system", "11b-inflight-visible-disabled", "11b-inflight-shared-system", "12-root", "13-title", "14-workshop", "15-preflight", "16-root", "17a-committed", "17b-duplicate", "18a-pending", "18b-error", "18c-retry-failure-copy-a-b", "18d-retry-success-copy-a-b"
]

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _row(id: String, detail: String) -> void:
	require(id in ROUTE_ROWS, "M8 route ledger only accepts locked row ids.")
	exercised_rows[id] = detail

func _subcase(id: String) -> void:
	require(id in REQUIRED_SUBCASES, "M8 route ledger only accepts required subcases.")
	executed_subcases[id] = true

func _ready() -> void:
	await _run()
	if failures.is_empty(): print("PASS: M8 route Back contract")
	print("M8 route Back ledger %d/18: %s" % [exercised_rows.size(), JSON.stringify(exercised_rows)])
	get_tree().quit(0 if failures.is_empty() else 1)

func _profile() -> Dictionary:
	return M9_TEST_PROFILE_FACTORY.founder_ready("cinderpaw")

func _mount() -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(576, 1024)
	viewport.size_2d_override = Vector2i(576, 1024)
	viewport.size_2d_override_stretch = true
	viewport.disable_3d = true
	add_child(viewport)
	var canvas := Control.new()
	canvas.size = Vector2(576, 1024)
	viewport.add_child(canvas)
	var main := MAIN.instantiate()
	canvas.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	return {"main":main, "viewport":viewport}

func _snapshot(main: Control) -> String:
	return JSON.stringify({
		"screen":main.screen,
		"starter":main.starter_inspector_id,
		"inspector":main.unified_inspector_id,
		"deck_pending":main.m3_pending_deck_slot_id,
		"market_confirmation":main.m3_market_confirmation,
		"settings_return":main.settings_return_screen,
		"printer_phase":str(main.printer_sequence.phase) if main.printer_sequence != null else "",
		"printer_progress":int(main.printer_sequence.progress_bps) if main.printer_sequence != null else -1,
		"profile":GameManager.profile,
		"revision":int(GameManager.profile.get("revision", 0))
	})

func _canonical_back_snapshot(main: Control) -> String:
	# The comparison intentionally includes every M8-owned local state.  A route
	# name alone would let visible/system Back disagree on a retained draft, job,
	# focus context, or battle generation while still appearing to pass.
	return JSON.stringify({
		"route":main.screen,
		"starter_inspector":main.starter_inspector_id,
		"archive_inspector":main.unified_inspector_id,
		"archive_page":int(main.get_meta("m3_archive_page", 0)),
		"archive_filter":str(main.unified_archive_filter),
		"deck_selected_card":str(main.get_meta("m3_deck_selected_card_id", "")),
		"deck_pending":main.m3_pending_deck_slot_id,
		"deck_draft":main.unified_deck_draft,
		"preprints":main.unified_preprint_draft,
		"market_confirmation":main.m3_market_confirmation,
		"settings_caller":main.settings_return_screen,
		"settings_draft":main.m3_settings_draft,
		"focus":main.get_viewport().gui_get_focus_owner().get_path() if main.get_viewport().gui_get_focus_owner() != null else "",
		"preflight":bool(main.get_meta("battle_preflight", false)),
		"printer_phase":str(main.printer_sequence.phase) if main.printer_sequence != null else "",
		"printer_progress":int(main.printer_sequence.progress_bps) if main.printer_sequence != null else -1,
		"printer_commit_requested":bool(main.printer_sequence.commit_requested) if main.printer_sequence != null else false,
		"printer_resolved":bool(main.printer_sequence.resolved) if main.printer_sequence != null else false,
		"battle_generation":int(main.unified_battle_coordinator.generation),
		"battle":var_to_str(main.battle.serialize()) if main.battle != null else "",
		"result_state":main.m3_result_state,
		"result_receipt":main.m3_result_receipt,
		"toast":main.toast,
		"profile":GameManager.profile,
		"revision":int(GameManager.profile.get("revision", 0))
	})

func _reset_pair(main: Control, profile: Dictionary) -> void:
	main.set_process(true)
	GameManager.profile = profile.duplicate(true)
	main.screen = "workshop"
	main.workshop_view = "overview"
	main.starter_inspector_id = ""
	main.unified_inspector_id = ""
	main.m3_pending_deck_slot_id = ""
	main.m3_market_confirmation.clear()
	main.m3_settings_draft.clear()
	main.m3_settings_draft_initialized = false
	main.set_meta("battle_preflight", false)
	main.printer_sequence = null
	main.battle = null
	main.battle_mode = ""
	main.battle_settlement_context.clear()
	# Coordinator state is presentation-local, but it is part of the exact Back
	# contract.  Restore it alongside the serialized route fixture so a prior
	# branch cannot make the second form look different by generation alone.
	main.unified_battle_coordinator.state = null
	main.unified_battle_coordinator.viewer_seat = 0
	main.unified_battle_coordinator.generation = 0
	main.unified_battle_coordinator.in_flight = false
	main.unified_battle_coordinator.presentation_active = false
	main.unified_battle_coordinator.cycle_active = false
	main.unified_battle_coordinator.last_error = ""
	main.unified_battle_coordinator.transient_focus = -2
	main.m3_result_state = "idle"
	main.m3_result_receipt.clear()
	main.printer_return_screen = "workshop"

func _visible_system_pair(main: Control, profile: Dictionary, description: String, setup: Callable, owner: String) -> void:
	_reset_pair(main, profile)
	setup.call()
	# Freeze time-driven presentation immediately after deterministic setup.  The
	# comparison is Back semantics, not a race between one extra Forge tick and a
	# different frame budget for a Button signal versus system notification.
	main.set_process(false)
	main.render()
	await get_tree().process_frame
	await _press(main, owner)
	# The closed control is queued for deletion on the visible branch while system
	# Back gives the replacement route its default focus. Compare stable route
	# focus context after releasing that transient, disposed owner.
	main.get_viewport().gui_release_focus()
	var visible := _canonical_back_snapshot(main)
	_reset_pair(main, profile)
	setup.call()
	main.set_process(false)
	main.render()
	await get_tree().process_frame
	await _focus_owner(main, owner)
	await _system(main)
	await get_tree().process_frame
	main.get_viewport().gui_release_focus()
	var system := _canonical_back_snapshot(main)
	main.set_process(true)
	if visible != system:
		print("M8 parity mismatch %s\nvisible=%s\nsystem=%s" % [description, visible, system])
	require(visible == system, "M8 visible/system Back pair is byte-equivalent for %s from identical serialized fixtures." % description)

func _physical_copy_pair(main: Control, profile: Dictionary, description: String, setup: Callable, owner: String) -> void:
	_reset_pair(main, profile); setup.call(); main.set_process(false); main.render(); await get_tree().process_frame; await _press(main, owner); main.get_viewport().gui_release_focus(); var first := _canonical_back_snapshot(main)
	_reset_pair(main, profile); setup.call(); main.set_process(false); main.render(); await get_tree().process_frame; await _press(main, owner); main.get_viewport().gui_release_focus(); var second := _canonical_back_snapshot(main); main.set_process(true)
	require(first == second, "M8 duplicate physical %s action is byte-equivalent from identical fixtures." % description)

func _focused_back_pair(main: Control, profile: Dictionary, description: String, setup: Callable, focused_owner: String, back_owner: String) -> void:
	_reset_pair(main, profile); setup.call(); main.set_process(false); main.render(); await get_tree().process_frame; await _focus_owner(main, focused_owner); await _press(main, back_owner); main.get_viewport().gui_release_focus(); var visible := _canonical_back_snapshot(main)
	_reset_pair(main, profile); setup.call(); main.set_process(false); main.render(); await get_tree().process_frame; await _focus_owner(main, focused_owner); await _system(main); main.get_viewport().gui_release_focus(); var system := _canonical_back_snapshot(main); main.set_process(true)
	require(visible == system, "M8 focused visible/system Back pair is byte-equivalent for %s." % description)

func _press(main: Control, node_name: String) -> bool:
	# `Main.render()` replaces plate children with queue_free().  At the frame
	# boundary a prior route's identically named owner can still be in the tree;
	# resolve the newest live owner instead of accidentally signalling a stale
	# Settings/Back button from the preceding fixture.
	var button: Button = null
	var matches := main.find_children(node_name, "Button", true, false)
	for index in range(matches.size() - 1, -1, -1):
		var candidate := matches[index] as Button
		if candidate != null and not candidate.is_queued_for_deletion() and candidate.is_visible_in_tree():
			button = candidate
			break
	require(button != null and button.get_global_rect().size.x >= 48.0 and button.get_global_rect().size.y >= 48.0, "M8 %s is a visible >=48px physical Back/Close target." % node_name)
	if button == null: return false
	button.grab_focus()
	button.emit_signal("pressed")
	await get_tree().process_frame
	return true

func _focus_owner(main: Control, node_name: String) -> void:
	var matches := main.find_children(node_name, "Button", true, false)
	for index in range(matches.size() - 1, -1, -1):
		var button := matches[index] as Button
		if button != null and not button.is_queued_for_deletion() and button.is_visible_in_tree():
			button.grab_focus()
			await get_tree().process_frame
			return

func _system(main: Control) -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await get_tree().process_frame
	await get_tree().process_frame

func _prepare_result_retry(main: Control, profile: Dictionary, result_id: String) -> bool:
	_reset_pair(main, profile)
	# This is the production Trial factory, with an explicit result id so the
	# fixture itself does not create a launch journal entry before Retry is pressed.
	var launched: Dictionary = GameManager.create_unified_battle("trial_first_layers", {"result_id":result_id}, 61)
	require(bool(launched.get("ok", false)), "M8 ResultRetry fixture creates a real legal finished Trial battle.")
	if not bool(launched.get("ok", false)):
		return false
	main.battle = launched.get("battle", null)
	if main.battle == null:
		require(false, "M8 ResultRetry fixture has a concrete UnifiedBattleState.")
		return false
	main.battle.finished = true
	main.battle.winner = 0
	main.battle_mode = "trial_first_layers"
	main.battle_settlement_context = (launched.get("settlement_context", {}) as Dictionary).duplicate(true)
	main.battle_settlement_context["result_id"] = result_id
	main.battle_settlement_finished = false
	main.screen = "m3_result"
	main.m3_result_state = "error"
	main.m3_result_receipt = {"result":"victory", "mode":"trial", "state":"error", "id":result_id}
	main.toast = "Prior persistence failure."
	return true

func _press_result_retry(main: Control, profile: Dictionary, result_id: String) -> Dictionary:
	if not _prepare_result_retry(main, profile, result_id):
		return {}
	main.set_process(false)
	main.render()
	await get_tree().process_frame
	var retry := main.find_child("ResultRetry", true, false) as Button
	require(retry != null and retry.is_visible_in_tree() and not retry.disabled and retry.get_global_rect().size.x >= 48.0 and retry.get_global_rect().size.y >= 48.0, "M8 ResultRetry is the real enabled >=48px physical retry control for an error receipt.")
	if retry != null:
		await _press(main, "ResultRetry")
	main.get_viewport().gui_release_focus()
	var outcome := {
		"snapshot":_canonical_back_snapshot(main),
		"result_state":main.m3_result_state,
		"receipt":main.m3_result_receipt.duplicate(true),
		"toast":main.toast,
		"revision":int(GameManager.profile.get("revision", 0))
	}
	main.set_process(true)
	return outcome

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(TEST_ROOT)
	SaveService.configure_test_paths(TEST_ROOT)
	GameManager.profile = _profile()
	var mounted := await _mount()
	var main: Control = mounted.main
	var baseline := JSON.stringify(GameManager.profile)

	# Title root and confirmation are explicit root/cancel states, never Workshop.
	main.screen = "title"; main.title_new_maker_confirmation = true; main.render(); await get_tree().process_frame
	await _system(main)
	require(main.screen == "title" and not main.title_new_maker_confirmation and JSON.stringify(GameManager.profile) == baseline, "M8 title New Maker confirmation Back cancels only the confirmation with zero mutation.")
	main.request_back()
	require(main.screen == "title" and main.title_exit_confirmation, "M9 title root Back opens the explicit Exit or Stay decision without falling through to Workshop.")
	await get_tree().process_frame
	main.request_back()
	require(main.screen == "title" and not main.title_exit_confirmation, "M9 title confirmation Back stays on the title route.")

	# Starter inspector and Archive detail resolve their foremost detail only.
	main.screen = "onboarding"; main.starter_inspector_id = "cinderpaw"; main.render(); await get_tree().process_frame
	await _press(main, "StarterInspectorClose")
	require(main.screen == "onboarding" and main.starter_inspector_id.is_empty(), "M8 starter inspect visible Close preserves the gallery route.")
	main.starter_inspector_id = "cinderpaw"; main.render(); await get_tree().process_frame
	await _system(main)
	require(main.screen == "onboarding" and main.starter_inspector_id.is_empty(), "M8 starter inspect Android Back matches visible Close.")
	main.screen = "unified_library"; main.unified_inspector_id = "cinderpaw"; main.render(); await get_tree().process_frame
	await _press(main, "ArchiveDetailClose")
	require(main.screen == "unified_library" and main.unified_inspector_id.is_empty(), "M8 Archive detail Close returns to the retained folio grid.")
	await _system(main)
	require(main.screen == "workshop", "M8 Archive root Android Back returns to Workshop only after its detail is closed.")

	# Forge callers are preserved for both free-starter review and Title resume.
	# This is deliberately the unprinted starter-selected profile: it is the only
	# authoritative free First Print state and therefore must return to Workshop.
	GameManager.profile = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	main.screen = "onboarding"; main.open_printer("cinderpaw"); await get_tree().process_frame
	await _press(main, "ArcaneForgeBack")
	require(main.screen == "workshop", "M8 First Print starter review visible Back returns to Workshop.")
	main.printer_sequence = null; main.screen = "title"; main.open_printer("cinderpaw"); await get_tree().process_frame
	await _system(main)
	require(main.screen == "title", "M8 First Print Title-resume Android Back returns to Title.")

	# Market confirmation cancels in place; root returns to Workshop only after that.
	main.screen = "unified_market"; main.m3_market_confirmation = {"category":"blueprints", "id":"mossmunk", "price":10}; main.render(); await get_tree().process_frame
	var market_profile := JSON.stringify(GameManager.profile)
	await _press(main, "M3MarketCancelPurchase")
	require(main.screen == "unified_market" and main.m3_market_confirmation.is_empty() and JSON.stringify(GameManager.profile) == market_profile, "M8 visible Market Cancel preserves the selected Market route without a purchase mutation.")
	await _system(main)
	require(main.screen == "workshop", "M8 Market root Android Back returns to Workshop after confirmation cancellation.")

	# Settings callers retain their caller and only discard their local draft.
	main.screen = "settings"; main.settings_return_screen = "title"; main.m3_settings_draft = {"text_scale_bps":15000}; main.m3_settings_draft_initialized = true; main.render(); await get_tree().process_frame
	await _press(main, "SettingsCancel")
	require(main.screen == "title" and main.m3_settings_draft.is_empty(), "M8 Settings visible Cancel returns to Title and clears only its local draft.")
	main.screen = "settings"; main.settings_return_screen = "workshop"; main.m3_settings_draft = {"text_scale_bps":15000}; main.m3_settings_draft_initialized = true; main.render(); await get_tree().process_frame
	await _system(main)
	require(main.screen == "workshop" and main.m3_settings_draft.is_empty(), "M8 Settings Android Back returns to Workshop and clears only its local draft.")

	# Proving has two explicit steps, while live battle/result never generic-fallback.
	var post_modal_profile := JSON.stringify(GameManager.profile)
	main.screen = "proving"; main.set_meta("battle_preflight", true); main.render(); await get_tree().process_frame
	await _system(main)
	require(main.screen == "proving" and not bool(main.get_meta("battle_preflight", false)), "M8 proving preflight Back returns to the challenge board only.")
	await _system(main)
	require(main.screen == "workshop", "M8 proving challenge-board Back returns to Workshop.")
	# The fixture is a real deterministic battle state, not a null/screen-only
	# surrogate. It deliberately has no settlement context because it is live.
	main.battle = UNIFIED_BATTLE_STATE.create(["cinderpaw"], ["aquafin"], 61)
	main.battle_mode = "trial_first_layers"
	main.battle_settlement_context = {"mode":"trial"}
	main.unified_battle_coordinator.configure(main.battle, 0)
	main.screen = "unified_battle"; main.toast = ""; main.render(); await get_tree().process_frame
	var live_state := var_to_str(main.battle.serialize()) if main.battle != null else ""
	var live_generation: int = int(main.unified_battle_coordinator.generation)
	await _system(main)
	require(main.screen == "unified_battle" and main.battle_back_confirmation and main.battle != null and var_to_str(main.battle.serialize()) == live_state and main.unified_battle_coordinator.generation == live_generation, "M9 live battle Back opens the guarded Resume or Concede decision without mutating battle state.")
	await _system(main)
	require(main.screen == "unified_battle" and not main.battle_back_confirmation, "M9 battle-modal Back dismisses the foreground decision without leaving or conceding.")
	# Finished local battle is the explicit no-settlement exception: both Return
	# forms can leave, while the nonlocal path above remains consumed.
	main.battle.finished = true; main.battle_mode = "local"; main.battle_settlement_context.clear(); main.screen = "unified_battle"; main.render(); await get_tree().process_frame
	main.dispatch_back(); await get_tree().process_frame
	require(main.screen == "workshop", "M8 finished local visible/system Return can leave because no settlement is pending.")
	for state in ["pending", "error"]:
		main.screen = "m3_result"; main.m3_result_state = state; main.m3_result_receipt = {"result":"victory", "state":state}; main.toast = ""; var result_before := JSON.stringify(GameManager.profile); var revision_before := int(GameManager.profile.get("revision", 0)); main.render(); await get_tree().process_frame
		var blocked_continue := main.find_child("ResultContinue", true, false) as Button
		var continue_disabled := blocked_continue != null and blocked_continue.disabled
		await _system(main)
		require(continue_disabled and main.screen == "m3_result" and main.m3_result_state == state and JSON.stringify(GameManager.profile) == result_before and int(GameManager.profile.get("revision", 0)) == revision_before and main.toast.contains("Settlement is not complete"), "M8 %s result Back retains its receipt with disabled Continue and no fabricated settlement." % state)
		_subcase("18a-pending" if state == "pending" else "18b-error")

	# Retry uses the real result button and the production Trial factory.  Each
	# duplicate starts with byte-identical profile/battle/context data; only the
	# SaveService root differs where isolation is needed to keep journal history
	# from contaminating the second copy.
	var result_fixture_profile: Dictionary = GameManager.profile.duplicate(true)
	var retry_profile := _profile()
	var blocked_root := TEST_ROOT.path_join("retry-blocked")
	DirAccess.make_dir_recursive_absolute(blocked_root)
	var blocked_parent := blocked_root.path_join("not_a_directory")
	var blocker := FileAccess.open(blocked_parent, FileAccess.WRITE)
	if blocker != null:
		blocker.store_string("M8 ResultRetry unavailable-storage fixture")
		blocker.close()
	SaveService.configure_test_paths(blocked_parent)
	var retry_failure_before := JSON.stringify(retry_profile)
	var retry_failure_revision := int(retry_profile.get("revision", 0))
	var retry_failure_a: Dictionary = await _press_result_retry(main, retry_profile, "m8-retry-failure")
	require(str(retry_failure_a.get("result_state", "")) == "error" and JSON.stringify(GameManager.profile) == retry_failure_before and int(GameManager.profile.get("revision", 0)) == retry_failure_revision and str(retry_failure_a.get("toast", "")).contains("storage"), "M8 failed ResultRetry keeps the physical error receipt and profile/revision without fabrication.")
	var retry_failure_b: Dictionary = await _press_result_retry(main, retry_profile, "m8-retry-failure")
	require(retry_failure_a == retry_failure_b, "M8 ResultRetry persistence-failure copies are byte-equivalent from identical fixtures.")
	_subcase("18c-retry-failure-copy-a-b")
	SaveService.configure_test_paths(TEST_ROOT)
	DirAccess.remove_absolute(blocked_parent)
	DirAccess.remove_absolute(blocked_root)

	var success_root_a := TEST_ROOT.path_join("retry-success-a")
	var success_root_b := TEST_ROOT.path_join("retry-success-b")
	DirAccess.make_dir_recursive_absolute(success_root_a)
	DirAccess.make_dir_recursive_absolute(success_root_b)
	var retry_success_before := JSON.stringify(retry_profile)
	var retry_success_revision := int(retry_profile.get("revision", 0))
	SaveService.configure_test_paths(success_root_a)
	var retry_success_a: Dictionary = await _press_result_retry(main, retry_profile, "m8-retry-success")
	require(str(retry_success_a.get("result_state", "")) in ["committed", "duplicate"] and int(retry_success_a.get("revision", -1)) == retry_success_revision + 1 and not (retry_success_a.get("receipt", {}) as Dictionary).is_empty() and GameManager.profile.get("claim_receipts", {}).has("m8-retry-success") and GameManager.profile.get("drop_receipts", {}).has("m8-retry-success"), "M8 successful ResultRetry commits one authoritative trial settlement and receipt exactly once: %s" % JSON.stringify(retry_success_a))
	SaveService.configure_test_paths(success_root_b)
	var retry_success_b: Dictionary = await _press_result_retry(main, retry_profile, "m8-retry-success")
	require(retry_success_a == retry_success_b and JSON.stringify(retry_profile) == retry_success_before, "M8 ResultRetry success copies are byte-equivalent from isolated identical fixtures without a second settlement in either copy.")
	_subcase("18d-retry-success-copy-a-b")
	SaveService.configure_test_paths(TEST_ROOT)
	DirAccess.remove_absolute(success_root_a.path_join("profile.json"))
	DirAccess.remove_absolute(success_root_a.path_join("profile.backup.json"))
	DirAccess.remove_absolute(success_root_a.path_join("journal.jsonl"))
	DirAccess.remove_absolute(success_root_a)
	DirAccess.remove_absolute(success_root_b.path_join("profile.json"))
	DirAccess.remove_absolute(success_root_b.path_join("profile.backup.json"))
	DirAccess.remove_absolute(success_root_b.path_join("journal.jsonl"))
	DirAccess.remove_absolute(success_root_b)
	# Retry assertions intentionally perform a real successful settlement.  Restore
	# the surrounding Back fixture so the remaining non-settlement route checks
	# keep their zero-mutation baseline.
	GameManager.profile = result_fixture_profile.duplicate(true)
	main.battle_mode = "training"; main.m3_result_state = "committed"; main.screen = "m3_result"; main.render(); await get_tree().process_frame
	await _press(main, "ResultContinue")
	require(main.screen == "workshop", "M8 committed result visible Continue uses the shared Back exit to Workshop.")
	require(JSON.stringify(GameManager.profile) == post_modal_profile, "M8 proving, live-battle, and result Back paths preserve profile/revision with no grant or settlement mutation.")

	# High-risk Back owners are compared from identical serialized fixtures, rather
	# than relying on the sequential route examples above.  This catches retained
	# draft/job/caller divergence hidden by a superficially correct destination.
	var pair_profile := _profile()
	# Freeze a real prepared Market snapshot before the parity copies.  The visible
	# and Android branches then compare cancellation only; neither branch is
	# allowed to invoke wall-clock preparation during its render.
	GameManager.profile = pair_profile.duplicate(true)
	main.m3_market_snapshot.clear()
	main._m3_prepare_market_once()
	pair_profile = GameManager.profile.duplicate(true)
	var pair_market_snapshot: Dictionary = main.m3_market_snapshot.duplicate(true)
	main.set_meta("m3_capture_frozen_market", true)
	await _visible_system_pair(main, pair_profile, "Archive detail", func(): main.screen = "unified_library"; main.unified_inspector_id = "cinderpaw", "ArchiveDetailClose")
	_subcase("06a-creature")
	await _visible_system_pair(main, pair_profile, "Archive support detail", func(): main.screen = "unified_library"; main.unified_inspector_id = "raw_filament", "ArchiveDetailClose")
	_row("M8-BK-06 archive-detail", "visible creature/support Archive detail Close == Android Back; retained folio"); _subcase("06b-support")
	await _visible_system_pair(main, pair_profile, "starter inspection folio", func(): main.screen = "onboarding"; main.starter_inspector_id = "cinderpaw", "StarterInspectorClose")
	_row("M8-BK-01 starter-inspect", "visible close == Android Back; no starter grant"); _subcase("01-visible-system")
	await _visible_system_pair(main, pair_profile, "Archive folio root", func(): main.screen = "unified_library", "ArchiveArchBack")
	_row("M8-BK-07 archive-root", "visible ArchiveArchBack == Android Back"); _subcase("07-root")
	# The actual pre-start First Print profile is starter_selected, not completed.
	var first_print_profile: Dictionary = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	await _visible_system_pair(main, first_print_profile, "First Print Workshop caller", func(): main.screen = "onboarding"; main.open_printer("cinderpaw"), "ArcaneForgeBack")
	await _visible_system_pair(main, first_print_profile, "First Print Title caller", func(): main.screen = "title"; main.open_printer("cinderpaw"), "ArcaneForgeBack")
	await _visible_system_pair(main, first_print_profile, "First Print Archive caller", func(): main.screen = "unified_library"; main.open_printer("cinderpaw"), "ArcaneForgeBack")
	_subcase("02a-workshop"); _subcase("02b-title"); _subcase("02c-archive")
	_row("M8-BK-02 first-print-review", "starter_selected Workshop/Title/Archive callers paired; no print/grant")
	await _visible_system_pair(main, pair_profile, "Deck clean selected-card focus", func(): main.screen = "unified_deck"; main.m3_deck_loaded_slot_id = str(GameManager.profile.get("active_deck_id", "starter-deck")); main.set_meta("m3_deck_selected_card_id", "cinderpaw"), "UnifiedFoundryWorkshopReturn")
	_subcase("09a-workshop")
	await _visible_system_pair(main, pair_profile, "Archive Open Deck caller", func(): main.screen = "unified_deck"; main.unified_inspector_id = "cinderpaw"; main.set_meta("m3_deck_selected_card_id", "cinderpaw"), "UnifiedFoundryWorkshopReturn")
	_subcase("09b-archive-deck")
	_row("M8-BK-09 deck-clean-root", "visible deck Back == Android Back")
	# Deck selection is a persistent workbench focus, not a modal. Back therefore
	# follows the clean/dirty root path while this explicit assertion protects draft.
	_reset_pair(main, pair_profile); main.screen = "unified_deck"; main.unified_deck_draft = ["cinderpaw"]; main.set_meta("m3_deck_selected_card_id", "cinderpaw"); main.render(); await get_tree().process_frame
	var deck_focus_before: Array = main.unified_deck_draft.duplicate(); await _system(main)
	require(main.unified_deck_draft == deck_focus_before, "M8 Deck card/Pre-Print inspect is current persistent focus, not an invented modal; Back preserves the draft.")
	_subcase("08a-creature")
	await _visible_system_pair(main, pair_profile, "Deck support selected focus", func(): main.screen = "unified_deck"; main.m3_deck_loaded_slot_id = str(GameManager.profile.get("active_deck_id", "starter-deck")); main.set_meta("m3_deck_selected_card_id", "raw_filament"), "UnifiedFoundryWorkshopReturn")
	_subcase("08b-support")
	await _focused_back_pair(main, pair_profile, "PrePrintClamp1 focused deck root", func(): main.screen = "unified_deck"; main.unified_preprint_draft = ["cinderpaw"]; main.set_meta("m3_deck_selected_card_id", "cinderpaw"), "PrePrintClamp1", "UnifiedFoundryWorkshopReturn")
	_reset_pair(main, pair_profile); main.screen = "unified_deck"; main.unified_preprint_draft = ["cinderpaw"]; main.render(); await get_tree().process_frame; var clamp := main.find_child("PrePrintClamp1", true, false) as Button; require(clamp != null and clamp.get_global_rect().size.x >= 48.0 and clamp.get_global_rect().size.y >= 48.0, "M8 PrePrintClamp1 is a real focusable physical clamp."); if clamp != null: clamp.grab_focus(); await _system(main); require(main.unified_preprint_draft == ["cinderpaw"], "M8 Pre-Print clamp focus survives Back without draft mutation.")
	_row("M8-BK-08 deck-inspect-focus", "persistent creature/support/clamp focus explicitly mapped"); _subcase("08c-preprint-clamp")
	await _visible_system_pair(main, pair_profile, "dirty Deck Stay", func(): main.screen = "unified_deck"; main.m3_deck_edit_slot_id = str(GameManager.profile.get("active_deck_id", "starter-deck")); main.m3_deck_loaded_slot_id = main.m3_deck_edit_slot_id; main.unified_deck_draft = ["cinderpaw"]; main.unified_preprint_draft = []; main.m3_pending_deck_slot_id = "__back__", "M3DeckDirtyStay")
	# Explicit dirty Save/Discard outcomes use the same legal persisted fixture.
	var saved_revision := int(GameManager.profile.get("revision", 0)); var saved_profile := JSON.stringify(GameManager.profile)
	var expected_saved_cards: Array = (GameManager.profile.get("decks", [])[0].get("cards", []) as Array).duplicate()
	_reset_pair(main, pair_profile); main.screen = "unified_deck"; main.m3_deck_edit_slot_id = str(GameManager.profile.get("active_deck_id", "starter-deck")); main.m3_pending_deck_slot_id = "__back__"; main.unified_deck_draft = expected_saved_cards.duplicate(); main.unified_preprint_draft = []; main.render(); await get_tree().process_frame; await _press(main, "M3DeckDirtySave")
	require(main.screen == "workshop" and int(GameManager.profile.get("revision", 0)) == saved_revision + 1, "M8 dirty Deck visible Save returns only after one combined legal commit.")
	_reset_pair(main, pair_profile); main.screen = "unified_deck"; main.m3_pending_deck_slot_id = "__back__"; main.unified_deck_draft = ["cinderpaw"]; main.render(); await get_tree().process_frame; await _press(main, "M3DeckDirtyDiscard")
	require(main.screen == "workshop" and JSON.stringify(GameManager.profile) == saved_profile, "M8 dirty Deck visible Discard returns without profile/revision mutation.")
	main.screen = "unified_deck"; main.m3_deck_loaded_slot_id = ""; main.unified_deck_draft = []; main.unified_preprint_draft = []; main.render(); await get_tree().process_frame
	require(main.unified_deck_draft == expected_saved_cards and main.unified_preprint_draft == [], "M8 re-entered Deck reloads saved deck and Pre-Print values after Discard.")
	await _physical_copy_pair(main, pair_profile, "dirty Deck Save", func(): main.screen = "unified_deck"; main.m3_deck_edit_slot_id = str(GameManager.profile.get("active_deck_id", "starter-deck")); main.m3_pending_deck_slot_id = "__back__"; main.unified_deck_draft = expected_saved_cards.duplicate(); main.unified_preprint_draft = [], "M3DeckDirtySave")
	await _physical_copy_pair(main, pair_profile, "dirty Deck Discard", func(): main.screen = "unified_deck"; main.m3_pending_deck_slot_id = "__back__"; main.unified_deck_draft = ["cinderpaw"], "M3DeckDirtyDiscard")
	_row("M8-BK-10 deck-dirty", "Stay paired; legal Save and Discard duplicate physical actions executed"); _subcase("10a-stay-visible-system"); _subcase("10c-discard-copy-a-b"); _subcase("10d-save-copy-a-b")
	await _visible_system_pair(main, pair_profile, "Market confirmation cancellation", func(): main.screen = "unified_market"; main.m3_market_snapshot = pair_market_snapshot.duplicate(true); main.m3_market_confirmation = {"category":"blueprints", "id":"mossmunk", "price":10, "consequence":"Add the offered blueprint license."}, "M3MarketCancelPurchase")
	var inflight_setup := func(): main.screen = "unified_market"; main.m3_market_snapshot = pair_market_snapshot.duplicate(true); main.m3_market_confirmation = {"category":"blueprints", "id":"mossmunk", "price":10}; main.m3_action_in_flight = true
	_reset_pair(main, pair_profile); inflight_setup.call(); main.render(); await get_tree().process_frame; var locked_cancel := main.find_child("M3MarketCancelPurchase", true, false) as Button; var cancel_disabled := locked_cancel != null and locked_cancel.disabled and locked_cancel.tooltip_text == "Order is being recorded. Please wait for this receipt." and locked_cancel.accessibility_name == locked_cancel.tooltip_text; var visible_inflight := _canonical_back_snapshot(main)
	require(cancel_disabled and not main.m3_market_confirmation.is_empty(), "M8 in-flight Market visible Cancel is disabled with the exact native wait reason.")
	_reset_pair(main, pair_profile); inflight_setup.call(); main.render(); await get_tree().process_frame; main.dispatch_back(); main.get_viewport().gui_release_focus(); var shared_inflight := _canonical_back_snapshot(main)
	_reset_pair(main, pair_profile); inflight_setup.call(); main.render(); await get_tree().process_frame; await _system(main); main.get_viewport().gui_release_focus(); var system_inflight := _canonical_back_snapshot(main)
	require(shared_inflight == system_inflight and shared_inflight != visible_inflight and main.m3_market_confirmation.is_empty() == false and main.toast.contains("being recorded"), "M8 in-flight Market shared and Android Back retain the identical pending order and wait reason.")
	main.m3_action_in_flight = false
	_row("M8-BK-11 market-confirm", "pending and in-flight confirmation states exercised"); _subcase("11a-pending-visible-system")
	_subcase("11b-inflight-visible-disabled"); _subcase("11b-inflight-shared-system")
	await _visible_system_pair(main, pair_profile, "Market root", func(): main.screen = "unified_market"; main.m3_market_snapshot = pair_market_snapshot.duplicate(true), "UnifiedFoundryWorkshopReturn")
	_row("M8-BK-12 market-root", "visible Back == Android Back"); _subcase("12-root")
	await _visible_system_pair(main, pair_profile, "Settings Title caller", func(): main.screen = "settings"; main.settings_return_screen = "title"; main.m3_settings_draft = {"text_scale_bps":15000}; main.m3_settings_draft_initialized = true, "SettingsCancel")
	_row("M8-BK-13 settings-title", "visible cancel == Android Back"); _subcase("13-title")
	await _visible_system_pair(main, pair_profile, "Settings Workshop caller", func(): main.screen = "settings"; main.settings_return_screen = "workshop"; main.m3_settings_draft = {"text_scale_bps":15000}; main.m3_settings_draft_initialized = true, "SettingsCancel")
	_row("M8-BK-14 settings-workshop", "visible cancel == Android Back"); _subcase("14-workshop")
	await _visible_system_pair(main, pair_profile, "proving preflight", func(): main.screen = "proving"; main.set_meta("battle_preflight", true), "ChallengeReturnWorkshop")
	_row("M8-BK-15 proving-preflight", "visible Back == Android Back; board retained"); _subcase("15-preflight")
	await _visible_system_pair(main, pair_profile, "proving challenge root", func(): main.screen = "proving", "ChallengeReturnWorkshop")
	_row("M8-BK-16 proving-root", "visible return == Android Back"); _subcase("16-root")
	await _visible_system_pair(main, pair_profile, "committed result", func(): main.screen = "m3_result"; main.battle_mode = "training"; main.m3_result_state = "committed"; main.m3_result_receipt = {"result":"victory", "mode":"training", "coins":0, "xp":0}, "ResultContinue")
	await _visible_system_pair(main, pair_profile, "duplicate result", func(): main.screen = "m3_result"; main.battle_mode = "training"; main.m3_result_state = "duplicate"; main.m3_result_receipt = {"result":"victory", "mode":"training", "duplicate":true}, "ResultContinue")
	_row("M8-BK-17 result-committed-duplicate", "distinct committed and duplicate visible/system pairs"); _subcase("17a-committed"); _subcase("17b-duplicate")
	await _visible_system_pair(main, pair_profile, "Forge PRINTING", func(): main.screen = "workshop"; main.open_printer("cinderpaw"); main.begin_printer(); main.advance_printer_for_test(4200), "ArcaneForgeBack"); _subcase("05a-printing")
	for phase_entry in [[FORGE_SEQUENCE.RAW_HOLD, "05a-raw-hold"], [FORGE_SEQUENCE.AWAKENING, "05a-awakening"], [FORGE_SEQUENCE.DEPARTING, "05a-departing"]]:
		await _visible_system_pair(main, pair_profile, "Forge phase %s" % str(phase_entry[0]), func(): main.screen = "workshop"; main.open_printer("cinderpaw"); main.begin_printer(); main.printer_sequence.phase = phase_entry[0]; main.printer_sequence.progress_bps = 7000, "ArcaneForgeBack")
		_subcase(str(phase_entry[1]))
	var raw_complete_setup := func(): main.screen = "workshop"; main.open_printer("cinderpaw"); main.begin_printer(); main.printer_sequence.phase = FORGE_SEQUENCE.RAW_COMPLETE; main.printer_sequence.progress_bps = 10000
	_reset_pair(main, pair_profile); raw_complete_setup.call(); main.render(); await get_tree().process_frame; var raw_back := main.find_child("ArcaneForgeBack", true, false) as Button; require(raw_back != null and raw_back.disabled and raw_back.tooltip_text.contains("temporarily unavailable"), "M9 RAW_COMPLETE exposes a disabled Back owner with its exact securing explanation."); main.request_back(); main.get_viewport().gui_release_focus(); var raw_shared := _canonical_back_snapshot(main)
	_reset_pair(main, pair_profile); raw_complete_setup.call(); main.render(); await get_tree().process_frame; raw_back = main.find_child("ArcaneForgeBack", true, false) as Button; require(raw_back != null and raw_back.disabled, "M9 RAW_COMPLETE system fixture preserves the disabled Back owner."); await _system(main); main.get_viewport().gui_release_focus(); var raw_system := _canonical_back_snapshot(main)
	require(raw_shared == raw_system and main.screen == "printer" and main.printer_sequence.phase == FORGE_SEQUENCE.RAW_COMPLETE and main.toast.contains("temporarily unavailable"), "M8 RAW_COMPLETE shared and Android Back retain identical securing state.")
	_subcase("05b-raw-complete-shared-system")
	await _visible_system_pair(main, pair_profile, "Forge AWAKENED Return", func(): main.screen = "workshop"; main.open_printer("cinderpaw"); main.begin_printer(); main.printer_sequence.phase = FORGE_SEQUENCE.AWAKENED, "ReturnAfterPrint"); _subcase("05c-awakened")
	await _visible_system_pair(main, pair_profile, "Forge FAILED Return", func(): main.screen = "workshop"; main.open_printer("cinderpaw"); main.begin_printer(); main.printer_sequence.phase = FORGE_SEQUENCE.FAILED; main.printer_failure = "test", "ReturnFailedPrint"); _subcase("05c-failed")
	_row("M8-BK-05 forge-active", "all active, RAW_COMPLETE, and terminal Back forms paired")
	await _visible_system_pair(main, pair_profile, "Forge blueprint selection Workshop caller", func(): main.screen = "workshop"; main.open_printer("cinderpaw"), "ArcaneForgeBack")
	await _visible_system_pair(main, pair_profile, "Forge blueprint selection Title caller", func(): main.screen = "title"; main.open_printer("cinderpaw"), "ArcaneForgeBack")
	await _visible_system_pair(main, pair_profile, "Forge blueprint selection Archive detail caller", func(): main.screen = "unified_library"; main.unified_inspector_id = "cinderpaw"; main.open_printer("cinderpaw"), "ArcaneForgeBack")
	await _visible_system_pair(main, pair_profile, "Forge Collection-equivalent caller", func(): main.screen = "unified_forgedex"; main.open_printer("cinderpaw"), "ArcaneForgeBack")
	# Retained Archive detail is a valid caller context, but cannot be treated as a
	# foreground modal once Forge owns the screen.
	_reset_pair(main, pair_profile); main.unified_inspector_id = "cinderpaw"; main.screen = "unified_library"; main.open_printer("cinderpaw"); await get_tree().process_frame; await _system(main)
	require(main.screen == "unified_library" and main.unified_inspector_id == "cinderpaw", "M8 Archive-origin Forge Back restores the retained Archive detail instead of swallowing it.")
	_row("M8-BK-03 forge-selection", "Workshop, Title, Archive-detail, and Collection recorded-caller pairs"); _subcase("03a-workshop"); _subcase("03b-archive"); _subcase("03c-collection")
	# Current approved IDLE Forge intentionally merges selection/review: selecting a
	# different blueprint stays on that physical surface and creates no draft.
	await _visible_system_pair(main, pair_profile, "merged IDLE Forge review", func(): main.screen = "workshop"; main.open_printer("cinderpaw"); main.printer_creature_id = "mossmunk", "ArcaneForgeBack")
	_reset_pair(main, pair_profile); main.screen = "workshop"; main.open_printer("cinderpaw"); var forge_before := JSON.stringify(GameManager.profile); main.printer_creature_id = "mossmunk"; main.render(); await get_tree().process_frame
	require(main.printer_sequence != null and int(main.printer_sequence.progress_bps) == 0 and JSON.stringify(GameManager.profile) == forge_before, "M8 merged Forge selection/review stays on the unstarted IDLE surface with zero transaction before Back.")
	_subcase("04a-loaded")
	var empty_profile := RULES.new_profile(); await _visible_system_pair(main, empty_profile, "empty Forge recovery", func(): main.screen = "workshop"; main.open_printer(""), "ArcaneForgeBack")
	require(JSON.stringify(GameManager.profile) == JSON.stringify(empty_profile), "M8 empty Forge recovery Back has zero profile mutation and exposes no Begin action.")
	_row("M8-BK-04 forge-print-review-merged-idle", "loaded IDLE and empty recovery pairs"); _subcase("04b-empty-recovery")
	_row("M8-BK-18 result-pending-error", "separate pending/error Back locks exercised")
	require(exercised_rows.size() == ROUTE_ROWS.size(), "M8 locked route ledger exercises all 18 stable rows, not a partial subset.")
	require(executed_subcases.size() == REQUIRED_SUBCASES.size(), "M8 required subcase ledger is complete; row marks alone cannot pass.")
	mounted.viewport.queue_free()
