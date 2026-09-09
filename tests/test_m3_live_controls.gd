extends Node
## Live-control proof: all activations below enter through the viewport at the
## rendered centre of a visible Button (or through ui_accept after real focus).
## This deliberately does not call controller methods or emit `pressed`.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const M9_TEST_PROFILES := preload("res://tests/m9_test_profile_factory.gd")
const BATTLE_STATE := preload("res://scripts/battle/unified_battle_state.gd")

var failures: Array[String] = []
var configured_root := ""

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

func _pointer_inject(target: Control) -> void:
	# Deliberately dispatch even for a disabled target. This is the stale-input
	# proof that _pointer_activate cannot provide because it correctly declines
	# disabled controls before touching the viewport.
	if not is_instance_valid(target): return
	var point := target.get_global_rect().get_center()
	var move := InputEventMouseMotion.new(); move.position = point; move.global_position = point
	get_viewport().push_input(move)
	await get_tree().process_frame
	var down := InputEventMouseButton.new(); down.position = point; down.global_position = point; down.button_index = MOUSE_BUTTON_LEFT; down.pressed = true
	get_viewport().push_input(down)
	await get_tree().process_frame
	var up := InputEventMouseButton.new(); up.position = point; up.global_position = point; up.button_index = MOUSE_BUTTON_LEFT; up.pressed = false
	get_viewport().push_input(up)
	await get_tree().process_frame

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

