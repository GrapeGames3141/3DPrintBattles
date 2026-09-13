extends Node

const Runtime := preload("res://scripts/team_runtime/team_prototype_runtime.gd")
const Shell := preload("res://scripts/team_ui/team_prototype_shell.gd")
const FirstPrint := preload("res://scripts/team_ui/team_prototype_first_print_controller.gd")
const PrintCompositor := preload("res://scripts/team_ui/team_prototype_print_compositor.gd")
const FacingCache := preload("res://scripts/ui/battle_facing_sprite_cache.gd")
const Sequence := preload("res://scripts/ui/arcane_forge_sequence.gd")
const Chassis := preload("res://scripts/team_ui/team_prototype_chassis.gd")

var failures: Array[String] = []
var requires := 0
var fixture_root := ""
var fresh_write_counter: Variant = null


class FaultRuntime extends RefCounted:
	var begin_failures := 0
	var complete_failures := 0
	var calls: Array[Dictionary] = []

	func collection_request(action: String, request_id: String, payload: Dictionary) -> Dictionary:
		calls.append({"action": action, "request_id": request_id, "payload": payload.duplicate(true)})
		if action == "begin_starter_print" and begin_failures > 0:
			begin_failures -= 1
			return {"ok": false, "error": "Injected Begin failure"}
		if action == "complete_starter_print" and complete_failures > 0:
			complete_failures -= 1
			return {"ok": false, "error": "Injected Complete failure"}
		return {"ok": true}


class StoreFault extends RefCounted:
	var reject_profile_write := false
	var profile_promotions: Array[String] = []
	var stage_calls: Array[Dictionary] = []

	func allow(stage: String, kind: String) -> bool:
		stage_calls.append({"stage": stage, "kind": kind})
		if stage == "primary_promotion" and kind == "profile":
			profile_promotions.append(kind)
		return not (reject_profile_write and stage == "temp_write" and kind == "profile")

func require(value: bool, message: String) -> void:
	requires += 1
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	fixture_root = _fixture_root()
	_test_print_clock()
	_test_first_print_retry_contract()
	_test_safe_area_conversion()
	await _test_persisted_first_print_faults()
	await _test_compositor_fail_closed()
	var write_counter := StoreFault.new()
	fresh_write_counter = write_counter
	var made := _runtime("collection-ui", Callable(write_counter, "allow"))
	require(not made.is_empty(), "fresh sibling UI fixture opens through the explicit runtime path")
	if not made.is_empty():
		await _test_routes_and_first_print(made.runtime)
		await _test_drafts_settings_and_back(made.runtime)
		await _test_fitted_safe_hit_owners(made.runtime)
		require(write_counter.profile_promotions.size() == 7, "only successful Choose, Begin, Complete, Acknowledge, Apply, Settings, and later Apply promote the isolated profile")
	await _test_all_starter_guarantees()
	await _test_settings_boundaries()
	await _test_editor_attempt_boundaries()
	await _test_recovery_route()
	print("TEAM_COLLECTION_UI requires=%d failures=%d" % [requires, failures.size()])
	print("TEAM_COLLECTION_UI failures=%d" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)

func _fixture_root() -> String:
	var qa := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-save-root="):
			qa = argument.trim_prefix("--qa-save-root=")
	var root := qa.get_base_dir().path_join("ui-fixtures")
	DirAccess.make_dir_recursive_absolute(root)
	return root

func _runtime(name: String, fault: Callable = Callable()) -> Dictionary:
	var path := fixture_root.path_join(name).path_join("profile.json")
	var profile := {"schema_version":31,"owned_blueprints":{},"owned_cards":{},"printed_models":{},"preserve":"ui-fixture"}
	return _runtime_with_profile(path, profile, fault)


func _runtime_with_profile(path: String, profile: Dictionary, fault: Callable = Callable()) -> Dictionary:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(profile))
	file.close()
	var opened := Runtime.open(path, {"compatible":true,"state":"ready","schema_version":31,"supported_schema":31,"message":""}, fault)
	return {"runtime":opened.runtime, "path":path} if bool(opened.get("ok", false)) and str(opened.get("recovery", "")).is_empty() else {}

func _shell(runtime: Variant, viewport_size := Vector2(576, 1024), insets := Rect2(Vector2.ZERO, Vector2.ZERO)) -> Variant:
	var shell := Shell.new()
	shell.size = viewport_size
	shell.synthetic_safe_insets = insets
	shell.synthetic_safe_insets_enabled = insets != Rect2(Vector2.ZERO, Vector2.ZERO)
	add_child(shell)
	shell.configure_runtime(runtime)
	await get_tree().process_frame
	return shell


func _test_fitted_safe_hit_owners(runtime: Variant) -> void:
	for fixture in [
		{"size":Vector2(576, 1024), "insets":Rect2(24, 48, 24, 48)},
		{"size":Vector2(720, 1280), "insets":Rect2(24, 48, 24, 48)},
	]:
		var shell: Variant = await _shell(runtime, fixture.size, fixture.insets)
		await get_tree().process_frame
		await _assert_visible_hits(shell)
		require(shell._stage.position.x >= fixture.insets.position.x and shell._stage.position.y >= fixture.insets.position.y, "%dx%d synthetic all-inset fit keeps the design stage inside safe content" % [int(fixture.size.x), int(fixture.size.y)])
		shell.navigate("team")
		await get_tree().process_frame
		await _assert_visible_hits(shell)
		_find_named_button(shell, "TeamBay0").pressed.emit()
		await get_tree().process_frame
		await _assert_visible_hits(shell)
		shell.back()
		shell.navigate("kit")
		await get_tree().process_frame
		await _assert_visible_hits(shell)
		_find_named_button(shell, "SupportChip_raw_filament").pressed.emit()
		await get_tree().process_frame
		await _assert_visible_hits(shell)
		shell.back()
		shell.navigate("starter")
		await get_tree().process_frame
		await _assert_visible_hits(shell)
		shell.navigate("settings")
		await get_tree().process_frame
		await _assert_visible_hits(shell)
		shell.queue_free()
		await get_tree().process_frame
	var top_only: Variant = await _shell(runtime, Vector2(576, 1024))
	var before: Vector2 = top_only._stage.position
	top_only.synthetic_safe_insets = Rect2(0, 48, 0, 0)
	top_only.synthetic_safe_insets_enabled = true
	top_only._fit()
	await get_tree().process_frame
	require(top_only._stage.position.y > before.y, "a top-only synthetic inset refits the live stage without requiring a viewport resize")
	await _assert_visible_hits(top_only)
	top_only.queue_free()
	await get_tree().process_frame

