extends Node

const Shell := preload("res://scripts/team_ui/team_prototype_shell.gd")
const Controller := preload("res://scripts/team_ui/team_prototype_battle_controller.gd")
const Runtime := preload("res://scripts/team_runtime/team_prototype_runtime.gd")
const Bot := preload("res://scripts/team_battle/team_battle_bot.gd")
const Seating := preload("res://scripts/team_ui/team_prototype_battle_seating.gd")
const Visual := preload("res://scripts/team_ui/team_prototype_battle_visual.gd")
const Facing := preload("res://scripts/ui/battle_facing_sprite_cache.gd")

var failures: Array[String] = []
var requires := 0
var battle_case := "all"


class StoreFault extends RefCounted:
	var cursor_temp_calls := 0
	var reject_cursor_at := -1
	var ledger_temp_calls := 0
	var reject_ledger_at := -1

	func allow(stage: String, kind: String) -> bool:
		if stage == "temp_write" and kind == "cursor":
			cursor_temp_calls += 1
			return reject_cursor_at < 0 or cursor_temp_calls != reject_cursor_at
		if stage == "temp_write" and kind == "ledger":
			ledger_temp_calls += 1
			return reject_ledger_at < 0 or ledger_temp_calls != reject_ledger_at
		return true


class RuntimeForwarder extends RefCounted:
	var target: Variant = null
	var generic_skip_calls := 0

	func view() -> Dictionary:
		return target.view()

	func pending_receipt() -> Dictionary:
		return target.pending_receipt()

	func current_result() -> Dictionary:
		return target.current_result()

	func acknowledge(match_id: String, request_id: String, cursor: int) -> Dictionary:
		return target.acknowledge(match_id, request_id, cursor)

	func skip(match_id: String, request_id: String, cursor: int) -> Dictionary:
		generic_skip_calls += 1
		return target.skip(match_id, request_id, cursor)


class BattleRuntime extends RefCounted:
	var started := false
	var start_calls: Array[Dictionary] = []

	func is_recovery() -> bool:
		return false

	func settings_view() -> Dictionary:
		return {"text_scale_bps":10000, "high_contrast":false, "reduced_motion":false}

	func collection_view() -> Dictionary:
		return {"ok":true, "voucher":{}, "printed_counts":{}, "support_counts":{}, "saved_loadout":{}}

	func view() -> Dictionary:
		return {"ok":true, "match":{
			"has_current":started,
			"resume":started,
			"can_start":not started,
			"current_match_id":"tp-match-1" if started else "",
			"next_match_sequence":1,
			"player":_player_view() if started else {},
			"presentation":{"request_id":"battle-run-1", "cursor":0, "stage_count":0},
		}}

	func start(request_id: String, sequence: int, seed: int) -> Dictionary:
		start_calls.append({"id":request_id, "sequence":sequence, "seed":seed})
		started = true
		return {"ok":true, "match_id":"tp-match-1"}

	func pending_receipt() -> Dictionary:
		return {"ok":true, "receipt":{}, "cursor":0, "stage_count":0}

	func current_result() -> Dictionary:
		return {}

	func run_cycle(_match_id: String, _request_id: String, _plan: Dictionary) -> Dictionary:
		return {"ok":false, "error":"fixture does not resolve cycles"}

	func acknowledge(_match_id: String, _request_id: String, _cursor: int) -> Dictionary:
		return {"ok":true}

	func skip(_match_id: String, _request_id: String, _cursor: int) -> Dictionary:
		return {"ok":true}

	func _player_view() -> Dictionary:
		return {
			"revision":0, "cycle":1, "result":"", "own":{"members":[], "hand":[], "ready_member_ids":[], "active_member_id":"", "fifo":[], "filament":5},
			"opponent":{"members":[], "ready_member_ids":[], "active_member_id":"", "fifo":[], "hand_count":0, "filament":5},
		}


func require(value: bool, message: String) -> void:
	requires += 1
	if not value:
		failures.append(message)
		push_error(message)


