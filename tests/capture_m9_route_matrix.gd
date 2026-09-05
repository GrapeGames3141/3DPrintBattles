extends Node
## Rendered M9A route evidence.  Route setup is deterministic fixture state, but
## each row activates its visible Back/Continue owner through Viewport.push_input
## before returning to the exact route that is captured.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const TEST_PROFILES := preload("res://tests/m9_test_profile_factory.gd")
const BATTLE_STATE := preload("res://scripts/battle/unified_battle_state.gd")
const CONTROLS := preload("res://scripts/ui/physical_control_family.gd")

const ROUTES := ["title", "workshop", "starter", "first_print", "active_forge", "founder_page_1", "founder_page_3", "founder_recovery", "archive", "deck", "market", "settings", "result", "battle_exit"]
const PRODUCTION_BASE := Vector2i(576, 1024)

var main: Control
var route_id := ""
var capture_size := Vector2i(576, 1024)
var app_root: Window

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	app_root = get_tree().root
	var args := OS.get_cmdline_user_args()
	route_id = str(args[0]) if not args.is_empty() else "title"
	if route_id not in ROUTES:
		push_error("Unknown M9 capture route: %s" % route_id)
		get_tree().quit(1)
		return
	if args.size() >= 3:
		capture_size = Vector2i(int(args[1]), int(args[2]))
	if capture_size.x < 320 or capture_size.y < 560:
		push_error("M9 capture needs a portrait surface, got %s." % capture_size)
		get_tree().quit(1)
		return
	if DisplayServer.get_name().to_lower() == "headless":
		push_error("M9 route capture needs Forward+; headless output is not visual evidence.")
		get_tree().quit(1)
		return
	var output := str(args[3]) if args.size() >= 4 else "E:/AI Projects/games/3d print battler/build/evidence/m9a-runtime-20260904/captures/%s-%dx%d.png" % [route_id, capture_size.x, capture_size.y]
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var window := app_root.get_window()
	# Keep the production logical canvas intact.  Higher physical window sizes are
	# raster-output fixtures, not a different UI layout contract.
	window.content_scale_size = PRODUCTION_BASE
	window.size = capture_size
	await get_tree().process_frame
	print("M9_ROUTE_SURFACE base=%s visible=%s window=%s transform=%s" % [window.content_scale_size, app_root.get_viewport().get_visible_rect().size, window.size, app_root.get_viewport().get_final_transform()])
	app_root.get_viewport().notify_mouse_entered()
	GameManager.save_compatibility = {"compatible": true, "state": "ready", "message": ""}
	GameManager.profile = TEST_PROFILES.founder_ready("cinderpaw")
	GameManager.profile.forge_coins = 1200
	_apply_accessibility_flags(args)
	main = MAIN.instantiate()
	app_root.add_child(main)
	await _prepare_route()
	await get_tree().process_frame
	await get_tree().process_frame
	if not await _prove_live_owner():
		get_tree().quit(1)
		return
	await _prepare_route()
	await get_tree().process_frame
	await get_tree().process_frame
	# The tested Battle Back action above dismisses its foreground decision. Reopen
	# it only for the evidence frame, so the capture proves the actual modal owner
	# rather than a background arena after a direct fixture reset.
	if route_id == "battle_exit" and not await _tap(_owner()):
		push_error("Battle exit capture could not reopen its foreground decision.")
		get_tree().quit(1)
		return
	var image := app_root.get_viewport().get_texture().get_image()
	if image == null or image.get_size() != capture_size:
		push_error("M9 rendered capture surface was unavailable or wrong size for %s." % route_id)
		get_tree().quit(1)
		return
	var result := image.save_png(output)
	if result != OK:
		push_error("Could not write M9 route capture: %s" % output)
		get_tree().quit(1)
		return
	print("M9_ROUTE_CAPTURE route=%s size=%s output=%s" % [route_id, capture_size, output])
	main.get_parent().remove_child(main)
	main.free()
	CONTROLS.release_cached_resources()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0)

func _fresh_founder_receipt() -> void:
	var founder: Dictionary = RULES.print_starter(RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile).profile
	GameManager.profile = founder
	var opened := GameManager.claim_next_starter_pack("workshop", {"caller": "workshop"})
	if not bool(opened.get("ok", false)):
		push_error("Founder receipt fixture could not atomically open.")
		return
	main._m3_open_pending_pack("workshop")

