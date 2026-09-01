extends Node
## Deterministic M3 capture hook. The caller supplies one matrix id and an E:
## output path; this harness never touches a real profile or native ad surface.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const ACCESSIBILITY_RULES := preload("res://scripts/core/accessibility_rules.gd")
const MATRIX_PATH := "res://tests/m3_capture_matrix.json"

func _matrix_ids() -> Array:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MATRIX_PATH))
	if not (parsed is Dictionary): return []
	var ids: Array = []
	for entry in parsed.get("standard", []):
		if entry is Dictionary: ids.append(str(entry.get("id", "")))
	for fixture in parsed.get("synthetic_tall", []):
		if fixture is Dictionary: ids.append(str(fixture.get("id", "")))
	return ids

func _capture_entry(capture_id: String) -> Dictionary:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MATRIX_PATH))
	if not (parsed is Dictionary): return {}
	for entry in parsed.get("standard", []):
		if entry is Dictionary and str(entry.get("id", "")) == capture_id: return entry.duplicate(true)
	for entry in parsed.get("synthetic_tall", []):
		if entry is Dictionary and str(entry.get("id", "")) == capture_id: return entry.duplicate(true)
	return {}

func _requested_size(args: Array, entry: Dictionary) -> Vector2:
	if entry.has("size"):
		var tall: Array = entry.get("size", []) as Array
		return Vector2(int(tall[0]), int(tall[1]))
	if args.size() >= 4:
		return Vector2(int(args[2]), int(args[3]))
	return Vector2(576, 1024)

func _capture_output_path(entry: Dictionary, capture_id: String, requested_size: Vector2, supplied: String) -> String:
	if not supplied.is_empty(): return supplied
	var pattern := str(entry.get("output_pattern", "{id}-{width}x{height}.png"))
	var file_name := pattern.replace("{id}", capture_id).replace("{width}", str(int(requested_size.x))).replace("{height}", str(int(requested_size.y)))
	return "E:/AI Projects/games/3d print battler/build/evidence/m3-captures/".path_join(file_name)

