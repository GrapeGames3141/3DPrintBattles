extends Node
## Reusable deterministic visual QA capture; output is deliberately outside the repository.
const OUTPUT_DIR := "E:/CodexCache/printforge-validation"
const MAIN_SCENE := preload("res://scenes/main.tscn")
const ART_GALLERY := preload("res://scripts/ui/creature_art_gallery.gd")
const CAPTURE_FEATURE_SETUP := preload("res://tests/capture_feature_setup.gd")
var workshop: Control
var capture_size := ""
var capture_mode := "onboarding"
var capture_tag := ""

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var forced_viewport := requested_capture_viewport()
	# The project uses Godot's square-base + canvas_items/expand pattern. The
	# command-line window resolution is the only capture sizing authority: do not
	# mask a project stretch failure with a content-scale override here.
	if forced_viewport.x > 0 and forced_viewport.y > 0:
		DisplayServer.window_set_size(forced_viewport)
	# Captures are visual evidence, not interactive runs; keep the desktop cursor
	# out of contact sheets and existing workshop screenshots.
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	capture_mode = requested_mode()
	capture_tag = requested_tag()
	# Autoload _ready() may still be pending on this same first frame. Configure
	# deterministic fixtures one frame later so a save load cannot replace them.
	call_deferred("_prepare_capture")

func _prepare_capture() -> void:
	await get_tree().process_frame
	GameManager.profile = fixture_profile() if capture_mode != "onboarding" else ProfileRules.new_profile()
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
	if capture_mode == "high_contrast_battle": GameManager.profile.settings.high_contrast = true; GameManager.profile.settings.reduced_motion = true
	if capture_mode == "station_live_reduced": GameManager.profile.settings.reduced_motion = true
	workshop = MAIN_SCENE.instantiate()
	workshop.shop_day_key = "2026-08-14"
	if CAPTURE_FEATURE_SETUP.configure_battle(workshop, capture_mode):
		pass
	elif CAPTURE_FEATURE_SETUP.configure_forge(workshop, capture_mode):
		pass
	elif CAPTURE_FEATURE_SETUP.configure_workshop(workshop, capture_mode):
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
	elif capture_mode != "onboarding": workshop.screen = capture_mode
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
	var armor_blueprint: Dictionary = ProgressionRules.learn_armor_blueprint(printed.profile, "helm")
	var armor_print: Dictionary = ProgressionRules.print_armor(armor_blueprint.profile, "helm")
	fixture = ProgressionRules.equip_armor(armor_print.profile, str(armor_print.profile.onboarding.starter_instance_id), str(armor_print.payload.armor_instance_id)).profile
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

func capture() -> void:
	await wait_for_stable_header()
	var capture_object := capture_workshop_object()
	if not capture_object.is_empty():
		var hotspot := workshop.find_child("WorkshopObject%s" % capture_object.capitalize(), true, false) as Button
		if hotspot != null:
			hotspot.grab_focus()
			await wait_frames(2)
	# Hide/capture the Windows pointer immediately before the viewport readback.
	# This is more reliable than the initial hidden request while the window gains focus.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await wait_frames(2)
	capture_size = requested_resolution()
	var suffix := "_%s" % capture_tag if not capture_tag.is_empty() else ""
	var image := get_viewport().get_texture().get_image()
	var expected := requested_capture_viewport()
	if expected.x > 0 and image.get_size() != expected:
		push_error("Capture dimension mismatch: expected %s, received %s" % [expected, image.get_size()])
		get_tree().quit(1)
		return
	image.save_png(OUTPUT_DIR.path_join("%s_%s%s.png" % [capture_mode, capture_size, suffix]))
	print("CAPTURED: %s (%s, %s%s)" % [OUTPUT_DIR, capture_mode, capture_size, suffix])
	get_tree().quit()

func wait_frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame

func wait_for_stable_header() -> void:
	# Avoid capturing before a resized window has completed its first container pass.
	for _frame in 60:
		var header := workshop.find_child("WorkshopHeader", true, false) as Control
		var bottom_safe := true
		if capture_mode in ["art_gallery_page1", "art_gallery_page2"]:
			var last_card := workshop.find_child("GalleryLastCard", true, false) as Control
			bottom_safe = last_card != null and last_card.is_visible_in_tree() and last_card.get_global_rect().end.y <= get_viewport().get_visible_rect().end.y - 12.0
		var header_top := 10.0 if get_viewport().size.y > get_viewport().size.x else 15.0
		if header and header.is_visible_in_tree() and header.get_global_rect().position.y >= header_top and header.get_global_rect().size.y >= 80.0 and bottom_safe:
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
			if mode in ["workshop", "station_live_printer_start", "station_live_printer_mid", "station_live_printer_hold", "station_live_printer_awakening", "station_live_printer_departing", "station_live_maker_team", "station_live_reduced", "station_live_review", "workshop_printer", "workshop_maker", "workshop_terminal", "workshop_terminal_offers", "workshop_terminal_forgedex", "workshop_terminal_trade", "workshop_proving", "workshop_yard", "workshop_maker_drawer", "workshop_proving_drawer", "workshop_printer_picker", "printer_picker_preview_mossmunk", "shop", "collection", "team", "armor", "deck", "yard", "calibration", "settings", "battle", "battle_review", "battle_secondary", "battle_voidmanta", "high_contrast_battle", "local_vs", "local_vs_ready", "trade", "trade_draft", "printer_preview", "printer_printing", "printer_raw_complete", "printer_raw_hold", "printer_awakening", "printer_departing", "printer_awakened", "printer_reduced", "printer_mossmunk_raw_complete", "art_gallery_page1", "art_gallery_page2"]: return mode
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
