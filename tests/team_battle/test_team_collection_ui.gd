extends Node

const Runtime := preload("res://scripts/team_runtime/team_prototype_runtime.gd")
const Shell := preload("res://scripts/team_ui/team_prototype_shell.gd")
const FirstPrint := preload("res://scripts/team_ui/team_prototype_first_print_controller.gd")
const PrintCompositor := preload("res://scripts/team_ui/team_prototype_print_compositor.gd")
const FacingCache := preload("res://scripts/ui/battle_facing_sprite_cache.gd")
const Sequence := preload("res://scripts/ui/arcane_forge_sequence.gd")

var failures: Array[String] = []
var requires := 0
var fixture_root := ""


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

	func allow(stage: String, kind: String) -> bool:
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
	await _test_persisted_first_print_faults()
	await _test_compositor_fail_closed()
	var made := _runtime("collection-ui")
	require(not made.is_empty(), "fresh sibling UI fixture opens through the explicit runtime path")
	if not made.is_empty():
		await _test_routes_and_first_print(made.runtime)
		await _test_drafts_settings_and_back(made.runtime)
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
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":31,"owned_blueprints":{},"owned_cards":{},"printed_models":{},"preserve":"ui-fixture"}))
	file.close()
	var opened := Runtime.open(path, {"compatible":true,"state":"ready","schema_version":31,"supported_schema":31,"message":""}, fault)
	return {"runtime":opened.runtime} if bool(opened.get("ok", false)) and str(opened.get("recovery", "")).is_empty() else {}

func _shell(runtime: Variant) -> Variant:
	var shell := Shell.new()
	shell.size = Vector2(576, 1024)
	add_child(shell)
	shell.configure_runtime(runtime)
	await get_tree().process_frame
	return shell

func _test_routes_and_first_print(runtime: Variant) -> void:
	var shell: Variant = await _shell(runtime)
	require(shell.route == "workshop" and _button_count(shell) >= 5, "Workshop exposes only native physical prototype navigation")
	shell.navigate("starter")
	await get_tree().process_frame
	require(shell.route == "starter" and _find_button(shell, "CHOOSE") != null, "starter carousel exposes native Choose action")
	_find_button(shell, "CHOOSE").pressed.emit()
	await get_tree().process_frame
	require(_find_button(shell, "CHOOSE BLUEPRINT") != null and str(runtime.collection_view().starter_id).is_empty(), "first Choose opens a native confirmation without an entitlement write")
	_find_button(shell, "CHOOSE BLUEPRINT").pressed.emit()
	await get_tree().process_frame
	require(shell.route == "forge" and str(runtime.collection_view().voucher.state) == "available", "Choose persists one starter voucher before Forge presentation")
	_find_button(shell, "START\nFREE PRINT").pressed.emit()
	await get_tree().process_frame
	require(str(runtime.collection_view().voucher.state) == "printing", "First Print persists before its presentation state")
	_find_button_contains(shell, "SKIP").pressed.emit()
	await get_tree().create_timer(.20).timeout
	require(str(runtime.collection_view().voucher.state) == "settled" and shell.route == "forge", "RAW_COMPLETE auto-commits once then remains in its finite visual sequence")
	require(_find_button_contains(shell, "RAW COMPLETE") != null, "successful raw hold is labeled RAW COMPLETE rather than a pending save")
	var animation_skip := _find_button_contains(shell, "SKIP")
	if animation_skip != null:
		animation_skip.pressed.emit()
	await get_tree().create_timer(.20).timeout
	require(shell.route == "grant", "only the post-save visual awaken/depart sequence opens the truthful grant receipt")
	var continue_button := _find_button(shell, "READY TO BATTLE")
	if continue_button != null:
		continue_button.pressed.emit()
	await get_tree().process_frame
	require(shell.route == "team" and str(runtime.collection_view().voucher.state) == "acknowledged", "grant acknowledgement opens an unsaved Team draft")
	shell.navigate("forge")
	await get_tree().process_frame
	require(shell.route == "workshop", "acknowledged voucher never loops back to the grant receipt")
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
	_find_button(shell, "CHOOSE BLUEPRINT").pressed.emit()
	await get_tree().process_frame
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
	shell.back()
	shell.navigate("forge")
	await get_tree().process_frame
	require(shell.route == "grant", "Back/reopen after durable Complete presents the existing grant instead of replaying completion")
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
	shell.navigate("team")
	await get_tree().process_frame
	require(_find_button(shell, "APPLY") != null and not _find_button(shell, "APPLY").disabled, "recommended 3/15 draft has a native valid Apply")
	_find_button(shell, "APPLY").pressed.emit()
	await get_tree().process_frame
	require(not runtime.collection_view().saved_loadout.is_empty(), "Team Apply is the only collection draft write")
	shell.navigate("kit")
	await get_tree().process_frame
	require(_kit_button_count(shell) >= 10, "Support Kit exposes all five native support plus/minus actions")
	shell.back()
	await get_tree().process_frame
	require(shell.route == "workshop", "visible/system Back cancels a local collection draft")
	shell.navigate("settings")
	await get_tree().process_frame
	var toggle := _find_button_prefix(shell, "TEXT")
	toggle.pressed.emit()
	_find_button(shell, "APPLY").pressed.emit()
	await get_tree().process_frame
	require(int(runtime.settings_view().text_scale_bps) == 15000, "Settings Apply persists only the checked native accessibility values")
	shell.queue_free()
	await get_tree().process_frame

func _find_button(root: Node, caption: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if (node as Button).text == caption:
			return node as Button
	return null

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
