extends Node
## Normal-mode M9 Forge phase map. It keeps the production logical canvas at
## 576x1024 while changing only the physical window raster for each batch.
## Direct phase assignment is explicitly recorded as a frozen projection; only
## Start, Back, and Resume rows send pointer events through the live viewport.

const MAIN := preload("res://scenes/main.tscn")
const PROFILES := preload("res://tests/m9_test_profile_factory.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")
const OUTPUT_ROOT_DEFAULT := "E:/AI Projects/games/3d print battler/build/evidence/m9a-runtime-20260904/forge-continuity/full-map-v2"
const ACCESSIBILITY_OUTPUT_ROOT := "E:/AI Projects/games/3d print battler/build/evidence/m9a-runtime-20260904/forge-continuity/accessibility-map-v4-final2"
const ACCESSIBILITY_SUPPLEMENT_ROOT := "E:/AI Projects/games/3d print battler/build/evidence/m9a-runtime-20260904/forge-continuity/accessibility-map-v4-supplemental7-forwardplus"
const LOGICAL_SIZE := Vector2i(576, 1024)
const STATION_PATH := "res://assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png"

var records: Array = []
var failed := false
var _mouse_notified := false
var _pause_resume_trace: Dictionary = {}
var output_root := OUTPUT_ROOT_DEFAULT
var capture_family := "normal"

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_configure_capture_family()
	if DisplayServer.get_name().to_lower() == "headless":
		push_error("M9 Forge normal-map captures require Forward+ rendering.")
		get_tree().quit(1)
		return
	if RenderingServer.get_current_rendering_method() != "forward_plus":
		push_error("M9 Forge normal-map captures require Forward+, got %s." % RenderingServer.get_current_rendering_method())
		get_tree().quit(1)
		return
	if capture_family.begins_with("accessibility"):
		await _capture_accessibility_map()
	else:
		for physical in [Vector2i(576, 1024), Vector2i(720, 1280)]:
			await _capture_resolution(physical)
			if failed:
				_write_manifest()
				get_tree().quit(1)
				return
	_write_manifest()
	if failed:
		get_tree().quit(1)
		return
	print("PASS: M9 Forge %s capture map" % capture_family)
	get_tree().quit(0)

func _configure_capture_family() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--forge-accessibility":
			capture_family = "accessibility"
		elif argument == "--forge-accessibility-supplemental":
			capture_family = "accessibility-supplemental"
	if capture_family == "accessibility":
		output_root = ACCESSIBILITY_OUTPUT_ROOT
	elif capture_family == "accessibility-supplemental":
		output_root = ACCESSIBILITY_SUPPLEMENT_ROOT

func _capture_accessibility_map() -> void:
	var text150 := {"text_scale_bps":15000, "high_contrast":false, "reduced_motion":false}
	var high_contrast := {"text_scale_bps":10000, "high_contrast":true, "reduced_motion":false}
	var reduced_motion := {"text_scale_bps":10000, "high_contrast":false, "reduced_motion":true}
	var combined_management := {"text_scale_bps":15000, "high_contrast":true, "reduced_motion":true}
	if capture_family == "accessibility-supplemental":
		await _capture_accessibility_supplemental()
		return
	for physical in [Vector2i(576, 1024), Vector2i(720, 1280)]:
		for state in ["RoutineIdle", "Print60", "Done", "Failed"]:
			await _capture_accessibility_forge_row("16-Text150-%s" % state, state, physical, text150)
			if failed: return
		for missing in ["MissingStatic", "MissingRaw"]:
			await _capture_accessibility_forge_row("20-MissingLayerSafe-%s" % missing, missing, physical, text150)
			if failed: return
		for route in ["Founder", "Market", "Archive", "Deck"]:
			await _capture_management_accessibility(route, physical, combined_management)
			if failed: return
	if failed: return
	for state in ["StarterIdle", "Print60", "RawComplete", "Failed"]:
		await _capture_accessibility_forge_row("17-HighContrast-%s" % state, state, Vector2i(720, 1280), high_contrast)
		if failed: return
	for state in ["Print00", "Print25", "Print60", "Print99", "RawHold", "Awakening", "Departing", "Done"]:
		await _capture_accessibility_forge_row("18-ReducedMotion-%s" % state, state, Vector2i(720, 1280), reduced_motion)
		if failed: return
	for state in ["StarterIdle", "RoutineIdle", "Print60", "Done"]:
		await _capture_accessibility_forge_row("19-Tall-%s" % state, state, Vector2i(1080, 2400), text150)
		if failed: return
	await _capture_first_print_workshop_returns(Vector2i(576, 1024))
	if failed: return
	await _capture_resize_persistence()

func _capture_accessibility_supplemental() -> void:
	# Normal-family controls changed only in native ink/copy. Keep their evidence
	# separate from the immutable 150%/HC/RM map while retaining the same capture
	# mechanics and authority checks.
	var normal := {"text_scale_bps":10000, "high_contrast":false, "reduced_motion":false}
	var large_high_contrast := {"text_scale_bps":15000, "high_contrast":true, "reduced_motion":true}
	for physical in [Vector2i(576, 1024), Vector2i(720, 1280)]:
		for route in ["Founder", "Market", "Archive", "Deck"]:
			await _capture_management_accessibility(route, physical, normal)
			if failed: return
		for route in ["Founder", "Market", "Archive", "Deck"]:
			await _capture_management_accessibility(route, physical, large_high_contrast)
			if failed: return
	for state in ["RoutineIdle", "Print60"]:
		await _capture_accessibility_forge_row("Normal-%s" % state, state, Vector2i(576, 1024), normal)
		if failed: return
	await _capture_resize_persistence()

