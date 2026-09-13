extends Node

const Shell := preload("res://scripts/team_ui/team_prototype_shell.gd")
const Runtime := preload("res://scripts/team_runtime/team_prototype_runtime.gd")
const Bot := preload("res://scripts/team_battle/team_battle_bot.gd")

var width := 576
var height := 1024
var text_scale_bps := 10000
var high_contrast := false
var reduced_motion := false
var synthetic_safe_insets := Rect2(Vector2.ZERO, Vector2.ZERO)
var synthetic_safe_insets_enabled := false
var battle_capture_case := "lifecycle"
var terminal_setup_root := ""
var terminal_outcome := "Win"
var battle_creature := "cinderpaw"
var saved_frames := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() >= 2 and args[0].is_valid_int() and args[1].is_valid_int():
		width = int(args[0])
		height = int(args[1])
		_parse_options(args)
	# Captures are evidence at their requested physical dimensions.  Sizing only the
	# shell leaves the headless window at its project default and silently produces a
	# 576 bitmap with a larger filename.
	get_window().content_scale_size = Vector2i(width, height)
	get_window().size = Vector2i(width, height)
	await get_tree().process_frame
	if battle_capture_case not in ["lifecycle", "progression", "hold", "result"]:
		push_error("Unsupported native Battle capture case: %s." % battle_capture_case)
		get_tree().quit(1)
		return
	if battle_capture_case == "result":
		await _capture_terminal_result()
		return
	if battle_capture_case == "progression":
		await _capture_progression()
		return
	if battle_capture_case == "hold":
		await _capture_hold()
		return
	var opened := _open_runtime()
	if not bool(opened.get("ok", false)):
		push_error(str(opened.get("error", "Battle capture fixture could not open.")))
		get_tree().quit(1)
		return
	var runtime: Variant = opened.runtime
	if not _bootstrap_applied(runtime):
		push_error("Battle capture fixture could not apply the first-session loadout.")
		runtime.close()
		get_tree().quit(1)
		return
	var shell := Shell.new()
	shell.size = Vector2(width, height)
	add_child(shell)
	shell.configure_runtime(runtime)
	shell.settings_draft = {"text_scale_bps":text_scale_bps, "high_contrast":high_contrast, "reduced_motion":reduced_motion}
	shell.synthetic_safe_insets = synthetic_safe_insets
	shell.synthetic_safe_insets_enabled = synthetic_safe_insets_enabled
	shell._fit()
	shell.replace_route("preflight")
	if not await _capture_surface(shell, "battle-preflight", shell.route == "preflight" and shell.find_child("BattleStartResume", true, false) != null):
		_finish_failure(shell, runtime)
		return
	var started: Dictionary = {}
	if battle_creature == "voltwig":
		# Seed 2 is a legal explicit QA Start.  It gives the rival Voltwig priority,
		# proving the approved front/rear pair in one genuine battle capture.
		started = runtime.start("battle-capture-voltwig-seed-two", 1, 2)
		shell.battle_controller.refresh()
	else:
		started = shell.battle_controller.start_or_resume()
	if not bool(started.get("ok", false)):
		push_error(str(started.get("error", "Battle capture Start failed.")))
		shell.queue_free()
		runtime.close()
		get_tree().quit(1)
		return
	shell.replace_route("battle")
	var controller: Variant = shell.battle_controller
	if not await _capture_surface(shell, "battle-opening-plan", shell.route == "battle" and not controller.player_view.is_empty() and controller.cursor >= controller.stage_count and shell.find_child("BattleRunCycle", true, false) != null):
		_finish_failure(shell, runtime)
		return
	var suit_copy := _hand_copy(controller.player_view, "standard_full_suit")
	if suit_copy.is_empty():
		push_error("Battle capture fixture lacks the real Full Suit hand copy for the target modal.")
		_finish_failure(shell, runtime)
		return
	# Equipment targets are derived from an explicit legal fabrication baseline.
	# The opening Plan capture above remains unselected; only the modal fixture
	# chooses this real same-cycle creature before selecting Full Suit.
	controller.set_fabrication("player:member:%s" % battle_creature)
	shell._battle_presenter._select_support(shell, controller, suit_copy, "standard_full_suit")
	var capture_targets: Array = controller.equipment_targets()
	if capture_targets.is_empty():
		push_error("Battle capture fixture has no authoritative equipment target after opening the modal.")
		_finish_failure(shell, runtime)
		return
	var first_target_name := "BattleEquipmentTarget_%s" % str(capture_targets[0]).replace(":", "_")
	if not await _capture_surface(shell, "battle-equipment-target", shell.modal == "battle_equipment" and shell.find_child(first_target_name, true, false) != null):
		_finish_failure(shell, runtime)
		return
	shell._battle_presenter._choose_equipment_target(shell, controller, str(capture_targets[0]))
	if not bool(controller.checked_plan().get("ok", false)):
		push_error("Battle capture fixture could not choose an authoritative equipment plan.")
		shell.queue_free()
		runtime.close()
		get_tree().quit(1)
		return
	var run: Dictionary = controller.run_cycle()
	if not bool(run.get("ok", false)):
		push_error(str(run.get("error", "Battle capture Run failed.")))
		shell.queue_free()
		runtime.close()
		get_tree().quit(1)
		return
	controller.set_presentation_paused(true, true)
	shell._render()
	if not await _capture(shell, "battle-queue", controller.cached_stage(), 0, "Queue", 0):
		_finish_failure(shell, runtime)
		return
	var print_start := _advance_and_freeze(controller, 0.25)
	shell._render()
	var print_mid := _advance_and_freeze(controller, 0.96)
	_sync_visual(shell, print_mid.stage, int(print_mid.progress_bps))
	var print_mid_expected := 5000 if reduced_motion else 6000
	if not await _capture(shell, "battle-print-60", print_mid.stage, int(print_mid.progress_bps), "Print", print_mid_expected):
		_finish_failure(shell, runtime)
		return
	var awaken_start := _advance_and_freeze(controller, 0.64)
	shell._render()
	var awaken_mid := _advance_and_freeze(controller, 0.22)
	_sync_visual(shell, awaken_mid.stage, int(awaken_mid.progress_bps))
	if not await _capture(shell, "battle-awaken-mid", awaken_mid.stage, int(awaken_mid.progress_bps), "Awaken", 4000):
		_finish_failure(shell, runtime)
		return
	var enter_start := _advance_and_freeze(controller, 0.33)
	shell._render()
	var enter_mid := _advance_and_freeze(controller, 0.37)
	_sync_visual(shell, enter_mid.stage, int(enter_mid.progress_bps))
	if not await _capture(shell, "battle-enter-mid", enter_mid.stage, int(enter_mid.progress_bps), "Enter/Fit", 4933):
		_finish_failure(shell, runtime)
		return
	if not _advance_until_stage(controller, "AttackLock"):
		push_error("Battle capture fixture did not reach AttackLock through the real receipt clock.")
		_finish_failure(shell, runtime)
		return
	shell._render()
	var windup := _advance_and_freeze(controller, 0.10)
	_sync_visual(shell, windup.stage, int(windup.progress_bps))
	if not await _capture(shell, "battle-attack-windup", windup.stage, int(windup.progress_bps), "AttackLock", 4000):
		_finish_failure(shell, runtime)
		return
	_advance_and_freeze(controller, 0.15)
	if not _advance_until_stage(controller, "Damage"):
		push_error("Battle capture fixture did not reach Damage through the paired AttackLock receipt.")
		_finish_failure(shell, runtime)
		return
	shell._render()
	var contact := _advance_and_freeze(controller, 0.17)
	_sync_visual(shell, contact.stage, int(contact.progress_bps))
	if not await _capture(shell, "battle-damage-contact", contact.stage, int(contact.progress_bps), "Damage", 3091):
		_finish_failure(shell, runtime)
		return
	var returning := _advance_and_freeze(controller, 0.18)
	_sync_visual(shell, returning.stage, int(returning.progress_bps))
	if not await _capture(shell, "battle-damage-return", returning.stage, int(returning.progress_bps), "Damage", 6364):
		_finish_failure(shell, runtime)
		return
	if not _advance_until_stage(controller, "Plan"):
		push_error("Battle capture fixture did not return to the next Plan through the real receipt cursor.")
		_finish_failure(shell, runtime)
		return
	# The nonterminal closing Plan is a receipt stage, not yet the next Cycle's
	# editable view. Let the controller persist its exact cursor before Run two.
	_advance_and_freeze(controller, 0.01)
	if controller.cursor < controller.stage_count:
		push_error("Battle capture fixture did not finish the nonterminal closing Plan cursor.")
		_finish_failure(shell, runtime)
		return
	shell._render()
	var second_run: Dictionary = controller.run_cycle()
	if not bool(second_run.get("ok", false)):
		push_error(str(second_run.get("error", "Battle capture fixture could not commit the queued equipment cycle.")))
		_finish_failure(shell, runtime)
		return
	if not _advance_until_stage(controller, "Print"):
		push_error("Battle capture fixture did not reach the queued equipment Print stage.")
		_finish_failure(shell, runtime)
		return
	shell._render()
	var suit_print := _advance_and_freeze(controller, 0.96)
	_sync_visual(shell, suit_print.stage, int(suit_print.progress_bps))
	if not await _capture(shell, "battle-suit-print-60", suit_print.stage, int(suit_print.progress_bps), "Print", 5000 if reduced_motion else 6000):
		_finish_failure(shell, runtime)
		return
	if not _advance_until_stage(controller, "Enter/Fit"):
		push_error("Battle capture fixture did not reach the equipment Fit stage.")
		_finish_failure(shell, runtime)
		return
	shell._render()
	var fit_mid := _advance_and_freeze(controller, 0.22)
	_sync_visual(shell, fit_mid.stage, int(fit_mid.progress_bps))
	if not await _capture(shell, "battle-suit-fit-mid", fit_mid.stage, int(fit_mid.progress_bps), "Enter/Fit", 4889):
		_finish_failure(shell, runtime)
		return
	shell.queue_free()
	await get_tree().process_frame
	runtime.close()
	_complete_capture()