func _test_routes_and_first_print(runtime: Variant) -> void:
	var shell: Variant = await _shell(runtime)
	require(shell.route == "workshop" and _button_count(shell) >= 5, "Workshop exposes only native physical prototype navigation")
	await _click_design(shell, Vector2(470, 1030))
	await get_tree().process_frame
	require(shell.route == "starter" and _find_button(shell, "CHOOSE") != null, "Workshop Forge hardware opens the native starter carousel")
	await _click_design(shell, Vector2(470, 1370))
	await get_tree().process_frame
	require(_find_button(shell, "CHOOSE BLUEPRINT") != null and str(runtime.collection_view().starter_id).is_empty(), "first Choose opens a native confirmation without an entitlement write")
	await _click_design(shell, Vector2(470, 1370))
	await get_tree().process_frame
	require(shell.route == "forge" and str(runtime.collection_view().voucher.state) == "available", "Choose persists one starter voucher before Forge presentation")
	await _click_design(shell, Vector2(471, 1427))
	await get_tree().process_frame
	require(str(runtime.collection_view().voucher.state) == "printing", "First Print persists before its presentation state")
	var active_controller: Variant = shell.first_print
	var active_progress := int(active_controller.sequence.progress_bps)
	shell.back()
	await get_tree().process_frame
	require(shell.route == "workshop", "Back leaves an active First Print for the Workshop without resolving it")
	shell.navigate("forge")
	await get_tree().process_frame
	require(shell.first_print == active_controller and shell._forge_action != null and is_instance_valid(shell._forge_action) and int(shell.first_print.sequence.progress_bps) >= active_progress, "reopening an active Forge preserves its controller progress and rebuilds only fresh route-owned nodes")
	await _click_design(shell, Vector2(471, 1427))
	await get_tree().create_timer(.20).timeout
	require(str(runtime.collection_view().voucher.state) == "settled" and shell.route == "forge", "RAW_COMPLETE auto-commits once then remains in its finite visual sequence")
	require(_find_button_contains(shell, "RAW COMPLETE") != null, "successful raw hold is labeled RAW COMPLETE rather than a pending save")
	var animation_skip := _find_button_contains(shell, "SKIP")
	if animation_skip != null:
		await _click_design(shell, Vector2(471, 1427))
	await get_tree().create_timer(.20).timeout
	require(shell.route == "grant", "only the post-save visual awaken/depart sequence opens the truthful grant receipt")
	var continue_button := _find_button(shell, "CONTINUE\nTO TEAM")
	if continue_button != null:
		await _click_design(shell, Vector2(750, 1450))
	await get_tree().process_frame
	require(shell.route == "team" and str(runtime.collection_view().voucher.state) == "acknowledged", "grant acknowledgement opens an unsaved Team draft")
	require(fresh_write_counter != null and fresh_write_counter.profile_promotions.size() == 4, "fresh Choose, Begin, Complete, and acknowledgement are the only durable profile promotions before local Team editing")
	shell.back()
	await get_tree().process_frame
	require(shell.route == "workshop", "Back from the acknowledged Team draft returns to Workshop, not an obsolete receipt")
	shell.navigate("forge")
	await get_tree().process_frame
	require(shell.route == "team", "acknowledged Forge route opens Team and never loops back to the grant receipt")
	shell.queue_free()
	await get_tree().process_frame

func _test_print_clock() -> void:
	for fps in [30, 60, 144]:
		var clock := FirstPrint.new()
		clock.sequence = Sequence.create(false, false)
		clock.sequence.begin()
		var elapsed := 0.0
		var frame := 1.0 / float(fps)
		while str(clock.sequence.phase) == Sequence.PRINTING and elapsed < 13.0:
			clock.advance_delta(frame, "print")
			elapsed += frame
		require(absf(elapsed - 12.0) <= frame + 0.001, "first-print %dfps clock reaches RAW_COMPLETE at twelve seconds within one input frame" % fps)
		require(str(clock.sequence.phase) == Sequence.RAW_COMPLETE, "first-print %dfps clock reaches RAW_COMPLETE" % fps)
	var paused := FirstPrint.new()
	paused.sequence = Sequence.create(false, false)
	paused.sequence.begin()
	paused.advance_delta(0.11, "print")
	paused.set_paused(true)
	paused.advance_delta(12.0, "print")
	paused.set_paused(false)
	paused.advance_delta(0.11, "print")
	require(paused.sequence.progress_bps == 0, "pause clears the presentation accumulator and prevents hidden background catch-up")
	paused.advance_delta(0.01, "print")
	require(paused.sequence.progress_bps == Sequence.presentation_step_bps(false, Sequence.PRINTING), "foreground presentation resumes only after a fresh full interval")
	var exceptional := FirstPrint.new()
	exceptional.sequence = Sequence.create(false, false)
	exceptional.sequence.begin()
	exceptional.advance_delta(12.0, "print")
	require(exceptional.sequence.progress_bps == Sequence.presentation_step_bps(false, Sequence.PRINTING) * 2, "exceptional foreground delta advances at most two bounded presentation steps")