func _capture_first_print_workshop_returns(physical: Vector2i) -> void:
	# These are live Back/Printer inputs, not frozen projections. They cover the
	# selected-starter route that used to fall through to the retired Workshop.
	var idle_main := await _mount(physical, "workshop", "cinderpaw", true)
	var idle_back := _button(idle_main, "ArcaneForgeBack")
	if idle_back == null:
		_fail("First Print IDLE Back has no ArcaneForgeBack owner.")
		return
	await _tap(idle_back)
	await get_tree().process_frame
	var selected_starter := str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected"
	var workshop_owner := idle_main.find_child("WorkshopPortraitPlate", true, false) != null and _button(idle_main, "WorkshopHotspotPrinter") != null
	if idle_main.screen != "workshop" or not selected_starter or not workshop_owner:
		_fail("First Print IDLE Back did not reach the approved physical Workshop with its selected starter intact.")
		return
	if not await _focus_actual_action(idle_main):
		_fail("First Print IDLE Back Workshop has no focusable physical action.")
		return
	await _write_capture(idle_main, "FirstPrintIdleBackWorkshop", physical, "actual_first_print_idle_back_physical_workshop")
	var idle_resume := _button(idle_main, "WorkshopHotspotPrinter")
	await _tap(idle_resume)
	await get_tree().process_frame
	if idle_main.screen != "printer" or idle_main.printer_creature_id != "cinderpaw" or idle_main.printer_price != 0 or idle_main.printer_sequence == null or idle_main.printer_sequence.phase != ArcaneForgeSequence.IDLE:
		_fail("First Print physical Printer did not reopen the selected free starter setup.")
		return
	await _write_capture(idle_main, "FirstPrintIdleBackReentry", physical, "actual_workshop_printer_reopens_first_print")
	if is_instance_valid(idle_main):
		idle_main.get_parent().remove_child(idle_main)
		idle_main.free()
	await get_tree().process_frame

	var active_main := await _mount(physical, "workshop", "cinderpaw", true)
	var start := _button(active_main, "BeginCreaturePrint")
	if start == null or start.disabled:
		_fail("First Print active Back fixture has no enabled actual Start.")
		return
	await _tap(start)
	active_main.printer_capture_freeze = true
	active_main.advance_printer_for_test(4200)
	await get_tree().process_frame
	var authority_before := _job_authority_hash(active_main)
	var identity_before := _presentation_identity(active_main)
	var active_back := _button(active_main, "ArcaneForgeBack")
	if active_back == null:
		_fail("First Print active Back has no ArcaneForgeBack owner.")
		return
	await _tap(active_back)
	await get_tree().process_frame
	var active_workshop_owner := active_main.find_child("WorkshopPortraitPlate", true, false) != null and _button(active_main, "WorkshopHotspotPrinter") != null
	if active_main.screen != "workshop" or not active_workshop_owner or authority_before != _job_authority_hash(active_main):
		_fail("Accepted first print Back did not preserve its job in the physical Workshop.")
		return
	if not await _focus_actual_action(active_main):
		_fail("Accepted first print Back Workshop has no focusable physical action.")
		return
	await _write_capture(active_main, "FirstPrintActiveBackWorkshop", physical, "actual_first_print_active_back_physical_workshop")
	var active_resume := _button(active_main, "WorkshopHotspotPrinter")
	await _tap(active_resume)
	await get_tree().process_frame
	var identity_after := _presentation_identity(active_main)
	if active_main.screen != "printer" or authority_before != _job_authority_hash(active_main) or identity_before.sequence_id != identity_after.sequence_id or identity_before.stage_id != identity_after.stage_id:
		_fail("First Print physical Printer did not resume the exact accepted sequence and persistent stage.")
		return
	await _write_capture(active_main, "FirstPrintActiveResume", physical, "actual_workshop_printer_resumes_first_print_job")
	if is_instance_valid(active_main):
		active_main.get_parent().remove_child(active_main)
		active_main.free()
	await get_tree().process_frame

func _set_accessibility_preferences(preferences: Dictionary) -> void:
	var settings: Dictionary = GameManager.profile.get("settings", {}).duplicate(true)
	for key in preferences.keys(): settings[str(key)] = preferences[key]
	GameManager.profile.settings = settings

