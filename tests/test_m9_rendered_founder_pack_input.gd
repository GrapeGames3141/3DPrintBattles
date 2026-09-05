extends Node

## One production-base, rendered interaction proof.  Every player decision below
## enters the active Control tree through Input.parse_input_event(); fixture setup
## may choose a legal profile or route, but never calls an asserted action handler.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const TEST_PROFILES := preload("res://tests/m9_test_profile_factory.gd")

var failures: Array[String] = []
var completed_starters: Array[String] = []
var completed_paid_packs: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	await _run()

func _button(main: Control, node_name: String) -> Button:
	return main.find_child(node_name, true, false) as Button

func _page_card(main: Control, index: int) -> Button:
	var dock := main.find_child("PackReceiptDock%02d" % (index + 1), true, false) as Control
	if dock == null or dock.get_child_count() != 1:
		return null
	return dock.get_child(0) as Button

func _input_pointer(target: Control, touch := false) -> bool:
	if target == null or not target.is_visible_in_tree() or target.disabled:
		return false
	var point := target.get_global_rect().get_center()
	print("M9_INPUT type=%s node=%s rect=%s expected=live_control_transition" % ["touch" if touch else "mouse", target.name, target.get_global_rect()])
	if touch:
		var touch_down := InputEventScreenTouch.new()
		touch_down.position = point
		touch_down.window_id = get_window().get_window_id()
		touch_down.index = 0
		touch_down.pressed = true
		Input.parse_input_event(touch_down)
		await get_tree().process_frame
		var touch_up := InputEventScreenTouch.new()
		touch_up.position = point
		touch_up.window_id = get_window().get_window_id()
		touch_up.index = 0
		touch_up.pressed = false
		Input.parse_input_event(touch_up)
	else:
		var move := InputEventMouseMotion.new()
		move.position = point
		move.global_position = point
		move.window_id = get_window().get_window_id()
		Input.parse_input_event(move)
		await get_tree().process_frame
		var down := InputEventMouseButton.new()
		down.position = point
		down.global_position = point
		down.window_id = get_window().get_window_id()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		Input.parse_input_event(down)
		await get_tree().process_frame
		var up := InputEventMouseButton.new()
		up.position = point
		up.global_position = point
		up.window_id = get_window().get_window_id()
		up.button_index = MOUSE_BUTTON_LEFT
		up.pressed = false
		Input.parse_input_event(up)
	await get_tree().process_frame
	return true

func _input_accept(target: Button) -> bool:
	if target == null or target.disabled or not target.is_visible_in_tree():
		return false
	target.grab_focus()
	await get_tree().process_frame
	if get_viewport().gui_get_focus_owner() != target:
		return false
	print("M9_INPUT type=keyboard node=%s rect=%s expected=focused_live_control_transition" % [target.name, target.get_global_rect()])
	var down := InputEventKey.new()
	down.keycode = KEY_ENTER
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up := InputEventKey.new()
	up.keycode = KEY_ENTER
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame
	return true

func _assert_qa_root() -> bool:
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var active_root := SaveService.profile_path.get_base_dir().replace("\\", "/")
	var valid := active_root.begins_with(evidence_root + "/")
	require(valid, "Rendered M9 input suite requires the pre-autoload E: QA root before profile access.")
	return valid

func _wait_render_ready() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	await get_tree().process_frame

func _capture_forward_plus_proof() -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var expected := Vector2i(576, 1024)
	require(image != null and image.get_size() == expected, "Rendered M9 input proof receives one real 576x1024 Forward+ viewport frame.")
	if image == null:
		return
	var output := SaveService.profile_path.get_base_dir().path_join("forward-plus-input-proof-576x1024.png")
	var saved := image.save_png(output)
	require(saved == OK, "Rendered M9 input proof writes its captured Forward+ frame under the isolated QA root.")
	print("M9_RENDER display=%s renderer=%s dimensions=%s png=%s" % [DisplayServer.get_name(), RenderingServer.get_current_rendering_method(), image.get_size(), output])

