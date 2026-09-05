extends Node

## Export-repair regression: build the Founder multiset through the actual Deck
## Workbench controls, persist it to a second fixed slot, then enter the normal
## offline preflight.  Never replace these input actions with direct callbacks.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const CARD_VIEW := preload("res://scripts/ui/unified_card_view.gd")
const SUPPORT_CARD_VIEW := preload("res://scripts/ui/support_card_view.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	await _run()

func _button(main: Control, node_name: String) -> Button:
	return main.find_child(node_name, true, false) as Button

func _qa_root_isolated() -> bool:
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var active_root := SaveService.profile_path.get_base_dir().replace("\\", "/")
	var valid := active_root.begins_with(evidence_root + "/")
	require(valid, "Deck export input fixture requires the pre-autoload E: QA root before any save transaction.")
	return valid

func _founder_ready() -> Dictionary:
	# Keep this harness independently copyable into an extracted APK project: test
	# helpers are excluded from release content, while these are the real rules
	# transitions that define the completed Founder fixture.
	var profile := RULES.new_profile()
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	profile = RULES.print_starter(profile).profile
	for _receipt in 3:
		var opened := RULES.claim_next_starter_pack(profile)
		if not bool(opened.get("ok", false)):
			return profile
		profile = RULES.clear_pack_reveal(opened.profile).profile
	return profile

func _requested_viewport() -> Vector2i:
	var width := 576
	var height := 1024
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-width="):
			width = maxi(1, int(argument.trim_prefix("--qa-width=")))
		elif argument.begins_with("--qa-height="):
			height = maxi(1, int(argument.trim_prefix("--qa-height=")))
	require(height > width, "Deck export input viewport must remain portrait, got %dx%d." % [width, height])
	return Vector2i(width, height)

func _wait_render_ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

func _tap(target: Control, touch: bool) -> bool:
	if target == null or not target.is_visible_in_tree() or target.disabled:
		return false
	var point := target.get_global_rect().get_center()
	print("DECK_EXPORT_INPUT type=%s node=%s rect=%s expected=rendered_control_transition" % ["touch" if touch else "mouse", target.name, target.get_global_rect()])
	if touch:
		var down := InputEventScreenTouch.new()
		down.position = point
		down.window_id = get_window().get_window_id()
		down.index = 0
		down.pressed = true
		Input.parse_input_event(down)
		await get_tree().process_frame
		var up := InputEventScreenTouch.new()
		up.position = point
		up.window_id = get_window().get_window_id()
		up.index = 0
		up.pressed = false
		Input.parse_input_event(up)
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
	await _wait_render_ready()
	return true

func _multiset(values: Array) -> Dictionary:
	var result := {}
	for value in values:
		var id := str(value)
		result[id] = int(result.get(id, 0)) + 1
	return result

func _saved_deck(profile: Dictionary, deck_id: String) -> Array:
	for deck_variant in profile.get("decks", []):
		if deck_variant is Dictionary and str((deck_variant as Dictionary).get("id", "")) == deck_id:
			return ((deck_variant as Dictionary).get("cards", []) as Array).duplicate()
	return []

func _slot_button(main: Control, slot_name: String) -> Button:
	for candidate in main.find_children("ArchiveDeckSlot*", "Button", true, false):
		var button := candidate as Button
		if button != null and button.accessibility_name.contains(slot_name):
			return button
	return null

func _occurrence_button(main: Control, card_id: String, add: bool) -> Button:
	var tray := main.find_child("M3OwnedCardRack", true, false) as ScrollContainer
	var target := _button(main, ("DeckPlus" if add else "DeckMinus") + card_id.capitalize())
	if tray == null or target == null:
		return null
	tray.ensure_control_visible(target)
	await get_tree().process_frame
	return _button(main, ("DeckPlus" if add else "DeckMinus") + card_id.capitalize())

func _assert_owned_fronts(main: Control, expected_cards: Array) -> void:
	var unique_ids: Dictionary = _multiset(expected_cards)
	var card_back := SUPPORT_CARD_VIEW.card_back_for_test()
	for card_id_variant in unique_ids:
		var card_id := str(card_id_variant)
		var tile := main.find_child("DeckOwnedCard" + card_id.capitalize(), true, false) as Button
		var art := tile.find_child("DeckCardCatalogArt", true, false) as TextureRect if tile != null else null
		require(tile != null and art != null and art.texture != null and art.texture != card_back and CARD_VIEW.art_for_definition(RULES.card(card_id)) != card_back, "Deck exposes the real approved face for owned %s, never the concealed card back." % card_id)

func _capture(main: Control, suffix: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var size := Vector2i(get_window().size)
	var path := SaveService.profile_path.get_base_dir().path_join("deck-export-%s-%dx%d.png" % [suffix, size.x, size.y])
	require(image != null and image.get_size() == size and image.save_png(path) == OK, "Deck export input capture %s is a real %s viewport PNG." % [suffix, size])
	print("DECK_EXPORT_CAPTURE path=%s renderer=%s display=%s dimensions=%s" % [path, RenderingServer.get_current_rendering_method(), DisplayServer.get_name(), size])

func _run() -> void:
	if not _qa_root_isolated():
		get_tree().quit(1)
		return
	if DisplayServer.get_name().to_lower() == "headless":
		require(false, "Deck export input requires a non-headless rendered viewport; headless source checks are not sufficient.")
		get_tree().quit(1)
		return
	var requested_viewport := _requested_viewport()
	get_window().content_scale_size = requested_viewport
	get_window().size = requested_viewport
	await _wait_render_ready()
	get_viewport().notify_mouse_entered()
	var profile: Dictionary = _founder_ready()
	var expected_cards: Array = RULES.active_deck(profile)
	require(expected_cards.size() == 40 and RULES.deck_reason(profile, expected_cards).is_empty(), "Deck export fixture starts from the real completed Founder 40-card multiset.")
	GameManager.profile = profile.duplicate(true)
	GameManager.save_compatibility = {"compatible":true, "state":"ready"}
	var main := MAIN.instantiate()
	main.screen = "workshop"
	add_child(main)
	await _wait_render_ready()
	var deck_hotspot := _button(main, "WorkshopHotspotDeck")
	require(deck_hotspot != null and deck_hotspot.get_global_rect().size.x >= 48.0 and deck_hotspot.get_global_rect().size.y >= 48.0 and await _tap(deck_hotspot, true), "Physical Workshop Deck hotspot enters the live Deck Workbench through parsed touch.")
	require(main.screen == "unified_deck", "Workshop Deck hotspot reaches the Deck Workbench route.")
	if main.screen != "unified_deck":
		await _finish(main)
		return
	var second_slot := _slot_button(main, "Queue Deck")
	require(second_slot != null and await _tap(second_slot, false), "Queue Deck fixed-slot medallion is a rendered input owner.")
	require(main.m3_deck_edit_slot_id == "deck-slot-2" and main.unified_deck_draft.is_empty(), "Second fixed deck slot begins empty without mutating the saved Founder deck.")
	var under_40_save := _button(main, "SaveActiveDeck")
	require(under_40_save != null and under_40_save.disabled, "Deck Save is truthfully disabled below the 40-card minimum.")
	var authority_before_draft := var_to_str(GameManager.profile)
	var first_id := str(expected_cards[0])
	var plus := await _occurrence_button(main, first_id, true)
	require(plus != null and await _tap(plus, true), "Owned %s adds through its rendered plus target." % first_id)
	var minus := await _occurrence_button(main, first_id, false)
	require(minus != null and await _tap(minus, false) and main.unified_deck_draft.is_empty(), "Rendered minus restores the empty local draft without profile mutation.")
	for index in expected_cards.size():
		var card_id := str(expected_cards[index])
		plus = await _occurrence_button(main, card_id, true)
		var added := plus != null and await _tap(plus, index % 2 == 1)
		require(added, "Owned card %d (%s) enters the second-slot draft through its live plus target." % [index + 1, card_id])
		if not added:
			await _finish(main)
			return
	require(var_to_str(GameManager.profile) == authority_before_draft and _multiset(main.unified_deck_draft) == _multiset(expected_cards) and RULES.deck_reason(GameManager.profile, main.unified_deck_draft).is_empty(), "Forty local Deck edits preserve profile authority and reproduce the exact owned Founder multiset.")
	var exhausted_plus := await _occurrence_button(main, first_id, true)
	require(exhausted_plus != null and exhausted_plus.disabled, "Over-owned Add is disabled once the second-slot draft reaches the owned copy limit.")
	_assert_owned_fronts(main, expected_cards)
	await _capture(main, "second-slot-legal")
	var revision_before_save := int(GameManager.profile.get("revision", 0))
	var save := _button(main, "SaveActiveDeck")
	require(save != null and not save.disabled and await _tap(save, true), "Legal second-slot Save and Activate enters through its rendered native control.")
	require(str(GameManager.profile.get("active_deck_id", "")) == "deck-slot-2" and int(GameManager.profile.get("revision", 0)) == revision_before_save + 1 and _multiset(_saved_deck(GameManager.profile, "deck-slot-2")) == _multiset(expected_cards), "Accepted Deck Save persists the exact second-slot multiset exactly once and activates it.")
	var loaded := SaveService.load_profile()
	require(not loaded.is_empty(), "Deck Save produces a reloadable isolated profile snapshot.")
	GameManager._initialize_loaded_profile(loaded)
	require(str(GameManager.profile.get("active_deck_id", "")) == "deck-slot-2" and _multiset(_saved_deck(GameManager.profile, "deck-slot-2")) == _multiset(expected_cards) and RULES.deck_reason(GameManager.profile, RULES.active_deck(GameManager.profile)).is_empty(), "Reload preserves the saved active second slot and its legal exact 40-card multiset.")
	main.screen = "workshop"
	main.render()
	await _wait_render_ready()
	var battle_hotspot := _button(main, "WorkshopHotspotBattleArena")
	require(battle_hotspot != null and await _tap(battle_hotspot, false) and main.screen == "proving", "Physical Workshop Battle Dais reaches the challenge board through parsed input.")
	var preflight := _button(main, "ChallengeContinuePreflight")
	require(preflight != null and await _tap(preflight, true), "Challenge board Review Preflight enters through its rendered control.")
	var begin := _button(main, "ChallengeBeginBattle")
	require(begin != null and not begin.disabled and await _tap(begin, false), "Legal active second slot enables and enters the normal bot Battle Begin control.")
	await _wait_render_ready()
	var player: Dictionary = main.battle.player(0) if main.battle != null else {}
	var battle_cards: Array = []
	battle_cards.append_array(player.get("hand", []) as Array)
	battle_cards.append_array(player.get("deck", []) as Array)
	require(main.screen == "unified_battle" and main.battle != null and battle_cards.size() == 40 and _multiset(battle_cards) == _multiset(expected_cards), "Bot battle opening hand plus remaining player deck retains the exact active second-slot 40-card multiset.")
	await _capture(main, "bot-opening-hand")
	await _finish(main)

func _finish(main: Control) -> void:
	if is_instance_valid(main):
		main.get_parent().remove_child(main)
		main.free()
	await get_tree().process_frame
	if failures.is_empty():
		print("PASS: deck export rendered input, save/reload, and bot opening multiset")
	get_tree().quit(0 if failures.is_empty() else 1)