func _apply_fixture(main: Control, profile: Dictionary, entry: Dictionary) -> void:
	# Keep the caller's Dictionary identity while filling persisted accessibility
	# defaults.  GameManager receives this same object, and the fixture mutates
	# only this normalized object, so profile.settings is always safe below.
	var ensured: Dictionary = ACCESSIBILITY_RULES.ensure_fields(profile)
	profile.clear()
	profile.merge(ensured, true)
	var inputs: Dictionary = entry.get("fixture_inputs", {}) if entry.get("fixture_inputs", {}) is Dictionary else {}
	if str(inputs.get("profile", "")) == "fresh_profile":
		var fresh := ACCESSIBILITY_RULES.ensure_fields(RULES.new_profile())
		profile.clear()
		profile.merge(fresh, true)
		GameManager.profile = profile
	profile.revision = int(entry.get("expected_profile_revision", 0))
	if inputs.has("text_scale_bps"): profile.settings.text_scale_bps = int(inputs.get("text_scale_bps", 10000))
	if bool(inputs.get("high_contrast", false)): profile.settings.high_contrast = true
	if bool(inputs.get("reduced_motion", false)): profile.settings.reduced_motion = true
	main.screen = str(entry.get("route", "unified_library"))
	if inputs.has("filter"):
		# The physical folio owns the category rail through this state key; the
		# legacy `unified_archive_filter` is not a presentation input on M3.
		main.set_meta("m3_archive_category", str(inputs.get("filter", "all")))
	if bool(inputs.get("owned", false)): main.m3_archive_owned_only = true
	if bool(inputs.get("printable", false)): main.m3_archive_printable_only = true
	if bool(inputs.get("empty_state", false)):
		profile.owned_cards = {}
		profile.owned_blueprints = {}
		main.m3_archive_owned_only = true
		main.m3_archive_printable_only = true
	if inputs.has("inspector"): main.unified_inspector_id = str(inputs.get("inspector", ""))
	if inputs.has("support_inspector"): main.unified_inspector_id = str(inputs.get("support_inspector", ""))
	if bool(inputs.get("fallback", false)): main.unified_inspector_id = "missing-catalog-id"
	if main.screen == "unified_deck":
		main.m3_deck_edit_slot_id = str(inputs.get("slot", "starter-deck"))
		# An injected draft is capture state; otherwise let the real presenter load
		# the saved fixed slot.  Preloading the id would leave DK-01's legal deck
		# blank and fake the route's actual state.
		if inputs.has("draft"):
			main.unified_deck_draft = (inputs.get("draft", []) as Array).duplicate()
			main.m3_deck_loaded_slot_id = main.m3_deck_edit_slot_id
		else:
			main.m3_deck_loaded_slot_id = ""
		if bool(inputs.get("dirty", false)): main.m3_pending_deck_slot_id = str(inputs.get("pending_slot", "deck-slot-2"))
		if bool(inputs.get("in_flight", false)): main.m3_action_in_flight = true
		if inputs.has("preprints"): main.unified_preprint_draft = (inputs.get("preprints", []) as Array).duplicate()
		if inputs.has("preprint_slots"):
			var requested_slots := int(inputs.get("preprint_slots", 1))
			profile.workshop_upgrades = []
			if requested_slots >= 2: profile.workshop_upgrades.append("preprint_slot_i")
			if requested_slots >= 3: profile.workshop_upgrades.append("preprint_slot_ii")
		if inputs.has("stale_preprint"):
			main.unified_preprint_draft = [str(inputs.get("stale_preprint", ""))]
			main.m3_deck_loaded_slot_id = main.m3_deck_edit_slot_id
		if inputs.has("ownership_overage"):
			var saved := RULES.active_deck(profile)
			saved.append(str(inputs.get("ownership_overage", "")))
			main.unified_deck_draft = saved
			main.m3_deck_loaded_slot_id = main.m3_deck_edit_slot_id
	if main.screen == "unified_market":
		main.unified_market_tab = str(inputs.get("tab", "blueprints"))
		if bool(inputs.get("newcomer", false)): profile.newcomer_started_at = 1700000000
		if bool(inputs.get("wishlist", false)): profile.wishlist = ["cinderpaw"]
		if inputs.has("pity"): profile.pack_pity["basic"] = int(inputs.get("pity", 0))
		if bool(inputs.get("owned_unique", false)): profile.workshop_upgrades.append("preprint_slot_i")
		main.m3_market_snapshot = RULES.market_snapshot(profile, 1700000000).duplicate(true)
		main.m3_market_revision = int(entry.get("expected_profile_revision", 0))
		main.m3_market_day_key = "fixture-2023-11-14"
		main.set_meta("m3_capture_frozen_market", true)
		if bool(inputs.get("confirmation", false)): main.m3_market_confirmation = {"id":"cinderpaw", "price":20, "consequence":"Add the offered blueprint license."}
		if inputs.has("failure"): main.m3_market_confirmation = {"id":"cinderpaw", "price":20, "consequence":"Purchase failed: %s." % str(inputs.get("failure"))}
	if main.screen == "m3_result":
		main.m3_result_state = str(inputs.get("state", "committed"))
		main.m3_result_receipt = inputs.duplicate(true)
	if inputs.has("starter_claimed"):
		profile.starter_pack_rewards = {"entitled":3, "opened":int(inputs.get("starter_claimed", 0))}
		if bool(inputs.get("pending_pack", false)):
			profile.pending_pack_reveal = {"pack_id":"basic", "starter_reward":true, "starter_opened":int(inputs.get("starter_claimed", 0)) + 1, "cards":(inputs.get("cards", ["cinderpaw", "aquafin", "voltwig", "mossmunk", "raw_filament"]) as Array).duplicate(), "receipt":"m3-capture"}
		elif main.screen == "unified_library":
			# The post-Keep receipt is a real native route state rather than a capture
			# annotation.  It makes the authoritative opened/entitled progression
			# visible after the pack machine has released navigation.
			main.toast = "Starter packs filed · %d / 3 opened" % int(inputs.get("starter_claimed", 0))
	if main.screen == "settings":
		main.settings_return_screen = str(inputs.get("caller", "workshop"))
		main.m3_settings_draft = profile.settings.duplicate(true); main.m3_settings_draft_initialized = true
	if inputs.has("recovery"):
		SaveService.recovery_status = str(inputs.get("recovery"))
		# Recovery proofs supply player-meaningful schema facts, not a fixture marker.
		var saved_schema := int(inputs.get("saved_schema_version", 9 if SaveService.recovery_status == "future_schema" else profile.get("schema_version", 0)))
		var supported_schema := int(inputs.get("supported_schema_version", 6))
		GameManager.save_compatibility = {"compatible":false, "state":SaveService.recovery_status, "schema_version":saved_schema, "supported_schema":supported_schema, "message":"Recovery requires a safe player decision."}
		if bool(inputs.get("new_maker_confirmation", false)): main.m3_recovery_new_maker_confirm = true
	var visible_state := ""
	if bool(inputs.get("in_flight", false)): visible_state = "Save request is locked in flight."
	if inputs.has("receipt"): visible_state = "Accepted receipt: %s" % str(inputs.get("receipt"))
	if inputs.has("failure"): visible_state = "Persistence failure: %s" % str(inputs.get("failure"))
	if not visible_state.is_empty(): main.toast = visible_state