func _capture_accessibility_forge_row(row: String, state: String, physical: Vector2i, preferences: Dictionary) -> void:
	var starter := state == "StarterIdle"
	var main := await _mount(physical, "workshop", "cinderpaw", starter)
	_set_accessibility_preferences(preferences)
	main.render()
	await get_tree().process_frame
	var projection := "frozen_accessibility_projection"
	if state in ["Print00", "Print25", "Print60", "Print99"]:
		projection = "actual_start_accessibility_projection"
		var start := _button(main, "BeginCreaturePrint")
		if start == null or start.disabled:
			_fail("%s has no enabled actual Start." % row)
			return
		await _tap(start)
		main.printer_capture_freeze = true
		var target := int({"Print00":0, "Print25":1750, "Print60":4200, "Print99":6930}.get(state, 0))
		if target > 0:
			main.advance_printer_for_test(maxi(1, target - main.printer_sequence.progress_bps))
			await get_tree().process_frame
	elif state == "RawComplete":
		main.printer_sequence.phase = ArcaneForgeSequence.RAW_COMPLETE
		main.printer_sequence.progress_bps = ArcaneForgeSequence.PRINT_COMPLETE_BPS
		main.render()
		await get_tree().process_frame
	elif state in ["RawHold", "Awakening", "Departing", "Done", "Failed"]:
		_set_frozen_phase(main, state)
		if state == "Failed": main.printer_failure = "Profile storage is unavailable; the Forge record was not committed."
		main.render()
		await get_tree().process_frame
	elif state in ["MissingStatic", "MissingRaw"]:
		var forge_component = main._physical_forge_component()
		forge_component.test_missing_layer = "static" if state == "MissingStatic" else "raw"
		main.render()
		await get_tree().process_frame
	# RAW_COMPLETE is the existing noninterruptible commit window: its visible Back
	# is intentionally disabled, so this row asserts that state rather than trying
	# to manufacture a focus target where none is legally available.
	if state != "RawComplete" and not await _focus_actual_action(main):
		_fail("%s could not focus a visible native action." % row)
		return
	await _write_capture(main, row, physical, projection)
	if is_instance_valid(main):
		main.get_parent().remove_child(main)
		main.free()
	await get_tree().process_frame

func _capture_management_accessibility(route: String, physical: Vector2i, preferences: Dictionary) -> void:
	await _configure_window(physical)
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	if route == "Founder":
		# Legal fixture setup reaches the first actual Founder receipt before this
		# capture. The capture itself is the persisted M3 pack route, not the
		# starter gallery that precedes it.
		GameManager.profile = RULES.new_profile()
		if not GameManager.choose_starter("cinderpaw") or not GameManager.print_selected_starter() or not bool(GameManager.claim_next_starter_pack("workshop", {"caller":"workshop"}).get("ok", false)):
			_fail("Founder accessibility fixture could not legally create its first pending receipt.")
			return
	else:
		GameManager.profile = PROFILES.founder_ready("cinderpaw")
		GameManager.profile.forge_coins = 1200
		if route in ["Archive", "Deck"]:
			GameManager.profile.spool_level = 7
	_set_accessibility_preferences(preferences)
	var main: Control = MAIN.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	if route == "Founder":
		main._m3_open_pending_pack("workshop")
	else:
		main.screen = {"Market":"unified_market", "Archive":"unified_library", "Deck":"unified_deck"}.get(route, "workshop")
		main.render()
	await get_tree().process_frame
	if route in ["Archive", "Deck"]:
		var level_label := main.find_child("ArchiveHudLevel" if route == "Archive" else "DeckHudLevel", true, false) as Label
		if level_label == null or level_label.text != "Level 7":
			_fail("%s accessibility fixture did not project the authoritative non-1 spool level." % route)
			return
	if not await _focus_actual_action(main):
		_fail("Management %s could not focus a visible native action." % route)
		return
	await _write_capture(main, "Management%s%s" % [route, _preference_capture_suffix(preferences)], physical, "actual_management_accessibility_focus" if route != "Founder" else "legal_founder_receipt_accessibility_focus")
	if is_instance_valid(main):
		main.get_parent().remove_child(main)
		main.free()
	await get_tree().process_frame

