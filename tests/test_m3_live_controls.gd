extends Node
## Live-control proof: all activations below enter through the viewport at the
## rendered centre of a visible Button (or through ui_accept after real focus).
## This deliberately does not call controller methods or emit `pressed`.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value: return
	failures.append(message)
	push_error(message)

func _pointer_activate(target: Button) -> bool:
	if not is_instance_valid(target) or target.disabled or not target.is_visible_in_tree(): return false
	var point := target.get_global_rect().get_center()
	var move := InputEventMouseMotion.new(); move.position = point; move.global_position = point
	get_viewport().push_input(move)
	await get_tree().process_frame
	# Native decoration is mouse-ignore; the hovered control must be the actual
	# topmost target, proving its visual centre is not consumed by another route.
	var hovered := get_viewport().gui_get_hovered_control()
	if hovered != target:
		push_error("Live centre target mismatch expected=%s path=%s rect=%s center=%s actual=%s path=%s" % [target.name, str(target.get_path()), str(target.get_global_rect()), str(point), hovered.name if is_instance_valid(hovered) else "<none>", str(hovered.get_path()) if is_instance_valid(hovered) else "<none>"])
		return false
	var down := InputEventMouseButton.new(); down.position = point; down.global_position = point; down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true
	get_viewport().push_input(down)
	await get_tree().process_frame
	var up := InputEventMouseButton.new(); up.position = point; up.global_position = point; up.button_index = MOUSE_BUTTON_LEFT; up.pressed = false
	get_viewport().push_input(up)
	await get_tree().process_frame
	return true

func _focus_accept(target: Button) -> bool:
	if not is_instance_valid(target) or target.disabled or not target.is_visible_in_tree(): return false
	target.grab_focus()
	await get_tree().process_frame
	if not target.has_focus(): return false
	var down := InputEventAction.new(); down.action = "ui_accept"; down.pressed = true
	get_viewport().push_input(down)
	await get_tree().process_frame
	var up := InputEventAction.new(); up.action = "ui_accept"; up.pressed = false
	get_viewport().push_input(up)
	await get_tree().process_frame
	return true

func _button(main: Control, node_name: String) -> Button:
	return main.find_child(node_name, true, false) as Button