func _inspect_all_pages(main: Control, label: String) -> bool:
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {})
	var expected: Array = (pending.get("cards", []) as Array).duplicate()
	expected.append_array((pending.get("bonus_cards", []) as Array).duplicate())
	var receipt := str(pending.get("receipt", ""))
	var authority_before := var_to_str(GameManager.profile)
	var revision_before := int(GameManager.profile.get("revision", 0))
	var expected_pages := maxi(1, ceili(expected.size() / 5.0))
	var visited := 0
	for page in expected_pages:
		require(main.unified_reveal_page == page, "%s opens expected receipt page %d/%d." % [label, page + 1, expected_pages])
		if main.unified_reveal_page != page:
			return false
		var page_count := mini(5, expected.size() - page * 5)
		for index in page_count:
			var expected_id := str(expected[page * 5 + index])
			var card := _page_card(main, index)
			require(card != null and card.is_visible_in_tree() and card.name == "UnifiedPackCardView" + expected_id.capitalize(), "%s exposes exact card %d (%s) in ordered dock %d on page %d." % [label, visited + 1, expected_id, index + 1, page + 1])
			if card != null:
				require(await _input_pointer(card, (visited % 2) == 1), "%s card %d enters through its rendered pointer target." % [label, visited + 1])
				require(main.m3_pack_inspector_id == expected_id and var_to_str(GameManager.profile) == authority_before and int(GameManager.profile.get("revision", 0)) == revision_before and str((GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).get("receipt", "")) == receipt, "%s card %d preserves authority while updating only selected receipt facts." % [label, visited + 1])
				if main.m3_pack_inspector_id != expected_id or var_to_str(GameManager.profile) != authority_before:
					return false
			else:
				return false
			visited += 1
		var next := _button(main, "UnifiedPackRevealNext")
		if page + 1 < expected_pages:
			require(next != null and not next.disabled and await _input_pointer(next, page % 2 == 0), "%s page %d Next is an active real control." % [label, page + 1])
			require(main.unified_reveal_page == page + 1, "%s page control advances exactly one receipt page." % label)
			if main.unified_reveal_page != page + 1:
				return false
		else:
			require((next == null or next.disabled) and visited == expected.size(), "%s exposes its final page with every expected card visited and no active Next." % label)
			return (next == null or next.disabled) and visited == expected.size()
	return false