func _capture_resize_persistence() -> void:
	var main := await _mount(Vector2i(576, 1024))
	var start := _button(main, "BeginCreaturePrint")
	if start == null or start.disabled:
		_fail("Resize persistence fixture has no enabled actual Start.")
		return
	await _tap(start)
	main.printer_capture_freeze = true
	main.advance_printer_for_test(4200)
	await get_tree().process_frame
	if not await _focus_actual_action(main):
		_fail("Resize persistence fixture has no focusable live Forge action before resize.")
		return
	var focus_before: Control = get_viewport().gui_get_focus_owner() as Control
	var focus_before_name: String = focus_before.name if focus_before != null else ""
	var authority_before := _job_authority_hash(main)
	var identity_before := _presentation_identity(main)
	# A tall physical viewport plus a real top safe-area inset changes the fitted
	# plate content without rebuilding Main. That exercises the resize callback,
	# not merely a second raster of the same 576px logical rectangle.
	await _configure_window(Vector2i(1080, 2400))
	main.set_meta("presentation_safe_top_inset", 48.0)
	var plate := main.find_child("ForgeContinuityStation", true, false) as PhysicalPortraitPlatePresenter
	if plate == null:
		_fail("Resize persistence fixture lost its physical Forge plate.")
		return
	main._apply_presentation_safe_area(plate)
	await get_tree().process_frame
	await get_tree().process_frame
	var identity_after := _presentation_identity(main)
	var forge = main._forge_component()
	var stage = forge.stage if forge != null else null
	var aperture = stage.get_parent() as Control if stage != null else null
	var native_content = aperture.get_parent() as Control if aperture != null else null
	var focus_after: Control = get_viewport().gui_get_focus_owner() as Control
	var focus_after_name: String = focus_after.name if focus_after != null else ""
	# Shell reconstruction deliberately gives the one persistent stage a fresh
	# clipped aperture. The accepted job and stage instance must survive, and its
	# dimensions must resync to that new plate content rather than retaining stale
	# 576px geometry.
	if authority_before != _job_authority_hash(main) or identity_before.sequence_id != identity_after.sequence_id or identity_before.stage_id != identity_after.stage_id or stage == null or aperture == null or native_content == null or not stage.size.is_equal_approx(native_content.size) or not stage.position.is_equal_approx(-aperture.position) or focus_after == null or focus_after_name != focus_before_name:
		_fail("Resize replaced the accepted Forge sequence/stage, mutated job authority, or left stale chamber geometry.")
		return
	_pause_resume_trace = {"focus_before":focus_before_name, "focus_after":focus_after_name, "stage_position":[stage.position.x, stage.position.y], "negative_aperture_position":[-aperture.position.x, -aperture.position.y]}
	await _write_capture(main, "ResizePersistentStage", Vector2i(1080, 2400), "actual_start_tall_safe_area_persistent_stage")
	if is_instance_valid(main):
		main.get_parent().remove_child(main)
		main.free()
	await get_tree().process_frame

func _focus_actual_action(node: Node) -> bool:
	for preferred in ["ArcaneForgeBack", "BeginCreaturePrint", "SkipPrinterAnimation", "UnifiedPackRevealBack", "WorkshopHotspotPrinter"]:
		var candidate := _button(node, preferred)
		if candidate != null and candidate.is_visible_in_tree() and not candidate.disabled:
			candidate.grab_focus()
			await get_tree().process_frame
			return candidate.has_focus()
	var all_buttons: Array[Node] = node.find_children("*", "Button", true, false)
	for candidate in all_buttons:
		var action := candidate as Button
		if action.is_visible_in_tree() and not action.disabled and action.focus_mode != Control.FOCUS_NONE:
			action.grab_focus()
			await get_tree().process_frame
			return action.has_focus()
	return false

func _capture_resolution(physical: Vector2i) -> void:
	var rows: Array[String] = ["StarterIdle", "RoutineIdle", "Print00", "Print25", "Print60", "Print99", "RawHold", "Awakening", "Departing", "Done", "Failed", "MissingStatic", "MissingRaw", "Core"]
	if physical == Vector2i(720, 1280):
		# These are named stress projections outside the unchanged M9-FC01..20
		# map. They make the core and largest creature's actual chamber geometry
		# reviewable rather than treating an empty IDLE bed as silhouette evidence.
		rows.append_array(["RoutineAlternateCaller", "RawComplete", "PausedCaller", "ResumedSameJob", "Largest", "SuitSafe", "Core60", "CoreRawHold", "Worldcoil60", "Worldcoil99", "WorldcoilRawHold", "WorldcoilAwakening"])
	for row in rows:
		await _capture_row(row, physical)
		if failed: return
	if physical == Vector2i(720, 1280):
		await _trace_legal_commit_and_skip(physical)

func _trace_legal_commit_and_skip(physical: Vector2i) -> void:
	var main := await _mount(physical)
	var start := _button(main, "BeginCreaturePrint")
	if start == null or start.disabled:
		_fail("Commit trace has no enabled actual Start.")
		return
	var before := _profile_authority_hash()
	await _tap(start)
	main.printer_capture_freeze = true
	main.advance_printer_for_test(ArcaneForgeSequence.PRINT_COMPLETE_BPS)
	await get_tree().process_frame
	var committed := _profile_authority_hash()
	var committed_phase: String = str(main.printer_sequence.phase if main.printer_sequence != null else "none")
	main._commit_printer_once()
	var duplicate := _profile_authority_hash()
	var skip := _button(main, "SkipPrinterAnimation")
	if skip == null:
		_fail("Commit trace has no legal Skip after resolution.")
		return
	await _tap(skip)
	await get_tree().process_frame
	var after_skip := _profile_authority_hash()
	if committed_phase != ArcaneForgeSequence.RAW_HOLD or before == committed or committed != duplicate or duplicate != after_skip:
		_fail("Legal RAW_COMPLETE must commit once; duplicate commit and post-resolution Skip cannot mutate authority.")
		return
	records.append({"id":"M9-FC-CommitOnceSkip", "dimensions":[physical.x, physical.y], "projection":"actual_start_actual_boundary_actual_skip", "authority_before_sha256":before, "authority_after_commit_sha256":committed, "authority_after_duplicate_sha256":duplicate, "authority_after_skip_sha256":after_skip, "phase_after_commit":committed_phase, "phase_after_skip":main.printer_sequence.phase if main.printer_sequence != null else "none"})
	main.get_parent().remove_child(main)
	main.free()
	await get_tree().process_frame

