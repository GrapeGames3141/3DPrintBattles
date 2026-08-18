extends Node

const MAIN := preload("res://scenes/main.tscn")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func escape(main: Control) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE
	main._unhandled_key_input(event)
	await get_tree().process_frame

func control_in_view(control: Control, viewport_size: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return rect.size.x >= 44.0 and rect.size.y >= 44.0 and rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= float(viewport_size.x) and rect.end.y <= float(viewport_size.y)

func hotspot_in_map_view(hotspot: Control, map: Control) -> bool:
	var hotspot_rect := hotspot.get_global_rect()
	var map_rect := map.get_global_rect().grow(-4.0)
	return hotspot_rect.position.x >= map_rect.position.x and hotspot_rect.end.x <= map_rect.end.x and hotspot_rect.position.y >= map_rect.position.y and hotspot_rect.end.y <= map_rect.end.y

func descendant_count(root: Node, node_name: String) -> int:
	var count := 0
	for node in root.find_children(node_name, "", true, false):
		if node.name == node_name:
			count += 1
	return count

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 500
	var learned: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, "mossmunk")
	require(bool(learned.get("ok", false)), "fixture learns a non-starter blueprint")
	GameManager.profile = learned.get("profile", profile)
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	require(main.screen == "workshop" and main.workshop_view == "overview", "new selected profile opens the Workshop overview")
	var map := main.find_child("WorkshopMap", true, false) as Control
	var hotspot_names := ["WorkshopHotspotPrinter", "WorkshopHotspotCollection", "WorkshopHotspotTeam", "WorkshopHotspotArmor", "WorkshopHotspotBattleArena", "WorkshopHotspotCardArchive", "WorkshopHotspotShop", "WorkshopHotspotCodex", "WorkshopHotspotTrade", "WorkshopHotspotCalibration"]
	require(map != null and main.find_child("WorkshopStationLiveLayer", true, false) == null and main.find_child("WorkshopAmbientLayer", true, false) == null, "overview remains a static dedicated spatial map")
	for hotspot_name in hotspot_names:
		var hotspot := main.find_child(hotspot_name, true, false) as Button
		require(hotspot != null and hotspot.text.is_empty() and not hotspot.tooltip_text.is_empty() and not hotspot.accessibility_name.is_empty() and hotspot.custom_minimum_size.x >= 44.0 and hotspot.custom_minimum_size.y >= 44.0, "%s remains an accessible direct-object overview target" % hotspot_name)
		require(hotspot != null and hotspot.find_child("WorkshopHotspotOverlay", true, false) == null, "%s has no visible overview overlay" % hotspot_name)
	require(descendant_count(main, "WorkshopHotspotOverlay") == 0 and main.find_child("WorkshopHotspotDoor", true, false) == null and main.find_child("WorkshopHotspotYard", true, false) == null, "overview keeps no legacy overlay, Door, or Yard hotspot")
	var calibration_revision := int(GameManager.profile.revision)
	var calibration_count := int(GameManager.profile.daily_job_count)
	main.activate_workshop_overview_hotspot("calibration")
	await get_tree().process_frame
	require(main.screen == "workshop" and main.workshop_view == "overview" and int(GameManager.profile.revision) == calibration_revision + 1 and int(GameManager.profile.daily_job_count) == calibration_count + 1, "Calibration dial claims exactly once and remains on the overview")
	for entry in [{"target":"collection", "screen":"collection"}, {"target":"team", "screen":"team"}, {"target":"armor", "screen":"armor"}, {"target":"battle_arena", "screen":"proving"}, {"target":"card_archive", "screen":"archive"}, {"target":"shop", "screen":"shop"}, {"target":"codex", "screen":"codex"}, {"target":"trade", "screen":"trade"}]:
		main.screen = "workshop"
		main.open_workshop_view("overview")
		main.activate_workshop_overview_hotspot(str(entry.target))
		await get_tree().process_frame
		require(main.screen == str(entry.screen), "%s routes directly from its pictured overview object" % str(entry.target))
		if str(entry.target) == "card_archive": require(main.find_child("ArchiveEditDeck", true, false) is Button, "Support Card Archive keeps Edit Deck reachable")
	main.screen = "workshop"
	main.open_workshop_view("overview")
	var printer_hotspot := main.find_child("WorkshopHotspotPrinter", true, false) as Button
	require(printer_hotspot != null and printer_hotspot.custom_minimum_size.x >= 44.0 and printer_hotspot.custom_minimum_size.y >= 44.0, "overview printer remains an accessible direct-object target")
	var before_open: Dictionary = GameManager.profile.duplicate(true)
	main.activate_workshop_overview_hotspot("printer")
	await get_tree().process_frame
	await get_tree().process_frame
	require(main.screen == "printer" and main.workshop_return_view == "overview", "overview printer opens Arcane Forge directly")
	require(main.find_child("WorkshopCloseupMap", true, false) == null and main.find_child("WorkshopStationLiveLayer", true, false) == null, "integrated Forge never renders the old live Printer close-up")
	require(main.find_child("PrinterBlueprintTray", true, false) == null and main.find_child("PrinterBlueprintDetail", true, false) == null and main.find_child("PrinterPreviewMossmunk", true, false) == null, "integrated Forge has no separate tray, duplicate detail, or preview action")
	var selector := main.find_child("PrinterBlueprintSelector", true, false) as Control
	var cinder_card := main.find_child("PrinterBlueprintCardCinderpaw", true, false) as Control
	var moss_card := main.find_child("PrinterBlueprintCardMossmunk", true, false) as Control
	var begin := main.find_child("BeginCreaturePrint", true, false) as Button
	require(selector != null and cinder_card != null and moss_card != null and begin != null, "idle Forge includes learned blueprint cards and one primary Begin Print action")
	require(int(moss_card.get_meta("price", -1)) == int(Catalog.rarity("common").print) and int(moss_card.get_meta("owned_count", -1)) == 0 and moss_card.find_child("PrinterBlueprintIdleArt", true, false) != null, "selector card preserves catalog price, owned count, and idle art")
	main.select_printer_blueprint("mossmunk")
	await get_tree().process_frame
	require(main.screen == "printer" and main.printer_creature_id == "mossmunk" and main.printer_price == int(Catalog.rarity("common").print), "selecting mossmunk updates the dormant Forge preview and facts in place")
	require(GameManager.profile == before_open, "opening and selecting blueprints do not mutate coins, inventory, or revision")
	begin = main.find_child("BeginCreaturePrint", true, false) as Button
	if begin != null: begin.emit_signal("pressed")
	await get_tree().process_frame
	require(main.printer_sequence != null and main.printer_sequence.phase == ArcaneForgeSequence.PRINTING and main.find_child("PrinterBlueprintSelector", true, false) == null, "Begin Print locks and hides creature selection for the transaction")
	await escape(main)
	require(main.screen == "printer", "Escape cannot cancel an in-progress print")
	# Verify Print Another reopens the same route without driving a real commit.
	main.printer_sequence.phase = ArcaneForgeSequence.AWAKENED
	main.return_to_printer_picker()
	await get_tree().process_frame
	require(main.screen == "printer" and main.printer_sequence.phase == ArcaneForgeSequence.IDLE and main.find_child("PrinterBlueprintSelector", true, false) != null, "Print Another resets the same integrated Forge with selection visible")
	await escape(main)
	require(main.screen == "workshop" and main.workshop_view == "overview", "idle Forge Escape returns directly to Workshop overview")
	var empty_profile: Dictionary = GameManager.profile.duplicate(true)
	GameManager.profile.blueprints = []
	main.open_printer_picker()
	await get_tree().process_frame
	require(main.screen == "printer" and main.find_child("PrinterBlueprintEmptyState", true, false) != null and main.find_child("PrinterBlueprintEmptyOffers", true, false) is Button and main.find_child("ArcaneForgeBack", true, false) is Button, "empty learned state remains in the Forge with Offers and correct back action")
	GameManager.profile = empty_profile
	main.cancel_printer_preview()
	await get_tree().process_frame
	for viewport_size in [Vector2i(1280, 720), Vector2i(576, 1024), Vector2i(720, 1280)]:
		get_viewport().size = viewport_size
		main.size = Vector2(viewport_size)
		main.screen = "workshop"
		main.workshop_view = "overview"
		main.render()
		await get_tree().process_frame
		await get_tree().process_frame
		map = main.find_child("WorkshopMap", true, false) as Control
		var expected_overview_path := "res://assets/ui/workshop/workshop_overview_portrait_v4.png" if viewport_size.y > viewport_size.x else "res://assets/ui/workshop/workshop_overview_landscape_v4.png"
		require(map != null and str(map.get_meta("workshop_stage_texture", "")) == expected_overview_path, "overview selects the orientation-matched direct-object map at %s" % viewport_size)
		for hotspot_name in hotspot_names:
			var responsive_hotspot := main.find_child(hotspot_name, true, false) as Control
			require(responsive_hotspot != null and control_in_view(responsive_hotspot, viewport_size), "%s stays in bounds at %s (rect %s)" % [hotspot_name, viewport_size, responsive_hotspot.get_global_rect() if responsive_hotspot != null else Rect2()])
		main.activate_workshop_overview_hotspot("printer")
		await get_tree().process_frame
		await get_tree().process_frame
		var stage := main.find_child("ArcaneForgeStage", true, false) as Control
		var responsive_selector := main.find_child("PrinterBlueprintSelector", true, false) as Control
		var first_card := main.find_child("PrinterSelectCinderpaw", true, false) as Button
		var responsive_begin := main.find_child("BeginCreaturePrint", true, false) as Button
		var responsive_back := main.find_child("ArcaneForgeBack", true, false) as Button
		require(stage != null and responsive_selector != null and first_card != null and first_card.focus_mode != Control.FOCUS_NONE and first_card.custom_minimum_size.x >= 44.0 and first_card.custom_minimum_size.y >= 44.0, "Forge keeps focusable touch-safe selector controls at %s" % viewport_size)
		var outer_forge_scroll := main.find_child("TouchFirstScroll", true, false) as ScrollContainer
		var card_content := first_card.get_parent().find_child("PrinterBlueprintCardContent", true, false) as Control if first_card != null else null
		require(outer_forge_scroll != null and not outer_forge_scroll.follow_focus and is_zero_approx(outer_forge_scroll.scroll_vertical), "Forge restores the outer scroll origin before focusing cartridges at %s" % viewport_size)
		require(card_content != null and card_content.get_rect().position.x >= 12.0 and card_content.get_rect().position.y >= 12.0 and card_content.get_rect().end.x <= first_card.get_rect().size.x - 12.0 and card_content.get_rect().end.y <= first_card.get_rect().size.y - 12.0, "cartridge content stays safely inset from the ornate rim at %s" % viewport_size)
		require(main.find_child("PrinterBlueprintCartridgeStrip", true, false) is ScrollContainer and main.find_child("PrinterBlueprintCartridgeStripContents", true, false) is HBoxContainer, "Forge uses a horizontal cartridge shelf at %s" % viewport_size)
		if viewport_size.y <= viewport_size.x:
			require(main.find_child("IntegratedForgeLayout", true, false) is HBoxContainer, "landscape uses a coherent printer-plus-selector composition at %s" % viewport_size)
			if viewport_size == Vector2i(1280, 720): require(responsive_begin != null and responsive_back != null and control_in_view(responsive_begin, viewport_size) and control_in_view(responsive_back, viewport_size), "1280x720 landscape keeps Begin and Back within the first visible Forge fold")
		require(responsive_begin != null and responsive_begin.custom_minimum_size.y >= 44.0 and control_in_view(stage, viewport_size), "Forge printer and primary action stay accessible at %s" % viewport_size)
		await escape(main)
		main.open_workshop_view("maker")
		await get_tree().process_frame
		await get_tree().process_frame
		var closeup_map := main.find_child("WorkshopCloseupMap", true, false) as Control
		require(closeup_map != null and main.workshop_view == "maker" and closeup_map.get_global_rect().position.x >= 0.0 and closeup_map.get_global_rect().end.x <= float(viewport_size.x), "legacy Maker close-up remains horizontally bounded at %s" % viewport_size)
		var maker_view: Dictionary = main._workshop_view_data("maker")
		for object in maker_view.objects:
			var object_button := main.find_child("WorkshopObject%s" % str(object.id).capitalize(), true, false) as Button
			require(object_button != null and object_button.custom_minimum_size.x >= 44.0 and object_button.custom_minimum_size.y >= 44.0 and object_button.find_child("WorkshopHotspotOverlay", true, false) != null, "%s retains its accessible physical Maker target at %s" % [str(object.id), viewport_size])
			if viewport_size.y > viewport_size.x and object_button != null:
				object_button.grab_focus()
				await get_tree().process_frame
				require(hotspot_in_map_view(object_button, closeup_map), "%s focus pans into the portrait Maker map at %s" % [str(object.id), viewport_size])
		if viewport_size.y > viewport_size.x:
			var pan_affordance := main.find_child("WorkshopPanAffordance", true, false) as Button
			require(pan_affordance != null and pan_affordance.text.is_empty() and pan_affordance.tooltip_text == "Swipe the workshop view to reach more tools", "portrait Maker close-up has the accessible pan affordance")
		require(get_viewport().gui_get_focus_owner() is Button, "render provides deterministic keyboard button focus at %s" % viewport_size)
	GameManager.profile.settings.reduced_motion = true
	main.screen = "workshop"
	main.workshop_view = "maker"
	main.workshop_drawer_object = ""
	main.render()
	await get_tree().process_frame
	await get_tree().process_frame
	var reduced_live := main.find_child("WorkshopStationLiveLayer", true, false)
	var reduced_plane := main.find_child("WorkshopCloseupMapArtPlane", true, false)
	var reduced_ambient := reduced_plane.find_child("WorkshopAmbientLayer", true, false) if reduced_plane != null else null
	var frozen_phase: float = float(reduced_ambient.phase) if reduced_ambient != null else -1.0
	await get_tree().process_frame
	await get_tree().process_frame
	require(reduced_live != null and not reduced_live.is_processing() and reduced_ambient != null and not bool(reduced_ambient.motion_enabled) and reduced_ambient.process_mode == Node.PROCESS_MODE_DISABLED and is_equal_approx(float(reduced_ambient.phase), frozen_phase), "reduced motion freezes Maker live and ambient presentation")
	GameManager.profile.settings.reduced_motion = false
	var stable_coins: int = int(GameManager.profile.coins)
	var stable_revision: int = int(GameManager.profile.revision)
	main.render()
	await get_tree().process_frame
	var moving_plane := main.find_child("WorkshopCloseupMapArtPlane", true, false)
	var moving_ambient := moving_plane.find_child("WorkshopAmbientLayer", true, false) if moving_plane != null else null
	var moving_phase: float = float(moving_ambient.phase) if moving_ambient != null else -1.0
	await get_tree().create_timer(0.08).timeout
	require(moving_ambient != null and bool(moving_ambient.motion_enabled) and moving_ambient.process_mode != Node.PROCESS_MODE_DISABLED and not is_equal_approx(float(moving_ambient.phase), moving_phase), "normal Maker ambient motion advances visibly")
	require(int(GameManager.profile.coins) == stable_coins and int(GameManager.profile.revision) == stable_revision, "Maker ambient motion does not mutate profile or printer authority")
	main.queue_free()
	if failures.is_empty(): print("PASS: integrated Arcane Forge workshop navigation")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
