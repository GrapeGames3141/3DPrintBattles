extends Node

## M9 deliberately drives Godot's normal viewport input path.  Do not replace
## these taps with `pressed.emit()` / direct callbacks: this test protects the
## physical plate hit stack that ships to touch devices.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const TEST_PROFILES := preload("res://tests/m9_test_profile_factory.gd")
const BATTLE_STATE := preload("res://scripts/battle/unified_battle_state.gd")
const CONTROLS := preload("res://scripts/ui/physical_control_family.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	await _run()

func _profile() -> Dictionary:
	var profile: Dictionary = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	profile = RULES.print_starter(profile).profile
	profile.forge_coins = 500
	return profile

func _tap_mouse(target: Control) -> void:
	var point := target.get_global_rect().get_center()
	var move := InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	move.window_id = get_window().get_window_id()
	get_viewport().push_input(move, true)
	await get_tree().process_frame
	var down := InputEventMouseButton.new()
	down.position = point
	down.global_position = point
	down.window_id = get_window().get_window_id()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	get_viewport().push_input(down, true)
	await get_tree().process_frame
	var up := InputEventMouseButton.new()
	up.position = point
	up.global_position = point
	up.window_id = get_window().get_window_id()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	get_viewport().push_input(up, true)
	await get_tree().process_frame

func _tap_touch(target: Control) -> void:
	var point := target.get_global_rect().get_center()
	var down := InputEventScreenTouch.new()
	down.position = point
	down.window_id = get_window().get_window_id()
	down.index = 0
	down.pressed = true
	get_viewport().push_input(down, true)
	await get_tree().process_frame
	var up := InputEventScreenTouch.new()
	up.position = point
	up.window_id = get_window().get_window_id()
	up.index = 0
	up.pressed = false
	get_viewport().push_input(up, true)
	await get_tree().process_frame

func _propagate_window_back() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)