func _configure_window(physical: Vector2i) -> void:
	var window := get_tree().root.get_window()
	window.content_scale_size = LOGICAL_SIZE
	window.size = physical
	if not _mouse_notified:
		get_viewport().notify_mouse_entered()
		_mouse_notified = true
	await get_tree().process_frame
	await get_tree().process_frame

func _mount(physical: Vector2i, caller := "workshop", subject := "cinderpaw", starter := false) -> Control:
	await _configure_window(physical)
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	GameManager.profile = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile if starter else PROFILES.founder_ready("cinderpaw")
	GameManager.profile.forge_coins = 1200
	GameManager.profile.owned_blueprints["mossmunk"] = true
	GameManager.profile.owned_cards["mossmunk"] = maxi(1, int(GameManager.profile.owned_cards.get("mossmunk", 0)))
	var main: Control = MAIN.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame
	main.screen = caller
	main.open_printer(subject)
	await get_tree().process_frame
	main.printer_capture_freeze = true
	return main

func _capture_row(row: String, physical: Vector2i) -> void:
	if row in ["Core60", "CoreRawHold"]:
		await _capture_core_stage_stress(row, physical)
		return
	var caller := "archive" if row == "RoutineAlternateCaller" else "workshop"
	var subject := "worldcoil" if row in ["Largest", "Worldcoil60", "Worldcoil99", "WorldcoilRawHold", "WorldcoilAwakening"] else "cinderpaw"
	var main := await _mount(physical, caller, subject, row == "StarterIdle")
	_pause_resume_trace = {}
	if row in ["Largest", "Worldcoil60", "Worldcoil99", "WorldcoilRawHold", "WorldcoilAwakening"]:
		GameManager.profile.owned_blueprints["worldcoil"] = true
		GameManager.profile.owned_cards["worldcoil"] = 1
		main.open_printer("worldcoil")
		await get_tree().process_frame
		main.printer_capture_freeze = true
	var projection := "frozen_projection"
	if row in ["Print00", "Print25", "Print60", "Print99", "PausedCaller", "ResumedSameJob"]:
		projection = "actual_start"
		var start := _button(main, "BeginCreaturePrint")
		if start == null or start.disabled:
			_fail("%s has no enabled actual Start." % row)
			return
		await _tap(start)
		await get_tree().process_frame
		main.printer_capture_freeze = true
		if main.printer_sequence == null or main.printer_sequence.phase != ArcaneForgeSequence.PRINTING:
			_fail("%s actual Start did not enter printing." % row)
			return
		var target: int = int({"Print00":0, "Print25":1750, "Print60":4200, "Print99":6930, "PausedCaller":4200, "ResumedSameJob":4200}.get(row, 0))
		if int(target) > 0:
			main.advance_printer_for_test(maxi(1, int(target) - main.printer_sequence.progress_bps))
			await get_tree().process_frame
	elif row == "Core":
		GameManager.profile.core_blueprints = ["ember"]
		main.open_core_printer("ember")
		main.printer_capture_freeze = true
	elif row == "SuitSafe":
		GameManager.profile.suit_blueprints = ["standard"]
		main.open_armor_printer("standard")
		main.printer_capture_freeze = true
	elif row == "RawComplete":
		main.printer_sequence.phase = ArcaneForgeSequence.RAW_COMPLETE
		main.printer_sequence.progress_bps = ArcaneForgeSequence.PRINT_COMPLETE_BPS
		main.render()
		await get_tree().process_frame
	elif row in ["RawHold", "Awakening", "Departing", "Done", "Failed", "Core60", "CoreRawHold", "Worldcoil60", "Worldcoil99", "WorldcoilRawHold", "WorldcoilAwakening"]:
		_set_frozen_phase(main, row)
		if row == "Failed": main.printer_failure = "Profile storage is unavailable; the Forge record was not committed."
		main.render()
		await get_tree().process_frame
	elif row in ["MissingStatic", "MissingRaw"]:
		var physical_component = main._physical_forge_component()
		physical_component.test_missing_layer = "static" if row == "MissingStatic" else "raw"
		main.render()
		await get_tree().process_frame
	if row == "PausedCaller":
		var active_back := _button(main, "ArcaneForgeBack")
		if active_back == null:
			_fail("PausedCaller has no actual Back owner.")
			return
		var paused_authority := _job_authority_hash(main)
		_pause_resume_trace = {"before_back":_presentation_identity(main)}
		await _tap(active_back)
		await get_tree().process_frame
		if main.screen != "workshop" or _job_authority_hash(main) != paused_authority:
			_fail("Actual active Back did not preserve the accepted job authority.")
			return
		_pause_resume_trace["after_back"] = _presentation_identity(main)
	if row == "ResumedSameJob":
		var before := _job_authority_hash(main)
		_pause_resume_trace = {"before_back":_presentation_identity(main)}
		var active_back := _button(main, "ArcaneForgeBack")
		if active_back == null:
			_fail("ResumedSameJob has no actual active Back owner.")
			return
		await _tap(active_back)
		await get_tree().process_frame
		if main.screen != "workshop" or _job_authority_hash(main) != before:
			_fail("Actual Resume fixture Back changed the accepted job authority.")
			return
		_pause_resume_trace["after_back"] = _presentation_identity(main)
		# Resume through the current physical Workshop overview hotspot, not an
		# obsolete view injection or direct Forge callback.
		var resume := _button(main, "WorkshopHotspotPrinter")
		if resume == null:
			_fail("ResumedSameJob has no actual Workshop resume control.")
			return
		await _tap(resume)
		await get_tree().process_frame
		if main.screen != "printer" or _job_authority_hash(main) != before:
			_fail("Actual Workshop Resume changed the accepted job authority.")
			return
		_pause_resume_trace["after_resume"] = _presentation_identity(main)
		if int(_pause_resume_trace.before_back.sequence_id) != int(_pause_resume_trace.after_resume.sequence_id) or int(_pause_resume_trace.before_back.stage_id) != int(_pause_resume_trace.after_resume.stage_id):
			_fail("Actual Workshop Resume replaced the accepted sequence or persistent stage.")
			return
	await _write_capture(main, row, physical, projection)
	if is_instance_valid(main):
		main.get_parent().remove_child(main)
		main.free()
	await get_tree().process_frame

