extends Node
## Reusable deterministic visual QA capture; output is deliberately outside the repository.
const OUTPUT_DIR := "E:/CodexCache/printforge-validation"
const MAIN_SCENE := preload("res://scenes/main.tscn")
const ART_GALLERY := preload("res://scripts/ui/creature_art_gallery.gd")
const CAPTURE_OFFLINE_QA_SETUP := preload("res://tests/capture_offline_qa_setup.gd")
const VFX_CONTACT_SHEET := preload("res://tests/vfx_contact_sheet.gd")
const TIERED_ARMOR_PALETTE_SHOWCASE := preload("res://tests/tiered_armor_palette_showcase.gd")
const CORE_POWER_SHOWCASE := preload("res://tests/core_power_showcase.gd")
const CORE_POWER_TIMELINE := preload("res://tests/core_power_timeline.gd")
const HELMET_GEM_CLOSEUP_SHOWCASE := preload("res://tests/helmet_gem_closeup_showcase.gd")
const UNIFIED_RULES := preload("res://scripts/core/unified_rules.gd")
const M1_TITLE_MODES := ["m1_title", "m1_title_text150", "m1_tall_safe_top"]
const M1_STARTER_MODES := ["m1_starter_focused", "m1_starter_inspector", "m1_starter_text150", "m1_starter_inspector_text150", "m1_starter_inspector_focus_select", "m1_starter_inspector_focus_close"]
const M1_FIRST_PRINT_MODES := ["m1_first_print_setup", "m1_first_print_text150"]
var workshop: Control
var capture_size := ""
var capture_mode := "onboarding"
var capture_tag := ""
var capture_feature_setup
var capture_output_dir := OUTPUT_DIR

func _ready() -> void:
	# Legacy feature captures are optional after the unified cleanup removed their
	# helper. Load it lazily so current unified visual-QA modes remain runnable.
	capture_feature_setup = load("res://tests/capture_feature_setup.gd") if ResourceLoader.exists("res://tests/capture_feature_setup.gd") else null
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var forced_viewport := requested_capture_viewport()
	# The project uses Godot's square-base + canvas_items/expand pattern. The
	# command-line window resolution is the only capture sizing authority: do not
	# mask a project stretch failure with a content-scale override here.
	if forced_viewport.x > 0 and forced_viewport.y > 0:
		DisplayServer.window_set_size(forced_viewport)
	# Captures are visual evidence, but must never hide, trap, or confine the
	# user's pointer. Visible pointer mode remains the exit invariant as well.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	capture_mode = requested_mode()
	capture_tag = requested_tag()
	capture_output_dir = requested_output_dir()
	DirAccess.make_dir_recursive_absolute(capture_output_dir)
	# Autoload _ready() may still be pending on this same first frame. Configure
	# deterministic fixtures one frame later so a save load cannot replace them.
	call_deferred("_prepare_capture")