func _keep_founder_receipt(main: Control, starter_id: String, receipt_index: int, expected_cards: int) -> void:
	await _inspect_all_pages(main, "%s Founder %d" % [starter_id, receipt_index])
	var keep := _button(main, "UnifiedPackRevealKeepCards")
	require(keep != null and keep.custom_minimum_size.y >= 56.0, "%s Founder %d exposes its 56px Keep control." % [starter_id, receipt_index])
	# Keep is keyboard-owned once as a distinct focus proof; the remaining keeps
	# use alternating real pointer input to exercise the physical plate stack.
	var kept := await _input_accept(keep) if starter_id == "voltwig" and receipt_index == 3 else await _input_pointer(keep, receipt_index % 2 == 0)
	require(kept, "%s Founder %d Keep enters through live input." % [starter_id, receipt_index])
	var rewards: Dictionary = GameManager.profile.get("starter_pack_rewards", {})
	require((GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty() and int(rewards.get("kept", 0)) == receipt_index and (GameManager.profile.get("decks", []) as Array)[0].get("cards", []).size() == expected_cards, "%s Founder %d Keep preserves the exact legal deck count %d." % [starter_id, receipt_index, expected_cards])

func _run_founder_starter(main: Control, starter_id: String, starter_index: int) -> void:
	GameManager.profile = RULES.new_profile()
	main.screen = "onboarding"
	main.starter_page = 0
	main.render()
	await get_tree().process_frame
	for _index in starter_index:
		var next := _button(main, "StarterNext")
		require(next != null and await _input_pointer(next, true), "%s starter carousel advances through its real Next target." % starter_id)
	var confirm := _button(main, "StarterConfirmFocused")
	var confirmed := await _input_accept(confirm) if starter_id == "voltwig" else await _input_pointer(confirm, starter_index == 1)
	require(confirmed and main.screen == "printer" and str(GameManager.profile.get("onboarding", {}).get("starter_id", "")) == starter_id, "%s uses its visible confirmation control to open the free physical Forge." % starter_id)
	var selected_deck: Array = (GameManager.profile.get("decks", []) as Array)[0].get("cards", [])
	require(selected_deck.size() == 1 and selected_deck[0] == starter_id, "%s visible choice owns exactly its one-card provisional deck before printing." % starter_id)
	var start := _button(main, "BeginCreaturePrint")
	require(start != null and await _input_pointer(start, starter_index == 2), "%s Start enters the legal first-print sequence through its physical Forge control." % starter_id)
	var skip := _button(main, "SkipPrinterAnimation")
	require(skip != null and await _input_pointer(skip, starter_index != 1), "%s first Skip reaches RAW_COMPLETE and commits once." % starter_id)
	await get_tree().process_frame
	require(main.printer_sequence != null and main.printer_sequence.resolved and int(GameManager.profile.get("owned_cards", {}).get(starter_id, 0)) == 1 and ((GameManager.profile.get("decks", []) as Array)[0].get("cards", []) as Array).size() == 1, "%s first-print commit is resolved exactly once with its one-card deck unchanged before presentation Skip completes." % starter_id)
	skip = _button(main, "SkipPrinterAnimation")
	require(skip != null and await _input_pointer(skip, starter_index == 1), "%s second Skip settles only the resolved visual sequence." % starter_id)
	var open_first := _button(main, "ForgeTerminalPrimary")
	require(open_first != null and await _input_pointer(open_first, true), "%s terminal opens Founder receipt 1 through its visible Forge action." % starter_id)
	require(main.screen == "m3_pack", "%s terminal routes to the committed Founder receipt." % starter_id)
	await _keep_founder_receipt(main, starter_id, 1, 14)
	for receipt_index in [2, 3]:
		var open_next := _button(main, "WorkshopOpenFounderPack")
		require(open_next != null and await _input_pointer(open_next, receipt_index == 2), "%s Workshop opens Founder receipt %d from its actual control." % [starter_id, receipt_index])
		require(main.screen == "m3_pack", "%s Founder receipt %d opens as a live saved receipt." % [starter_id, receipt_index])
		await _keep_founder_receipt(main, starter_id, receipt_index, 1 + receipt_index * 13)
	var starter_deck: Array = (GameManager.profile.get("decks", []) as Array)[0].get("cards", [])
	require(starter_deck.size() == 40 and starter_deck.count(starter_id) == 12 and starter_deck.count("mossmunk") == 8 and RULES.deck_reason(GameManager.profile, starter_deck).is_empty(), "%s completes the visible three-receipt Founder path at the exact legal 40-card deck." % starter_id)

func _select_pack(main: Control, pack_id: String) -> Button:
	for candidate in main.find_children("MarketOffer%sSlot*" % pack_id.capitalize(), "Button", true, false):
		var tile := candidate as Button
		if tile != null and tile.is_visible_in_tree():
			return tile
	return null

func _run_paid_pack(main: Control, pack_id: String) -> bool:
	main.screen = "unified_market"
	main.unified_market_tab = "packs"
	main.m3_market_snapshot.clear()
	main.render()
	await get_tree().process_frame
	var offer := _select_pack(main, pack_id)
	var selected := offer != null and await _input_pointer(offer, pack_id.length() % 2 == 0)
	require(selected and str(main.get_meta("m3_market_selected_offer_key", "")).begins_with(pack_id + ":"), "%s Pack is selected through its real frozen Market cubby." % pack_id.capitalize())
	if not selected or not str(main.get_meta("m3_market_selected_offer_key", "")).begins_with(pack_id + ":"):
		return false
	var purchase := _button(main, "MarketPurchaseSelected")
	var purchase_opened := purchase != null and await _input_pointer(purchase, false)
	require(purchase_opened and not main.m3_market_confirmation.is_empty() and main.find_child("M3MarketConfirm", true, false) != null, "%s Pack Purchase reaches its visible confirmation through the rendered hit target." % pack_id.capitalize())
	if not purchase_opened or main.m3_market_confirmation.is_empty():
		return false
	var displayed_price := int(main.m3_market_confirmation.get("price", -1))
	require(displayed_price > 0 and main.find_child("M3MarketConfirm", true, false) != null, "%s Pack exposes a positive frozen displayed debit before confirmation." % pack_id.capitalize())
	if displayed_price <= 0:
		return false
	var coins_before := int(GameManager.profile.get("forge_coins", 0))
	var confirm := _button(main, "M3MarketConfirmPurchase")
	require(confirm != null and await _input_pointer(confirm, true), "%s Pack confirmation enters through its physical Confirm control." % pack_id.capitalize())
	await get_tree().process_frame
	await get_tree().process_frame
	var pending: Dictionary = GameManager.profile.get("pending_pack_reveal", {})
	require(main.screen == "m3_pack" and str(pending.get("pack_id", "")) == pack_id and int(pending.get("effective_price", -1)) == displayed_price and int(GameManager.profile.get("forge_coins", 0)) == coins_before - displayed_price, "%s Pack records exactly the frozen displayed debit before revealing its receipt." % pack_id.capitalize())
	if main.screen != "m3_pack" or str(pending.get("pack_id", "")) != pack_id:
		return false
	if pack_id == "basic":
		require((pending.get("bonus_cards", []) as Array).size() == 5, "Basic paid-pack pity fixture reaches its visible five-card bonus page.")
	if not await _inspect_all_pages(main, "%s paid Pack" % pack_id.capitalize()):
		return false
	var saved_receipt := str((GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).get("receipt", ""))
	var saved_page := int(main.unified_reveal_page)
	var saved_selection := str(main.m3_pack_inspector_id)
	var receipt_back := _button(main, "UnifiedPackRevealBack")
	require(receipt_back != null and await _input_pointer(receipt_back, true) and main.screen == "unified_market" and not (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty(), "%s Pack Back preserves the saved receipt at its actual Market caller." % pack_id.capitalize())
	if main.screen != "unified_market":
		return false
	var market_back := _button(main, "UnifiedFoundryWorkshopReturn")
	require(market_back != null and await _input_pointer(market_back, false) and main.screen == "workshop", "%s Pack Market Back reaches Workshop through the route-owned physical control." % pack_id.capitalize())
	if main.screen != "workshop":
		return false
	# The Market-owned Back rebuilds the Workshop plate. Let that replacement settle
	# before resolving the newly attached Resume control by its live geometry.
	await _wait_render_ready()
	var resume := _button(main, "WorkshopResumePendingPack")
	var resumed: bool = await _input_pointer(resume, pack_id != "forge")
	require(resumed and main.screen == "m3_pack" and str((GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).get("receipt", "")) == saved_receipt and main.unified_reveal_page == saved_page and main.m3_pack_inspector_id == saved_selection, "%s Pack Workshop Resume reopens the same receipt/page/selection through live input (screen=%s pending=%s)." % [pack_id.capitalize(), main.screen, str((GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).get("receipt", ""))])
	if not resumed or main.screen != "m3_pack":
		return false
	var keep := _button(main, "UnifiedPackRevealKeepCards")
	var owned_before := var_to_str(GameManager.profile.get("owned_cards", {}))
	var deck_before := var_to_str(GameManager.profile.get("decks", []))
	var keep_coins := int(GameManager.profile.get("forge_coins", 0))
	require(keep != null and await _input_pointer(keep, false), "%s Pack Keep acknowledges the opened paid receipt through its physical control." % pack_id.capitalize())
	require((GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty() and int(GameManager.profile.get("forge_coins", 0)) == keep_coins and var_to_str(GameManager.profile.get("owned_cards", {})) == owned_before and var_to_str(GameManager.profile.get("decks", [])) == deck_before, "%s Pack Keep clears only its acknowledged pending receipt without changing coins, cards, or deck." % pack_id.capitalize())
	return (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty()

func _run() -> void:
	if not _assert_qa_root():
		get_tree().quit(1)
		return
	if DisplayServer.get_name().to_lower() == "headless" or RenderingServer.get_current_rendering_method() != "forward_plus":
		require(false, "Rendered M9 input suite requires a non-headless Forward+ display surface; no synthetic headless input proof is accepted.")
		get_tree().quit(1)
		return
	get_window().content_scale_size = Vector2i(576, 1024)
	get_window().size = Vector2i(576, 1024)
	await get_tree().process_frame
	get_viewport().notify_mouse_entered()
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	# The negative reproduces the old full-surface STOP-owner failure first; after
	# removal the same exact Input.parse path must reach the actual Market Back.
	GameManager.profile = RULES.new_profile()
	GameManager.profile.forge_coins = 50000
	GameManager.profile.newcomer_started_at = int(Time.get_unix_time_from_system()) - 8 * 86400
	main.screen = "unified_market"
	main.render()
	await _wait_render_ready()
	await _capture_forward_plus_proof()
	var stop_probe := _button(main, "UnifiedFoundryWorkshopReturn")
	var blocker := Control.new()
	blocker.name = "RenderedInputStopOverlay"
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_child(blocker)
	require(stop_probe != null and await _input_pointer(stop_probe, false) and main.screen == "unified_market", "STOP-overlay negative blocks the actual Market Back coordinate before positive proof.")
	blocker.queue_free()
	await get_tree().process_frame
	require(stop_probe != null and await _input_pointer(stop_probe, true) and main.screen == "workshop", "The same Market Back coordinate reaches its live owner once the STOP overlay is absent.")
	for starter_index in 3:
		var starter_id := str(RULES.STARTER_IDS[starter_index])
		await _run_founder_starter(main, starter_id, starter_index)
		var completed_deck: Array = (GameManager.profile.get("decks", []) as Array)[0].get("cards", [])
		if completed_deck.size() == 40 and RULES.deck_reason(GameManager.profile, completed_deck).is_empty():
			completed_starters.append(starter_id)
	require(completed_starters == ["cinderpaw", "aquafin", "voltwig"], "All three starters complete the rendered Founder flow before paid-pack proof begins.")
	var paid_profile: Dictionary = TEST_PROFILES.founder_ready("cinderpaw")
	paid_profile.forge_coins = 50000
	paid_profile.newcomer_started_at = int(Time.get_unix_time_from_system()) - 8 * 86400
	paid_profile.pack_pity["basic"] = 50
	GameManager.profile = paid_profile
	for pack_id in ["basic", "forge", "arcane", "primordial", "champion"]:
		if await _run_paid_pack(main, pack_id):
			completed_paid_packs.append(pack_id)
		else:
			break
	require(completed_paid_packs == ["basic", "forge", "arcane", "primordial", "champion"], "All five paid packs complete frozen-price confirmation, receipt browsing, Back/Resume, and Keep through rendered input.")
	if is_instance_valid(main):
		main.get_parent().remove_child(main)
		main.free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: M9 rendered Founder and paid-pack Input.parse flow")
	get_tree().quit(0 if failures.is_empty() else 1)