func _parse_options(args: PackedStringArray) -> void:
	for value in args:
		if value.begins_with("--text-scale-bps="):
			text_scale_bps = int(value.trim_prefix("--text-scale-bps="))
		elif value == "--high-contrast":
			high_contrast = true
		elif value == "--reduced-motion":
			reduced_motion = true
		elif value.begins_with("--synthetic-safe-insets="):
			var values := value.trim_prefix("--synthetic-safe-insets=").split(",", false)
			if values.size() == 4:
				var left := float(values[0])
				var top := float(values[1])
				var right := float(values[2])
				var bottom := float(values[3])
				synthetic_safe_insets = Rect2(Vector2(left, top), Vector2(right, bottom))
				synthetic_safe_insets_enabled = true
		elif value.begins_with("--battle-capture-case="):
			battle_capture_case = value.trim_prefix("--battle-capture-case=").strip_edges().to_lower()
		elif value.begins_with("--terminal-setup-root="):
			terminal_setup_root = value.trim_prefix("--terminal-setup-root=").strip_edges()
		elif value.begins_with("--terminal-outcome="):
			terminal_outcome = value.trim_prefix("--terminal-outcome=").strip_edges()
		elif value.begins_with("--battle-creature="):
			battle_creature = value.trim_prefix("--battle-creature=").strip_edges().to_lower()