func _validate_navigation_fixture(main: Control, capture_id: String) -> bool:
	if capture_id == "M3-NV-01":
		var continue_button := main.find_child("TitleContinue", true, false) as Button
		if main.screen == "title" and is_instance_valid(continue_button) and continue_button.text == "CONTINUE": return true
		push_error("M3-NV-01 must render the real completed-profile TitleContinue control with CONTINUE copy.")
		return false
	if capture_id == "M3-NV-02":
		var expected := ["WorkshopHotspotPrinter", "WorkshopHotspotBattleArena", "WorkshopHotspotCardArchive", "WorkshopHotspotDeck", "WorkshopHotspotSupplies", "WorkshopHotspotSettings"]
		var actual: Array = main.find_children("WorkshopHotspot*", "Button", true, false)
		if main.screen != "workshop" or actual.size() != 6:
			push_error("M3-NV-02 must render exactly six real physical Workshop hotspot Buttons.")
			return false
		for node_name in expected:
			if not (main.find_child(node_name, true, false) is Button):
				push_error("M3-NV-02 is missing canonical Workshop hotspot %s." % node_name)
				return false
	if capture_id == "M3-NV-03":
		return main.screen == "title" and main.find_child("TitleConfirmNewMaker", true, false) is Button and main.find_child("TitleCancelNewMaker", true, false) is Button and main.find_child("TitleContinue", true, false) == null
	if capture_id == "M3-NV-04":
		var fresh_continue := main.find_child("TitleContinue", true, false) as Button
		return main.screen == "title" and is_instance_valid(fresh_continue) and fresh_continue.text == "NEW MAKER" and main.find_child("TitleNewMaker", true, false) == null
	if capture_id == "M3-NV-05":
		return main.screen == "title" and main.find_child("TitleContinue", true, false) is Button and main.find_child("TitleSettings", true, false) is Button
	if capture_id == "M3-AX-03":
		var new_maker := main.find_child("TitleNewMaker", true, false) as Button
		return main.screen == "title" and is_instance_valid(new_maker) and new_maker.has_focus() and new_maker.find_child("WorkshopHotspotTightFocusStrokeTop", true, false) != null
	return true