func _prepare_capture() -> void:
	await get_tree().process_frame
	GameManager.profile = fixture_profile() if capture_mode not in ["onboarding", "feedback_starter"] else ProfileRules.new_profile()
	if capture_mode.begins_with("unified_"):
		GameManager.profile = UNIFIED_RULES.ensure(ProfileRules.new_profile())
		GameManager.profile.coins = 720
		GameManager.profile = UNIFIED_RULES.choose_starter(GameManager.profile, "cinderpaw").profile
		GameManager.profile = UNIFIED_RULES.print_starter(GameManager.profile).profile
		if capture_mode == "unified_pack_reveal":
			GameManager.profile = UNIFIED_RULES.buy_pack(GameManager.profile, "forge", PackedByteArray([1,2,3,4,5,6,7,8])).profile
		if capture_mode == "unified_forgedex":
			UNIFIED_RULES.grant_card(GameManager.profile, "mossmunk")
	elif capture_mode.begins_with("feedback_"):
		GameManager.profile = UNIFIED_RULES.ensure(ProfileRules.new_profile())
		GameManager.profile.coins = 720
		if capture_mode in ["feedback_first_print", "feedback_mid_print"]:
			GameManager.profile = UNIFIED_RULES.choose_starter(GameManager.profile, "cinderpaw").profile
		if capture_mode in ["feedback_workshop", "feedback_collection", "feedback_deck_builder"]:
			GameManager.profile = UNIFIED_RULES.choose_starter(GameManager.profile, "cinderpaw").profile
			GameManager.profile = UNIFIED_RULES.print_starter(GameManager.profile).profile
	if capture_mode.begins_with("m1_"):
		GameManager.profile = ProfileRules.new_profile() if capture_mode in M1_TITLE_MODES or capture_mode in M1_STARTER_MODES else UNIFIED_RULES.ensure(ProfileRules.new_profile())
		if capture_mode in M1_FIRST_PRINT_MODES:
			GameManager.profile = UNIFIED_RULES.choose_starter(GameManager.profile, "cinderpaw").profile
		elif capture_mode not in M1_TITLE_MODES and capture_mode not in M1_STARTER_MODES:
			GameManager.profile = UNIFIED_RULES.choose_starter(GameManager.profile, "cinderpaw").profile
			GameManager.profile = UNIFIED_RULES.print_starter(GameManager.profile).profile
		if "text150" in capture_mode: GameManager.profile.settings.text_scale_bps = 15000
		if capture_mode == "m1_workshop_contrast": GameManager.profile.settings.high_contrast = true
		if capture_mode == "m1_workshop_reduced": GameManager.profile.settings.reduced_motion = true
	if capture_mode in ["trials_legacy", "trial_battle_legacy"]:
		GameManager.profile = legacy_trial_profile()
	if capture_mode in ["trials_teamlaunch", "trial_battle_teamlaunch"]:
		GameManager.profile = team_launch_profile()
	# Explicit capture-only injection proves the Android review custom-feature
	# economy floor without pretending the desktop process has that feature.
	if capture_mode in ["station_live_review", "battle_review"]:
		GameManager.apply_android_review_coin_floor(true)
	if capture_mode in ["art_gallery_page1", "art_gallery_page2"]:
		workshop = ART_GALLERY.new()
		workshop.page = 1 if capture_mode == "art_gallery_page1" else 2
		get_tree().root.call_deferred("add_child", workshop)
		call_deferred("capture")
		return
	if capture_mode == "battle_vfx_contact_sheet":
		workshop = VFX_CONTACT_SHEET.new()
		get_tree().root.call_deferred("add_child", workshop)
		call_deferred("capture_contact_sheet")
		return
	if capture_mode == "tiered_armor_palette_showcase":
		workshop = TIERED_ARMOR_PALETTE_SHOWCASE.new()
		get_tree().root.call_deferred("add_child", workshop)
		call_deferred("capture_contact_sheet")
		return
	if capture_mode == "core_power_showcase":
		workshop = CORE_POWER_SHOWCASE.new()
		get_tree().root.call_deferred("add_child", workshop)
		call_deferred("capture_contact_sheet")
		return
	if capture_mode == "core_power_timeline":
		workshop = CORE_POWER_TIMELINE.new()
		get_tree().root.call_deferred("add_child", workshop)
		call_deferred("capture_contact_sheet")
		return
	if capture_mode == "helmet_gem_closeup":
		workshop = HELMET_GEM_CLOSEUP_SHOWCASE.new()
		get_tree().root.call_deferred("add_child", workshop)
		call_deferred("capture_contact_sheet")
		return
	if capture_mode == "helmet_gem_static_closeup":
		workshop = HELMET_GEM_CLOSEUP_SHOWCASE.new()
		workshop.show_activation_overlay = false
		get_tree().root.call_deferred("add_child", workshop)
		call_deferred("capture_contact_sheet")
		return
	if capture_mode == "high_contrast_battle": GameManager.profile.settings.high_contrast = true
	if capture_mode == "reduced_motion_battle": GameManager.profile.settings.reduced_motion = true
	if capture_mode == "station_live_reduced": GameManager.profile.settings.reduced_motion = true
	workshop = MAIN_SCENE.instantiate()
	workshop.shop_day_key = "2026-08-14"
	if CAPTURE_OFFLINE_QA_SETUP.configure(workshop, capture_mode):
		pass
	elif capture_feature_setup != null and capture_feature_setup.configure_battle(workshop, capture_mode):
		pass
	elif capture_feature_setup != null and capture_feature_setup.configure_forge(workshop, capture_mode):
		pass
	elif capture_feature_setup != null and capture_feature_setup.configure_workshop(workshop, capture_mode):
		pass
	elif capture_mode in ["trade", "trade_draft", "trade_settled"]:
		workshop.screen = "trade"
		workshop.local_trade = LocalTradeAuthority.create(GameManager.profile, workshop._guildmate_profile())
		var yours: Array = workshop.local_trade.eligible(workshop.local_trade.creator)
		var theirs: Array = workshop.local_trade.eligible(workshop.local_trade.partner)
		if not yours.is_empty() and not theirs.is_empty():
			workshop.trade_creator_choice = yours[0]; workshop.trade_partner_choice = theirs[0]
			workshop.local_trade.choose(yours[0], theirs[0])
			if capture_mode in ["trade_draft", "trade_settled"]: workshop.local_trade.confirm(0, workshop.local_trade.creator_revision, workshop.local_trade.partner_revision)
			if capture_mode == "trade_settled":
				var settled: Dictionary = workshop.local_trade.confirm(1, workshop.local_trade.creator_revision, workshop.local_trade.partner_revision)
				if bool(settled.get("settled", false)): GameManager.profile = settled.creator
	elif capture_mode == "unified_battle":
		var setup: Dictionary = GameManager.create_unified_battle("trial_first_layers", {}, 61)
		workshop.battle = setup.get("battle", null)
		workshop.battle_mode = "trial_first_layers"
		workshop.battle_settlement_context = setup.get("settlement_context", {})
		workshop.screen = "unified_battle"
	elif capture_mode == "unified_pack_reveal": workshop.screen = "unified_market"
	elif capture_mode == "unified_forgedex": workshop.screen = "unified_forgedex"
	elif capture_mode == "feedback_starter": workshop.screen = "onboarding"
	elif capture_mode == "feedback_first_print":
		workshop.screen = "printer"
		workshop.printer_creature_id = "cinderpaw"
		workshop.printer_blueprint_selected_id = "cinderpaw"
		workshop.printer_price = 0
		workshop.printer_sequence = ArcaneForgeSequence.create(false)
	elif capture_mode == "feedback_mid_print":
		workshop.screen = "printer"
		workshop.printer_creature_id = "cinderpaw"
		workshop.printer_blueprint_selected_id = "cinderpaw"
		workshop.printer_price = 0
		workshop.printer_sequence = ArcaneForgeSequence.create(false)
		workshop.printer_sequence.begin()
		workshop.printer_sequence.advance(4200)
	elif capture_mode == "feedback_workshop": workshop.screen = "workshop"
	elif capture_mode == "feedback_collection": workshop.screen = "unified_library"
	elif capture_mode == "feedback_deck_builder": workshop.screen = "unified_deck"
	elif capture_mode == "unified_library_inspector": workshop.screen = "unified_library"; workshop.unified_inspector_id = "cinderpaw"; workshop.unified_inspector_tab = "stats"
	elif capture_mode in M1_TITLE_MODES: workshop.screen = "title"
	elif capture_mode in M1_STARTER_MODES:
		workshop.screen = "onboarding"
		workshop.starter_page = 0
		if "inspector" in capture_mode: workshop.starter_inspector_id = "cinderpaw"
	elif capture_mode in M1_FIRST_PRINT_MODES:
		workshop.screen = "printer"
		workshop.printer_creature_id = "cinderpaw"
		workshop.printer_blueprint_selected_id = "cinderpaw"
		workshop.printer_price = 0
		workshop.printer_sequence = ArcaneForgeSequence.create(false)
	elif capture_mode.begins_with("m1_workshop"):
		workshop.screen = "workshop"
		if capture_mode == "m1_workshop_synthetic": workshop.set_meta("synthetic_admob_overlay_stress", true)
	elif capture_mode != "onboarding": workshop.screen = capture_mode
	if capture_mode == "m1_tall_safe_top": workshop.set_meta("presentation_safe_top_inset", 84.0)
	if capture_mode == "proving":
		# The real navigation path freezes the daily contracts before rendering;
		# reproduce that precondition for an honest Proving Door visual capture.
		GameManager.prepare_daily_training(workshop.shop_day_key)
	# Capture explicit deterministic phase snapshots; never let Main's live printer timer
	# advance an awakening state while the header settles.
	workshop.printer_capture_freeze = true
	workshop.workshop_ambient_capture_freeze = true
	get_tree().root.call_deferred("add_child", workshop)
	call_deferred("capture")