func _prepare_route() -> void:
	if not is_instance_valid(main): return
	main.title_exit_confirmation = false
	main.battle_back_confirmation = false
	main.printer_capture_freeze = false
	match route_id:
		"title":
			GameManager.profile = TEST_PROFILES.founder_ready("cinderpaw")
			main.screen = "title"
		"workshop":
			GameManager.profile = TEST_PROFILES.founder_ready("cinderpaw")
			main.screen = "workshop"; main.workshop_view = "overview"
		"starter":
			GameManager.profile = RULES.new_profile()
			main.screen = "onboarding"
		"first_print":
			GameManager.profile = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
			main.screen = "onboarding"; main.render(); await get_tree().process_frame; main.open_printer("cinderpaw")
		"active_forge":
			GameManager.profile = TEST_PROFILES.founder_ready("cinderpaw")
			main.screen = "workshop"; main.render(); await get_tree().process_frame; main.open_printer("cinderpaw"); main.printer_capture_freeze = true; main.begin_printer(); main.printer_sequence.progress_bps = 4200; main.render()
		"founder_page_1", "founder_page_3", "founder_recovery":
			_fresh_founder_receipt()
			await get_tree().process_frame
			if route_id == "founder_page_1":
				var mossmunk := _pack_card_target("Mossmunk")
				if not await _tap(mossmunk): return
			elif route_id == "founder_page_3":
				var next := main.find_child("UnifiedPackRevealNext", true, false) as Button
				if not await _tap(next): return
				if not await _tap(main.find_child("UnifiedPackRevealNext", true, false) as Button): return
			elif route_id == "founder_recovery":
				main._m3_back_from_pack()
		"archive": main.screen = "unified_library"
		"deck": main.screen = "unified_deck"
		"market": main.screen = "unified_market"
		"settings": main.screen = "settings"; main.settings_return_screen = "workshop"
		"result":
			main.screen = "m3_result"; main.m3_result_state = "committed"; main.m3_result_receipt = {"result": "victory", "mode": "training", "coins": 25, "xp": 10}
		"battle_exit":
			main.battle = BATTLE_STATE.create(["cinderpaw"], ["aquafin"], 61)
			main.battle_mode = "training"; main.battle_settlement_context = {"mode": "training"}; main.unified_battle_coordinator.configure(main.battle, 0); main.screen = "unified_battle"
	_apply_accessibility_flags(OS.get_cmdline_user_args())
	main.render()

func _apply_accessibility_flags(args: Array) -> void:
	var settings: Dictionary = GameManager.profile.get("settings", {})
	if "--text150" in args: settings.text_scale_bps = 15000
	if "--high-contrast" in args: settings.high_contrast = true
	if "--reduced-motion" in args: settings.reduced_motion = true
	GameManager.profile.settings = settings

func _owner() -> Button:
	match route_id:
		"title": return main.find_child("TitleBack", true, false) as Button
		"workshop": return main.find_child("WorkshopBack", true, false) as Button
		"starter": return main.find_child("StarterBack", true, false) as Button
		"first_print": return main.find_child("ArcaneForgeBack", true, false) as Button
		"active_forge": return main.find_child("ArcaneForgeBack", true, false) as Button
		"founder_page_1", "founder_page_3": return main.find_child("UnifiedPackRevealBack", true, false) as Button
		"founder_recovery": return main.find_child("WorkshopBack", true, false) as Button
		"archive": return main.find_child("ArchiveArchBack", true, false) as Button
		"deck", "market": return main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
		"settings": return main.find_child("SettingsCancel", true, false) as Button
		"result": return main.find_child("ResultContinue", true, false) as Button
		"battle_exit": return main.find_child("UnifiedBattleBack", true, false) as Button
	return null

func _pack_card_target(card_name: String) -> Button:
	for candidate in main.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button != null and button.accessibility_name.begins_with("%s · inspect committed pack card" % card_name):
			return button
	return null

func _prove_live_owner() -> bool:
	var owner := _owner()
	if not is_instance_valid(owner) or not owner.is_visible_in_tree() or owner.disabled:
		push_error("M9 route %s lacks a live visible owner." % route_id)
		return false
	if owner.get_global_rect().size.x < 56.0 or owner.get_global_rect().size.y < 56.0:
		push_error("M9 route %s owner is below the 56px target: %s." % [route_id, owner.get_global_rect().size])
		return false
	if not await _tap(owner): return false
	if not _expected_action_result(): return false
	if route_id == "battle_exit":
		var modal := main.find_child("UnifiedBattleExitBack", true, false) as Button
		if not is_instance_valid(modal) or not main.battle_back_confirmation:
			push_error("Battle Back did not open its foreground exit decision.")
			return false
		if modal.get_global_rect().size.x < 56.0 or modal.get_global_rect().size.y < 56.0:
			push_error("Battle foreground Back is below the 56px target.")
			return false
		return await _tap(modal)
	return true

func _expected_action_result() -> bool:
	match route_id:
		"title": return main.title_exit_confirmation
		"workshop", "starter", "founder_recovery": return main.screen == "title"
		"first_print": return main.screen == "workshop" and str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected"
		"active_forge": return main.screen == "workshop" and main.printer_sequence != null
		"founder_page_1", "founder_page_3": return main.screen == "workshop" and not (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty()
		"archive", "deck", "market", "settings", "result": return main.screen == "workshop"
		"battle_exit": return main.battle_back_confirmation
	return false

func _tap(target: Button) -> bool:
	if not is_instance_valid(target) or target.disabled or not target.is_visible_in_tree(): return false
	# Viewport.push_input consumes preserved logical-canvas coordinates. The
	# physical window transform is recorded above for raster evidence only.
	var point := target.get_global_rect().get_center()
	var move := InputEventMouseMotion.new(); move.position = point; move.global_position = point
	app_root.get_viewport().push_input(move, true)
	await get_tree().process_frame
	if app_root.get_viewport().gui_get_hovered_control() != target:
		var hovered := app_root.get_viewport().gui_get_hovered_control()
		push_error("M9 live owner is obstructed: target=%s hovered=%s." % [target.name, hovered.name if hovered != null else "<none>"])
		return false
	var down := InputEventMouseButton.new(); down.position = point; down.global_position = point; down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true
	app_root.get_viewport().push_input(down, true)
	await get_tree().process_frame
	var up := InputEventMouseButton.new(); up.position = point; up.global_position = point; up.button_index = MOUSE_BUTTON_LEFT
	app_root.get_viewport().push_input(up, true)
	await get_tree().process_frame
	return true