func _test_safe_area_conversion() -> void:
	var insets := Chassis.local_safe_insets(Vector2(540, 960), Vector2(0, 0), Vector2(1080, 1920), Rect2(0, 96, 1080, 1728))
	require(insets.position == Vector2(0, 48) and insets.size == Vector2(0, 48), "display safe-area pixels convert once into the logical viewport coordinate boundary")
	var outside := Chassis.local_safe_insets(Vector2(540, 960), Vector2(100, 200), Vector2(1080, 1920), Rect2(2000, 2000, 10, 10))
	require(outside == Rect2(Vector2.ZERO, Vector2.ZERO), "nonintersecting safe display rectangles add no synthetic inset")
	var stage := Control.new()
	Chassis.fit_design(stage, Vector2(720, 1280), Rect2(24, 48, 24, 48))
	require(stage.scale.x == stage.scale.y and stage.position.x >= 24.0 and stage.position.y >= 48.0, "all four synthetic safe insets retain one uniformly fitted 941 design stage")
	require(80.0 * stage.scale.x >= 48.0, "the smallest registered 80-design-pixel hardware hit remains at least 48 final pixels in the 720 all-inset fixture")
	stage.free()


func _test_first_print_retry_contract() -> void:
	var fake := FaultRuntime.new()
	fake.begin_failures = 1
	fake.complete_failures = 1
	var controller := FirstPrint.new()
	controller.configure(fake, {"starter_id": "cinderpaw", "voucher": {"state": "available"}}, false)
	require(not bool(controller.start().get("ok", false)), "injected Begin failure keeps the first-print controller retryable")
	require(bool(controller.start().get("ok", false)), "retained Begin request retries successfully")
	require(fake.calls.size() == 2 and fake.calls[0].request_id == fake.calls[1].request_id, "Begin retry reuses one retained authority request ID")
	controller.advance(Sequence.PRINT_COMPLETE_BPS, "tp-voucher-begin")
	require(str(controller.sequence.phase) == Sequence.RAW_COMPLETE and not controller.save_error.is_empty(), "failed Complete remains visibly RAW_COMPLETE without resolve_commit(false)")
	require(bool(controller.retry("tp-voucher-begin").get("ok", false)), "retained Complete request retries successfully")
	require(str(controller.sequence.phase) == Sequence.RAW_HOLD and controller.save_error.is_empty(), "successful Complete alone opens the post-save Raw Hold")
	require(fake.calls[2].request_id == fake.calls[3].request_id, "Complete retry reuses the exact attempted completion request ID")
	controller.advance(Sequence.RAW_HOLD_BPS, "tp-voucher-begin")
	controller.advance(Sequence.AWAKEN_BPS, "tp-voucher-begin")
	controller.advance(Sequence.DEPART_BPS, "tp-voucher-begin")
	require(str(controller.sequence.phase) == Sequence.AWAKENED, "natural controller flow traverses Raw Hold, Awaken and Depart before its grant-ready terminal pose")
	require(fake.calls.filter(func(call): return str(call.action) == "complete_starter_print").size() == 2, "post-save presentation never repeats the completed authority action")
	var reopened := FirstPrint.new()
	reopened.configure(fake, {"starter_id": "cinderpaw", "voucher": {"state": "printing"}}, false)
	require(reopened.sequence != null and str(reopened.sequence.phase) == Sequence.PRINTING and reopened.begin_request_id.is_empty(), "Back/reopen restores only a pending presentation without a duplicate Begin")


func _test_persisted_first_print_faults() -> void:
	var fault := StoreFault.new()
	var made := _runtime("first-print-store-fault", Callable(fault, "allow"))
	require(not made.is_empty(), "fault-injected first-print fixture opens through the real file boundary")
	if made.is_empty():
		return
	var runtime: Variant = made.runtime
	var shell: Variant = await _shell(runtime)
	shell.navigate("starter")
	_find_button(shell, "CHOOSE").pressed.emit()
	fault.reject_profile_write = true
	_find_button(shell, "CHOOSE BLUEPRINT").pressed.emit()
	await get_tree().process_frame
	var starter_retry := _find_named_label(shell, "StarterSaveRetry")
	require(str(runtime.collection_view().starter_id).is_empty() and _find_named_button(shell, "StarterChooseConfirm") != null and _find_named_button(shell, "StarterChooseConfirm").text == "RETRY SAVE" and starter_retry != null and starter_retry.text == "Save not confirmed. Retry.", "failed starter choice immediately rerenders its retained confirmation as Retry Save")
	fault.reject_profile_write = false
	_find_named_button(shell, "StarterChooseConfirm").pressed.emit()
	await get_tree().process_frame
	require(str(runtime.collection_view().starter_id) == "cinderpaw", "starter Retry keeps the original confirmation payload and commits once")
	fault.reject_profile_write = true
	_find_button(shell, "START\nFREE PRINT").pressed.emit()
	await get_tree().process_frame
	var begin_id := str(shell.first_print.begin_request_id)
	require(not begin_id.is_empty() and str(runtime.collection_view().voucher.state) == "available", "real Begin write failure remains on the available voucher with its retained request")
	fault.reject_profile_write = false
	_find_button_contains(shell, "RETRY START").pressed.emit()
	await get_tree().process_frame
	require(str(runtime.collection_view().voucher.state) == "printing" and str(shell.first_print.begin_request_id) == begin_id, "real Begin retry preserves one request identity across the durable write")
	var print_id := str(runtime.collection_view().voucher.print_id)
	fault.reject_profile_write = true
	shell.first_print.advance(Sequence.PRINT_COMPLETE_BPS, print_id)
	var complete_id := str(shell.first_print.complete_request_id)
	require(str(shell.first_print.sequence.phase) == Sequence.RAW_COMPLETE and str(runtime.collection_view().voucher.state) == "printing", "real Complete write failure stays at RAW_COMPLETE without a false grant")
	fault.reject_profile_write = false
	shell._retry_complete()
	await get_tree().process_frame
	require(str(runtime.collection_view().voucher.state) == "settled" and str(shell.first_print.complete_request_id) == complete_id, "real Complete retry keeps the exact authority identity and settles once")
	shell._refresh_cache()
	shell.replace_route("grant")
	await get_tree().process_frame
	fault.reject_profile_write = true
	_find_button(shell, "CONTINUE\nTO TEAM").pressed.emit()
	await get_tree().process_frame
	var acknowledge_id := str((shell.retained_requests.get("acknowledge_grant", {}) as Dictionary).get("id", ""))
	require(not acknowledge_id.is_empty() and str(runtime.collection_view().voucher.state) == "settled", "real acknowledgement failure keeps the durable receipt and its retained request")
	fault.reject_profile_write = false
	_find_button(shell, "RETRY\nCONTINUE").pressed.emit()
	await get_tree().process_frame
	require(str(runtime.collection_view().voucher.state) == "acknowledged" and acknowledge_id.is_empty() == false and not shell.retained_requests.has("acknowledge_grant"), "real acknowledgement retry completes once and releases its retained request")
	shell.back()
	shell.navigate("forge")
	await get_tree().process_frame
	require(shell.route == "team", "reopening Forge after an acknowledged receipt routes to Team without replaying completion or the grant")
	shell.queue_free()
	await get_tree().process_frame