func fixture_profile() -> Dictionary:
	var fixture: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	fixture.coins = 1000
	var blueprint: Dictionary = ProgressionRules.purchase_creature_blueprint(fixture, "mossmunk")
	var printed: Dictionary = ProgressionRules.print_creature(blueprint.profile, "mossmunk")
	var suit_blueprint: Dictionary = ProgressionRules.learn_suit_blueprint(printed.profile, "standard")
	var suit_print: Dictionary = ProgressionRules.print_suit(suit_blueprint.profile, "standard")
	fixture = ProgressionRules.equip_suit(suit_print.profile, str(suit_print.profile.onboarding.starter_instance_id), str(suit_print.payload.suit_instance_id)).profile
	fixture.team = [str(fixture.onboarding.starter_instance_id), str(printed.payload.instance_id)]
	# A spare print remains off-team so the trade capture demonstrates a legal offer.
	var spare: Dictionary = ProgressionRules.print_creature(fixture, "mossmunk")
	if bool(spare.ok): fixture = spare.profile
	var third_blueprint: Dictionary = ProgressionRules.purchase_creature_blueprint(fixture, "aquafin")
	if bool(third_blueprint.ok):
		var third_print: Dictionary = ProgressionRules.print_creature(third_blueprint.profile, "aquafin")
		if bool(third_print.ok):
			fixture = third_print.profile
			fixture.team = [str(fixture.onboarding.starter_instance_id), str(printed.payload.instance_id), str(third_print.payload.instance_id)]
	fixture.support_cards.coolant = 1
	return fixture