func _deck_preprint_hc_ink_fits(ink: Label, plate: NinePatchRect) -> bool:
	if ink == null or plate == null or ink.text != "SAVE\nPRE-\nPRINTS": return false
	var font := ink.get_theme_font("font")
	var font_size := ink.get_theme_font_size("font_size")
	if font == null or font_size < 18 or not plate.get_global_rect().encloses(ink.get_global_rect()): return false
	var lines: Array = ink.text.split("\n")
	var spacing := ink.get_theme_constant("line_spacing")
	var glyph_stack := font.get_height(font_size) * lines.size() + spacing * (lines.size() - 1)
	for line in lines:
		if font.get_string_size(str(line), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > ink.get_global_rect().size.x: return false
	return lines.size() == 3 and glyph_stack <= ink.get_global_rect().size.y

func _ready() -> void:
	var requested_size := Vector2i(720, 1280) if "--720" in OS.get_cmdline_user_args() else Vector2i(576, 1024)
	get_window().content_scale_size = requested_size
	get_window().size = requested_size
	await get_tree().process_frame
	configured_root = SaveService.profile_path.get_base_dir()
	if not configured_root.replace("\\", "/").contains("/build/evidence/"):
		require(false, "M3 live-control test requires pre-autoload E: build/evidence QA storage; refusing fixture writes outside it.")
		get_tree().quit(1)
		return
	var root := configured_root.path_join("m3-live-controls")
	DirAccess.make_dir_recursive_absolute(root)
	SaveService.configure_test_paths(root)
	GameManager.save_compatibility = {"compatible":true, "state":"ready", "message":""}
	var profile := M9_TEST_PROFILES.founder_ready()
	profile.forge_coins = 1200
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame

	# Archive browse/filter/detail/Deck handoff: pointer centres are topmost and
	# browsing remains byte-equivalent.
	main.screen = "unified_library"; main.render(); await get_tree().process_frame
	var archive_revision := int(GameManager.profile.get("revision", 0))
	var archive_next := _button(main, "ArchivePageNext")
	var archive_page := int(main.get_meta("m3_archive_page", 0))
	require(is_instance_valid(archive_next) and not archive_next.disabled and await _pointer_activate(archive_next) and int(main.get_meta("m3_archive_page", 0)) == archive_page + 1 and int(GameManager.profile.get("revision", 0)) == archive_revision, "Live Archive pager next owns its right rocker zone and changes only the visible page.")
	var archive_previous := _button(main, "ArchivePagePrevious")
	require(is_instance_valid(archive_previous) and await _focus_accept(archive_previous) and int(main.get_meta("m3_archive_page", 0)) == archive_page and int(GameManager.profile.get("revision", 0)) == archive_revision, "Focused Archive pager previous owns its separate left rocker zone without profile mutation.")
	var owned := _button(main, "ArchiveWellOwned")
	require(await _pointer_activate(owned) and main.m3_archive_owned_only and int(GameManager.profile.get("revision", 0)) == archive_revision, "Live pointer activates the topmost Archive Owned well with zero mutation.")
	var clear := _button(main, "ArchiveWellClear")
	require(await _focus_accept(clear) and not main.m3_archive_owned_only and int(GameManager.profile.get("revision", 0)) == archive_revision, "Focused ui_accept clears Archive wells without mutation.")
	GameManager.profile.settings = {"text_scale_bps":15000,"high_contrast":true,"reduced_motion":false}
	main.render(); await get_tree().process_frame
	archive_next = _button(main, "ArchivePageNext")
	var archive_back := _button(main, "ArchiveArchBack")
	var archive_owned := _button(main, "ArchiveWellOwned")
	require(is_instance_valid(archive_next) and is_instance_valid(archive_back) and is_instance_valid(archive_owned) and archive_next.get_theme_font_size("font_size") >= 18 and archive_back.get_theme_font_size("font_size") >= 18 and archive_owned.get_theme_font_size("font_size") >= 18, "Archive navigation, Back, and filter controls use the native 18px text150 font rather than a fixed 12px label.")
	GameManager.profile.settings = {"text_scale_bps":10000,"high_contrast":false,"reduced_motion":false}
	main.render(); await get_tree().process_frame
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
	clamp = _button(main, "PrePrintClamp1")
	require(await _focus_accept(clamp) and main.unified_preprint_draft == ["cinderpaw"], "Focused Pre-Print clamp restores one non-empty Cinderpaw draft before its independent save proof.")
	var deck_before_preprint_save: Array = (GameManager.profile.get("decks", []) as Array).duplicate(true)
	var preprint_revision := int(GameManager.profile.get("revision", 0))
	var save_preprint := _button(main, "SavePrePrintLoadout")
	var preprint_plate := main.find_child("SavePrePrintLoadoutPlate", true, false) as NinePatchRect
	var preprint_ink := main.find_child("SavePrePrintLoadoutInk", true, false) as Label
	var save_deck_control := _button(main, "SaveActiveDeck")
	require(preprint_plate != null and preprint_ink != null and preprint_plate.get_global_rect().encloses(preprint_ink.get_global_rect()) and is_instance_valid(save_deck_control) and is_instance_valid(save_preprint) and not save_deck_control.get_global_rect().intersects(save_preprint.get_global_rect()) and save_deck_control.custom_minimum_size.y >= 56.0 and save_preprint.custom_minimum_size.y >= 56.0, "Deck Save and Save Pre-Prints retain separate 56px physical owners, with full native ink inside the mounted parchment face.")
	GameManager.profile.settings = {"text_scale_bps":15000,"high_contrast":true,"reduced_motion":false}
	main.render(); await get_tree().process_frame
	preprint_ink = main.find_child("SavePrePrintLoadoutInk", true, false) as Label
	preprint_plate = main.find_child("SavePrePrintLoadoutPlate", true, false) as NinePatchRect
	require(_deck_preprint_hc_ink_fits(preprint_ink, preprint_plate), "Deck Save Pre-Prints keeps all three measured readable 18px HC lines inside the widened native parchment ink seat.")
	GameManager.profile.settings = {"text_scale_bps":10000,"high_contrast":false,"reduced_motion":false}
	main.render(); await get_tree().process_frame
	save_preprint = _button(main, "SavePrePrintLoadout")
	require(await _focus_accept(save_preprint) and GameManager.profile.get("preprints", []) == ["cinderpaw"] and main.m3_saved_preprint_draft == ["cinderpaw"] and GameManager.profile.get("decks", []) == deck_before_preprint_save and int(GameManager.profile.get("revision", 0)) > preprint_revision, "Focused Save Pre-Prints uses its independent right key to persist a non-empty clamp loadout without changing the saved deck.")
	var deck_revision := int(GameManager.profile.get("revision", 0))
	var save_deck := _button(main, "SaveActiveDeck")
	require(await _pointer_activate(save_deck) and GameManager.profile.get("preprints", []) == ["cinderpaw"] and int(GameManager.profile.get("revision", 0)) > deck_revision, "Live Save Deck uses its separate left physical key and preserves the already-saved Pre-Print loadout.")

	# Market selector, cubby, confirmation, and Cancel are browse-only physical paths.
	main.screen = "unified_market"; main.render(); await get_tree().process_frame
	var market_revision := int(GameManager.profile.get("revision", 0))
	var market_caption_rail := main.find_child("MarketCategoryCaptionRail", true, false) as NinePatchRect
	var market_caption_ink := main.find_child("MarketCategoryCaptionInk", true, false) as Control
	var market_caption_ok := market_caption_rail != null and market_caption_ink != null
	for node_name in ["Blueprints", "Cards", "Packs", "Upgrades", "Cosmetics"]:
		var caption := main.find_child("MarketTabCaption" + node_name.capitalize(), true, false) as Label
		var tab_control := _button(main, "MarketTab" + node_name.capitalize())
		var caption_rect := caption.get_global_rect() if caption != null else Rect2()
		var ink_rect := market_caption_ink.get_global_rect() if market_caption_ink != null else Rect2()
		var caption_inside := ink_rect.position.x <= caption_rect.position.x + 0.1 and ink_rect.position.y <= caption_rect.position.y + 0.1 and ink_rect.end.x + 0.1 >= caption_rect.end.x and ink_rect.end.y + 0.1 >= caption_rect.end.y
		market_caption_ok = market_caption_ok and caption != null and tab_control != null and caption_inside and tab_control.get_global_rect().intersects(caption_rect) and caption.mouse_filter == Control.MOUSE_FILTER_IGNORE and caption.get_theme_font_size("font_size") >= 12
	require(market_caption_ok, "Market category ink is seated on its mounted caption rail and each original selector remains its sole overlapping hit owner.")
	var packs := _button(main, "MarketTabPacks")
	require(await _pointer_activate(packs) and main.unified_market_tab == "packs" and (main.find_child("MarketTabInkPacksUnderline", true, false) as ColorRect).color.a > 0.0 and int(GameManager.profile.get("revision", 0)) == market_revision, "Live Market tab pointer latches exactly one drawer and its passive caption underline without mutation.")
	var offer := main.find_children("MarketOffer*Slot*", "Button", true, false)[0] as Button
	require(await _pointer_activate(offer), "Live Market offer pointer selects the visible cubby occurrence.")
	var purchase := _button(main, "MarketPurchaseSelected")
	require(await _focus_accept(purchase) and main.find_child("M3MarketConfirm", true, false) != null and int(GameManager.profile.get("revision", 0)) == market_revision, "Focused Purchase opens its in-cabinet confirmation without mutation.")
	var cancel := _button(main, "M3MarketCancelPurchase")
	require(await _pointer_activate(cancel) and main.find_child("M3MarketConfirm", true, false) == null, "Live Market Cancel retracts the physical confirmation receipt.")
	GameManager.profile.settings = {"text_scale_bps":15000,"high_contrast":true,"reduced_motion":false}
	main.render(); await get_tree().process_frame
	var market_hc_ink := main.find_child("MarketCategoryCaptionInk", true, false) as Control
	var market_hc_font_ok := market_hc_ink != null
	for node_name in ["Blueprints", "Cards", "Packs", "Upgrades", "Cosmetics"]:
		var caption := main.find_child("MarketTabCaption" + node_name.capitalize(), true, false) as Label
		var caption_rect := caption.get_global_rect() if caption != null else Rect2()
		var ink_rect := market_hc_ink.get_global_rect() if market_hc_ink != null else Rect2()
		var font := caption.get_theme_font("font") if caption != null else null
		var font_size := caption.get_theme_font_size("font_size") if caption != null else 0
		var full_width := font.get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x if font != null else INF
		var caption_inside := ink_rect.position.x <= caption_rect.position.x + 0.1 and ink_rect.position.y <= caption_rect.position.y + 0.1 and ink_rect.end.x + 0.1 >= caption_rect.end.x and ink_rect.end.y + 0.1 >= caption_rect.end.y
		market_hc_font_ok = market_hc_font_ok and caption != null and font_size >= 18 and absf(caption.get_global_transform().get_scale().x - 1.0) <= 0.01 and caption_inside and full_width <= caption_rect.size.x - 4.0
	require(market_hc_font_ok, "Market category copy remains unscaled readable 18px text150 ink with two-pixel side padding in every physical rail column, never inherited from the decorative quarter-scale NinePatch.")
	GameManager.profile.settings = {"text_scale_bps":10000,"high_contrast":false,"reduced_motion":false}
	main.render(); await get_tree().process_frame

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
	var onboarding_profile := RULES.new_profile()
	onboarding_profile = RULES.choose_starter(onboarding_profile, "cinderpaw").profile
	onboarding_profile = RULES.print_starter(onboarding_profile).profile
	GameManager.profile = onboarding_profile
	var seeded_pack := GameManager.claim_next_starter_pack("unified_library")
	require(bool(seeded_pack.get("ok", false)), "Live Pack setup commits one authoritative starter receipt before control testing.")
	main.m3_pack_inspector_id = ""; main._m3_open_pending_pack("unified_library"); await get_tree().process_frame
	var pending_cards: Array = (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).get("cards", []) as Array
	var first_pack_id := str(pending_cards[0]) if not pending_cards.is_empty() else ""
	var pack_card := _button(main, "UnifiedPackCardView" + first_pack_id.capitalize())
	var receipt_revision := int(GameManager.profile.get("revision", 0))
	require(await _pointer_activate(pack_card) and main.m3_pack_inspector_id == first_pack_id and int(GameManager.profile.get("revision", 0)) == receipt_revision, "Live Pack dock pointer exposes persisted card facts without mutating progression.")
	var next_page := _button(main, "UnifiedPackRevealNext")
	require(await _pointer_activate(next_page) and main.unified_reveal_page == 1 and int(GameManager.profile.get("revision", 0)) == receipt_revision, "Live Pack page target persists only receipt UI state, not a profile revision.")
	var pack_back := _button(main, "UnifiedPackRevealBack")
	require(await _pointer_activate(pack_back) and main.screen == "unified_library" and not (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty() and main.unified_reveal_page == 1 and main.m3_pack_inspector_id == first_pack_id, "Pack Back returns once to its stored caller while preserving pending receipt page and selected-card context without claiming cards.")
	main.screen = "workshop"; main.render(); await get_tree().process_frame
	var resume_pack := _button(main, "WorkshopResumePendingPack")
	require(await _pointer_activate(resume_pack) and main.screen == "m3_pack" and main.unified_reveal_page == 1, "Workshop recovery reopens the same pending receipt at its saved page.")
	var keep := _button(main, "UnifiedPackRevealKeepCards")
	var keep_ink := main.find_child("PackKeepLabel", true, false) as Label
	require(keep_ink != null and keep.get_global_rect().encloses(keep_ink.get_global_rect()) and keep_ink.text == "KEEP CARDS" and await _focus_accept(keep) and int((GameManager.profile.get("starter_pack_rewards", {}) as Dictionary).get("opened", 0)) == 1 and int((GameManager.profile.get("starter_pack_rewards", {}) as Dictionary).get("kept", 0)) == 1 and (GameManager.profile.get("pending_pack_reveal", {}) as Dictionary).is_empty() and main.screen == "unified_library", "Focused Keep acknowledges one committed Founder receipt from its single contained native ink seat and returns to its caller without opening another.")
	GameManager.profile = profile

	# The starter's physical Confirm plate is a real viewport target. It chooses
	# the blueprint once and opens its separate free first-print route.
	GameManager.profile = RULES.new_profile()
	main.screen = "onboarding"; main.starter_page = 0; main.render(); await get_tree().process_frame
	var starter_confirm := _button(main, "StarterConfirmFocused")
	var starter_confirm_ink := main.find_child("StarterConfirmFocusedInk", true, false) as Label
	var starter_inspect := _button(main, "StarterInspectFocused")
	var starter_inspect_ink := main.find_child("StarterInspectFocusedInk", true, false) as Label
	var inspect_center := starter_inspect_ink.get_global_rect().get_center() if starter_inspect_ink != null else Vector2.ZERO
	var confirm_center := starter_confirm_ink.get_global_rect().get_center() if starter_confirm_ink != null else Vector2.ZERO
	require(starter_confirm_ink != null and starter_inspect_ink != null and starter_confirm_ink.mouse_filter == Control.MOUSE_FILTER_IGNORE and starter_inspect_ink.mouse_filter == Control.MOUSE_FILTER_IGNORE and inspect_center.distance_to(Vector2(129, 724)) <= 2.0 and confirm_center.distance_to(Vector2(452, 724)) <= 2.0 and await _pointer_activate(starter_confirm) and str(GameManager.profile.get("onboarding", {}).get("state", "")) == "starter_selected" and str(GameManager.profile.get("onboarding", {}).get("starter_id", "")) == "cinderpaw" and main.screen == "printer", "Live Starter Confirm uses the full physical cream plate to choose once and open the free first print while its passive native ink stays centered on the two cream faces.")
	GameManager.profile = profile

	# Run Cycle is the only owner of the pictured lower-right mount. A live press
	# must advance authority once; a stale disabled press must not advance it again.
	var battle := BATTLE_STATE.create(["cinderpaw"], ["aquafin"], 41)
	battle.phase = "main"; battle.active_seat = 0
	main.battle = battle; main.battle_mode = "training"; main.unified_local_handoff = false; main.unified_ai_pending = false
	main.unified_battle_coordinator.configure(battle, 0)
	main.screen = "unified_battle"; main.render(); await get_tree().process_frame
	var run_mount := _button(main, "UnifiedRunCycleLever")
	var run_revision := int(battle.revision)
	require(is_instance_valid(run_mount) and await _pointer_activate(run_mount) and int(battle.revision) > run_revision, "Live Run Cycle press reaches the single pictured mount and begins a checked cycle.")
	run_mount = _button(main, "UnifiedRunCycleLever")
	var locked_revision := int(battle.revision)
	await _pointer_inject(run_mount)
	require(is_instance_valid(run_mount) and run_mount.disabled and int(battle.revision) == locked_revision, "Locked Run Cycle mount declines injected stale viewport input without changing authority revision.")
	main.unified_battle_coordinator.invalidate_generation()
	main.unified_ai_pending = false
	main.battle = null

	# Result has one physical exit. No duplicate HUD Back control can receive focus.
	main.screen = "m3_result"; main.battle_mode = "daily"; main.m3_result_state = "committed"; main.m3_result_receipt = {"result":"victory", "coins":1, "xp":1}; main.render(); await get_tree().process_frame
	var result_continue := _button(main, "ResultContinue")
	require(main.find_child("ResultReceiptBack", true, false) == null and await _pointer_activate(result_continue) and main.screen == "workshop", "Live Result Continue is the sole physical exit owner.")

	main.queue_free()
	await get_tree().process_frame
	if failures.is_empty(): print("PASS: M3 live pointer/focus physical control paths")
	SaveService.configure_test_paths(configured_root)
	get_tree().quit(0 if failures.is_empty() else 1)