func _test_compositor_fail_closed() -> void:
	var compositor := PrintCompositor.new()
	add_child(compositor)
	await get_tree().process_frame
	compositor.render_state(null, Rect2(0, 0, 380, 508), Vector2(190, 473), Vector2(403.5, 874.1), 225.0 / 380.0, Rect2(142, 317, 498, 631), 0, 0, Vector2.ZERO, false)
	require(not bool(compositor.presentation_snapshot().get("valid", true)), "null subject fails closed without a presentation fallback")
	var subject := FacingCache.texture_for_creature("cinderpaw")
	compositor.render_state(subject, Rect2(0, -1, 380, 508), Vector2(190, 473), Vector2(403.5, 874.1), 225.0 / 380.0, Rect2(142, 317, 498, 631), 0, 0, Vector2.ZERO, false)
	require(not bool(compositor.presentation_snapshot().get("valid", true)), "negative source region fails closed without rendering a whole atlas")
	var region := FacingCache.safe_source_region_for_creature("cinderpaw", FacingCache.raw_frame_for_creature("cinderpaw", 1))
	compositor.render_state(subject, region, Vector2(190, 473), Vector2(403.5, 874.1), 225.0 / 380.0, Rect2(142, 317, 498, 631), 10000, 10000, Vector2.ZERO, false)
	var grounded: Dictionary = compositor.presentation_snapshot()
	compositor.render_state(subject, region, Vector2(190, 473), Vector2(403.5, 874.1), 225.0 / 380.0, Rect2(142, 317, 498, 631), 10000, 10000, Vector2(30, 110), false, true, 1.0)
	var departing: Dictionary = compositor.presentation_snapshot()
	var grounded_position: Vector2 = grounded.get("living_position", Vector2.ZERO)
	var departing_position: Vector2 = departing.get("living_position", Vector2.ZERO)
	var grounded_shadow_center: Vector2 = grounded.get("shadow_center", Vector2.ZERO)
	var departing_shadow_center: Vector2 = departing.get("shadow_center", Vector2.ZERO)
	require(departing_position.x > grounded_position.x and departing_position.y > grounded_position.y, "normal departure advances forward and down from its rooted bed pose")
	require((departing_shadow_center - grounded_shadow_center).is_equal_approx(departing_position - grounded_position), "normal departure moves the soft shadow center exactly with its rooted living subject")
	compositor.render_state(subject, region, Vector2(190, 473), Vector2(403.5, 874.1), 225.0 / 380.0, Rect2(142, 317, 498, 631), 10000, 10000, Vector2(30, 110), true, true, 1.0)
	var reduced_motion: Dictionary = compositor.presentation_snapshot()
	var reduced_motion_position: Vector2 = reduced_motion.get("living_position", Vector2.ZERO)
	var reduced_motion_shadow_center: Vector2 = reduced_motion.get("shadow_center", Vector2.ZERO)
	require(reduced_motion_position == grounded_position, "reduced-motion departure remains grounded without translation")
	require(reduced_motion_shadow_center.is_equal_approx(grounded_shadow_center), "reduced-motion shadow remains grounded with no hidden translation")
	compositor.render_state(subject, region, Vector2(190, 473), Vector2(403.5, 874.1), 225.0 / 380.0, Rect2(142, 317, 498, 631), 10000, 10000, Vector2.ZERO, false, false, 0.0)
	require(not bool(compositor.presentation_snapshot().presentation_visible), "terminal handoff removes the departing bed subject instead of snapping it home")
	compositor.queue_free()
	await get_tree().process_frame