func _select_equipment_plan(controller: Variant) -> bool:
	var suit_copy := ""
	for copy_value in controller.player_view.get("own", {}).get("hand", []):
		if copy_value is Dictionary and str(copy_value.get("card_id", "")) == "standard_full_suit":
			suit_copy = str(copy_value.get("copy_id", ""))
	if suit_copy.is_empty():
		return false
	controller.set_support(suit_copy)
	var targets: Array = controller.equipment_targets()
	if targets.is_empty():
		return false
	controller.set_equipment_target(str(targets[0]))
	return bool(controller.checked_plan().get("ok", false))


func _sync_visual(shell: Variant, stage: Dictionary, progress_bps: int) -> void:
	if shell._battle_visual != null and is_instance_valid(shell._battle_visual):
		shell._battle_visual.set_stage(stage, progress_bps, reduced_motion)


func _advance_and_freeze(controller: Variant, seconds: float) -> Dictionary:
	controller.set_presentation_paused(false)
	var remaining := maxf(seconds, 0.0)
	while remaining > 0.0001:
		controller.advance_presentation(minf(remaining, 0.10), reduced_motion)
		remaining -= minf(remaining, 0.10)
	var snapshot := {"stage":controller.cached_stage().duplicate(true), "progress_bps":controller.stage_progress_bps(reduced_motion)}
	controller.set_presentation_paused(true, true)
	return snapshot


func _advance_until_stage(controller: Variant, target: String) -> bool:
	for step in 96:
		if str(controller.cached_stage().get("name", "")) == target:
			return true
		_advance_and_freeze(controller, 0.10)
	return str(controller.cached_stage().get("name", "")) == target