func _ready() -> void:
	var requested_size := Vector2i(720, 1280) if "--720" in OS.get_cmdline_user_args() else Vector2i(576, 1024)
	get_window().content_scale_size = requested_size
	get_window().size = requested_size
	await get_tree().process_frame
	var root := "E:/AI Projects/games/3d print battler/build/task-state/m3-live-controls"
	DirAccess.make_dir_recursive_absolute(root)
	SaveService.configure_test_paths(root)
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	var profile := RULES.new_profile()
	profile.forge_coins = 1200
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	profile = RULES.print_starter(profile).profile
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame

	# Archive browse/filter/detail/Deck handoff: pointer centres are topmost and
	# browsing remains byte-equivalent.
	main.screen = "unified_library"; main.render(); await get_tree().process_frame
	var archive_revision := int(GameManager.profile.get("revision", 0))
	var owned := _button(main, "ArchiveWellOwned")
	require(await _pointer_activate(owned) and main.m3_archive_owned_only and int(GameManager.profile.get("revision", 0)) == archive_revision, "Live pointer activates the topmost Archive Owned well with zero mutation.")
	var clear := _button(main, "ArchiveWellClear")
	require(await _focus_accept(clear) and not main.m3_archive_owned_only and int(GameManager.profile.get("revision", 0)) == archive_revision, "Focused ui_accept clears Archive wells without mutation.")
	var card := _button(main, "ArchiveBlueprintCardCinderpaw")
	require(await _pointer_activate(card) and main.find_child("M3ArchiveDetailApertures", true, false) != null, "Live pointer opens the CO-02 archive leaf from its physical card well.")
	var open_deck := _button(main, "ArchiveDetailOpenDeck")
	require(await _focus_accept(open_deck) and main.screen == "unified_deck" and str(main.get_meta("m3_deck_selected_card_id", "")) == "cinderpaw", "Focused Archive Open Deck keeps the stable inspected id and performs no automatic deck edit.")

	# Deck selection and an unlocked clamp go through physical controls only.
	var selected := _button(main, "DeckOwnedCardCinderpaw")
	require(await _pointer_activate(selected), "Live pointer selects an owned Deck creature card.")
	var clamp := _button(main, "PrePrintClamp1")
	var preprint_before: Array = main.unified_preprint_draft.duplicate()
	require(is_instance_valid(clamp) and not clamp.disabled and await _focus_accept(clamp) and main.unified_preprint_draft.size() == preprint_before.size() + 1 and main.unified_preprint_draft[0] == "cinderpaw", "Focused empty Pre-Print clamp places the selected eligible creature in order without profile mutation.")
	clamp = _button(main, "PrePrintClamp1")
	require(await _pointer_activate(clamp) and main.unified_preprint_draft.is_empty(), "Live pointer removes the populated physical Pre-Print clamp.")

	# Market selector, cubby, confirmation, and Cancel are browse-only physical paths.
	main.screen = "unified_market"; main.render(); await get_tree().process_frame
	var market_revision := int(GameManager.profile.get("revision", 0))
	var packs := _button(main, "MarketTabPacks")
	require(await _pointer_activate(packs) and main.unified_market_tab == "packs" and int(GameManager.profile.get("revision", 0)) == market_revision, "Live Market tab pointer latches exactly one drawer without mutation.")
	var offer := main.find_children("MarketOffer*Slot*", "Button", true, false)[0] as Button
	require(await _pointer_activate(offer), "Live Market offer pointer selects the visible cubby occurrence.")
	var purchase := _button(main, "MarketPurchaseSelected")
	require(await _focus_accept(purchase) and main.find_child("M3MarketConfirm", true, false) != null and int(GameManager.profile.get("revision", 0)) == market_revision, "Focused Purchase opens its in-cabinet confirmation without mutation.")
	var cancel := _button(main, "M3MarketCancelPurchase")
	require(await _pointer_activate(cancel) and main.find_child("M3MarketConfirm", true, false) == null, "Live Market Cancel retracts the physical confirmation receipt.")

	# Settings draft controls use both activation modes and Cancel returns to caller.
	main.screen = "settings"; main.settings_return_screen = "workshop"; main.render(); await get_tree().process_frame
	var settings_revision := int(GameManager.profile.get("revision", 0))
	var text_150 := _button(main, "SettingsText15000")
	require(await _pointer_activate(text_150) and int(main.m3_settings_draft.get("text_scale_bps", 0)) == 15000 and int(GameManager.profile.get("revision", 0)) == settings_revision, "Live Settings text dial changes only the native draft.")
	var contrast := _button(main, "SettingsHighContrast")
	require(await _focus_accept(contrast) and bool(main.m3_settings_draft.get("high_contrast", false)), "Focused Settings accessibility latch updates live draft feedback.")
	var settings_cancel := _button(main, "SettingsCancel")
	require(await _pointer_activate(settings_cancel) and main.screen == "workshop" and int(GameManager.profile.get("revision", 0)) == settings_revision, "Live Settings Cancel returns to Workshop without persisting its local draft.")

	# A committed receipt alone owns Pack. Its card is inspectable and Keep is a
	# real focus activation, never a direct claim call.
	GameManager.profile.starter_pack_rewards = {"entitled":3, "opened":0}
	var seeded_pack := GameManager.claim_next_starter_pack()
	require(bool(seeded_pack.get("ok", false)), "Live Pack setup commits one authoritative starter receipt before control testing.")
	main.screen = "unified_library"; main.m3_pack_inspector_id = ""; main.render(); await get_tree().process_frame
	var pending_cards: Array = (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).get("cards", []) as Array
	var first_pack_id := str(pending_cards[0]) if not pending_cards.is_empty() else ""
	var pack_card := _button(main, "UnifiedPackCardView" + first_pack_id.capitalize())
	require(await _pointer_activate(pack_card) and main.m3_pack_inspector_id == first_pack_id, "Live Pack dock pointer exposes persisted card facts in the receipt surface.")
	var keep := _button(main, "UnifiedPackRevealKeepCards")
	require(await _focus_accept(keep) and int((GameManager.profile.get("starter_pack_rewards", {}) as Dictionary).get("opened", 0)) == 2 and str((GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).get("receipt", "")) == "starter-basic-2", "Focused Keep files the committed receipt exactly through its physical control and chains only the authorized next starter receipt.")
	# Keep has legitimately chained pack two; clear this test-only receipt through the
	# existing authoritative helper before asserting an unrelated Result route.
	GameManager.claim_pending_pack_reveal_result()

	# Result has one physical exit. No duplicate HUD Back control can receive focus.
	main.screen = "m3_result"; main.battle_mode = "daily"; main.m3_result_state = "committed"; main.m3_result_receipt = {"result":"victory", "coins":1, "xp":1}; main.render(); await get_tree().process_frame
	var result_continue := _button(main, "ResultContinue")
	require(main.find_child("ResultReceiptBack", true, false) == null and await _pointer_activate(result_continue) and main.screen == "workshop", "Live Result Continue is the sole physical exit owner.")

	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: M3 live pointer/focus physical control paths")
	get_tree().quit(0 if failures.is_empty() else 1)