func _capture_core_stage_stress(row: String, physical: Vector2i) -> void:
	await _configure_window(physical)
	var fixture := Control.new()
	fixture.name = "LegacyCoreGeometryFixture"
	fixture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fixture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(fixture)
	var plate := TextureRect.new()
	plate.name = "LegacyCoreGeometryStation"
	plate.texture = ResourceLoader.load(STATION_PATH) as Texture2D
	plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode = TextureRect.STRETCH_SCALE
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fixture.add_child(plate)
	var stage := ArcaneForgeStage.new()
	stage.name = "LegacyCoreGeometryStage"
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fixture.add_child(stage)
	stage.configure("cinderpaw", false, false, "ember", "ember")
	stage.set_continuity_station(true)
	_set_stage_only_phase(stage, row)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or image.get_size() != physical:
		_fail("%s stage-only capture dimensions were %s, expected %s." % [row, str(image.get_size() if image != null else Vector2i()), str(physical)])
		fixture.queue_free()
		return
	var folder := "%s/%dx%d" % [output_root, physical.x, physical.y]
	DirAccess.make_dir_recursive_absolute(folder)
	var output := "%s/M9-FC-%s-%dx%d.png" % [folder, row, physical.x, physical.y]
	if FileAccess.file_exists(output):
		_fail("Capture output already exists; refusing to overwrite immutable evidence: %s" % output)
		fixture.queue_free()
		return
	if image.save_png(output) != OK:
		_fail("Could not save %s." % output)
		fixture.queue_free()
		return
	var visible: Array[String] = [STATION_PATH]
	for texture in [stage.raw, stage._continuity_guide, stage._continuity_head]:
		if texture != null and not texture.resource_path.is_empty(): visible.append(texture.resource_path)
	var profile_hash := _profile_authority_hash()
	var record := {"id":"M9-FC-%s" % row, "physical_png":output, "dimensions":[physical.x, physical.y], "logical_canvas":[LOGICAL_SIZE.x, LOGICAL_SIZE.y], "projection":"stage_only_legacy_geometry", "runtime_core_route":"safe_unavailable_no_approved_blueprint_ink", "phase":stage.phase, "progress_bps":stage.progress_bps, "authority_before_sha256":profile_hash, "authority_after_sha256":profile_hash, "png_bytes":FileAccess.get_file_as_bytes(output).size(), "png_sha256":FileAccess.get_sha256(output), "visible_texture_paths":_unique_sorted(visible), "loaded_texture_paths":_unique_sorted(visible), "pause_resume":{}}
	records.append(record)
	print("FORGE_NORMAL_MAP_CAPTURE %s" % JSON.stringify(record))
	fixture.queue_free()
	await get_tree().process_frame

func _write_capture(main: Control, row: String, physical: Vector2i, projection: String) -> void:
	var authority_before := _authority_hash(main)
	await RenderingServer.frame_post_draw
	var authority_after := _authority_hash(main)
	if authority_after != authority_before:
		_fail("%s render/capture mutated authority." % row)
		return
	var image := get_viewport().get_texture().get_image()
	if image == null or image.get_size() != physical:
		_fail("%s capture dimensions were %s, expected %s." % [row, str(image.get_size() if image != null else Vector2i()), str(physical)])
		return
	var folder := "%s/%dx%d" % [output_root, physical.x, physical.y]
	DirAccess.make_dir_recursive_absolute(folder)
	var output := "%s/M9-FC-%s-%dx%d.png" % [folder, row, physical.x, physical.y]
	if FileAccess.file_exists(output):
		_fail("Capture output already exists; refusing to overwrite immutable evidence: %s" % output)
		return
	if image.save_png(output) != OK:
		_fail("Could not save %s." % output)
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	var record := {"id":"M9-FC-%s" % row, "physical_png":output, "dimensions":[physical.x, physical.y], "logical_canvas":[LOGICAL_SIZE.x, LOGICAL_SIZE.y], "projection":projection, "phase":main.printer_sequence.phase if main.printer_sequence != null else "none", "progress_bps":main.printer_sequence.progress_bps if main.printer_sequence != null else -1, "authority_before_sha256":authority_before, "authority_after_sha256":authority_after, "focus_owner":focus_owner.name if focus_owner != null else "", "presentation_identity":_presentation_identity(main) if main.printer_sequence != null else {}, "settings":GameManager.profile.get("settings", {}).duplicate(true), "png_bytes":FileAccess.get_file_as_bytes(output).size(), "png_sha256":FileAccess.get_sha256(output), "visible_texture_paths":_visible_texture_paths(main), "loaded_texture_paths":_loaded_texture_paths(main), "pause_resume":_pause_resume_trace.duplicate(true)}
	records.append(record)
	print("FORGE_NORMAL_MAP_CAPTURE %s" % JSON.stringify(record))