func _capture(shell: Variant, prefix: String, stage: Dictionary, progress_bps: int, expected_stage: String, expected_progress_bps: int) -> bool:
	var controller: Variant = shell.battle_controller
	var actual: Dictionary = controller.cached_stage()
	if str(stage.get("name", "")) != expected_stage or progress_bps != expected_progress_bps:
		push_error("Capture driver missed requested %s/%d for %s (prepared %s/%d)." % [expected_stage, expected_progress_bps, prefix, str(stage.get("name", "")), progress_bps])
		return false
	if str(actual.get("name", "")) != expected_stage or controller.stage_progress_bps(reduced_motion) != expected_progress_bps:
		push_error("Capture boundary drifted for %s (expected %s/%d, got %s/%d)." % [prefix, expected_stage, expected_progress_bps, str(actual.get("name", "")), controller.stage_progress_bps(reduced_motion)])
		return false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	actual = controller.cached_stage()
	if str(actual.get("name", "")) != expected_stage or controller.stage_progress_bps(reduced_motion) != expected_progress_bps:
		push_error("Capture frame drifted for %s." % prefix)
		return false
	var visual_state := {}
	if shell._battle_visual != null and is_instance_valid(shell._battle_visual):
		visual_state = shell._battle_visual.printer_snapshot("player")
	var player_print_identity := _printed_member_identity(stage, "player")
	var rival_print_identity := _printed_member_identity(stage, "rival")
	if str(stage.get("name", "")) == "Print" and not bool(visual_state.get("valid", false)):
		push_error("Print capture has no valid player printer presentation for %s." % prefix)
		return false
	if prefix == "battle-print-60" and not player_print_identity.ends_with(":" + battle_creature):
		push_error("Requested %s lifecycle capture rendered a different player print subject: %s." % [battle_creature, player_print_identity])
		return false
	if prefix == "battle-print-60" and battle_creature == "voltwig" and (not rival_print_identity.ends_with(":voltwig") or not player_print_identity.ends_with(":voltwig")):
		push_error("Voltwig capture must prove both player and rival printed Voltwig directions, got player=%s rival=%s." % [player_print_identity, rival_print_identity])
		return false
	var root := _capture_root()
	DirAccess.make_dir_recursive_absolute(root)
	var image := get_viewport().get_texture().get_image()
	if image == null or image.get_size() != Vector2i(width, height):
		push_error("Battle capture dimensions were %s; expected %dx%d for %s." % [str(image.get_size() if image != null else Vector2i()), width, height, prefix])
		return false
	var base := "%s-%dx%d" % [prefix, width, height]
	if image.save_png(root.path_join("%s.png" % base)) != OK:
		push_error("Battle capture PNG could not be saved for %s." % prefix)
		return false
	var metadata := FileAccess.open(root.path_join("%s.json" % base), FileAccess.WRITE)
	if metadata == null:
		push_error("Battle capture metadata path is unavailable for %s." % prefix)
		return false
	metadata.store_string(JSON.stringify({
		"width": width,
		"height": height,
		"route": shell.route,
		"match_id": shell.battle_controller.match_id(),
		"stage": stage.get("name", "Plan"),
		"cursor": shell.battle_controller.cursor,
		"progress_bps": progress_bps,
		"player_printer": visual_state,
		"requested_creature": battle_creature,
		"player_print_identity": player_print_identity,
		"rival_print_identity": rival_print_identity,
		"text_scale_bps": text_scale_bps,
		"high_contrast": high_contrast,
		"reduced_motion": reduced_motion,
		"synthetic_safe_insets": [synthetic_safe_insets.position.x, synthetic_safe_insets.position.y, synthetic_safe_insets.size.x, synthetic_safe_insets.size.y],
		"pass": true,
	}))
	metadata.close()
	saved_frames += 1
	return true