func _capture_pointer_activate(target: Button) -> bool:
	if not is_instance_valid(target) or target.disabled or not target.is_visible_in_tree(): return false
	var point := target.get_global_rect().get_center()
	var move := InputEventMouseMotion.new(); move.position = point; move.global_position = point; get_viewport().push_input(move)
	await get_tree().process_frame
	if get_viewport().gui_get_hovered_control() != target:
		push_error("Capture target is obscured: %s at %s" % [target.name, point])
		return false
	var down := InputEventMouseButton.new(); down.position = point; down.global_position = point; down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true; get_viewport().push_input(down)
	await get_tree().process_frame
	var up := InputEventMouseButton.new(); up.position = point; up.global_position = point; up.button_index = MOUSE_BUTTON_LEFT; up.pressed = false; get_viewport().push_input(up)
	await get_tree().process_frame
	return true

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := str(args[0]) if not args.is_empty() else "M3-CO-01"
	var entry := _capture_entry(mode)
	if entry.is_empty():
		push_error("Unknown M3 capture id: %s" % mode)
		get_tree().quit(1)
		return
	var requested_size := _requested_size(args, entry)
	if not entry.has("size") and requested_size not in [Vector2(576, 1024), Vector2(720, 1280)]:
		push_error("Standard M3 capture requires 576x1024 or 720x1280: %s" % requested_size)
		get_tree().quit(1)
		return
	var output := _capture_output_path(entry, mode, requested_size, str(args[1]) if args.size() > 1 else "")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var window := get_window()
	window.content_scale_size = Vector2i(requested_size)
	window.size = Vector2i(requested_size)
	await get_tree().process_frame
	SaveService.configure_test_paths("E:/AI Projects/games/3d print battler/build/task-state/m3-runtime-20260831/capture-save")
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	var profile := RULES.new_profile(); profile.forge_coins = 1200; profile = RULES.choose_starter(profile, "cinderpaw").profile; profile = RULES.print_starter(profile).profile
	profile = ACCESSIBILITY_RULES.ensure_fields(profile)
	GameManager.profile = profile
	var main := MAIN.instantiate(); add_child(main)
	_apply_fixture(main, GameManager.profile, entry)
	if mode == "M3-DK-01":
		var saved_cards: Array = []
		for deck_variant in profile.get("decks", []):
			if deck_variant is Dictionary and str((deck_variant as Dictionary).get("id", "")) == str(profile.get("active_deck_id", "starter-deck")):
				saved_cards = ((deck_variant as Dictionary).get("cards", []) as Array).duplicate()
				break
		if saved_cards.size() < 40 or not RULES.deck_reason(profile, saved_cards).is_empty():
			push_error("M3-DK-01 fixture requires the saved active deck to be legal with at least 40 cards.")
			get_tree().quit(1)
			return
	if mode == "M3-TALL-02": main.set_meta("synthetic_admob_overlay_stress", true)
	main.render()
	await get_tree().process_frame
	await get_tree().process_frame
	if mode == "M3-NV-03":
		var new_maker := main.find_child("TitleNewMaker", true, false) as Button
		if not is_instance_valid(new_maker):
			push_error("M3-NV-03 requires the real completed Title New Maker action.")
			get_tree().quit(1)
			return
		if not await _capture_pointer_activate(new_maker):
			get_tree().quit(1)
			return
	if mode == "M3-NV-05":
		var settings := main.find_child("TitleSettings", true, false) as Button
		if not is_instance_valid(settings):
			push_error("M3-NV-05 requires the real Title Settings action.")
			get_tree().quit(1)
			return
		if not await _capture_pointer_activate(settings):
			get_tree().quit(1)
			return
		var back := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
		if not is_instance_valid(back):
			push_error("M3-NV-05 requires the physical Settings return control.")
			get_tree().quit(1)
			return
		if not await _capture_pointer_activate(back):
			get_tree().quit(1)
			return
	if mode == "M3-AX-03":
		var focus_new_maker := main.find_child("TitleNewMaker", true, false) as Button
		if is_instance_valid(focus_new_maker): focus_new_maker.grab_focus()
		await get_tree().process_frame
	if not _validate_navigation_fixture(main, mode):
		get_tree().quit(1)
		return
	# A Forward+ project still receives Godot's dummy texture storage under --headless.
	# Do not dereference that null renderer texture or create substitute evidence.
	if DisplayServer.get_name().to_lower() == "headless":
		push_error("M3 capture requires a real Forward+ display surface; headless dummy rendering cannot produce evidence.")
		get_tree().quit(1)
		return
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("M3 capture requires a rendered viewport; headless dummy rendering cannot produce evidence.")
		get_tree().quit(1)
		return
	if image.get_size() != Vector2i(requested_size):
		push_error("M3 capture size mismatch: expected %s, got %s" % [requested_size, image.get_size()])
		get_tree().quit(1)
		return
	var result := image.save_png(output)
	if result != OK: push_error("Could not save M3 capture: %s" % output)
	else: print("M3_CAPTURE id=%s output=%s" % [mode, output])
	get_tree().quit(0 if result == OK else 1)