func _preference_capture_suffix(preferences: Dictionary) -> String:
	if int(preferences.get("text_scale_bps", 10000)) >= 15000 and bool(preferences.get("high_contrast", false)) and bool(preferences.get("reduced_motion", false)):
		return "150HCRM"
	return "Normal"

func _authority_hash(main: Control) -> String:
	var sequence: ArcaneForgeSequence = main.printer_sequence as ArcaneForgeSequence
	var snapshot := {"profile":GameManager.profile, "screen":main.screen, "subject":main.printer_creature_id, "caller":main.printer_return_screen, "phase":sequence.phase if sequence != null else "", "progress":sequence.progress_bps if sequence != null else -1, "elapsed":sequence.phase_elapsed_bps if sequence != null else -1, "commit_requested":sequence.commit_requested if sequence != null else false, "resolved":sequence.resolved if sequence != null else false}
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(JSON.stringify(snapshot).to_utf8_buffer())
	return hashing.finish().hex_encode()

func _job_authority_hash(main: Control) -> String:
	var sequence: ArcaneForgeSequence = main.printer_sequence as ArcaneForgeSequence
	var snapshot := {"profile":GameManager.profile, "subject":main.printer_creature_id, "caller":main.printer_return_screen, "phase":sequence.phase if sequence != null else "", "progress":sequence.progress_bps if sequence != null else -1, "elapsed":sequence.phase_elapsed_bps if sequence != null else -1, "commit_requested":sequence.commit_requested if sequence != null else false, "resolved":sequence.resolved if sequence != null else false}
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(JSON.stringify(snapshot).to_utf8_buffer())
	return hashing.finish().hex_encode()

func _profile_authority_hash() -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(JSON.stringify(GameManager.profile).to_utf8_buffer())
	return hashing.finish().hex_encode()

func _visible_texture_paths(node: Node) -> Array[String]:
	var paths: Array[String] = []
	_collect_visible_textures(node, paths)
	var forge = node._forge_component() if node.has_method("_forge_component") else null
	var stage = forge.stage if forge != null else null
	var stage_paths := _stage_texture_paths(stage)
	# The chamber draws these resources manually. Remove the loaded child cache
	# entries first, then add only the assets this frozen phase actually draws.
	for path in stage_paths:
		while paths.has(path): paths.erase(path)
	if stage != null and stage.is_visible_in_tree():
		for texture in [stage._continuity_guide, stage._continuity_head]:
			if texture != null and not texture.resource_path.is_empty(): paths.append(texture.resource_path)
		var sequence: ArcaneForgeSequence = node.printer_sequence as ArcaneForgeSequence
		var phase := sequence.phase if sequence != null else ""
		var raw_is_drawn := phase in [ArcaneForgeSequence.RAW_COMPLETE, ArcaneForgeSequence.RAW_HOLD, ArcaneForgeSequence.AWAKENING]
		if phase == ArcaneForgeSequence.PRINTING and sequence != null:
			raw_is_drawn = sequence.layer_reveal_bps() > 0
		if raw_is_drawn and stage.raw != null and not stage.raw.resource_path.is_empty(): paths.append(stage.raw.resource_path)
		var living_is_drawn := not bool(node.printer_is_armor) and phase in [ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.DEPARTING]
		if living_is_drawn and stage.living != null and not stage.living.resource_path.is_empty(): paths.append(stage.living.resource_path)
	if node.find_child("ForgeContinuityStation", true, false) != null:
		paths.append("res://assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png")
	return _unique_sorted(paths)

func _loaded_texture_paths(node: Node) -> Array[String]:
	var paths: Array[String] = []
	_collect_visible_textures(node, paths)
	var forge = node._forge_component() if node.has_method("_forge_component") else null
	var stage = forge.stage if forge != null else null
	paths.append_array(_stage_texture_paths(stage))
	if node.find_child("ForgeContinuityStation", true, false) != null:
		paths.append("res://assets/ui/physical_ui/forge-continuity/enclosed-forge-static-master-v1.png")
	return _unique_sorted(paths)

func _stage_texture_paths(stage: ArcaneForgeStage) -> Array[String]:
	var paths: Array[String] = []
	if stage == null: return paths
	for texture in [stage.raw, stage.living, stage._continuity_guide, stage._continuity_head]:
		if texture != null and not texture.resource_path.is_empty(): paths.append(texture.resource_path)
	return paths

func _unique_sorted(paths: Array[String]) -> Array[String]:
	var unique := {}
	for path in paths:
		if not path.is_empty(): unique[path] = true
	var result: Array[String] = []
	for path in unique.keys(): result.append(str(path))
	result.sort()
	return result