func _capture_surface(shell: Variant, prefix: String, condition: bool) -> bool:
	if not condition:
		push_error("Battle capture surface precondition failed for %s." % prefix)
		return false
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var root := _capture_root()
	DirAccess.make_dir_recursive_absolute(root)
	var base := "%s-%dx%d" % [prefix, width, height]
	var image := get_viewport().get_texture().get_image()
	if image == null or image.get_size() != Vector2i(width, height):
		push_error("Battle surface dimensions were %s; expected %dx%d for %s." % [str(image.get_size() if image != null else Vector2i()), width, height, prefix])
		return false
	if image.save_png(root.path_join("%s.png" % base)) != OK:
		push_error("Battle surface capture PNG could not be saved for %s." % prefix)
		return false
	var metadata := FileAccess.open(root.path_join("%s.json" % base), FileAccess.WRITE)
	if metadata == null:
		push_error("Battle capture metadata path is unavailable for %s." % prefix)
		return false
	metadata.store_string(JSON.stringify({
		"width":width,
		"height":height,
		"route":shell.route,
		"modal":shell.modal,
		"stage":shell.battle_controller.cached_stage().get("name", "Plan"),
		"requested_creature":battle_creature,
		"text_scale_bps":text_scale_bps,
		"high_contrast":high_contrast,
		"reduced_motion":reduced_motion,
		"synthetic_safe_insets":[synthetic_safe_insets.position.x, synthetic_safe_insets.position.y, synthetic_safe_insets.size.x, synthetic_safe_insets.size.y],
		"pass":true,
	}))
	metadata.close()
	saved_frames += 1
	return true


func _hand_copy(player_view: Dictionary, card_id: String) -> String:
	for value in player_view.get("own", {}).get("hand", []):
		if value is Dictionary and str(value.get("card_id", "")) == card_id:
			return str(value.get("copy_id", ""))
	return ""


func _printed_member_identity(stage: Dictionary, seat: String) -> String:
	for event_value in stage.get("events", []):
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if str(event.get("type", "")) == "print_work" and str(event.get("seat", "")) == seat:
			var head: Dictionary = event.get("head_before", {})
			if str(head.get("kind", "")) == "companion":
				return str(head.get("member_identity_id", ""))
	return ""


func _finish_failure(shell: Variant, runtime: Variant) -> void:
	shell.queue_free()
	runtime.close()
	get_tree().quit(1)


func _complete_capture() -> void:
	if saved_frames <= 0:
		push_error("Native Battle capture completed without a saved PNG and metadata frame.")
		get_tree().quit(1)
		return
	print("TEAM_NATIVE_BATTLE_UI_CAPTURE case=%s creature=%s frames=%d failures=0" % [battle_capture_case, battle_creature, saved_frames])
	print("TEAM_NATIVE_BATTLE_UI_CAPTURE failures=0")
	get_tree().quit()


func _capture_progression() -> void:
	var opened := _open_runtime()
	if not bool(opened.get("ok", false)):
		push_error(str(opened.get("error", "Progression capture fixture could not open.")))
		get_tree().quit(1)
		return
	var runtime: Variant = opened.runtime
	if not _bootstrap_applied(runtime):
		push_error("Progression capture fixture could not apply the real Cinderpaw loadout.")
		runtime.close()
		get_tree().quit(1)
		return
	var shell: Variant = _capture_shell(runtime)
	var controller: Variant = shell.battle_controller
	if not bool(controller.start_or_resume().get("ok", false)):
		_finish_failure(shell, runtime)
		return
	shell.replace_route("battle")
	var cinder_id := "player:member:cinderpaw"
	var aquafin_id := "player:member:aquafin"
	controller.set_fabrication(cinder_id)
	controller.set_support(_hand_copy(controller.player_view, "iron_gem"))
	controller.set_equipment_target(cinder_id)
	if not bool(controller.run_cycle().get("ok", false)) or not bool(controller.skip_to_result().get("ok", false)):
		_finish_failure(shell, runtime)
		return
	controller.set_fabrication(aquafin_id)
	controller.set_support(_hand_copy(controller.player_view, "raw_filament"))
	if not bool(controller.run_cycle().get("ok", false)) or not _advance_until_stage(controller, "Enter/Fit"):
		_finish_failure(shell, runtime)
		return
	shell._render()
	if not await _capture(shell, "battle-gem-fit", controller.cached_stage(), 0, "Enter/Fit", 0):
		_finish_failure(shell, runtime)
		return
	if not bool(controller.skip_to_result().get("ok", false)):
		_finish_failure(shell, runtime)
		return
	controller.clear_plan()
	if not bool(controller.run_cycle().get("ok", false)) or not _advance_until_stage(controller, "Enter/Fit"):
		_finish_failure(shell, runtime)
		return
	shell._render()
	if not await _capture(shell, "battle-aquafin-ready", controller.cached_stage(), 0, "Enter/Fit", 0):
		_finish_failure(shell, runtime)
		return
	if not bool(controller.skip_to_result().get("ok", false)):
		_finish_failure(shell, runtime)
		return
	controller.set_swap(aquafin_id)
	if not bool(controller.run_cycle().get("ok", false)) or not _advance_until_stage(controller, "Swap"):
		_finish_failure(shell, runtime)
		return
	shell._render()
	if not await _capture(shell, "battle-swap-start", controller.cached_stage(), 0, "Swap", 0):
		_finish_failure(shell, runtime)
		return
	var swap_mid := _advance_and_freeze(controller, 0.30)
	_sync_visual(shell, swap_mid.stage, int(swap_mid.progress_bps))
	if not await _capture(shell, "battle-swap-mid", swap_mid.stage, int(swap_mid.progress_bps), "Swap", 5000):
		_finish_failure(shell, runtime)
		return
	# Continue with genuine deterministic Bot decisions until a nonterminal receipt
	# exposes both the prescribed Defeat and automatic Replace events.
	if not bool(controller.skip_to_result().get("ok", false)):
		_finish_failure(shell, runtime)
		return
	var replacement_captured := false
	for continuation in range(1, 28):
		var chosen: Dictionary = Bot.choose_plan(controller.player_view)
		if not bool(chosen.get("ok", false)):
			break
		controller.local_plan = (chosen.get("plan", {}) as Dictionary).duplicate(true)
		if not bool(controller.run_cycle().get("ok", false)):
			break
		if _receipt_has_type(controller.receipt, "defeat") and _receipt_has_type(controller.receipt, "replacement"):
			if not _advance_until_stage(controller, "Defeat"):
				break
			shell._render()
			if not await _capture(shell, "battle-defeat", controller.cached_stage(), 0, "Defeat", 0):
				_finish_failure(shell, runtime)
				return
			if not _advance_until_stage(controller, "Replace"):
				break
			shell._render()
			if not await _capture(shell, "battle-replace", controller.cached_stage(), 0, "Replace", 0):
				_finish_failure(shell, runtime)
				return
			replacement_captured = true
			break
		if _terminal_result_index(controller.receipt) >= 0 or not bool(controller.skip_to_result().get("ok", false)):
			break
	if not replacement_captured:
		push_error("Progression capture could not reach the real nonterminal Defeat/Replace boundary.")
		_finish_failure(shell, runtime)
		return
	shell.queue_free()
	await get_tree().process_frame
	runtime.close()
	_complete_capture()