func _test_drafts_settings_and_back(runtime: Variant) -> void:
	var shell: Variant = await _shell(runtime)
	await _click_design(shell, Vector2(189, 562))
	await get_tree().process_frame
	require(shell.route == "team", "a viewport press and release at the visible Workshop Team hardware opens Team")
	require(_find_button(shell, "APPLY") != null and not _find_button(shell, "APPLY").disabled, "recommended 3/15 draft has a native valid Apply")
	await _click_design(shell, Vector2(174.81, 355.0))
	await get_tree().process_frame
	require(_find_named_button(shell, "TeamChoice_cinderpaw") != null, "Team bay opens a native printed-companion selector")
	require(_find_named_button(shell, "TeamBay0").focus_mode == Control.FOCUS_NONE and _find_named_button(shell, "TeamChoice_cinderpaw").focus_mode != Control.FOCUS_NONE, "a collection modal owns keyboard focus while route controls are removed from focus traversal")
	var duplicate_aquafin := _find_named_button(shell, "TeamChoice_aquafin")
	require(duplicate_aquafin != null and duplicate_aquafin.disabled, "Team selector rejects a duplicate already occupying another printed slot")
	await _click_design(shell, Vector2(259, 198))
	await get_tree().process_frame
	require(shell.modal.is_empty() and get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().name == "TeamBay0", "the actual modal Back plate closes the Team selector and restores its source focus")
	_find_named_button(shell, "TeamPriority").pressed.emit()
	await get_tree().process_frame
	_find_named_button(shell, "Priority_aquafin").pressed.emit()
	await get_tree().process_frame
	_find_button(shell, "MOVE UP").pressed.emit()
	await get_tree().process_frame
	require(str(shell.draft_priority[0]) == "aquafin" and shell.draft_team.has("cinderpaw"), "Priority controls reorder independently without replacing Team identities")
	await _back_key()
	await get_tree().process_frame
	require(get_viewport().gui_get_focus_owner() != null and get_viewport().gui_get_focus_owner().name == "TeamPriority", "Escape closes Print Order and restores its stable source focus")
	_find_button(shell, "APPLY").pressed.emit()
	await get_tree().process_frame
	require(not runtime.collection_view().saved_loadout.is_empty(), "Team Apply is the only collection draft write")
	require(_collection_request_count(runtime) == 5, "fresh onboarding commits exactly Choose, Begin, Complete, Acknowledge, and Apply")
	require(fresh_write_counter != null and fresh_write_counter.profile_promotions.size() == 5, "fresh first-session workflow performs exactly five successful profile promotions through Apply")
	shell.navigate("kit")
	await get_tree().process_frame
	var raw_chip := _find_named_button(shell, "SupportChip_raw_filament")
	if raw_chip != null:
		raw_chip.pressed.emit()
	await get_tree().process_frame
	require(_find_named_button(shell, "SupportPlus_raw_filament") != null and _find_named_button(shell, "SupportMinus_raw_filament") != null, "Support Kit opens an owned bounded native inspector")
	_find_named_button(shell, "SupportMinus_raw_filament").pressed.emit()
	await get_tree().process_frame
	shell.back()
	await get_tree().process_frame
	require(_kit_total_for(shell) == 14 and _find_named_button(shell, "CollectionApply").disabled, "actual Minus makes the fourteen-card Kit visibly ineligible for Apply")
	_find_named_button(shell, "SupportChip_raw_filament").pressed.emit()
	await get_tree().process_frame
	_find_named_button(shell, "SupportPlus_raw_filament").pressed.emit()
	await get_tree().process_frame
	shell.back()
	await get_tree().process_frame
	require(shell.modal.is_empty(), "Back closes the Support inspector before leaving the Kit draft")
	var expected_effects := {
		"raw_filament": "Cost 0 · Filament +2",
		"heated_spool": "Cost 0 · Filament +3",
		"standard_full_suit": "Cost 2 · Armor +8 · Print 1",
		"iron_gem": "Cost 2 · Attack +2 · Print 1",
		"forge_surge": "Cost 2 · Attack 150%",
	}
	for support in ["raw_filament", "heated_spool", "standard_full_suit", "iron_gem"]:
		require(_find_named_button(shell, "SupportChip_%s" % support) != null, "%s uses a native first-page Support owner" % support)
		_find_named_button(shell, "SupportChip_%s" % support).pressed.emit()
		await get_tree().process_frame
		require(_find_named_button(shell, "SupportPlus_%s" % support) != null and _find_named_button(shell, "SupportMinus_%s" % support) != null, "%s opens the same bounded native inspector" % support)
		var effect_label := _find_named_label(shell, "SupportEffect_%s" % support)
		require(effect_label != null and effect_label.text.contains(str(expected_effects[support])), "%s inspector exposes its authoritative Team Battle effect and cost" % support)
		shell.back()
		await get_tree().process_frame
	_find_named_button(shell, "KitNext").pressed.emit()
	await get_tree().process_frame
	require(_find_named_button(shell, "SupportChip_forge_surge") != null, "the fifth V3 Support type is reachable on Kit page two")
	_find_named_button(shell, "SupportChip_forge_surge").pressed.emit()
	await get_tree().process_frame
	require(_find_named_button(shell, "SupportPlus_forge_surge") != null, "the fifth Support opens the same owned bounded inspector")
	var surge_effect := _find_named_label(shell, "SupportEffect_forge_surge")
	require(surge_effect != null and surge_effect.text.contains(str(expected_effects.forge_surge)), "forge_surge inspector exposes its authoritative Team Battle effect and cost")
	var forge_plus := _find_named_button(shell, "SupportPlus_forge_surge")
	forge_plus.pressed.emit()
	await get_tree().process_frame
	require(_kit_total_for(shell) == 15 and _find_named_button(shell, "SupportPlus_forge_surge").disabled, "owned Support controls keep a full Kit at its exact fifteen-card maximum")
	shell.back()
	await get_tree().process_frame
	shell.back()
	await get_tree().process_frame
	require(shell.route == "workshop", "visible/system Back cancels a local collection draft")
	shell.navigate("settings")
	await get_tree().process_frame
	var toggle := _find_named_button(shell, "SettingsTextScale")
	toggle.pressed.emit()
	_find_named_button(shell, "SettingsApply").pressed.emit()
	await get_tree().process_frame
	require(int(runtime.settings_view().text_scale_bps) == 15000, "Settings Apply persists only the checked native accessibility values")
	shell.navigate("team")
	await get_tree().process_frame
	_find_named_button(shell, "TeamPriority").pressed.emit()
	await get_tree().process_frame
	_find_named_button(shell, "Priority_mossmunk").pressed.emit()
	await get_tree().process_frame
	_find_button(shell, "MOVE UP").pressed.emit()
	await get_tree().process_frame
	await _back_key()
	_find_button(shell, "APPLY").pressed.emit()
	await get_tree().process_frame
	require(_collection_request_count(runtime) == 6, "a later changed Team Apply creates one fresh accepted logical request")
	await _assert_visible_hits(shell)
	shell._queue_back_dispatch()
	shell._queue_back_dispatch()
	await get_tree().process_frame
	await get_tree().process_frame
	require(shell.leave_confirmation, "a close-key notification pair deduplicates to one root Leave confirmation")
	require(_find_named_button(shell, "LeaveStay") != null and _find_named_button(shell, "WorkshopTeam") == null, "the root Leave/Stay sheet is modal and leaves no Workshop hotspot behind it")
	shell.back()
	await _back_key()
	await get_tree().process_frame
	require(shell.leave_confirmation, "a later deliberate Back tap remains available after the deduplicated root prompt")
	shell.back()
	shell.queue_free()
	await get_tree().process_frame