func _ready() -> void:
	battle_case = _battle_case()
	if _case_enabled("preflight"):
		await _test_preflight_scaffold()
	if _case_enabled("foundation"):
		_test_shared_seating_projection()
		_test_real_runtime_target_boundary()
		_test_real_cursor_fault_boundaries()
		await _test_real_native_plan_pointer_actions()
	if _case_enabled("interactions"):
		await _test_real_native_plan_pointer_actions()
		await _test_real_native_start_and_run_retry_actions()
		await _test_real_native_hand_faces_and_heated_forecast()
	if _case_enabled("terminal"):
		await _test_real_terminal_skip_boundary()
	if _case_enabled("playback"):
		_test_shared_seating_projection()
		await _test_cached_receipt_boundaries()
	if _case_enabled("progression"):
		await _test_real_gem_ready_swap_progression()
	if _case_enabled("hold"):
		await _test_real_hold_progression()
	if battle_case == "terminal-setup":
		_test_terminal_setup()
	if battle_case == "terminal-loss" or battle_case == "terminal-draw":
		await _test_real_terminal_skip_boundary()
	print("TEAM_NATIVE_BATTLE_UI case=%s requires=%d failures=%d" % [battle_case, requires, failures.size()])
	print("TEAM_NATIVE_BATTLE_UI failures=%d" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func _test_shared_seating_projection() -> void:
	var cinder := {"identity_id":"player:member:cinderpaw", "status":"Ready"}
	var aquafin := {"identity_id":"player:member:aquafin", "status":"Unspent"}
	var moss := {"identity_id":"player:member:mossmunk", "status":"Defeated"}
	var empty_active := {
		"active_member_id":"",
		"priority":["player:member:mossmunk", "player:member:aquafin", "player:member:cinderpaw"],
		"members":[cinder, aquafin, moss],
	}
	var projected: Dictionary = Seating.project(empty_active)
	var docket: Dictionary = projected.get("docket", {})
	var bays: Array = projected.get("bays", [])
	require(str(docket.get("identity_id", "")) == "player:member:aquafin", "shared seating gives the no-Active docket to Printing/Unspent before priority bays")
	require(bays.size() == 2 and str((bays[0] as Dictionary).get("identity_id", "")) == "player:member:mossmunk" and str((bays[1] as Dictionary).get("identity_id", "")) == "player:member:cinderpaw", "shared seating preserves projected priority for both physical bays")
	var replacement := empty_active.duplicate(true)
	replacement["active_member_id"] = "player:member:aquafin"
	replacement["priority"] = ["player:member:cinderpaw", "player:member:mossmunk", "player:member:aquafin"]
	var replacement_projection: Dictionary = Seating.project(replacement)
	var replacement_bays: Array = replacement_projection.get("bays", [])
	require(replacement_projection.get("docket", {}).is_empty() and replacement_bays.size() == 2 and str((replacement_bays[1] as Dictionary).get("identity_id", "")) == "player:member:mossmunk", "replacement seating keeps the nonzero second bay identity stable for controls and visual roots")


func _test_cached_receipt_boundaries() -> void:
	await _test_plan_idle_pose_owner()
	var fault := StoreFault.new()
	var opened := _open_real_runtime(_fixture_path("playback-cache"), fault)
	require(bool(opened.get("ok", false)), "playback cache fixture opens through the real Runtime")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	if not _bootstrap_applied(runtime, "battle-cache"):
		require(false, "playback cache fixture reaches an applied 3/15 loadout")
		runtime.close()
		return
	var controller := Controller.new()
	controller.configure(runtime)
	require(bool(controller.start_or_resume().get("ok", false)), "playback cache fixture persists its real Start")
	_prepare_bot_plan(controller)
	require(bool(controller.run_cycle().get("ok", false)), "playback cache fixture creates a receipt")
	var identity_before := controller.stage_identity()
	var stage_before: Dictionary = controller.cached_stage()
	controller.refresh()
	require(controller.stage_identity() == identity_before and controller.cached_stage() == stage_before, "duplicate reads retain the cached current stage without importing a future receipt stage")
	require(bool(controller.acknowledge_stage().get("ok", false)), "playback cache fixture advances one real receipt boundary")
	require(controller.stage_identity() != identity_before and str(controller.cached_stage().get("name", "")) != str(stage_before.get("name", "")), "accepted acknowledgement swaps the cached stage only at its cursor boundary")
	runtime.close()


func _test_plan_idle_pose_owner() -> void:
	var visual := Visual.new()
	add_child(visual)
	await get_tree().process_frame
	var member := {"identity_id":"player:member:cinderpaw", "member_id":"cinderpaw", "status":"Active", "hp":34}
	visual.set_projection({
		"own":{"active_member_id":"player:member:cinderpaw", "priority":["player:member:cinderpaw"], "members":[member]},
		"opponent":{"active_member_id":"", "priority":[], "members":[]},
	}, false)
	var holder := visual.get_node_or_null("BattleFigure_player_member_cinderpaw") as Control
	var sprite := holder.get_node_or_null("Sprite") as TextureRect if holder != null else null
	var before_region := (sprite.texture as AtlasTexture).region if sprite != null and sprite.texture is AtlasTexture else Rect2()
	for tick in 12:
		visual._process(0.05)
	var after_region := (sprite.texture as AtlasTexture).region if sprite != null and sprite.texture is AtlasTexture else Rect2()
	var expected_region := Facing.safe_source_region_for_creature("cinderpaw", Facing.frame_for_creature("cinderpaw", 0, 0.60))
	var rooted: Variant = holder.get_meta("root", Vector2.ZERO) if holder != null else Vector2.ZERO
	require(holder != null and sprite != null and before_region != after_region and after_region == expected_region and rooted is Vector2 and (rooted as Vector2).is_equal_approx(Vector2(470.5, 924.2)), "editable Plan advances the expected idle frame while preserving its registered floor root")
	visual.queue_free()
	await get_tree().process_frame


func _test_preflight_scaffold() -> void:
	var runtime := BattleRuntime.new()
	var controller := Controller.new()
	controller.configure(runtime)
	require(controller.can_start() and not controller.has_current(), "valid preflight exposes Start Battle")
	var started: Dictionary = controller.start_or_resume()
	require(bool(started.get("ok", false)) and runtime.start_calls.size() == 1, "Start freezes one request envelope and calls the runtime once")
	require(int(runtime.start_calls[0].sequence) == 1 and int(runtime.start_calls[0].seed) == 0, "Start uses the stable sequence-derived seed")
	require(controller.has_current() and bool(controller.match_view.get("resume", false)), "accepted Start refreshes the durable Resume projection")
	var shell := Shell.new()
	shell.size = Vector2(576, 1024)
	add_child(shell)
	shell.configure_runtime(runtime)
	shell.navigate("preflight")
	await get_tree().process_frame
	require(shell.route == "preflight" and shell.find_child("BattleStartResume", true, false) != null, "native preflight renders its registered Start or Resume owner")
	shell.replace_route("battle")
	await get_tree().process_frame
	require(shell.route == "battle" and shell.find_child("TeamPrototypeBattleVisual", true, false) != null, "native battle route mounts one passive visual owner over the approved chassis")
	shell.queue_free()
	await get_tree().process_frame


func _test_real_runtime_target_boundary() -> void:
	var path := _fixture_path("target-boundary")
	var fault := StoreFault.new()
	var opened := _open_real_runtime(path, fault)
	require(bool(opened.get("ok", false)), "real file-boundary Battle fixture opens")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	require(_bootstrap_applied(runtime, "battle-target"), "real fixture persists the accepted first-session and 3/15 loadout path")
	var controller := Controller.new()
	controller.configure(runtime)
	var started: Dictionary = controller.start_or_resume()
	require(bool(started.get("ok", false)), "real Runtime accepts the preflight Start boundary")
	var suit_copy := ""
	for copy_value in controller.player_view.get("own", {}).get("hand", []):
		if copy_value is Dictionary and str(copy_value.get("card_id", "")) == "standard_full_suit":
			suit_copy = str(copy_value.get("copy_id", ""))
	controller.set_support(suit_copy)
	var targets: Array = controller.equipment_targets()
	require(not suit_copy.is_empty() and targets == ["player:member:cinderpaw"], "target-free Suit baseline exposes the exact canonical Cinderpaw equipment target")
	runtime.close()


func _test_real_cursor_fault_boundaries() -> void:
	var fault := StoreFault.new()
	var opened := _open_real_runtime(_fixture_path("cursor-faults"), fault)
	require(bool(opened.get("ok", false)), "cursor fault fixture opens through the actual Store")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	require(_bootstrap_applied(runtime, "battle-cursor"), "cursor fault fixture reaches an applied 3/15 loadout")
	var controller := Controller.new()
	controller.configure(runtime)
	require(bool(controller.start_or_resume().get("ok", false)), "cursor fault fixture persists its real Start")
	_prepare_bot_plan(controller)
	require(bool(controller.run_cycle().get("ok", false)), "cursor fault fixture creates a real nonterminal receipt")
	var live_request_id := controller.receipt_request_id()
	var duplicate_run := controller.run_cycle()
	require(not bool(duplicate_run.get("ok", false)) and controller.receipt_request_id() == live_request_id and controller.cursor == 0, "duplicate Run input during a durable receipt cannot submit a second cycle or relabel playback as a save failure")
	var receipt_before: Dictionary = runtime.pending_receipt()
	fault.reject_cursor_at = fault.cursor_temp_calls + 3
	var skipped := controller.skip_to_result()
	var accepted: Dictionary = runtime.pending_receipt()
	require(not bool(skipped.get("ok", false)) and controller.presentation_paused and controller.cursor == int(accepted.get("cursor", -1)) and controller.cursor == 2 and controller.current_stage() == (accepted.receipt.stages[2] as Dictionary), "partial real Skip reloads the accepted cursor then latches Retry without stale receipt state")
	controller.set_presentation_paused(true)
	controller.set_presentation_paused(false)
	require(controller.presentation_paused, "focus pause/resume cannot clear a cursor-store failure latch")
	fault.reject_cursor_at = -1
	var resumed_skip := controller.skip_to_result()
	require(bool(resumed_skip.get("ok", false)) and not controller.presentation_paused, "explicit nonterminal Skip retry resumes only after the real Store accepts it")
	# New receipt: reject its first automatic Queue cursor write and verify focus
	# changes cannot turn it into background retries.
	controller.refresh()
	if bool(controller.match_view.get("resume", false)):
		_prepare_bot_plan(controller)
		if bool(controller.checked_plan().get("ok", false)):
			controller.run_cycle()
	var receipt_one_id := controller.receipt_request_id()
	controller.presentation_elapsed = 0.10
	controller.refresh()
	require(is_equal_approx(controller.presentation_elapsed, 0.10), "same real receipt identity preserves its local presentation clock across duplicate reads")
	fault.reject_cursor_at = fault.cursor_temp_calls + 1
	for step in 4:
		controller.advance_presentation(0.10, false)
	var rejected_calls := fault.cursor_temp_calls
	controller.set_presentation_paused(true)
	controller.set_presentation_paused(false)
	for step in 4:
		controller.advance_presentation(0.10, false)
	require(controller.presentation_paused and fault.cursor_temp_calls == rejected_calls, "failed real automatic acknowledgement remains latched without focus-triggered retry")
	fault.reject_cursor_at = -1
	var retried := controller.retry_stage()
	require(bool(retried.get("ok", false)) and fault.cursor_temp_calls == rejected_calls + 1, "explicit Retry persists exactly one real cursor acknowledgement")
	require(str(controller.cached_stage().get("name", "")) == "Print", "real Queue acknowledgement reaches the projected Print stage")
	var print_cursor := controller.cursor
	var expected_bands := [2500, 5000, 7500]
	for band in expected_bands:
		for step in 4:
			controller.advance_presentation(0.10, true)
		require(controller.cursor == print_cursor and controller.stage_progress_bps(true) == int(band), "reduced-motion Print retains 1.60 seconds and reaches only the approved four visual bands")
	for step in 3:
		controller.advance_presentation(0.10, true)
	controller.advance_presentation(0.09, true)
	require(controller.cursor == print_cursor and controller.stage_progress_bps(true) == 7500, "reduced-motion Print does not acknowledge before 1.60 seconds")
	controller.advance_presentation(0.01, true)
	require(controller.cursor == print_cursor + 1, "reduced-motion Print acknowledges exactly once at its full 1.60-second boundary")
	var next_receipt := controller.skip_to_result()
	require(bool(next_receipt.get("ok", false)), "nonterminal receipt Skip reaches the next real Plan after Print")
	_prepare_bot_plan(controller)
	var second_run := controller.run_cycle()
	require(bool(second_run.get("ok", false)) and controller.cursor == 0 and controller.receipt_request_id() != receipt_one_id and is_zero_approx(controller.presentation_elapsed), "a new real Run request at cursor zero resets the receipt clock without reusing the prior boundary")
	runtime.close()


func _test_real_native_plan_pointer_actions() -> void:
	var fault := StoreFault.new()
	var fixture_path := _fixture_path("native-pointer")
	var opened := _open_real_runtime(fixture_path, fault)
	require(bool(opened.get("ok", false)), "native pointer fixture opens through the real Runtime")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	if not _bootstrap_applied(runtime, "battle-pointer"):
		require(false, "native pointer fixture reaches the applied 3/15 loadout")
		runtime.close()
		return
	var shell := Shell.new()
	shell.size = Vector2(576, 1024)
	add_child(shell)
	shell.configure_runtime(runtime)
	var started: Dictionary = shell.battle_controller.start_or_resume()
	require(bool(started.get("ok", false)), "native pointer fixture persists a real Start before mounting Battle")
	if not bool(started.get("ok", false)):
		shell.queue_free()
		runtime.close()
		return
	shell.replace_route("battle")
	await get_tree().process_frame
	var before := FileAccess.get_file_as_bytes(_ledger_path(fixture_path))
	await _click_design(shell, Vector2(137.2, 1092.5))
	var docket_button := shell.find_child("BattleFabrication_player_member_cinderpaw", true, false) as Button
	require(str(shell.battle_controller.local_plan.get("fabrication_id", "")) == "player:member:cinderpaw" and docket_button != null and docket_button.find_child("BattleSelectedRing", true, false) != null, "pointer press/release stores fabrication and leaves a persistent full-parent selected ring")
	var support := _first_button_with_prefix(shell, "BattleSupport_")
	require(support != null, "native Battle mounts a projected player-hand Button owner for pointer input")
	var support_mounted := support != null
	if support != null:
		await _click_control(support)
	var selected_support_button := _first_button_with_prefix(shell, "BattleSupport_")
	require(support_mounted and not str(shell.battle_controller.local_plan.get("support_copy_id", "")).is_empty() and selected_support_button != null and selected_support_button.find_child("BattleSelectedRing", true, false) != null, "pointer press/release reaches a real projected hand parent with persistent selected ring")
	var clear: Button = shell.find_child("BattleClearPlan", true, false) as Button
	if clear != null:
		await _click_control(clear)
	require(shell.battle_controller.local_plan.get("fabrication_id", "") == "" and shell.battle_controller.local_plan.get("support_copy_id", "") == "" and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == before, "native Clear Plan pointer action removes only local selections with zero cursor or ledger write")
	var suit := _button_with_accessibility(shell, "Full Suit")
	require(suit != null, "native Battle exposes the authoritative Full Suit hand owner rather than a legacy card back")
	if suit != null:
		await _click_control(suit)
	require(shell.modal == "battle_equipment" and not str(shell.battle_controller.local_plan.get("support_copy_id", "")).is_empty() and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == before, "equipment selection opens one exclusive provisional target sheet with zero writes")
	var blocker := shell.find_child("BattleEquipmentBlocker", true, false) as ColorRect
	require(blocker != null and blocker.mouse_filter == Control.MOUSE_FILTER_STOP, "equipment sheet mounts a pointer-blocking stage-local modal owner")
	var modal_cancel := shell.find_child("BattleEquipmentCancel", true, false) as Button
	require(modal_cancel != null and not modal_cancel.disabled, "equipment sheet mounts its registered native Cancel pointer owner")
	if modal_cancel != null:
		await _click_control(modal_cancel)
	await get_tree().process_frame
	await get_tree().process_frame
	var restored_source := shell.get_viewport().gui_get_focus_owner()
	require(shell.modal.is_empty() and str(shell.battle_controller.local_plan.get("support_copy_id", "")).is_empty() and restored_source != null and str(restored_source.name).begins_with("BattleSupport_") and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == before, "native Cancel pointer clears provisional equipment state, restores source focus, and writes nothing")
	suit = _button_with_accessibility(shell, "Full Suit")
	if suit != null:
		await _click_control(suit)
	var target := shell.find_child("BattleEquipmentTarget_player_member_cinderpaw", true, false) as Button
	var target_mounted := target != null
	require(target_mounted and target.text.contains("NEXT"), "equipment target sheet labels its legal same-Plan fabrication as NEXT")
	if target != null:
		await _click_control(target)
	require(target_mounted and shell.modal.is_empty() and not str(shell.battle_controller.local_plan.get("equipment_target_id", "")).is_empty(), "equipment target row finalizes the selected canonical target")
	suit = _button_with_accessibility(shell, "Full Suit")
	if suit != null:
		await _click_control(suit)
	require(str(shell.battle_controller.local_plan.get("support_copy_id", "")).is_empty() and str(shell.battle_controller.local_plan.get("equipment_target_id", "")).is_empty(), "retapping the finalized support clears both provisional fields without reopening the modal")
	shell.queue_free()
	await get_tree().process_frame
	runtime.close()


func _test_real_native_start_and_run_retry_actions() -> void:
	var invalid_fault := StoreFault.new()
	var invalid_opened := _open_real_runtime(_fixture_path("native-invalid-preflight"), invalid_fault)
	require(bool(invalid_opened.get("ok", false)), "invalid preflight fixture opens through the real Runtime")
	if bool(invalid_opened.get("ok", false)):
		var invalid_runtime: Variant = invalid_opened.runtime
		var invalid_shell := Shell.new()
		invalid_shell.size = Vector2(576, 1024)
		add_child(invalid_shell)
		invalid_shell.configure_runtime(invalid_runtime)
		invalid_shell.navigate("preflight")
		await get_tree().process_frame
		var open_team := invalid_shell.find_child("BattleStartResume", true, false) as Button
		require(open_team != null and str(open_team.accessibility_name).begins_with("OPEN TEAM"), "invalid native preflight exposes Open Team instead of a disabled Start")
		if open_team != null:
			await _click_control(open_team)
		require(invalid_shell.route == "team", "invalid preflight Open Team pointer action enters the editable Team route")
		invalid_shell.queue_free()
		await get_tree().process_frame
		invalid_runtime.close()

	var fault := StoreFault.new()
	var fixture_path := _fixture_path("native-start-run-retry")
	var opened := _open_real_runtime(fixture_path, fault)
	require(bool(opened.get("ok", false)), "native Start and Run retry fixture opens through the actual Store")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	if not _bootstrap_applied(runtime, "battle-start-run"):
		require(false, "native Start and Run retry fixture reaches the applied 3/15 loadout")
		runtime.close()
		return
	var shell := Shell.new()
	shell.size = Vector2(576, 1024)
	add_child(shell)
	shell.configure_runtime(runtime)
	shell.navigate("preflight")
	await get_tree().process_frame
	var start_before := FileAccess.get_file_as_bytes(_ledger_path(fixture_path))
	fault.reject_ledger_at = fault.ledger_temp_calls + 1
	var start_button := shell.find_child("BattleStartResume", true, false) as Button
	require(start_button != null, "valid native preflight mounts its Start Battle pointer owner")
	if start_button != null:
		await _click_control(start_button)
	var frozen_start_id := str(shell.battle_controller.envelopes.get("start", {}).get("id", ""))
	require(shell.route == "preflight" and not frozen_start_id.is_empty() and not shell.battle_controller.last_error.is_empty() and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == start_before and not bool(runtime.view().match.get("has_current", false)), "failed pointer Start retains one frozen request envelope without creating a match, wallet, or ledger mutation")
	fault.reject_ledger_at = -1
	start_button = shell.find_child("BattleStartResume", true, false) as Button
	if start_button != null:
		await _click_control(start_button)
	var start_ledger := _json_file(_ledger_path(fixture_path))
	var started_match_id := str(runtime.view().match.get("current_match_id", ""))
	require(shell.route == "battle" and not started_match_id.is_empty() and start_ledger.get("starts", {}).has(frozen_start_id), "pointer Start Retry reuses the frozen ID and persists exactly that real Start")
	var start_bytes := FileAccess.get_file_as_bytes(_ledger_path(fixture_path))
	shell.replace_route("preflight")
	await get_tree().process_frame
	var resume_button := shell.find_child("BattleStartResume", true, false) as Button
	require(resume_button != null and str(resume_button.accessibility_name).begins_with("RESUME"), "accepted Start changes preflight to Resume rather than a new Match")
	if resume_button != null:
		await _click_control(resume_button)
	require(shell.route == "battle" and str(runtime.view().match.get("current_match_id", "")) == started_match_id and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == start_bytes, "pointer Resume never creates or persists another Start")

	var fabrication := shell.find_child("BattleFabrication_player_member_cinderpaw", true, false) as Button
	require(fabrication != null, "newly started Plan mounts Cinderpaw's real fabrication owner")
	if fabrication != null:
		await _click_control(fabrication)
	var checked: Dictionary = shell.battle_controller.checked_plan()
	require(bool(checked.get("ok", false)), "native pointer fabrication yields an authoritative runnable Plan")
	var run_before := FileAccess.get_file_as_bytes(_ledger_path(fixture_path))
	fault.reject_ledger_at = fault.ledger_temp_calls + 1
	var run_button := shell.find_child("BattleRunCycle", true, false) as Button
	require(run_button != null and not run_button.disabled, "native Plan exposes an enabled Run Cycle owner")
	if run_button != null:
		await _click_control(run_button)
	var frozen_run_id := str(shell.battle_controller.envelopes.get("run", {}).get("id", ""))
	var failed_pending: Dictionary = runtime.pending_receipt()
	require(shell.route == "battle" and not frozen_run_id.is_empty() and not shell.battle_controller.last_error.is_empty() and int(failed_pending.get("stage_count", -1)) == 0 and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == run_before, "failed pointer Run retains its Plan and frozen ID without prematurely creating a receipt or ledger mutation")
	fault.reject_ledger_at = -1
	run_button = shell.find_child("BattleRunCycle", true, false) as Button
	if run_button != null:
		await _click_control(run_button)
	var run_ledger := _json_file(_ledger_path(fixture_path))
	var current_record: Dictionary = run_ledger.get("current", {})
	var accepted_request := str((current_record.get("presentation", {}) as Dictionary).get("request_id", ""))
	var receipt_id: String = shell.battle_controller.receipt_request_id()
	require(not receipt_id.is_empty() and accepted_request == frozen_run_id and shell.battle_controller.cursor == 0, "pointer Run Retry persists only the frozen Run ID and opens its first receipt cursor")
	var run_bytes := FileAccess.get_file_as_bytes(_ledger_path(fixture_path))
	# Receipt playback owns this hardware as Skip, so its old Run center cannot be
	# treated as a duplicate Run callback.  The foundation case invokes the
	# controller duplicate guard directly; here prove the editable owner is gone.
	var removed_run := shell.find_child("BattleRunCycle", true, false) as Button
	require(removed_run == null and shell.battle_controller.receipt_request_id() == receipt_id and shell.battle_controller.cursor == 0 and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == run_bytes and shell.battle_controller.last_error.is_empty(), "durable receipt playback removes the editable Run owner; the controller duplicate guard remains covered by foundation")
	shell.queue_free()
	await get_tree().process_frame
	runtime.close()


func _test_real_native_hand_faces_and_heated_forecast() -> void:
	var fault := StoreFault.new()
	var fixture_path := _fixture_path("native-hand-faces")
	var opened := _open_real_runtime(fixture_path, fault)
	require(bool(opened.get("ok", false)), "native hand fixture opens through the real Runtime and Store")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	if not _bootstrap_applied(runtime, "battle-hand-faces"):
		require(false, "native hand fixture reaches the applied production loadout")
		runtime.close()
		return
	var shell := Shell.new()
	shell.size = Vector2(576, 1024)
	add_child(shell)
	shell.configure_runtime(runtime)
	var controller: Variant = shell.battle_controller
	if not bool(controller.start_or_resume().get("ok", false)):
		require(false, "native hand fixture starts the real sequence-one match")
		shell.queue_free()
		runtime.close()
		return
	shell.replace_route("battle")
	var face_ids: Dictionary = {}
	var heated_forecast_verified := false
	for cycle in range(1, 20):
		shell._render()
		for copy_value in controller.player_view.get("own", {}).get("hand", []):
			if not copy_value is Dictionary:
				continue
			var copy: Dictionary = copy_value
			var copy_id := str(copy.get("copy_id", ""))
			var card_id := str(copy.get("card_id", ""))
			var owner := shell.find_child("BattleSupport_%s" % copy_id.replace(":", "_"), true, false) as Button
			var art := shell.find_child("BattleSupportArt_%s" % copy_id.replace(":", "_"), true, false) as TextureRect
			var accessible_name: String = {
				"raw_filament": "Raw Filament",
				"heated_spool": "Heated Spool",
				"standard_full_suit": "Full Suit",
				"iron_gem": "Iron Gem",
				"forge_surge": "Forge Surge",
			}.get(card_id, card_id)
			if owner != null and art != null and art.texture != null and owner.accessibility_name.contains(accessible_name):
				face_ids[card_id] = true
		var heated_copy := _hand_copy_id(controller.player_view, "heated_spool")
		if not heated_copy.is_empty() and int(controller.player_view.get("own", {}).get("filament", 0)) == 8:
			controller.clear_plan()
			controller.set_support(heated_copy)
			var heated_checked: Dictionary = controller.checked_plan()
			heated_forecast_verified = bool(heated_checked.get("ok", false)) and int((heated_checked.get("forecast", {}) as Dictionary).get("available_filament", -1)) == 9
			controller.clear_plan()
			if heated_forecast_verified and face_ids.size() == 5:
				break
		_prepare_bot_plan(controller)
		if not bool(controller.run_cycle().get("ok", false)) or _terminal_result_index(controller.receipt) >= 0 or not bool(controller.skip_to_result().get("ok", false)):
			break
	require(face_ids.has("raw_filament") and face_ids.has("heated_spool") and face_ids.has("standard_full_suit") and face_ids.has("iron_gem") and face_ids.has("forge_surge"), "native own-hand rendering mounts a non-null V3 face texture and accessible owner for all five approved Support IDs")
	require(heated_forecast_verified, "real checked native forecast caps 8 filament plus Heated Spool at Available 9 rather than UI-derived 11")
	shell.queue_free()
	await get_tree().process_frame
	runtime.close()


func _test_real_gem_ready_swap_progression() -> void:
	var fault := StoreFault.new()
	var fixture_path := _fixture_path("progression-gem-ready-swap")
	var opened := _open_real_runtime(fixture_path, fault)
	require(bool(opened.get("ok", false)), "F1 progression fixture opens through the real Runtime and Store")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	if not _bootstrap_applied(runtime, "battle-f1"):
		require(false, "F1 progression fixture persists the accepted first-session and applied Cinderpaw loadout")
		runtime.close()
		return
	var controller := Controller.new()
	controller.configure(runtime)
	require(bool(controller.start_or_resume().get("ok", false)), "F1 progression starts the genuine sequence-one match")
	if not controller.has_current():
		runtime.close()
		return
	var cinder_id := "player:member:cinderpaw"
	var aquafin_id := "player:member:aquafin"
	var gem_copy := _hand_copy_id(controller.player_view, "iron_gem")
	controller.set_fabrication(cinder_id)
	controller.set_support(gem_copy)
	controller.set_equipment_target(cinder_id)
	var cycle_one_checked: Dictionary = controller.checked_plan()
	require(bool(cycle_one_checked.get("ok", false)) and str((cycle_one_checked.get("plan", {}) as Dictionary).get("fabrication_id", "")) == cinder_id and str((cycle_one_checked.get("plan", {}) as Dictionary).get("equipment_target_id", "")) == cinder_id, "F1 Cycle 1 uses the checked canonical Cinderpaw fabrication and Iron Gem target")
	var cycle_one: Dictionary = controller.run_cycle()
	require(bool(cycle_one.get("ok", false)), "F1 Cycle 1 persists its real companion-before-equipment FIFO receipt")
	if not bool(cycle_one.get("ok", false)):
		runtime.close()
		return
	var cycle_one_receipt: Dictionary = controller.receipt.duplicate(true)
	require(_receipt_has_event(cycle_one_receipt, "print_work", "player") and _receipt_has_event(cycle_one_receipt, "equipment_queued", "player") and not _receipt_has_event(cycle_one_receipt, "equipment_fit", "player"), "F1 Cycle 1 projects both the companion print and queued Iron Gem without fitting it early")
	require(bool(controller.skip_to_result().get("ok", false)), "F1 Cycle 1 advances only through the real cursor to its next editable Plan")
	controller.set_fabrication(aquafin_id)
	controller.set_support(_hand_copy_id(controller.player_view, "raw_filament"))
	var cycle_two_checked: Dictionary = controller.checked_plan()
	require(bool(cycle_two_checked.get("ok", false)) and str((cycle_two_checked.get("plan", {}) as Dictionary).get("fabrication_id", "")) == aquafin_id, "F1 Cycle 2 keeps Aquafin fabrication independent from its real Raw Filament Support")
	var cycle_two: Dictionary = controller.run_cycle()
	require(bool(cycle_two.get("ok", false)), "F1 Cycle 2 persists the real FIFO Gem Fit receipt")
	if not bool(cycle_two.get("ok", false)):
		runtime.close()
		return
	var fit: Dictionary = _receipt_event(controller.receipt, "equipment_fit", "player")
	var fit_snapshot: Dictionary = _receipt_event_snapshot(controller.receipt, "equipment_fit", "player")
	var fitted_cinder: Dictionary = _member_by_identity(fit_snapshot.get("own", {}), cinder_id)
	require(str(fit.get("card_id", "")) == "iron_gem" and str(fit.get("target_identity_id", "")) == cinder_id and bool(fitted_cinder.get("gem_slot", false)), "F1 Cycle 2 projects the exact Iron Gem Fit on persistent Cinderpaw with its gem slot set")
	require(_receipt_attack_damage(controller.receipt, "player") == 9, "F1 Cycle 2 projects Cinderpaw's Gem-equipped attack lock damage as 9 without Forge Surge")
	require(bool(controller.skip_to_result().get("ok", false)), "F1 Cycle 2 acknowledges only its real nonterminal receipt cursor")
	controller.clear_plan()
	require(bool(controller.checked_plan().get("ok", false)) and bool(controller.run_cycle().get("ok", false)), "F1 Cycle 3 accepts a genuine empty Plan")
	var entered: Dictionary = _receipt_event(controller.receipt, "companion_entered", "player")
	var entered_snapshot: Dictionary = _receipt_event_snapshot(controller.receipt, "companion_entered", "player")
	var ready_aquafin: Dictionary = _member_by_identity(entered_snapshot.get("own", {}), aquafin_id)
	require(str(entered.get("member_identity_id", "")) == aquafin_id and str(ready_aquafin.get("status", "")) == "Ready", "F1 Cycle 3 moves the same Aquafin identity into Ready through the projected Enter event")
	require(bool(controller.skip_to_result().get("ok", false)), "F1 Cycle 3 reaches its next editable Plan through Runtime cursor acknowledgement")
	var cinder_hp_before_swap := int(_member_by_identity(controller.player_view.get("own", {}), cinder_id).get("hp", -1))
	var pre_swap_snapshot: Dictionary = controller.player_view.duplicate(true)
	var swap_shell := Shell.new()
	swap_shell.size = Vector2(576, 1024)
	add_child(swap_shell)
	swap_shell.configure_runtime(runtime)
	swap_shell.replace_route("battle")
	await get_tree().process_frame
	var ready_swap := swap_shell.find_child("BattleSwap_player_member_aquafin", true, false) as Button
	require(ready_swap != null and not ready_swap.disabled, "F1 native Plan exposes Aquafin's real Ready bay swap owner before the authoritative Swap")
	if ready_swap != null:
		await _click_control(ready_swap)
	var selected_swap := swap_shell.find_child("BattleSwap_player_member_aquafin", true, false) as Button
	var disabled_hand := _first_button_with_prefix(swap_shell, "BattleSupport_")
	require(str(swap_shell.battle_controller.local_plan.get("swap_id", "")) == aquafin_id and selected_swap != null and selected_swap.find_child("BattleSelectedRing", true, false) != null and disabled_hand != null and disabled_hand.disabled, "F1 native Ready swap pointer retains a full-parent selected ring and disables the mutually exclusive Support hand")
	if selected_swap != null:
		await _click_control(selected_swap)
	var restored_hand := _first_button_with_prefix(swap_shell, "BattleSupport_")
	require(str(swap_shell.battle_controller.local_plan.get("swap_id", "")).is_empty() and restored_hand != null and not restored_hand.disabled, "F1 retapping the selected native Ready swap clears it and restores the Support hand without a write")
	swap_shell.queue_free()
	await get_tree().process_frame
	controller.set_swap(aquafin_id)
	var swap_checked: Dictionary = controller.checked_plan()
	require(bool(swap_checked.get("ok", false)) and str((swap_checked.get("plan", {}) as Dictionary).get("swap_id", "")) == aquafin_id, "F1 Cycle 4 checks the canonical Ready Aquafin swap identity")
	require(bool(controller.run_cycle().get("ok", false)), "F1 Cycle 4 persists the real Team Swap receipt")
	var swap: Dictionary = _receipt_event(controller.receipt, "swap", "player")
	var swap_snapshot: Dictionary = _receipt_event_snapshot(controller.receipt, "swap", "player")
	var swapped_cinder: Dictionary = _member_by_identity(swap_snapshot.get("own", {}), cinder_id)
	var swapped_aquafin: Dictionary = _member_by_identity(swap_snapshot.get("own", {}), aquafin_id)
	require(str(swap.get("active_member_id", "")) == aquafin_id and str(swap.get("reserve_member_id", "")) == cinder_id and str((swap_snapshot.get("own", {}) as Dictionary).get("active_member_id", "")) == aquafin_id and str(swapped_aquafin.get("status", "")) == "Active", "F1 Swap makes Aquafin the sole projected Active companion through the canonical event")
	require(str(swapped_cinder.get("status", "")) == "Ready" and bool(swapped_cinder.get("gem_slot", false)) and int(swapped_cinder.get("hp", -2)) == cinder_hp_before_swap, "F1 Swap preserves Cinderpaw identity, exact health, and Gem slot in Ready without a duplicate")
	var swap_visual := Visual.new()
	add_child(swap_visual)
	swap_visual.set_previous_projection(pre_swap_snapshot)
	swap_visual.set_projection(swap_snapshot, false)
	swap_visual.set_stage(_receipt_stage(controller.receipt, "Swap"), 0, false, "f1-swap")
	var incoming_start: Dictionary = swap_visual.figure_snapshot(aquafin_id)
	var outgoing_start: Dictionary = swap_visual.figure_snapshot(cinder_id)
	swap_visual.set_stage(_receipt_stage(controller.receipt, "Swap"), 5000, false, "f1-swap")
	var incoming_mid: Dictionary = swap_visual.figure_snapshot(aquafin_id)
	var outgoing_mid: Dictionary = swap_visual.figure_snapshot(cinder_id)
	swap_visual.set_stage(_receipt_stage(controller.receipt, "Swap"), 10000, false, "f1-swap")
	var incoming_end: Dictionary = swap_visual.figure_snapshot(aquafin_id)
	var outgoing_end: Dictionary = swap_visual.figure_snapshot(cinder_id)
	var separated_mid := absf(float((incoming_mid.get("shadow_center", Vector2.ZERO) as Vector2).x) - float((outgoing_mid.get("shadow_center", Vector2.ZERO) as Vector2).x)) >= 120.0
	require(bool(incoming_start.get("visible", false)) and bool(outgoing_start.get("visible", false)) and bool(incoming_mid.get("visible", false)) and bool(outgoing_mid.get("visible", false)) and bool(incoming_end.get("visible", false)) and bool(outgoing_end.get("visible", false)) and float((incoming_start.get("sprite_size", Vector2.ZERO) as Vector2).x) < float((incoming_end.get("sprite_size", Vector2.ZERO) as Vector2).x) and float((outgoing_start.get("sprite_size", Vector2.ZERO) as Vector2).x) > float((outgoing_end.get("sprite_size", Vector2.ZERO) as Vector2).x) and separated_mid, "F1 Swap keeps both canonical figures visible at 0, 50, and 100 percent while interpolating Ready/Active scale and separated lane shadows")
	swap_visual.queue_free()
	await get_tree().process_frame
	require(bool(controller.skip_to_result().get("ok", false)), "F2 continuation acknowledges the recorded Swap before returning to a real editable Plan")
	var found_replacement := false
	for continuation in range(1, 28):
		_prepare_bot_plan(controller)
		var continuation_checked: Dictionary = controller.checked_plan()
		if not bool(continuation_checked.get("ok", false)) or not bool(controller.run_cycle().get("ok", false)):
			break
		var defeat_event: Dictionary = _receipt_event_any_seat(controller.receipt, "defeat")
		var replacement_event: Dictionary = _receipt_event_any_seat(controller.receipt, "replacement")
		if not defeat_event.is_empty() and not replacement_event.is_empty():
			var seat := str(defeat_event.get("seat", ""))
			var defeat_snapshot: Dictionary = _receipt_event_snapshot(controller.receipt, "defeat", seat)
			var replace_snapshot: Dictionary = _receipt_event_snapshot(controller.receipt, "replacement", seat)
			var defeat_side: Dictionary = defeat_snapshot.get("own", {}) if seat == "player" else defeat_snapshot.get("opponent", {})
			var replace_side: Dictionary = replace_snapshot.get("own", {}) if seat == "player" else replace_snapshot.get("opponent", {})
			var defeated_id := str(defeat_event.get("member_identity_id", ""))
			var replacement_id := str(replacement_event.get("member_identity_id", ""))
			var defeated: Dictionary = _member_by_identity(defeat_side, defeated_id)
			var replacement: Dictionary = _member_by_identity(replace_side, replacement_id)
			require(replacement_id == _first_ready_by_priority(defeat_side) and str(defeated.get("status", "")) == "Defeated" and int(defeated.get("hp", -1)) == 0, "F2 Defeat retains the zero-HP defeated identity and chooses the first Ready priority record for automatic replacement")
			require(str(replace_side.get("active_member_id", "")) == replacement_id and str(replacement.get("status", "")) == "Active" and str(_member_by_identity(replace_side, defeated_id).get("status", "")) == "Defeated", "F2 Replace promotes exactly the named Ready identity without resurrecting or duplicating the defeated companion")
			found_replacement = true
			break
		if _terminal_result_index(controller.receipt) >= 0 or not bool(controller.skip_to_result().get("ok", false)):
			break
	require(found_replacement, "F2 adaptive real Runtime continuation reaches a nonterminal Defeat then automatic Replace boundary")
	runtime.close()


func _test_real_hold_progression() -> void:
	# The deterministic HOLD candidate is intentionally run through Runtime.  It
	# does not manufacture missing Actives, filament, or receipt events.
	var fault := StoreFault.new()
	var fixture_path := _fixture_path("progression-hold")
	var opened := _open_real_runtime(fixture_path, fault)
	require(bool(opened.get("ok", false)), "F3 HOLD fixture opens through the real Runtime and Store")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	if not _bootstrap_applied(runtime, "battle-f3"):
		require(false, "F3 HOLD fixture reaches an applied production loadout")
		runtime.close()
		return
	var controller := Controller.new()
	controller.configure(runtime)
	require(bool(controller.start_or_resume().get("ok", false)), "F3 HOLD fixture starts the real sequence-one match")
	var found_hold := false
	for cycle in range(1, 24):
		var player: Dictionary = controller.player_view
		var own: Dictionary = player.get("own", {})
		var opening_hold_boundary := str(own.get("active_member_id", "")).is_empty() and (own.get("ready_member_ids", []) as Array).is_empty() and int(own.get("filament", 0)) < 3 and _has_unspent_or_printing(own)
		var plan := {"fabrication_id":"", "support_copy_id":"", "equipment_target_id":"", "swap_id":""} if opening_hold_boundary else _low_filament_hold_plan(player, cycle)
		controller.local_plan = plan
		var checked: Dictionary = controller.checked_plan()
		var forecast: Dictionary = checked.get("forecast", {})
		if not bool(checked.get("ok", false)):
			# An unaffordable missing default is the exact F3 boundary.  It is
			# legal precisely because no active/ready companion can be printed.
			if str(forecast.get("default_fabrication_reason", "")) == "default_need_filament":
				var no_fabrication := str((checked.get("plan", {}) as Dictionary).get("fabrication_id", "")).is_empty()
				require(no_fabrication, "F3 keeps the unaffordable default fabrication field empty before the genuine HOLD Run")
			else:
				break
		var run: Dictionary = controller.run_cycle()
		if not bool(run.get("ok", false)):
			break
		var attack_stage: Dictionary = _receipt_stage(controller.receipt, "AttackLock")
		var damage_stage: Dictionary = _receipt_stage(controller.receipt, "Damage")
		var holds: Array = _events_of_type(attack_stage, "hold")
		if opening_hold_boundary and holds.size() == 2 and (damage_stage.get("events", []) as Array).is_empty():
			var same_beat := str((holds[0] as Dictionary).get("beat_id", "")) == str((holds[1] as Dictionary).get("beat_id", "")) and not str((holds[0] as Dictionary).get("beat_id", "")).is_empty()
			require(str((checked.get("plan", {}) as Dictionary).get("fabrication_id", "")).is_empty() and str(forecast.get("default_fabrication_reason", "")) == "default_need_filament" and same_beat, "F3 real unaffordable default produces two same-beat HOLD events, no damage, and default_need_filament")
			found_hold = true
			break
		if not bool(controller.skip_to_result().get("ok", false)):
			break
	require(found_hold, "F3 invariant-driven real Runtime path reaches a nonterminal low-filament HOLD without authority mutation")
	runtime.close()


func _hand_copy_id(player_view: Dictionary, card_id: String) -> String:
	for value in player_view.get("own", {}).get("hand", []):
		if value is Dictionary and str(value.get("card_id", "")) == card_id:
			return str(value.get("copy_id", ""))
	return ""


func _receipt_stage(receipt: Dictionary, stage_name: String) -> Dictionary:
	for value in receipt.get("stages", []):
		if value is Dictionary and str(value.get("name", "")) == stage_name:
			return (value as Dictionary).duplicate(true)
	return {}


func _events_of_type(stage: Dictionary, event_type: String) -> Array:
	var values: Array = []
	for value in stage.get("events", []):
		if value is Dictionary and str(value.get("type", "")) == event_type:
			values.append((value as Dictionary).duplicate(true))
	return values


func _receipt_has_event(receipt: Dictionary, event_type: String, seat: String) -> bool:
	return not _receipt_event(receipt, event_type, seat).is_empty()


func _receipt_event(receipt: Dictionary, event_type: String, seat: String) -> Dictionary:
	for stage_value in receipt.get("stages", []):
		if not stage_value is Dictionary:
			continue
		for event_value in (stage_value as Dictionary).get("events", []):
			if event_value is Dictionary and str(event_value.get("type", "")) == event_type and str(event_value.get("seat", "")) == seat:
				return (event_value as Dictionary).duplicate(true)
	return {}


func _receipt_event_any_seat(receipt: Dictionary, event_type: String) -> Dictionary:
	for stage_value in receipt.get("stages", []):
		if not stage_value is Dictionary:
			continue
		for event_value in (stage_value as Dictionary).get("events", []):
			if event_value is Dictionary and str(event_value.get("type", "")) == event_type:
				return (event_value as Dictionary).duplicate(true)
	return {}


func _receipt_event_snapshot(receipt: Dictionary, event_type: String, seat: String) -> Dictionary:
	for stage_value in receipt.get("stages", []):
		if not stage_value is Dictionary:
			continue
		var stage: Dictionary = stage_value
		for event_value in stage.get("events", []):
			if event_value is Dictionary and str(event_value.get("type", "")) == event_type and str(event_value.get("seat", "")) == seat:
				return (stage.get("snapshot", {}) as Dictionary).duplicate(true)
	return {}


func _member_by_identity(own: Dictionary, identity_id: String) -> Dictionary:
	for value in own.get("members", []):
		if value is Dictionary and str(value.get("identity_id", "")) == identity_id:
			return (value as Dictionary).duplicate(true)
	return {}


func _has_unspent_or_printing(own: Dictionary) -> bool:
	for value in own.get("members", []):
		if value is Dictionary and str(value.get("status", "")) in ["Unspent", "Printing"]:
			return true
	return false


func _first_ready_by_priority(side: Dictionary) -> String:
	var members: Dictionary = {}
	for value in side.get("members", []):
		if value is Dictionary:
			members[str(value.get("identity_id", ""))] = value
	for identity_id in side.get("priority", []):
		var member: Dictionary = members.get(str(identity_id), {})
		if str(member.get("status", "")) == "Ready":
			return str(identity_id)
	return ""


func _receipt_attack_damage(receipt: Dictionary, seat: String) -> int:
	for stage_value in receipt.get("stages", []):
		if not stage_value is Dictionary:
			continue
		for event_value in (stage_value as Dictionary).get("events", []):
			if event_value is Dictionary and str(event_value.get("type", "")) == "attack_locked" and str(event_value.get("seat", "")) == seat:
				return int(event_value.get("damage", 0))
	return 0


func _low_filament_hold_plan(player_view: Dictionary, cycle: int) -> Dictionary:
	# Never fabricate a reserve.  Use only a real cost-two Support when it is
	# presently drawable; this keeps the fixture honest if the deterministic hand
	# order changes while still preserving the F3 invariant.
	var plan := {"fabrication_id":"", "support_copy_id":"", "equipment_target_id":"", "swap_id":""}
	if cycle == 1:
		plan.fabrication_id = "player:member:cinderpaw"
	var desired := ["iron_gem", "forge_surge", "forge_surge", "standard_full_suit", "standard_full_suit", "forge_surge", "iron_gem"]
	var wanted := str(desired[(cycle - 1) % desired.size()])
	for value in player_view.get("own", {}).get("hand", []):
		if value is Dictionary and str(value.get("card_id", "")) == wanted:
			plan.support_copy_id = str(value.get("copy_id", ""))
			if wanted in ["iron_gem", "standard_full_suit"]:
				var active_id := str((player_view.get("own", {}) as Dictionary).get("active_member_id", ""))
				plan.equipment_target_id = active_id if not active_id.is_empty() else "player:member:cinderpaw"
			break
	return plan


func _test_real_terminal_skip_boundary() -> void:
	var fault := StoreFault.new()
	var fixture_path := _terminal_fixture_path()
	var source_bytes := {}
	if not _terminal_setup_root().is_empty():
		for name in _terminal_primary_names():
			source_bytes[name] = FileAccess.get_file_as_bytes(_terminal_setup_root().path_join(name))
		var copied := _copy_terminal_primaries(_terminal_setup_root(), fixture_path.get_base_dir())
		require(copied, "terminal outcome copies only the prepared durable profile, match, and cursor primaries into a fresh fixture")
		if not copied:
			return
	var opened := _open_real_runtime(fixture_path, fault, _terminal_setup_root().is_empty())
	require(bool(opened.get("ok", false)), "terminal fixture opens through the actual Runtime and Store")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	if _terminal_setup_root().is_empty():
		require(_bootstrap_applied(runtime, "battle-terminal"), "terminal fixture reaches a real applied loadout")
		var first: Dictionary = runtime.start("battle-terminal-sequence-one", 1, 2)
		var first_terminal := _play_to_terminal(runtime, str(first.get("match_id", "")), "battle-terminal-first", true)
		require(bool(first.get("ok", false)) and bool(first_terminal.get("ok", false)), "sequence one settles through production Runtime before the ordinary Win fixture")
	var outcome := _terminal_outcome()
	var seed: int = int({"Win":0, "Loss":14, "Draw":44}.get(outcome, 0))
	var second: Dictionary = runtime.start("battle-terminal-sequence-two", 2, seed)
	if not bool(second.get("ok", false)):
		require(false, "prepared sequence two starts through the copied durable fixture")
		runtime.close()
		return
	var terminal := _play_to_terminal(runtime, str(second.get("match_id", "")), "battle-terminal-second", false)
	require(bool(second.get("ok", false)) and bool(terminal.get("ok", false)), "prepared sequence two reaches its real terminal receipt without consuming Result")
	if not bool(terminal.get("ok", false)):
		runtime.close()
		return
	var expected_reward: Dictionary = {"Win":{"coins":30, "xp":40}, "Loss":{"coins":10, "xp":20}, "Draw":{"coins":20, "xp":30}}.get(outcome, {})
	var settled_reward: Dictionary = runtime.current_result()
	require(str(settled_reward.get("result", "")) == outcome and int(settled_reward.get("coins", -1)) == int(expected_reward.get("coins", -2)) and int(settled_reward.get("xp", -1)) == int(expected_reward.get("xp", -2)), "terminal receipt exposes the exact already-settled %s reward once" % outcome)
	var forwarder := RuntimeForwarder.new()
	forwarder.target = runtime
	var controller := Controller.new()
	controller.configure(forwarder)
	var result_index := _terminal_result_index(controller.receipt)
	var reward_before := JSON.stringify(runtime.current_result())
	var wallet_before := JSON.stringify((runtime.view().match as Dictionary).get("wallet", {}))
	var ledger_before := FileAccess.get_file_as_bytes(_ledger_path(fixture_path))
	var terminal_skip := controller.skip_to_result()
	require(bool(terminal_skip.get("ok", false)) and controller.cursor == result_index and controller.cursor < controller.stage_count and forwarder.generic_skip_calls == 0 and JSON.stringify(runtime.current_result()) == reward_before and JSON.stringify((runtime.view().match as Dictionary).get("wallet", {})) == wallet_before and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == ledger_before, "terminal Skip acknowledges every canonical cursor up to visible Result with zero generic skips, wallet mutation, or ledger replay")
	if battle_case == "terminal":
		await _test_native_terminal_result_pointer(runtime, fault, fixture_path, reward_before, wallet_before, ledger_before)
	else:
		fault.reject_cursor_at = fault.cursor_temp_calls + 1
		var blocked_continue := controller.acknowledge_stage()
		require(not bool(blocked_continue.get("ok", false)) and controller.presentation_paused and not bool(runtime.view().match.get("can_start", false)) and JSON.stringify(runtime.current_result()) == reward_before and JSON.stringify((runtime.view().match as Dictionary).get("wallet", {})) == wallet_before and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == ledger_before, "failed final Continue leaves the settled reward, wallet, and ledger unchanged and exposes a real cursor Retry")
		fault.reject_cursor_at = -1
		var continued := controller.retry_stage()
		require(bool(continued.get("ok", false)) and bool(runtime.view().match.get("can_start", false)) and JSON.stringify(runtime.current_result()) == reward_before and JSON.stringify((runtime.view().match as Dictionary).get("wallet", {})) == wallet_before and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == ledger_before, "final Continue retry acknowledges only its cursor and never replays the terminal reward")
	if not source_bytes.is_empty():
		var unchanged := true
		for name in _terminal_primary_names():
			unchanged = unchanged and FileAccess.get_file_as_bytes(_terminal_setup_root().path_join(name)) == source_bytes.get(name, PackedByteArray())
		require(unchanged, "selected terminal outcome leaves all three prepared source primaries byte-identical")
	runtime.close()


func _test_native_terminal_result_pointer(runtime: Variant, fault: StoreFault, fixture_path: String, reward_before: String, wallet_before: String, ledger_before: PackedByteArray) -> void:
	var shell := Shell.new()
	shell.size = Vector2(576, 1024)
	add_child(shell)
	shell.configure_runtime(runtime)
	shell.replace_route("result")
	await get_tree().process_frame
	var continue_button := shell.find_child("BattleResultContinue", true, false) as Button
	require(continue_button != null and str(continue_button.accessibility_name).contains("Continue"), "pending real Win Result mounts the native Continue pointer owner")
	fault.reject_cursor_at = fault.cursor_temp_calls + 1
	if continue_button != null:
		await _click_control(continue_button)
	continue_button = shell.find_child("BattleResultContinue", true, false) as Button
	require(continue_button != null and str(continue_button.accessibility_name).contains("Retry") and not shell.battle_controller.last_error.is_empty() and not bool(runtime.view().match.get("can_start", false)) and JSON.stringify(runtime.current_result()) == reward_before and JSON.stringify((runtime.view().match as Dictionary).get("wallet", {})) == wallet_before and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == ledger_before, "failed native Result Continue pointer keeps the settled result immutable and exposes Retry")
	var back_button := shell.find_child("RouteBack", true, false) as Button
	if back_button != null:
		await _click_control(back_button)
	require(shell.route == "workshop", "native Result Back leaves the pending receipt without consuming it")
	shell.navigate("preflight")
	await get_tree().process_frame
	var resume_button := shell.find_child("BattleStartResume", true, false) as Button
	require(resume_button != null and str(resume_button.accessibility_name).contains("RESUME"), "Back followed by preflight exposes Resume Result rather than New Battle")
	if resume_button != null:
		await _click_control(resume_button)
	require(shell.route == "result", "native Resume returns to the same visible pending Result receipt")
	fault.reject_cursor_at = -1
	continue_button = shell.find_child("BattleResultContinue", true, false) as Button
	if continue_button != null:
		await _click_control(continue_button)
	require(bool(runtime.view().match.get("can_start", false)) and JSON.stringify(runtime.current_result()) == reward_before and JSON.stringify((runtime.view().match as Dictionary).get("wallet", {})) == wallet_before and FileAccess.get_file_as_bytes(_ledger_path(fixture_path)) == ledger_before, "native Result Retry acknowledges only its final cursor and never replays the Win reward")
	shell.queue_free()
	await get_tree().process_frame


func _test_terminal_setup() -> void:
	var fault := StoreFault.new()
	var fixture_path := _fixture_path("terminal-setup")
	var opened := _open_real_runtime(fixture_path, fault)
	require(bool(opened.get("ok", false)), "terminal setup opens the real Runtime and Store")
	if not bool(opened.get("ok", false)):
		return
	var runtime: Variant = opened.runtime
	var draw := _terminal_outcome() == "Draw"
	var starter := "voltwig" if draw else "cinderpaw"
	var team := ["voltwig", "cinderpaw", "mossmunk"] if draw else ["cinderpaw", "aquafin", "mossmunk"]
	require(_bootstrap_applied(runtime, "battle-terminal-setup", starter, team), "terminal setup applies the authoritative first-session loadout")
	var first: Dictionary = runtime.start("battle-terminal-setup-sequence-one", 1, 2)
	var settled := _play_to_terminal(runtime, str(first.get("match_id", "")), "battle-terminal-setup-first", true)
	require(bool(first.get("ok", false)) and bool(settled.get("ok", false)) and bool(runtime.view().match.get("can_start", false)), "terminal setup completes sequence one through Runtime and leaves sequence two startable")
	runtime.close()


func _open_real_runtime(path: String, fault: StoreFault, create := true) -> Dictionary:
	if create:
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		var initial := FileAccess.open(path, FileAccess.WRITE)
		if initial == null:
			return {"ok":false, "error":"Fixture profile could not be created."}
		initial.store_string(JSON.stringify({"schema_version":31, "owned_blueprints":{}, "owned_cards":{}, "printed_models":{}}))
		initial.close()
	elif not FileAccess.file_exists(path):
		return {"ok":false, "error":"Prepared fixture profile is missing."}
	return Runtime.open(path, {"compatible":true, "state":"ready", "schema_version":31, "supported_schema":31, "message":""}, Callable(fault, "allow"))


func _bootstrap_applied(runtime: Variant, prefix: String, starter := "cinderpaw", team := ["cinderpaw", "aquafin", "mossmunk"]) -> bool:
	var chosen: Dictionary = runtime.collection_request("choose_starter", "%s-choose" % prefix, {"starter_id":starter})
	if not bool(chosen.get("ok", false)):
		return false
	var begun: Dictionary = runtime.collection_request("begin_starter_print", "%s-begin" % prefix, {})
	if not bool(begun.get("ok", false)):
		return false
	var completed: Dictionary = runtime.collection_request("complete_starter_print", "%s-complete" % prefix, {"print_id":str(begun.result.print_id)})
	if not bool(completed.get("ok", false)):
		return false
	var acknowledged: Dictionary = runtime.collection_request("acknowledge_grant", "%s-ack" % prefix, {"receipt_id":str(completed.result.receipt_id)})
	if not bool(acknowledged.get("ok", false)):
		return false
	return bool(runtime.collection_request("apply_loadout", "%s-apply" % prefix, {"team":team, "priority":team, "kit":runtime.collection_view().recommended_kit}).get("ok", false))


func _prepare_bot_plan(controller: Variant) -> void:
	var chosen: Dictionary = Bot.choose_plan(controller.player_view)
	if bool(chosen.get("ok", false)):
		controller.local_plan = (chosen.plan as Dictionary).duplicate(true)


func _play_to_terminal(runtime: Variant, match_id: String, prefix: String, consume_terminal: bool) -> Dictionary:
	for cycle in range(1, 80):
		var match: Dictionary = runtime.view().match
		var player: Dictionary = match.player
		var chosen: Dictionary = Bot.choose_plan(player)
		if not bool(chosen.get("ok", false)):
			return {"ok":false, "error":"Bot could not choose a legal production Plan."}
		var request_id := "%s-run-%d" % [prefix, cycle]
		var run: Dictionary = runtime.run_cycle(match_id, request_id, chosen.plan)
		if not bool(run.get("ok", false)):
			return run
		var pending: Dictionary = runtime.pending_receipt()
		var result_index := _terminal_result_index(pending.get("receipt", {}))
		if result_index >= 0:
			if not consume_terminal:
				return {"ok":true, "request_id":request_id, "result_index":result_index}
			var terminal_skip: Dictionary = runtime.skip(match_id, request_id, int(pending.get("cursor", 0)))
			if not bool(terminal_skip.get("ok", false)):
				return terminal_skip
			return {"ok":true, "result":str((runtime.view().match as Dictionary).get("player", {}).get("result", ""))}
		var skipped: Dictionary = runtime.skip(match_id, request_id, int(pending.get("cursor", 0)))
		if not bool(skipped.get("ok", false)):
			return skipped
	return {"ok":false, "error":"Terminal fixture exceeded the bounded cycle budget."}


func _terminal_result_index(value: Variant) -> int:
	if not value is Dictionary:
		return -1
	var stages: Array = value.get("stages", [])
	for index in stages.size():
		if not stages[index] is Dictionary or str((stages[index] as Dictionary).get("name", "")) != "Result":
			continue
		for event_value in (stages[index] as Dictionary).get("events", []):
			if event_value is Dictionary and str(event_value.get("type", "")) == "terminal":
				return index
	return -1


func _fixture_path(case_name: String) -> String:
	return _qa_root().get_base_dir().path_join("ui-battle-fixtures").path_join(case_name).path_join("profile.json")


func _terminal_fixture_path() -> String:
	return _fixture_path("terminal-%s" % _terminal_outcome().to_lower())


func _terminal_primary_names() -> Array[String]:
	return ["profile.json", "profile.team-match.json", "profile.team-cursor.json"]


func _terminal_setup_root() -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with("--terminal-setup-root="):
			return value.trim_prefix("--terminal-setup-root=")
	return ""


func _terminal_outcome() -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with("--terminal-outcome="):
			return value.trim_prefix("--terminal-outcome=").capitalize()
	return "Win"


func _copy_terminal_primaries(source_root: String, destination_root: String) -> bool:
	var source_base := source_root.simplify_path().replace("\\", "/")
	var destination_base := destination_root.simplify_path().replace("\\", "/")
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").simplify_path().replace("\\", "/")
	if source_base.contains("..") or destination_base.contains(".."):
		return false
	if not source_base.begins_with(evidence_root):
		return false
	if not destination_base.begins_with(evidence_root):
		return false
	if DirAccess.make_dir_recursive_absolute(destination_base) != OK:
		return false
	for name in ["profile.json", "profile.team-match.json", "profile.team-cursor.json"]:
		var source := source_base.path_join(name)
		var destination := destination_base.path_join(name)
		var bytes := FileAccess.get_file_as_bytes(source)
		if bytes.is_empty() or FileAccess.get_file_as_bytes(destination).size() > 0:
			return false
		var output := FileAccess.open(destination, FileAccess.WRITE)
		if output == null:
			return false
		output.store_buffer(bytes)
		output.close()
		if FileAccess.get_file_as_bytes(destination) != bytes:
			return false
	return true


func _click_design(shell: Variant, design_position: Vector2) -> void:
	var viewport_position: Vector2 = shell._stage.position + design_position * shell._stage.scale
	await _click_viewport(viewport_position)


func _click_control(control: Control) -> void:
	await _click_viewport(control.get_global_rect().get_center())


func _click_viewport(viewport_position: Vector2) -> void:
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


func _dispatch_cancel() -> void:
	var cancel := InputEventKey.new()
	cancel.keycode = KEY_ESCAPE
	cancel.pressed = true
	get_viewport().push_input(cancel, true)
	await get_tree().process_frame


func _first_button_with_prefix(root: Node, prefix: String) -> Button:
	for node_value in root.find_children("*", "Button", true, false):
		if node_value is Button and node_value.name.begins_with(prefix):
			return node_value as Button
	return null


func _button_with_accessibility(root: Node, fragment: String) -> Button:
	for node_value in root.find_children("*", "Button", true, false):
		if node_value is Button and str((node_value as Button).accessibility_name).contains(fragment):
			return node_value as Button
	return null


func _ledger_path(profile_path: String) -> String:
	return "%s.team-match.json" % profile_path.get_basename()


func _json_file(path: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	return parsed.duplicate(true) if parsed is Dictionary else {}


func _qa_root() -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with("--qa-save-root="):
			return value.trim_prefix("--qa-save-root=")
	return "user://qa"


func _battle_case() -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with("--native-battle-case="):
			return value.trim_prefix("--native-battle-case=").strip_edges().to_lower()
	return "all"


func _case_enabled(name: String) -> bool:
	return battle_case == "all" or battle_case == name