func _capture_hold() -> void:
	var opened := _open_runtime()
	if not bool(opened.get("ok", false)):
		push_error(str(opened.get("error", "HOLD capture fixture could not open.")))
		get_tree().quit(1)
		return
	var runtime: Variant = opened.runtime
	if not _bootstrap_applied(runtime):
		push_error("HOLD capture fixture could not apply the real Cinderpaw loadout.")
		runtime.close()
		get_tree().quit(1)
		return
	var shell: Variant = _capture_shell(runtime)
	var controller: Variant = shell.battle_controller
	if not bool(controller.start_or_resume().get("ok", false)):
		_finish_failure(shell, runtime)
		return
	shell.replace_route("battle")
	for cycle in range(1, 24):
		var player: Dictionary = controller.player_view
		var own: Dictionary = player.get("own", {})
		var boundary := str(own.get("active_member_id", "")).is_empty() and (own.get("ready_member_ids", []) as Array).is_empty() and int(own.get("filament", 0)) < 3 and _has_unspent_or_printing(own)
		controller.local_plan = {"fabrication_id":"", "support_copy_id":"", "equipment_target_id":"", "swap_id":""} if boundary else _hold_plan(player, cycle)
		var checked: Dictionary = controller.checked_plan()
		if not bool(checked.get("ok", false)):
			break
		if not bool(controller.run_cycle().get("ok", false)):
			break
		if boundary and _receipt_has_type(controller.receipt, "hold"):
			if not _advance_until_stage(controller, "AttackLock"):
				break
			shell._render()
			if not await _capture(shell, "battle-hold", controller.cached_stage(), 0, "AttackLock", 0):
				_finish_failure(shell, runtime)
				return
			shell.queue_free()
			await get_tree().process_frame
			runtime.close()
			_complete_capture()
			return
		if not bool(controller.skip_to_result().get("ok", false)):
			break
	push_error("HOLD capture could not reach the real low-filament no-Active boundary.")
	_finish_failure(shell, runtime)


func _capture_shell(runtime: Variant) -> Variant:
	var shell := Shell.new()
	shell.size = Vector2(width, height)
	add_child(shell)
	shell.configure_runtime(runtime)
	shell.settings_draft = {"text_scale_bps":text_scale_bps, "high_contrast":high_contrast, "reduced_motion":reduced_motion}
	shell.synthetic_safe_insets = synthetic_safe_insets
	shell.synthetic_safe_insets_enabled = synthetic_safe_insets_enabled
	shell._fit()
	return shell