func _test_all_starter_guarantees() -> void:
	var expected := {
		"cinderpaw": ["aquafin", "mossmunk"],
		"aquafin": ["voltwig", "mossmunk"],
		"voltwig": ["cinderpaw", "mossmunk"],
	}
	for starter_value in expected.keys():
		var starter := str(starter_value)
		var made := _runtime("guarantee-%s" % starter)
		require(not made.is_empty(), "%s guarantee fixture opens through the isolated file boundary" % starter)
		if made.is_empty():
			continue
		var runtime: Variant = made.runtime
		var chosen: Dictionary = runtime.collection_request("choose_starter", "guarantee-%s" % starter, {"starter_id":starter})
		var view: Dictionary = runtime.collection_view()
		var guarantees: Array = expected[starter]
		require(bool(chosen.get("ok", false)) and str(view.starter_id) == starter, "%s starter choice binds one immutable voucher identity" % starter)
		require(int(view.printed_counts.get(starter, 0)) == 0 and int(view.printed_counts.get(str(guarantees[0]), 0)) > 0 and int(view.printed_counts.get(str(guarantees[1]), 0)) > 0, "%s grants exactly its two already-Printed companion guarantees without a second voucher print" % starter)
		runtime.close()


func _test_settings_boundaries() -> void:
	var malformed_path := fixture_root.path_join("settings-malformed").path_join("profile.json")
	var malformed_profile := {
		"schema_version":31,
		"owned_blueprints":{},
		"owned_cards":{},
		"printed_models":{},
		"preserve":"settings-fixture",
		"team_prototype_settings":{"text_scale_bps":"huge","high_contrast":"yes","reduced_motion":0,"unknown_setting":"preserve-me"},
	}
	var malformed := _runtime_with_profile(malformed_path, malformed_profile)
	require(not malformed.is_empty(), "malformed Settings values remain readable without coercion or recovery")
	if not malformed.is_empty():
		var safe: Dictionary = malformed.runtime.settings_view()
		require(int(safe.text_scale_bps) == 10000 and not bool(safe.high_contrast) and not bool(safe.reduced_motion), "malformed Settings types safely project the default in memory without a write")
		malformed.runtime.close()
	var float_path := fixture_root.path_join("settings-float").path_join("profile.json")
	var float_profile := malformed_profile.duplicate(true)
	float_profile.team_prototype_settings = {"text_scale_bps":15000.0,"high_contrast":false,"reduced_motion":false,"unknown_setting":"preserve-me"}
	var fault := StoreFault.new()
	var floated := _runtime_with_profile(float_path, float_profile, Callable(fault, "allow"))
	require(not floated.is_empty(), "JSON whole-number Settings fixture reopens")
	if floated.is_empty():
		return
	var runtime: Variant = floated.runtime
	require(int(runtime.settings_view().text_scale_bps) == 15000 and not bool(runtime.settings_view().high_contrast), "JSON float 15000 reloads as supported 150 percent independently of contrast")
	var shell: Variant = await _shell(runtime)
	shell.navigate("settings")
	await get_tree().process_frame
	require(_find_named_button(shell, "SettingsTextScale").accessibility_name.begins_with("Text Size:") and _find_named_button(shell, "SettingsHighContrast").accessibility_name.begins_with("High Contrast:") and _find_named_button(shell, "SettingsReducedMotion").accessibility_name.begins_with("Reduced Motion:"), "all three Settings toggles expose their full native accessible setting names")
	fault.reject_profile_write = true
	_find_named_button(shell, "SettingsHighContrast").pressed.emit()
	_find_named_button(shell, "SettingsApply").pressed.emit()
	await get_tree().process_frame
	var retry_caption := shell.find_child("SettingsApplyCaption", true, false) as Label
	require(not shell.route_error.is_empty() and retry_caption != null and retry_caption.text == "RETRY SAVE" and _find_named_button(shell, "SettingsApply").accessibility_name == "RETRY SAVE", "failed Settings Apply keeps the local draft visible on its real Retry owner")
	fault.reject_profile_write = false
	_find_named_button(shell, "SettingsApply").pressed.emit()
	await get_tree().process_frame
	var stored_text := FileAccess.get_file_as_string(float_path)
	require(stored_text.contains("unknown_setting") and stored_text.contains("preserve-me"), "Settings retry preserves unknown namespace keys through the file boundary")
	var chosen: Dictionary = runtime.collection_request("choose_starter", "settings-followup", {"starter_id":"aquafin"})
	stored_text = FileAccess.get_file_as_string(float_path)
	require(bool(chosen.get("ok", false)) and stored_text.contains("unknown_setting") and stored_text.contains("preserve-me"), "a later Collection action preserves unknown Settings keys after the Settings retry")
	shell.queue_free()
	await get_tree().process_frame
	runtime.close()
	var replacement_path := fixture_root.path_join("editor-replacement").path_join("profile.json")
	var replacement_profile := {"schema_version":31,"owned_blueprints":{},"owned_cards":{},"printed_models":{"fixture-voltwig":{"blueprint_id":"voltwig"}},"preserve":"replacement-fixture"}
	var replacement := _runtime_with_profile(replacement_path, replacement_profile)
	require(not replacement.is_empty(), "four-Printed companion replacement fixture opens")
	if replacement.is_empty():
		return
	var replacement_runtime: Variant = replacement.runtime
	require(_bootstrap_to_ack(replacement_runtime, "replacement"), "replacement fixture reaches a valid acknowledged collection")
	var replacement_shell: Variant = await _shell(replacement_runtime)
	replacement_shell.navigate("team")
	await get_tree().process_frame
	_find_named_button(replacement_shell, "TeamBay0").pressed.emit()
	await get_tree().process_frame
	var voltwig_choice := _find_named_button(replacement_shell, "TeamChoice_voltwig")
	require(voltwig_choice != null and not voltwig_choice.disabled, "eligible fourth Printed companion is available for a real Team replacement")
	voltwig_choice.pressed.emit()
	await get_tree().process_frame
	require(str(replacement_shell.draft_team[0]) == "voltwig" and str(replacement_shell.draft_priority[0]) == "voltwig", "Team selector replaces one identity and updates only its matching priority entry")
	replacement_shell.queue_free()
	await get_tree().process_frame
	replacement_runtime.close()