func legacy_trial_profile() -> Dictionary:
	var legacy: Dictionary = fixture_profile()
	legacy["creatures"] = [{"id":"cinderpaw"}]
	legacy["team"] = [{"species":"cinderpaw"}]
	legacy["active_deck_id"] = "missing-review-deck"
	legacy["decks"] = []
	return legacy

func team_launch_profile() -> Dictionary:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").get("profile", {})
	profile["coins"] = 5000
	for creature_id in ["brambleowl", "verdantitan"]:
		var learned: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, creature_id)
		profile = learned.get("profile", profile)
		var printed: Dictionary = ProgressionRules.print_creature(profile, creature_id)
		profile = printed.get("profile", profile)
	var suit_tier: String = str(Catalog.SUITS[0].get("id", ""))
	var learned_suit: Dictionary = ProgressionRules.learn_suit_blueprint(profile, suit_tier)
	profile = learned_suit.get("profile", profile)
	var printed_suit: Dictionary = ProgressionRules.print_suit(profile, suit_tier)
	profile = printed_suit.get("profile", profile)
	var bramble_instance: String = str(profile.get("creatures", [])[1].get("instance_id", ""))
	var suit_instance: String = str(profile.get("suits", [])[0].get("suit_instance_id", ""))
	var equipped: Dictionary = ProgressionRules.equip_suit(profile, bramble_instance, suit_instance)
	profile = equipped.get("profile", profile)
	profile["team"] = [str(profile.get("creatures", [])[0].get("instance_id", "")), bramble_instance, str(profile.get("creatures", [])[2].get("instance_id", ""))]
	return profile

func capture() -> void:
	# Capture an actual accessible impact cue after the first Battle route. The
	# director is capture-muted, so this only exercises visible presentation.
	if capture_mode == "battle_impact" and workshop != null:
		workshop._audio_director.cue("impact")
		workshop.render()
	await wait_for_stable_header()
	var requested_focus := m1_requested_focus_button()
	if not requested_focus.is_empty():
		var focus_hotspot := workshop.find_child(requested_focus, true, false) as Button
		if focus_hotspot == null or not focus_hotspot.is_visible_in_tree():
			push_error("M1 focus capture could not find %s." % requested_focus)
			get_tree().quit(1)
			return
		focus_hotspot.release_focus()
		await wait_frames(1)
		focus_hotspot.call_deferred("grab_focus")
		await wait_frames(4)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		if not focus_hotspot.has_focus():
			push_error("M1 focus capture did not receive keyboard focus before rasterization.")
			get_tree().quit(1)
			return
	if capture_mode.begins_with("m1_") and not validate_m1_capture():
		get_tree().quit(1)
		return
	if capture_mode in ["workshop_printer_picker", "printer_picker_preview_mossmunk", "integrated_forge", "integrated_forge_mossmunk"]:
		# Fixture setup bypasses Main.open_printer(), so run its focus/scroll reset
		# only after the Forge has rendered into the tree and header has settled.
		await workshop._focus_printer_picker_origin()
		await wait_frames(2)
	# The trial screen is deliberately scrollable on a phone.  Pin the capture
	# position after all deferred focus/layout work so the evidence proves both
	# the initial list and a genuine lower-list scroll state.
	if capture_mode in ["proving", "trials", "trials_scrolled", "trials_legacy", "trials_teamlaunch"]:
		var trial_scroll := workshop.find_child("TouchFirstScroll", true, false) as ScrollContainer
		if trial_scroll != null:
			if capture_mode == "trials_scrolled":
				trial_scroll.scroll_vertical = int(trial_scroll.get_v_scroll_bar().max_value)
			else:
				trial_scroll.scroll_vertical = 0
			await wait_frames(2)
	if capture_mode in ["card_archive", "card_detail", "deck_cards", "shop_cards", "local_card_handoff", "local_card_revealed", "battle_hand_cards_focus"]:
		var card_scroll := workshop.find_child("BattleSecondaryScroll" if capture_mode == "battle_hand_cards_focus" else "TouchFirstScroll", true, false) as ScrollContainer
		if card_scroll != null:
			card_scroll.scroll_vertical = int(card_scroll.get_v_scroll_bar().max_value) if capture_mode == "battle_hand_cards_focus" else 0
			await wait_frames(2)
	if capture_mode.begins_with("battle_vfx_") and workshop != null:
		# Replay the finite visual at a meaningful deterministic point after layout
		# has settled. This does not submit an intent or mutate BattleState.
		var stage := workshop.find_child("BattleStage", true, false) as BattleSpriteStage
		if stage != null:
			var kind := "attack" if capture_mode == "battle_vfx_basic" else ("" if capture_mode == "battle_vfx_idle" else "ability")
			stage.configure(workshop.battle.active_unit(0), workshop.battle.active_unit(1), kind, 0, bool(workshop.settings().get("reduced_motion", false)), bool(workshop.settings().get("high_contrast", false)), int(workshop.battle_presentation_serial) + 1)
			stage.advance_presentation(0.38 if kind == "ability" else 0.26)
			await wait_frames(1)
	var capture_object := capture_workshop_object()
	if not capture_object.is_empty():
		var hotspot := workshop.find_child("WorkshopObject%s" % capture_object.capitalize(), true, false) as Button
		if hotspot != null:
			hotspot.grab_focus()
			await wait_frames(2)
	# Captures must never trap or confine the user's pointer. The viewport readback
	# is deterministic without taking mouse ownership, so leave it visible.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await wait_frames(2)
	if capture_mode.begins_with("m1_workshop") and requested_focus.is_empty():
		# Never rely on pointer hover for capture state. Clear incidental hover rings.
		for transient_ring in workshop.find_children("WorkshopHotspotTightFocusRing", "Panel", true, false):
			(transient_ring as Panel).hide()
		await wait_frames(1)
	if not requested_focus.is_empty():
		var raster_focus_hotspot := workshop.find_child(requested_focus, true, false) as Button
		if raster_focus_hotspot == null:
			push_error("M1 focus capture lost the printer hotspot before rasterization.")
			get_tree().quit(1)
			return
		raster_focus_hotspot.grab_focus()
		var raster_focus_ring := raster_focus_hotspot.find_child("WorkshopHotspotTightFocusRing", true, false) as Panel
		if raster_focus_ring != null:
			raster_focus_ring.show()
			for edge in ["Top", "Right", "Bottom", "Left"]:
				var stroke := raster_focus_ring.find_child("WorkshopHotspotTightFocusStroke%s" % edge, true, false) as Control
				if stroke == null or stroke.get_global_rect().get_area() <= 0.0:
					push_error("M1 focus capture lost %s edge on %s." % [edge, requested_focus])
					get_tree().quit(1)
					return
		await wait_frames(2)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
	capture_size = requested_resolution()
	var suffix := "_%s" % capture_tag if not capture_tag.is_empty() else ""
	var image := get_viewport().get_texture().get_image()
	var expected := requested_capture_viewport()
	if expected.x > 0 and image.get_size() != expected:
		push_error("Capture dimension mismatch: expected %s, received %s" % [expected, image.get_size()])
		get_tree().quit(1)
		return
	var output_path := capture_output_dir.path_join("%s_%s%s.png" % [capture_mode, capture_size, suffix])
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("Capture PNG save failed: %s (%s)" % [output_path, save_error])
		get_tree().quit(1)
		return
	print("CAPTURED: %s (%s, %s%s)" % [capture_output_dir, capture_mode, capture_size, suffix])
	get_tree().quit()