func _receipt_has_type(receipt: Dictionary, event_type: String) -> bool:
	for stage_value in receipt.get("stages", []):
		if not stage_value is Dictionary:
			continue
		for event_value in (stage_value as Dictionary).get("events", []):
			if event_value is Dictionary and str(event_value.get("type", "")) == event_type:
				return true
	return false


func _has_unspent_or_printing(own: Dictionary) -> bool:
	for value in own.get("members", []):
		if value is Dictionary and str(value.get("status", "")) in ["Unspent", "Printing"]:
			return true
	return false


func _hold_plan(player_view: Dictionary, cycle: int) -> Dictionary:
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


func _capture_terminal_result() -> void:
	if terminal_outcome != "Win" or terminal_setup_root.is_empty():
		push_error("Result capture requires the prepared real Win fixture.")
		get_tree().quit(1)
		return
	var opened := _open_runtime()
	if not bool(opened.get("ok", false)):
		push_error(str(opened.get("error", "Result capture fixture could not open.")))
		get_tree().quit(1)
		return
	var runtime: Variant = opened.runtime
	var started: Dictionary = runtime.start("battle-capture-result-sequence-two", 2, 0)
	if not bool(started.get("ok", false)):
		push_error(str(started.get("error", "Result capture could not start sequence two.")))
		runtime.close()
		get_tree().quit(1)
		return
	var terminal: Dictionary = _play_to_terminal(runtime, str(started.get("match_id", "")), "battle-capture-result")
	if not bool(terminal.get("ok", false)):
		push_error(str(terminal.get("error", "Result capture could not reach the terminal receipt.")))
		runtime.close()
		get_tree().quit(1)
		return
	var shell := Shell.new()
	shell.size = Vector2(width, height)
	add_child(shell)
	shell.configure_runtime(runtime)
	shell.settings_draft = {"text_scale_bps":text_scale_bps, "high_contrast":high_contrast, "reduced_motion":reduced_motion}
	shell.synthetic_safe_insets = synthetic_safe_insets
	shell.synthetic_safe_insets_enabled = synthetic_safe_insets_enabled
	shell._fit()
	var controller: Variant = shell.battle_controller
	var result_boundary: Dictionary = controller.skip_to_result()
	if not bool(result_boundary.get("ok", false)):
		push_error(str(result_boundary.get("error", "Result capture could not reach visible Result.")))
		_finish_failure(shell, runtime)
		return
	shell.replace_route("result")
	var result_stage: Dictionary = controller.cached_stage()
	if not await _capture(shell, "battle-result-pending", result_stage, controller.stage_progress_bps(reduced_motion), "Result", 0):
		_finish_failure(shell, runtime)
		return
	shell.queue_free()
	await get_tree().process_frame
	runtime.close()
	_complete_capture()


func _play_to_terminal(runtime: Variant, match_id: String, prefix: String) -> Dictionary:
	for cycle in range(1, 80):
		var match: Dictionary = runtime.view().match
		var player: Dictionary = match.player
		var chosen: Dictionary = Bot.choose_plan(player)
		if not bool(chosen.get("ok", false)):
			return {"ok":false, "error":"Bot could not choose a legal production Plan."}
		var run: Dictionary = runtime.run_cycle(match_id, "%s-run-%d" % [prefix, cycle], chosen.plan)
		if not bool(run.get("ok", false)):
			return run
		var pending: Dictionary = runtime.pending_receipt()
		if _terminal_result_index(pending.get("receipt", {})) >= 0:
			return {"ok":true}
		var request_id := str((runtime.view().match as Dictionary).get("presentation", {}).get("request_id", ""))
		var skipped: Dictionary = runtime.skip(match_id, request_id, int(pending.get("cursor", 0)))
		if not bool(skipped.get("ok", false)):
			return skipped
	return {"ok":false, "error":"Result capture exceeded the bounded cycle budget."}


func _terminal_result_index(receipt: Variant) -> int:
	if not receipt is Dictionary:
		return -1
	var stages: Array = receipt.get("stages", [])
	for index in stages.size():
		var stage: Variant = stages[index]
		if not stage is Dictionary or str(stage.get("name", "")) != "Result":
			continue
		for event_value in stage.get("events", []):
			if event_value is Dictionary and str(event_value.get("type", "")) == "terminal":
				return index
	return -1