func _bootstrap_to_ack(runtime: Variant, prefix: String, starter: String = "cinderpaw") -> bool:
	var choose: Dictionary = runtime.collection_request("choose_starter", "%s-choose" % prefix, {"starter_id":starter})
	if not bool(choose.get("ok", false)):
		return false
	var begin: Dictionary = runtime.collection_request("begin_starter_print", "%s-begin" % prefix, {})
	if not bool(begin.get("ok", false)):
		return false
	var view: Dictionary = runtime.collection_view()
	var complete: Dictionary = runtime.collection_request("complete_starter_print", "%s-complete" % prefix, {"print_id":str(view.voucher.print_id)})
	if not bool(complete.get("ok", false)):
		return false
	view = runtime.collection_view()
	var acknowledged: Dictionary = runtime.collection_request("acknowledge_grant", "%s-ack" % prefix, {"receipt_id":str(view.voucher.receipt_id)})
	return bool(acknowledged.get("ok", false))


func _test_editor_attempt_boundaries() -> void:
	var fault := StoreFault.new()
	var made := _runtime("editor-attempts", Callable(fault, "allow"))
	require(not made.is_empty(), "editor attempt fixture opens through the sibling runtime path")
	if made.is_empty():
		return
	var runtime: Variant = made.runtime
	require(_bootstrap_to_ack(runtime, "editor"), "editor fixture reaches the durable acknowledged grant before local draft tests")
	var shell: Variant = await _shell(runtime)
	shell.navigate("team")
	await get_tree().process_frame
	var kit: Dictionary = shell.draft_kit.duplicate(true)
	kit.raw_filament = int(kit.raw_filament) - 1
	require(not bool(runtime.preview_loadout(shell.draft_team, shell.draft_priority, kit).get("ok", false)), "fourteen-card Kit remains invalid before Apply")
	kit = shell.draft_kit.duplicate(true)
	kit.raw_filament = int(kit.raw_filament) + 1
	require(not bool(runtime.preview_loadout(shell.draft_team, shell.draft_priority, kit).get("ok", false)), "sixteen-card Kit remains invalid before Apply")
	fault.reject_profile_write = true
	_find_named_button(shell, "CollectionApply").pressed.emit()
	await get_tree().process_frame
	var failed_id := str((shell.retained_requests.get("apply_loadout", {}) as Dictionary).get("id", ""))
	var apply_retry := _find_named_label(shell, "CollectionSaveRetry")
	require(not failed_id.is_empty() and not shell.route_error.is_empty() and _find_named_button(shell, "CollectionApply").text == "RETRY APPLY" and apply_retry != null and apply_retry.text == "Save not confirmed. Retry.", "actual Apply write failure immediately exposes the retained retry and bounded status on the editor")
	fault.reject_profile_write = false
	_find_named_button(shell, "CollectionApply").pressed.emit()
	await get_tree().process_frame
	require(shell.route == "workshop" and not shell.retained_requests.has("apply_loadout"), "actual Apply Retry saves the retained payload once and releases it only after success")
	shell.navigate("team")
	await get_tree().process_frame
	_find_named_button(shell, "TeamPriority").pressed.emit()
	await get_tree().process_frame
	_find_named_button(shell, "Priority_mossmunk").pressed.emit()
	await get_tree().process_frame
	_find_button(shell, "MOVE UP").pressed.emit()
	await get_tree().process_frame
	await _back_key()
	fault.reject_profile_write = true
	_find_named_button(shell, "CollectionApply").pressed.emit()
	await get_tree().process_frame
	var cancelled_id := str((shell.retained_requests.get("apply_loadout", {}) as Dictionary).get("id", ""))
	_find_named_button(shell, "CollectionCancel").pressed.emit()
	await get_tree().process_frame
	require(shell.route == "workshop" and not shell.retained_requests.has("apply_loadout"), "Cancel abandons an unaccepted failed Apply attempt and restores the saved draft")
	shell.navigate("team")
	await get_tree().process_frame
	_find_named_button(shell, "TeamPriority").pressed.emit()
	await get_tree().process_frame
	_find_named_button(shell, "Priority_aquafin").pressed.emit()
	await get_tree().process_frame
	_find_button(shell, "MOVE UP").pressed.emit()
	await get_tree().process_frame
	await _back_key()
	_find_named_button(shell, "CollectionApply").pressed.emit()
	await get_tree().process_frame
	var replacement_id := str((shell.retained_requests.get("apply_loadout", {}) as Dictionary).get("id", ""))
	require(not replacement_id.is_empty() and replacement_id != cancelled_id and replacement_id != failed_id, "a genuinely changed draft receives a fresh Apply identity after cancellation")
	fault.reject_profile_write = false
	shell.back()
	shell.queue_free()
	await get_tree().process_frame
	runtime.close()