func m1_requested_focus_button() -> String:
	var workshop_targets := {"m1_workshop_focus_printer":"WorkshopHotspotPrinter", "m1_workshop_focus_battle_arena":"WorkshopHotspotBattleArena", "m1_workshop_focus_card_archive":"WorkshopHotspotCardArchive", "m1_workshop_focus_deck":"WorkshopHotspotDeck", "m1_workshop_focus_supplies":"WorkshopHotspotSupplies", "m1_workshop_focus_settings":"WorkshopHotspotSettings", "m1_workshop_focus":"WorkshopHotspotPrinter"}
	if workshop_targets.has(capture_mode): return str(workshop_targets[capture_mode])
	if capture_mode == "m1_starter_inspector_focus_select": return "StarterInspectorSelect"
	if capture_mode == "m1_starter_inspector_focus_close": return "StarterInspectorClose"
	return ""

func capture_contact_sheet() -> void:
	# Raw capture-only ImageTextures finish their first render after the root
	# attachment; retain extra frames so every labeled VFX cell is present.
	await wait_frames(24)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await wait_frames(2)
	capture_size = requested_resolution()
	var suffix := "_%s" % capture_tag if not capture_tag.is_empty() else ""
	var image := get_viewport().get_texture().get_image()
	var expected := requested_capture_viewport()
	if expected.x > 0 and image.get_size() != expected:
		push_error("Capture dimension mismatch: expected %s, received %s" % [expected, image.get_size()])
		get_tree().quit(1)
		return
	var output_path := capture_output_dir.path_join("%s_%s%s.png" % [capture_mode, capture_size, suffix])
	var save_error := image.save_png(output_path)
	if save_error != OK:
		push_error("Capture PNG save failed: %s (%s)" % [output_path, save_error])
		get_tree().quit(1)
		return
	print("CAPTURED: %s (%s, %s%s)" % [capture_output_dir, capture_mode, capture_size, suffix])
	get_tree().quit()

func wait_frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame

func wait_for_stable_header() -> void:
	# Avoid capturing before a resized window has completed its first container pass.
	for _frame in 60:
		if capture_mode.begins_with("m1_"):
			var anchor_name := "TitleContinue" if capture_mode in M1_TITLE_MODES else "StarterCarouselCard" if capture_mode in M1_STARTER_MODES else "FirstPrintEmptyBedProof" if capture_mode in M1_FIRST_PRINT_MODES else "WorkshopProgressInstrument"
			var m1_anchor := workshop.find_child(anchor_name, true, false) as Control
			if m1_anchor != null and m1_anchor.is_visible_in_tree() and m1_anchor.get_global_rect().get_area() > 0.0:
				await wait_frames(6)
				return
			await get_tree().process_frame
			continue
		if capture_mode == "feedback_starter":
			var starter_grid := workshop.find_child("StarterChoiceGrid", true, false) as Control
			if starter_grid != null and starter_grid.is_visible_in_tree() and starter_grid.get_global_rect().get_area() > 0.0:
				await wait_frames(6)
				return
			await get_tree().process_frame
			continue
		if capture_mode in ["feedback_first_print", "feedback_mid_print"]:
			var forge_stage := workshop.find_child("FeedbackForgeStage", true, false) as Control
			if forge_stage != null and forge_stage.is_visible_in_tree() and forge_stage.get_global_rect().get_area() > 0.0:
				await wait_frames(6)
				return
			await get_tree().process_frame
			continue
		if capture_mode == "feedback_workshop":
			var progress_instrument := workshop.find_child("WorkshopProgressInstrument", true, false) as Control
			if progress_instrument != null and progress_instrument.is_visible_in_tree() and progress_instrument.get_global_rect().end.y <= get_viewport().get_visible_rect().size.y:
				await wait_frames(6)
				return
			await get_tree().process_frame
			continue
		if capture_mode in ["feedback_collection", "feedback_deck_builder"]:
			var book := workshop.find_child("ArchiveBookShell", true, false) as Control
			var archive_progress := workshop.find_child("ArchiveHudProgress", true, false) as Control
			if book != null and archive_progress != null and book.is_visible_in_tree() and archive_progress.is_visible_in_tree() and book.get_global_rect().end.y <= get_viewport().get_visible_rect().size.y:
				await wait_frames(6)
				return
			await get_tree().process_frame
			continue
		if capture_mode == "unified_battle":
			var battle_heading := workshop.find_child("UnifiedBattleHeading", true, false) as Control
			if battle_heading and battle_heading.is_visible_in_tree() and battle_heading.get_global_rect().get_area() > 0.0 and battle_heading.get_global_rect().end.y <= get_viewport().get_visible_rect().end.y:
				await wait_frames(6)
				return
			await get_tree().process_frame
			continue
		var header := workshop.find_child("WorkshopHeader", true, false) as Control
		var workshop_progress := workshop.find_child("WorkshopHudProgress", true, false) as Control
		var bottom_safe := true
		if capture_mode in ["art_gallery_page1", "art_gallery_page2"]:
			var last_card := workshop.find_child("GalleryLastCard", true, false) as Control
			bottom_safe = last_card != null and last_card.is_visible_in_tree() and last_card.get_global_rect().end.y <= get_viewport().get_visible_rect().end.y - 12.0
		var header_top := 10.0 if get_viewport().size.y > get_viewport().size.x else 15.0
		var progress_safe := capture_mode != "feedback_workshop" or (workshop_progress != null and workshop_progress.is_visible_in_tree() and workshop_progress.get_global_rect().position.y >= 0.0 and workshop_progress.get_global_rect().end.y <= get_viewport().get_visible_rect().size.y)
		if header and header.is_visible_in_tree() and header.get_global_rect().position.y >= header_top and header.get_global_rect().size.y >= 48.0 and bottom_safe and progress_safe:
			await wait_frames(6)
			return
		await get_tree().process_frame
	push_error("Capture header never reached a safe visible layout.")

func requested_resolution() -> String:
	var size := DisplayServer.window_get_size()
	if size.x <= 0 or size.y <= 0: size = get_viewport().get_texture().get_size()
	return "%dx%d" % [int(size.x), int(size.y)]

func requested_capture_viewport() -> Vector2i:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-viewport="):
			var values := arg.trim_prefix("--capture-viewport=").split("x")
			if values.size() == 2:
				return Vector2i(int(values[0]), int(values[1]))
	return Vector2i.ZERO