func _capture_root() -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with("--qa-save-root="):
			return value.trim_prefix("--qa-save-root=").get_base_dir().path_join("captures")
	return "user://captures"


func _open_runtime() -> Dictionary:
	var profile_path := _capture_root().get_base_dir().path_join("battle-capture-fixtures").path_join("profile.json")
	if battle_capture_case == "result":
		if not _copy_terminal_primaries(terminal_setup_root, profile_path.get_base_dir()):
			return {"ok":false, "error":"Prepared terminal primaries could not be copied into the isolated capture fixture."}
		return Runtime.open(profile_path, {"compatible":true, "state":"ready", "schema_version":31, "supported_schema":31, "message":""})
	DirAccess.make_dir_recursive_absolute(profile_path.get_base_dir())
	var file := FileAccess.open(profile_path, FileAccess.WRITE)
	if file == null:
		return {"ok":false, "error":"Capture fixture profile path is unavailable."}
	file.store_string(JSON.stringify({"schema_version":31, "owned_blueprints":{}, "owned_cards":{}, "printed_models":{}}))
	file.close()
	return Runtime.open(profile_path, {"compatible":true, "state":"ready", "schema_version":31, "supported_schema":31, "message":""})


func _copy_terminal_primaries(source_root: String, destination_root: String) -> bool:
	var source := source_root.simplify_path().replace("\\", "/")
	var destination := destination_root.simplify_path().replace("\\", "/")
	if source.is_empty() or destination.is_empty() or source == destination:
		return false
	var root := _capture_root().get_base_dir().simplify_path().replace("\\", "/")
	if not destination.begins_with(root + "/"):
		return false
	if not DirAccess.dir_exists_absolute(source):
		return false
	if DirAccess.make_dir_recursive_absolute(destination) != OK:
		return false
	for name in ["profile.json", "profile.team-match.json", "profile.team-cursor.json"]:
		var input_path := source.path_join(name)
		var output_path := destination.path_join(name)
		var bytes := FileAccess.get_file_as_bytes(input_path)
		if bytes.is_empty() or FileAccess.file_exists(output_path):
			return false
		var output := FileAccess.open(output_path, FileAccess.WRITE)
		if output == null:
			return false
		output.store_buffer(bytes)
		output.close()
		if FileAccess.get_file_as_bytes(output_path) != bytes:
			return false
	return true


func _bootstrap_applied(runtime: Variant) -> bool:
	if battle_creature not in ["cinderpaw", "aquafin", "voltwig", "mossmunk"]:
		return false
	# Mossmunk is the common guaranteed companion, not a carousel starter.  Choose
	# Cinderpaw to obtain its real grant, then place Mossmunk first in the applied
	# production priority so the captured FIFO subject is genuinely Mossmunk.
	var starter := "cinderpaw" if battle_creature == "mossmunk" else battle_creature
	var team: Array = []
	var priority: Array = []
	if battle_creature == "cinderpaw":
		team = ["cinderpaw", "aquafin", "mossmunk"]
	elif battle_creature == "aquafin":
		team = ["aquafin", "voltwig", "mossmunk"]
	elif battle_creature == "voltwig":
		team = ["voltwig", "cinderpaw", "mossmunk"]
	elif battle_creature == "mossmunk":
		team = ["cinderpaw", "aquafin", "mossmunk"]
	priority = [battle_creature]
	for member_id in team:
		if member_id != battle_creature:
			priority.append(member_id)
	var chosen: Dictionary = runtime.collection_request("choose_starter", "battle-capture-choose", {"starter_id":starter})
	if not bool(chosen.get("ok", false)):
		return false
	var begun: Dictionary = runtime.collection_request("begin_starter_print", "battle-capture-begin", {})
	if not bool(begun.get("ok", false)):
		return false
	var completed: Dictionary = runtime.collection_request("complete_starter_print", "battle-capture-complete", {"print_id":str(begun.result.print_id)})
	if not bool(completed.get("ok", false)):
		return false
	var acknowledged: Dictionary = runtime.collection_request("acknowledge_grant", "battle-capture-ack", {"receipt_id":str(completed.result.receipt_id)})
	if not bool(acknowledged.get("ok", false)):
		return false
	var collection: Dictionary = runtime.collection_view()
	var applied: Dictionary = runtime.collection_request("apply_loadout", "battle-capture-apply", {"team":team, "priority":priority, "kit":collection.recommended_kit})
	return bool(applied.get("ok", false))