func _set_frozen_phase(main: Control, row: String) -> void:
	var states := {
		"RawHold":{"phase":ArcaneForgeSequence.RAW_HOLD, "progress":7000, "elapsed":1500},
		"Awakening":{"phase":ArcaneForgeSequence.AWAKENING, "progress":8000, "elapsed":1000},
		"Departing":{"phase":ArcaneForgeSequence.DEPARTING, "progress":9500, "elapsed":500},
		"Done":{"phase":ArcaneForgeSequence.AWAKENED, "progress":10000, "elapsed":0},
		"Failed":{"phase":ArcaneForgeSequence.FAILED, "progress":7000, "elapsed":0},
		"Core60":{"phase":ArcaneForgeSequence.PRINTING, "progress":4200, "elapsed":0},
		"CoreRawHold":{"phase":ArcaneForgeSequence.RAW_HOLD, "progress":7000, "elapsed":1500},
		"Worldcoil60":{"phase":ArcaneForgeSequence.PRINTING, "progress":4200, "elapsed":0},
		"Worldcoil99":{"phase":ArcaneForgeSequence.PRINTING, "progress":6930, "elapsed":0},
		"WorldcoilRawHold":{"phase":ArcaneForgeSequence.RAW_HOLD, "progress":7000, "elapsed":1500},
		"WorldcoilAwakening":{"phase":ArcaneForgeSequence.AWAKENING, "progress":8000, "elapsed":1000}
	}
	var state: Dictionary = states.get(row, {})
	main.printer_sequence.phase = str(state.get("phase", ArcaneForgeSequence.RAW_HOLD))
	main.printer_sequence.progress_bps = int(state.get("progress", 7000))
	main.printer_sequence.phase_elapsed_bps = int(state.get("elapsed", 0))
	var is_printing: bool = main.printer_sequence.phase == ArcaneForgeSequence.PRINTING
	# A printing projection has not crossed the existing commit boundary. Hold and
	# later terminal projections are explicitly post-resolution fixtures.
	main.printer_sequence.commit_requested = not is_printing
	main.printer_sequence.resolved = not is_printing

func _set_stage_only_phase(stage: ArcaneForgeStage, row: String) -> void:
	if row == "Core60":
		stage.set_preview_phase(ArcaneForgeSequence.PRINTING, 4200)
	else:
		stage.set_preview_phase(ArcaneForgeSequence.RAW_HOLD, 7000, 5000)

func _collect_visible_textures(node: Node, paths: Array[String]) -> void:
	if node is TextureRect and (node as TextureRect).is_visible_in_tree():
		var texture := (node as TextureRect).texture
		if texture != null and not texture.resource_path.is_empty(): paths.append(texture.resource_path)
	if node is PhysicalPortraitPlatePresenter and (node as PhysicalPortraitPlatePresenter).is_visible_in_tree():
		var plate_texture := (node as PhysicalPortraitPlatePresenter).plate_texture
		if plate_texture != null and not plate_texture.resource_path.is_empty(): paths.append(plate_texture.resource_path)
	if node is Control and (node as Control).is_visible_in_tree():
		for style_name in ["normal", "hover", "pressed", "disabled", "focus", "panel", "background", "fill"]:
			var style := (node as Control).get_theme_stylebox(style_name)
			if style is StyleBoxTexture:
				var style_texture := (style as StyleBoxTexture).texture
				if style_texture != null and not style_texture.resource_path.is_empty(): paths.append(style_texture.resource_path)
	for child in node.get_children(): _collect_visible_textures(child, paths)

func _presentation_identity(main: Control) -> Dictionary:
	var forge = main._forge_component()
	var stage = forge.stage if forge != null else null
	var sequence: ArcaneForgeSequence = main.printer_sequence as ArcaneForgeSequence
	return {"sequence_id":sequence.get_instance_id() if sequence != null else -1, "stage_id":stage.get_instance_id() if stage != null else -1, "stage_parent_id":stage.get_parent().get_instance_id() if stage != null and stage.get_parent() != null else -1, "generation":int(sequence.get_instance_id()) if sequence != null else -1, "subject":main.printer_creature_id, "phase":sequence.phase if sequence != null else "", "progress":sequence.progress_bps if sequence != null else -1, "caller":main.printer_return_screen}

func _button(node: Node, node_name: String) -> Button:
	if node is Button and node.name == node_name: return node as Button
	for child in node.get_children():
		var found := _button(child, node_name)
		if found != null: return found
	return null

func _tap(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point; event.button_index = MOUSE_BUTTON_LEFT; event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0; event.pressed = pressed
		get_viewport().push_input(event, true)
	await get_tree().process_frame

func _write_manifest() -> void:
	DirAccess.make_dir_recursive_absolute(output_root)
	var file := FileAccess.open("%s/manifest.json" % output_root, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"capture_family":"M9 Forge %s map v1" % capture_family, "rendering_method":RenderingServer.get_current_rendering_method(), "display_server":DisplayServer.get_name(), "records":records}, "\t"))
		file.close()

func _fail(message: String) -> void:
	failed = true
	push_error(message)
	_write_manifest()
	get_tree().quit(1)