func _test_recovery_route() -> void:
	var path := fixture_root.path_join("recovery").path_join("profile.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{not-json")
	file.close()
	var opened := Runtime.open(path, {"compatible":true,"state":"ready","schema_version":31,"supported_schema":31,"message":""})
	require(bool(opened.get("ok", false)) and not str(opened.get("recovery", "")).is_empty(), "corrupt sibling profile opens the native shell in read-only recovery")
	if not bool(opened.get("ok", false)):
		return
	var shell: Variant = await _shell(opened.runtime)
	var original_bytes := FileAccess.get_file_as_bytes(path)
	require(shell.route == "recovery" and _find_named_button(shell, "RecoveryDetails") != null, "Recovery route exposes only native Details and Back owners")
	_find_named_button(shell, "RecoveryDetails").pressed.emit()
	await get_tree().process_frame
	var recovery_summary := _find_named_label(shell, "RecoverySummary")
	require(_find_button(shell, "CLOSE") != null and recovery_summary != null and recovery_summary.text == "Profile data is damaged. You can leave safely." and recovery_summary.accessibility_name.contains("profile_corrupt"), "Recovery Details keeps the user-facing damaged-save copy while preserving the diagnostic only for accessibility")
	_find_button(shell, "CLOSE").pressed.emit()
	await get_tree().process_frame
	# Use the real recovery Back plate, rather than a button signal, to prove the
	# root-only Leave/Stay route does not leak through to a mutable Workshop.
	await _click_design(shell, Vector2(96, 72))
	require(shell.route == "recovery" and shell.leave_confirmation and _find_named_button(shell, "LeaveStay") != null, "the Recovery Back plate opens the read-only Leave/Stay confirmation")
	_find_named_button(shell, "LeaveStay").pressed.emit()
	await get_tree().process_frame
	require(shell.route == "recovery" and not shell.leave_confirmation, "Stay returns directly to Recovery without exposing Workshop")
	await _back_key()
	require(shell.route == "recovery" and shell.leave_confirmation, "the native Back key uses the same Recovery Leave/Stay dispatcher")
	shell.back()
	await get_tree().process_frame
	require(FileAccess.get_file_as_bytes(path) == original_bytes, "Recovery Details and Leave/Stay navigation make zero profile writes")
	shell.queue_free()
	await get_tree().process_frame

func _find_button(root: Node, caption: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if (node as Button).text == caption:
			return node as Button
	return null


func _find_named_button(root: Node, node_name: String) -> Button:
	var found := root.find_child(node_name, true, false)
	return found as Button if found is Button else null


func _find_named_label(root: Node, node_name: String) -> Label:
	var found := root.find_child(node_name, true, false)
	return found as Label if found is Label else null

func _find_button_prefix(root: Node, caption: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if (node as Button).text.begins_with(caption):
			return node as Button
	return null


func _find_button_contains(root: Node, caption: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if (node as Button).text.contains(caption):
			return node as Button
	return null

func _button_count(root: Node) -> int:
	return root.find_children("*", "Button", true, false).size()

func _kit_button_count(root: Node) -> int:
	var count := 0
	for node in root.find_children("*", "Button", true, false):
		if (node as Button).text in ["+", "−"]:
			count += 1
	return count


func _kit_total_for(shell: Variant) -> int:
	var total := 0
	for value in shell.draft_kit.values():
		total += int(value)
	return total


func _collection_request_count(runtime: Variant) -> int:
	var prototype: Dictionary = runtime._profile.get("team_prototype", {})
	return (prototype.get("requests", {}) as Dictionary).size()


func _assert_visible_hits(shell: Variant) -> void:
	var visible: Array[Rect2] = []
	for node in shell.find_children("*", "Button", true, false):
		var button := node as Button
		if button.disabled or not button.visible:
			continue
		var bounds := button.get_global_rect()
		var required_hit := float(button.get_meta("required_final_hit", 48.0))
		require(bounds.size.x >= required_hit and bounds.size.y >= required_hit, "%s keeps its %dpx final native hit target after the 941 design fit" % [button.name, int(required_hit)])
		for other in visible:
			require(bounds.intersection(other).size == Vector2.ZERO, "%s does not overlap a neighboring active native hit" % button.name)
		visible.append(bounds)


func _click_design(shell: Variant, design_position: Vector2) -> void:
	var viewport_position: Vector2 = shell._stage.position + design_position * shell._stage.scale
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = viewport_position
	press.global_position = viewport_position
	press.pressed = true
	get_viewport().push_input(press, true)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = viewport_position
	release.global_position = viewport_position
	release.pressed = false
	get_viewport().push_input(release, true)
	await get_tree().process_frame


func _back_key() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	get_viewport().push_input(event, true)
	await get_tree().process_frame