func _run() -> void:
	# GameManager is an autoload, so this suite must receive a debug QA storage
	# root on the process command line before the scene is instantiated.  Never
	# redirect it late here: that can mix a prior receipt sidecar into this test.
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var active_root := SaveService.profile_path.get_base_dir().replace("\\", "/")
	if not active_root.begins_with(evidence_root + "/"):
		require(false, "M9 real input requires an E: --qa-save-root before autoload profile access.")
		get_tree().quit(1)
		return
	get_window().content_scale_size = Vector2i(576, 1024)
	get_window().size = Vector2i(576, 1024)
	await get_tree().process_frame
	get_viewport().notify_mouse_entered()
	GameManager.profile = _profile()
	GameManager.save_compatibility = {"compatible": true, "state": "ready"}
	var main := MAIN.instantiate()
	main.screen = "unified_market"
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var back := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
	require(back != null and back.get_global_rect().size.x >= 56.0 and back.get_global_rect().size.y >= 56.0, "Market exposes a readable 56px physical Back target.")
	if back != null:
		# This recreates the original M8 fault in-place: a late full-rect STOP
		# decoration consumes the same physical coordinate before the Back owner.
		var blocker := Control.new()
		blocker.name = "M9BaselineFullRectStopBlocker"
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		main.add_child(blocker)
		await _tap_mouse(back)
		require(main.screen == "unified_market", "A recreated full-rect STOP decoration blocks the Market Back center.")
		blocker.queue_free()
		await get_tree().process_frame
		await _tap_mouse(back)
		require(main.screen == "workshop", "A mouse tap at the Market Back center reaches the actual Back control through the viewport.")
		main.screen = "unified_market"
		main.render()
		await get_tree().process_frame
		back = main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
		if back != null:
			await _tap_touch(back)
			require(main.screen == "workshop", "A touch tap at the Market Back center reaches the actual Back control through the viewport.")
		main.screen = "unified_market"
		main.render()
		await get_tree().process_frame
		# Propagate from the Window rather than invoking Main._notification directly.
		call_deferred("_propagate_window_back")
		await get_tree().process_frame
		await get_tree().process_frame
		require(main.screen == "workshop", "Window Back propagation reaches the same Market-to-Workshop dispatcher.")
		main.screen = "unified_market"
		main.render()
		await get_tree().process_frame
	var key_back := InputEventKey.new()
	key_back.keycode = KEY_BACK
	key_back.pressed = true
	get_viewport().push_input(key_back, true)
	await get_tree().process_frame
	require(main.screen == "workshop", "KEY_BACK reaches the same Market-to-Workshop dispatcher.")
	# These production-route targets are all real top-layer controls.  The fixture
	# sets route state only; every asserted transition enters by pointer input.
	main.screen = "title"
	main.render()
	await get_tree().process_frame
	var title_back := main.find_child("TitleBack", true, false) as Button
	if title_back != null:
		await _tap_touch(title_back)
		require(main.title_exit_confirmation, "A touch tap on Title Back opens the explicit Exit or Stay decision.")
		var title_stay := main.find_child("TitleStay", true, false) as Button
		if title_stay != null:
			await _tap_mouse(title_stay)
			require(not main.title_exit_confirmation and main.screen == "title", "Title Stay keeps the maker in the title route.")
	else:
		require(false, "Title exposes a real Back or Exit control.")
	main.screen = "workshop"
	main.workshop_view = "overview"
	main.render()
	await get_tree().process_frame
	var workshop_back := main.find_child("WorkshopBack", true, false) as Button
	if workshop_back != null:
		await _tap_mouse(workshop_back)
		require(main.screen == "title", "A mouse tap on Workshop Back returns to Title.")
	else:
		require(false, "Workshop overview exposes a real Back control.")
	# Archive and Deck use their route-owned physical Back targets, not the old
	# generic workshop shell.
	main.screen = "unified_library"
	main.render()
	await get_tree().process_frame
	var archive_back := main.find_child("ArchiveArchBack", true, false) as Button
	if archive_back != null:
		await _tap_mouse(archive_back)
		require(main.screen == "workshop", "A mouse tap on Archive Back returns through the physical Archive owner.")
	else:
		require(false, "Archive exposes a physical Back target.")
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	var deck_back := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
	if deck_back != null:
		await _tap_touch(deck_back)
		require(main.screen == "workshop", "A touch tap on Deck Back returns through the physical Deck owner.")
	else:
		require(false, "Deck exposes a physical Back target.")
	main.screen = "onboarding"
	main.render()
	await get_tree().process_frame
	var starter_back := main.find_child("StarterBack", true, false) as Button
	if starter_back != null:
		await _tap_touch(starter_back)
		require(main.screen == "title", "A touch tap on Starter Back returns to Title before a blueprint is committed.")
	else:
		require(false, "Starter selection exposes a real Back control.")
	# First Print is a genuine starter-selected profile. Its Back is a real
	# physical target and must preserve the unprinted onboarding selection.
	GameManager.profile = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	main.screen = "onboarding"
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var first_print_back := main.find_child("ArcaneForgeBack", true, false) as Button
	if first_print_back != null:
		await _tap_mouse(first_print_back)
		var first_print_resume := main.find_child("WorkshopHotspotPrinter", true, false) as Button
		require(main.screen == "workshop" and main.find_child("WorkshopPortraitPlate", true, false) != null and first_print_resume != null and str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected", "A mouse tap on First Print Back returns to the approved physical Workshop without committing or clearing the selected starter.")
		if first_print_resume != null:
			await _tap_touch(first_print_resume)
			require(main.screen == "printer" and main.printer_creature_id == "cinderpaw" and main.printer_price == 0 and main.printer_sequence != null and main.printer_sequence.phase == "idle", "A touch tap on the physical Workshop Printer reopens the selected free First Print setup.")
	else:
		require(false, "First Print exposes its physical Back target.")
	# Result uses Continue as its sole Back owner. This is a committed receipt
	# fixture; the assertion still reaches it through the rendered button center.
	GameManager.profile = TEST_PROFILES.founder_ready("cinderpaw")
	main.battle_mode = "training"
	main.m3_result_state = "committed"
	main.m3_result_receipt = {"outcome":"Victory", "settlement":"committed", "coins":25, "xp":10}
	main.screen = "m3_result"
	main.render()
	await get_tree().process_frame
	var result_continue := main.find_child("ResultContinue", true, false) as Button
	if result_continue != null:
		await _tap_mouse(result_continue)
		require(main.screen == "workshop", "A mouse tap on Result Continue reaches the committed Result Back owner and returns to Workshop.")
	else:
		require(false, "Committed Result exposes its physical Continue/Back target.")
	# A legal completed Founder profile may safely enter a live Forge presentation.
	GameManager.profile = TEST_PROFILES.founder_ready("cinderpaw")
	main.screen = "workshop"
	main.open_printer("cinderpaw")
	main.begin_printer()
	await get_tree().process_frame
	var forge_back := main.find_child("ArcaneForgeBack", true, false) as Button
	if forge_back != null:
		await _tap_touch(forge_back)
		require(main.screen == "workshop" and main.printer_sequence != null, "A touch tap on active Forge Back returns to Workshop while preserving the accepted job.")
	else:
		require(false, "An active Forge exposes its physical Back target.")
	# Founder receipt pagination and recovery are pointer-only after its committed
	# claim setup; neither page browsing nor Back may acknowledge ownership.
	var founder: Dictionary = RULES.print_starter(RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile).profile
	GameManager.profile = founder
	var opened := GameManager.claim_next_starter_pack("workshop", {"caller":"workshop"})
	require(bool(opened.get("ok", false)), "Matrix setup commits one Founder receipt before opening Pack UI.")
	main._m3_open_pending_pack("workshop")
	await get_tree().process_frame
	var mossmunk_tile: Button
	for candidate in main.find_children("*", "Button", true, false):
		var tile := candidate as Button
		if tile != null and tile.accessibility_name.begins_with("Mossmunk · inspect committed pack card"):
			mossmunk_tile = tile
			break
	if mossmunk_tile != null:
		await _tap_touch(mossmunk_tile)
		require(main.m3_pack_inspector_id == "mossmunk", "A touch tile selection persists the selected Founder card in the inline receipt facts.")
	else:
		var pack_buttons: Array[String] = []
		for candidate in main.find_children("*", "Button", true, false): pack_buttons.append((candidate as Button).name)
		require(false, "Founder receipt exposes Mossmunk as a real whole-tile target. Buttons: %s" % ", ".join(pack_buttons))
	var receipt_next := main.find_child("UnifiedPackRevealNext", true, false) as Button
	if receipt_next != null:
		await _tap_mouse(receipt_next)
		require(main.unified_reveal_page >= 1 and main.m3_pack_inspector_id == "mossmunk" and not (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty(), "A mouse tap pages a 13-card Founder receipt without acknowledging it or clearing its selected card.")
		var receipt_back := main.find_child("UnifiedPackRevealBack", true, false) as Button
		if receipt_back != null:
			await _tap_touch(receipt_back)
			require(main.screen == "workshop" and not GameManager.profile.get("pending_pack_reveal", {}).is_empty(), "A touch tap leaves the committed Founder receipt recoverable from Workshop.")
			var workshop_settings := main.find_child("WorkshopHotspotSettings", true, false) as Button
			if workshop_settings != null:
				await _tap_touch(workshop_settings)
				require(main.screen == "settings", "A pending receipt ticket leaves the Workshop Settings dial reachable by touch.")
				var settings_cancel := main.find_child("SettingsCancel", true, false) as Button
				if settings_cancel != null:
					await _tap_mouse(settings_cancel)
					require(main.screen == "workshop" and not GameManager.profile.get("pending_pack_reveal", {}).is_empty(), "Closing Settings preserves the pending receipt and returns to its Workshop caller.")
				else:
					require(false, "Settings opened from a pending receipt exposes its native Back target.")
			else:
				require(false, "A pending receipt Workshop still exposes its independent Settings dial target.")
			var resume_pack := main.find_child("WorkshopResumePendingPack", true, false) as Button
			if resume_pack != null:
				await _tap_mouse(resume_pack)
				require(main.screen == "m3_pack" and main.unified_reveal_page >= 1 and main.m3_pack_inspector_id == "mossmunk", "A mouse resume returns to the saved receipt page and inline Mossmunk selection.")
				var resumed_back := main.find_child("UnifiedPackRevealBack", true, false) as Button
				if resumed_back != null:
					await _tap_touch(resumed_back)
					require(main.screen == "workshop", "A selected inline receipt exits to its caller in one Back action.")
				else:
					require(false, "Resumed Founder receipt exposes its physical Back target.")
			else:
				require(false, "Workshop exposes the real saved-pack resume control.")
		else:
			require(false, "Founder receipt exposes a physical Back target.")
	else:
		require(false, "Founder receipt exposes a physical Next target for page two.")
	# Battle Back opens a shielded decision through a physical pointer, then the
	# foreground Back dismisses it without touching the serialized battle state.
	GameManager.profile = TEST_PROFILES.founder_ready("cinderpaw")
	main.battle = BATTLE_STATE.create(["cinderpaw"], ["aquafin"], 61)
	main.battle_mode = "training"
	main.battle_settlement_context = {"mode":"training"}
	main.unified_battle_coordinator.configure(main.battle, 0)
	main.screen = "unified_battle"
	main.render()
	await get_tree().process_frame
	var battle_back := main.find_child("UnifiedBattleBack", true, false) as Button
	if battle_back != null:
		var serialized_before := var_to_str(main.battle.serialize())
		await _tap_mouse(battle_back)
		require(main.battle_back_confirmation and var_to_str(main.battle.serialize()) == serialized_before, "A mouse tap on Battle Back opens the shielded Resume or Concede decision without battle mutation.")
		var modal_back := main.find_child("UnifiedBattleExitBack", true, false) as Button
		if modal_back != null:
			await _tap_touch(modal_back)
			require(not main.battle_back_confirmation and main.screen == "unified_battle", "A touch tap on modal Battle Back dismisses only the foreground decision.")
		else:
			require(false, "Battle exit decision exposes its foreground Back target.")
	else:
		require(false, "Battle exposes its physical Back target.")
	# This fixture deliberately creates every route, including Forge and battle
	# presentation nodes.  Free its owned scene immediately, release shared test
	# cache references, then give the renderer two frames to retire CanvasItems.
	if is_instance_valid(main):
		main.get_parent().remove_child(main)
		main.free()
	CONTROLS.release_cached_resources()
	await get_tree().process_frame
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: M9 real mouse and touch navigation")
	get_tree().quit(0 if failures.is_empty() else 1)