func requested_mode() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-mode="):
			var mode := arg.trim_prefix("--capture-mode=")
			if mode in ["unified_library_inspector", "unified_battle", "unified_pack_reveal", "unified_forgedex", "feedback_starter", "feedback_first_print", "feedback_mid_print", "feedback_workshop", "feedback_collection", "feedback_deck_builder"]: return mode
			if mode in ["future_save_recovery", "workshop", "station_live_printer_start", "station_live_printer_mid", "station_live_printer_hold", "station_live_printer_awakening", "station_live_printer_departing", "station_live_maker_team", "station_live_reduced", "station_live_review", "workshop_printer", "workshop_maker", "workshop_terminal", "workshop_terminal_offers", "workshop_terminal_forgedex", "workshop_terminal_trade", "workshop_proving", "workshop_yard", "workshop_maker_drawer", "workshop_proving_drawer", "workshop_printer_picker", "printer_picker_preview_mossmunk", "integrated_forge", "integrated_forge_mossmunk", "shop", "collection", "team", "armor", "deck", "codex", "yard", "calibration", "settings", "proving", "trials", "trials_scrolled", "trials_legacy", "trials_teamlaunch", "battle", "battle_review", "battle_secondary", "battle_hand", "battle_impact", "battle_voidmanta", "training_result", "battle_vfx_idle", "battle_vfx_basic", "battle_vfx_fire", "battle_vfx_water", "battle_vfx_lightning", "battle_vfx_nature", "battle_vfx_ice", "battle_vfx_stone", "battle_vfx_wind", "battle_vfx_arcane", "battle_vfx_contact_sheet", "tiered_armor_palette_showcase", "core_power_showcase", "core_power_timeline", "helmet_gem_closeup", "helmet_gem_static_closeup", "trial_battle", "trial_battle_legacy", "trial_battle_teamlaunch", "high_contrast_battle", "reduced_motion_battle", "local_vs", "local_vs_ready", "trade", "trade_draft", "printer_preview", "printer_printing", "printer_raw_complete", "printer_raw_hold", "printer_awakening", "printer_departing", "printer_awakened", "printer_reduced", "printer_mossmunk_raw_complete", "suit_preview", "suit_printing", "suit_raw_hold", "suit_awakened", "suit_legendary_raw_hold", "suit_legendary_awakened", "art_gallery_page1", "art_gallery_page2", "card_archive", "card_detail", "deck_cards", "shop_cards", "battle_hand_cards", "battle_hand_cards_focus", "local_card_handoff", "local_card_revealed", "high_contrast_cards", "unified_market", "unified_library", "unified_deck", "unified_upgrades"]: return mode
			if mode in ["m1_title", "m1_title_text150", "m1_tall_safe_top", "m1_starter_focused", "m1_starter_inspector", "m1_starter_text150", "m1_starter_inspector_text150", "m1_starter_inspector_focus_select", "m1_starter_inspector_focus_close", "m1_first_print_setup", "m1_first_print_text150", "m1_workshop", "m1_workshop_focus", "m1_workshop_focus_printer", "m1_workshop_focus_battle_arena", "m1_workshop_focus_card_archive", "m1_workshop_focus_deck", "m1_workshop_focus_supplies", "m1_workshop_focus_settings", "m1_workshop_text150", "m1_workshop_contrast", "m1_workshop_reduced", "m1_workshop_synthetic"]: return mode
	return "onboarding"

func capture_workshop_object() -> String:
	match capture_mode:
		"workshop_terminal_offers": return "offer_screen"
		"workshop_terminal_forgedex": return "forgedex_screen"
		"workshop_terminal_trade": return "trade_terminal"
	return ""

func requested_tag() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-tag="):
			return arg.trim_prefix("--capture-tag=").validate_filename()
	return ""

func requested_output_dir() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-output-dir="):
			return arg.trim_prefix("--capture-output-dir=")
	return OUTPUT_DIR
func m1_visual_bottom() -> float:
	var size := get_viewport().get_visible_rect().size
	if capture_mode != "m1_workshop_synthetic": return size.y
	var reserve := 96.0 if is_equal_approx(size.x, 576.0) else 120.0 if is_equal_approx(size.x, 720.0) else 180.0
	return size.y - reserve

func m1_control_in_bounds(control: Control, bottom: float) -> bool:
	if control == null or not control.is_visible_in_tree(): return false
	var rect := control.get_global_rect()
	return rect.position.x >= -0.5 and rect.end.x <= get_viewport().get_visible_rect().size.x + 0.5 and rect.end.y <= bottom + 0.5

func m1_require(value: bool, message: String) -> bool:
	if not value: push_error(message)
	return value

func validate_m1_capture() -> bool:
	var bottom := m1_visual_bottom()
	var ok := true
	if capture_mode in M1_TITLE_MODES:
		var enter := workshop.find_child("TitleContinue", true, false) as Button
		var settings_action := workshop.find_child("TitleSettings", true, false) as Button
		var version := workshop.find_child("TitleStatusVersion", true, false) as Label
		ok = m1_require(enter != null and enter.custom_minimum_size.y >= 56.0 and m1_control_in_bounds(enter, bottom), "M1 title primary is live, touch-safe, and in bounds.") and ok
		ok = m1_require(settings_action != null and settings_action.custom_minimum_size.y >= 48.0 and m1_control_in_bounds(settings_action, bottom) and version != null, "M1 title native settings/version nodes are in bounds.") and ok
	elif capture_mode in M1_STARTER_MODES:
		var card := workshop.find_child("StarterCarouselCard", true, false) as Control
		var starter_plate := workshop.find_child("StarterR2PhysicalPlate", true, false) as Control
		var inspect := workshop.find_child("StarterInspectFocused", true, false) as Button
		var confirm := workshop.find_child("StarterConfirmFocused", true, false) as Button
		ok = m1_require(starter_plate != null and card != null and inspect != null and confirm != null and m1_control_in_bounds(inspect, bottom) and m1_control_in_bounds(confirm, bottom), "M1 starter carousel has the approved physical desk, native focused card, and separate in-bounds Inspect/Confirm controls.") and ok
		if "inspector" in capture_mode: ok = m1_require(workshop.find_child("StarterCardInspector", true, false) != null, "M1 starter inspector is live before capture.") and ok
	elif capture_mode in M1_FIRST_PRINT_MODES:
		var plate := workshop.find_child("FirstPrintR2PhysicalPlate", true, false) as Control
		var empty_bed := workshop.find_child("FirstPrintEmptyBedProof", true, false) as Control
		var begin := workshop.find_child("BeginCreaturePrint", true, false) as Button
		ok = m1_require(plate != null and empty_bed != null and begin != null and m1_control_in_bounds(begin, bottom) and workshop.find_child("FeedbackForgeStage", true, false) == null and workshop.find_child("ArcaneForgeStage", true, false) == null, "M1 first-print setup has the physical empty bed, no Forge/raw/living stage, and an in-bounds begin action.") and ok
	else:
		var hotspots := workshop.find_children("WorkshopHotspot*", "Button", true, false)
		ok = m1_require(hotspots.size() == 6, "M1 Workshop has exactly six live physical station hotspots.") and ok
		for hotspot_name in ["WorkshopHotspotPrinter", "WorkshopHotspotBattleArena", "WorkshopHotspotCardArchive", "WorkshopHotspotDeck", "WorkshopHotspotSupplies", "WorkshopHotspotSettings"]:
			var hotspot := workshop.find_child(hotspot_name, true, false) as Button
			ok = m1_require(hotspot != null and hotspot.custom_minimum_size.y >= 48.0 and not hotspot.accessibility_name.is_empty() and m1_control_in_bounds(hotspot, bottom - (28.0 if capture_mode == "m1_workshop_synthetic" else 0.0)), "%s is live, touch-safe, and in bounds." % hotspot_name) and ok
		var station_label_limit := bottom - (28.0 if capture_mode == "m1_workshop_synthetic" else 0.0)
		for station_suffix in ["Printer", "BattleArena", "CardArchive", "Deck", "Supplies", "Settings"]:
			var station_label := workshop.find_child("WorkshopStationLabel%s" % station_suffix, true, false) as Label
			ok = m1_require(station_label != null and station_label.is_visible_in_tree() and not station_label.text.is_empty() and m1_control_in_bounds(station_label, station_label_limit), "Workshop native %s label is visibly rendered inside the content boundary." % station_suffix) and ok
			if capture_mode == "m1_workshop_contrast" and station_label != null:
				ok = m1_require(station_label.get_theme_color("font_color") == Color("000000") and station_label.get_theme_constant("outline_size") >= 1, "High-contrast Workshop %s label retains its local black-on-white override." % station_suffix) and ok
		if capture_mode.begins_with("m1_workshop_focus"):
			var focused_hotspot := workshop.find_child(m1_requested_focus_button(), true, false) as Button
			var focus_ring := focused_hotspot.find_child("WorkshopHotspotTightFocusRing", true, false) as Panel if focused_hotspot != null else null
			ok = m1_require(focused_hotspot != null and focused_hotspot.has_focus() and focus_ring != null and focus_ring.is_visible_in_tree() and focus_ring.get_global_rect().size.x > 0.0 and focus_ring.get_global_rect().size.y > 0.0, "M1 focused Workshop capture has a visible, nonzero tight keyboard-focus ring on the printer hotspot.") and ok
		if capture_mode == "m1_workshop_synthetic":
			var band := workshop.find_child("SyntheticAdMobOverlayStress", true, false) as ColorRect
			var stress_label := workshop.find_child("SyntheticAdMobOverlayStressLabel", true, false) as Label
			ok = m1_require(band != null and stress_label != null and "Synthetic overlay stress" in stress_label.text and is_equal_approx(band.get_global_rect().size.y, get_viewport().get_visible_rect().size.y - bottom), "M1 synthetic fixture is visibly labeled and owns the exact bottom stress reserve.") and ok
	return ok
