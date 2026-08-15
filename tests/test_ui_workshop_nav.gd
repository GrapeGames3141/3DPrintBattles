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
	var moss_blueprint: Dictionary = ProgressionRules.purchase_creature_blueprint(profile, "mossmunk")
	require(bool(moss_blueprint.get("ok", false)), "picker fixture learns a non-starter blueprint")
	profile = moss_blueprint.get("profile", profile)
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	require(main.screen == "workshop" and main.workshop_view == "overview", "new selected profile opens the workshop overview")
	var map := main.find_child("WorkshopMap", true, false) as Control
	require(map != null, "overview has a dedicated spatial workshop map")
	require(main.find_child("WorkshopStationLiveLayer", true, false) == null and main.find_child("WorkshopAmbientLayer", true, false) == null, "static overview has no live printer, team, or ambient artifact")
	var zone_names := ["WorkshopZonePrinter", "WorkshopZoneMaker", "WorkshopZoneTerminal", "WorkshopZoneProving", "WorkshopZoneYard"]
	for zone_name in zone_names:
		var zone := main.find_child(str(zone_name), true, false) as Button
		require(zone != null and zone.text.is_empty() and not zone.tooltip_text.is_empty() and not zone.accessibility_name.is_empty(), "%s is an accessible unlabeled spatial zone" % zone_name)
		require(zone != null and zone.custom_minimum_size.x >= 44.0 and zone.custom_minimum_size.y >= 44.0, "%s preserves a 44-unit target" % zone_name)
		require(zone != null and zone.find_child("WorkshopHotspotOverlay", true, false) != null, "%s has a physical-item overlay" % zone_name)
	require(descendant_count(main, "WorkshopHotspotRune") == 0 and descendant_count(main, "Rune") == 0, "workshop navigation does not render diamond rune glyph controls")
	for view_id in ["printer", "maker", "terminal", "proving", "yard"]:
		main.open_workshop_view(view_id)
		await get_tree().process_frame
		var closeup := main.find_child("WorkshopCloseupMap", true, false) as Control
		require(main.workshop_view == view_id and closeup != null and main.find_child("WorkshopOverviewButton", true, false) is Button, "%s opens a close-up with an overview return" % view_id)
		var view: Dictionary = main._workshop_view_data(view_id)
		for object in view.objects:
			var object_button := main.find_child("WorkshopObject%s" % str(object.id).capitalize(), true, false) as Button
			require(object_button != null and object_button.text.is_empty() and not object_button.accessibility_name.is_empty(), "%s object hotspot is accessible without a plaque" % str(object.id))
	main.open_workshop_view("printer")
	await get_tree().process_frame
	await get_tree().process_frame
	var picker_entry := main.find_child("PrinterBlueprintTrayButton", true, false) as Button
	require(picker_entry != null and picker_entry.is_visible_in_tree() and picker_entry.custom_minimum_size.y >= 44.0 and picker_entry.accessibility_name == "Choose a Print Blueprint Tray", "Printer station has a persistent accessible Choose a Print entry")
	var profile_before_picker: Dictionary = GameManager.profile.duplicate(true)
	picker_entry.emit_signal("pressed")
	await get_tree().process_frame
	await get_tree().process_frame
	require(main.printer_picker_open and main.find_child("PrinterBlueprintTray", true, false) != null, "Choose a Print opens the station-local Blueprint Tray")
	var picker_ids: Array[String] = main.printer_blueprint_ids()
	require(picker_ids == ["cinderpaw", "mossmunk"], "Blueprint Tray lists only learned catalog IDs in deterministic order")
	var cinder_card := main.find_child("PrinterBlueprintCardCinderpaw", true, false) as Control
	var moss_card := main.find_child("PrinterBlueprintCardMossmunk", true, false) as Control
	require(cinder_card != null and int(cinder_card.get_meta("price", -1)) == int(Catalog.rarity("common").print) and int(cinder_card.get_meta("owned_count", -1)) == 1, "starter card shows catalog price and exact owned count")
	require(moss_card != null and int(moss_card.get_meta("price", -1)) == int(Catalog.rarity("common").print) and int(moss_card.get_meta("owned_count", -1)) == 0 and moss_card.find_child("PrinterBlueprintIdleArt", true, false) != null, "non-starter card shows art, catalog price, and zero owned prints")
	require(GameManager.profile == profile_before_picker, "opening the picker and cards does not mutate profile authority")
	var moss_preview := main.find_child("PrinterPreviewMossmunk", true, false) as Button
	require(moss_preview != null, "non-starter Preview action is present")
	if moss_preview != null:
		moss_preview.emit_signal("pressed")
		await get_tree().process_frame
		await get_tree().process_frame
	require(main.screen == "printer" and main.printer_creature_id == "mossmunk" and main.printer_price == int(Catalog.rarity("common").print), "non-starter preview opens the exact selected Arcane Forge creature and price")
	require(GameManager.profile == profile_before_picker, "previewing a selected blueprint has no coin, inventory, or revision mutation")
	main.cancel_printer_preview()
	await get_tree().process_frame
	require(main.screen == "workshop" and main.workshop_view == "printer" and main.printer_picker_open, "Cancel Preview returns to the same Printer Blueprint Tray")
	var restored_profile: Dictionary = GameManager.profile.duplicate(true)
	GameManager.profile.blueprints = []
	main.open_printer_picker()
	await get_tree().process_frame
	require(main.find_child("PrinterBlueprintEmptyState", true, false) != null and main.find_child("PrinterBlueprintEmptyOffers", true, false) is Button, "empty Blueprint Tray explains the Forge Offers route")
	GameManager.profile = restored_profile
	main.close_printer_picker()
	await get_tree().process_frame
	main.open_workshop_view("maker")
	await get_tree().process_frame
	main.select_workshop_object("team_board")
	await get_tree().process_frame
	require(main.find_child("WorkshopContextDrawer", true, false) != null, "selecting a close-up object opens a compact contextual drawer")
	await escape(main)
	require(main.workshop_view == "maker" and main.workshop_drawer_object.is_empty(), "Escape closes the contextual drawer before leaving the close-up")
	await escape(main)
	require(main.workshop_view == "overview", "Escape from a close-up returns to the workshop overview")
	main.open_workshop_view("maker")
	main._run_workshop_station("deck")
	await get_tree().process_frame
	require(main.screen == "deck", "maker drawer actions retain the established deck route")
	await escape(main)
	require(main.screen == "workshop" and main.workshop_view == "maker", "Escape from a station returns to its launching close-up")
	await escape(main)
	require(main.workshop_view == "overview", "a second Escape returns from the launching close-up to overview")
	main.screen = "workshop"
	main.workshop_view = "printer"
	main._run_workshop_station("printer")
	await get_tree().process_frame
	require(main.screen == "workshop" and main.workshop_view == "printer" and main.printer_picker_open, "Printer station action opens selection rather than silently choosing the starter")
	main.close_printer_picker()
	for entry in [{"target":"collection", "screen":"collection"}, {"target":"team", "screen":"team"}, {"target":"deck", "screen":"deck"}, {"target":"armor", "screen":"armor"}, {"target":"calibration", "screen":"calibration"}, {"target":"shop", "screen":"shop"}, {"target":"codex", "screen":"codex"}, {"target":"trade", "screen":"trade"}, {"target":"yard", "screen":"yard"}]:
		main.screen = "workshop"
		main.workshop_view = "overview"
		main._run_workshop_station(str(entry.target))
		await get_tree().process_frame
		require(main.screen == str(entry.screen), "%s remains routed through the contextual station action" % str(entry.target))
	for viewport_size in [Vector2i(1280, 720), Vector2i(576, 1024), Vector2i(720, 1280)]:
		get_viewport().size = viewport_size
		main.size = Vector2(viewport_size)
		main.screen = "workshop"
		main.open_workshop_view("overview")
		await get_tree().process_frame
		await get_tree().process_frame
		map = main.find_child("WorkshopMap", true, false) as Control
		var expected_overview_path := "res://assets/ui/workshop/workshop_overview_portrait_v3.png" if viewport_size.y > viewport_size.x else "res://assets/ui/workshop/workshop_overview_landscape_v3.png"
		require(map != null and str(map.get_meta("workshop_stage_texture", "")) == expected_overview_path, "overview selects the distinct v3 stage plate for %s" % viewport_size)
		main.open_workshop_view("printer")
		await get_tree().process_frame
		var live_layer := main.find_child("WorkshopStationLiveLayer", true, false)
		require(live_layer != null and live_layer.station_id == "printer" and live_layer.is_processing(), "normal-motion live Printer station processes presentation only at %s" % viewport_size)
		var responsive_picker := main.find_child("PrinterBlueprintTrayButton", true, false) as Control
		require(responsive_picker != null and control_in_view(responsive_picker, viewport_size), "Choose a Print remains visible and touch-safe at %s" % viewport_size)
		main.open_workshop_view("overview")
		await get_tree().process_frame
		for zone_name in zone_names:
			var zone := main.find_child(str(zone_name), true, false) as Control
			require(zone != null and control_in_view(zone, viewport_size), "%s stays in bounds at %s (rect %s)" % [zone_name, viewport_size, zone.get_global_rect() if zone != null else Rect2()])
		main.open_workshop_view("maker")
		await get_tree().process_frame
		await get_tree().process_frame
		var closeup_map := main.find_child("WorkshopCloseupMap", true, false) as Control
		require(closeup_map != null and closeup_map.get_global_rect().position.x >= 0.0 and closeup_map.get_global_rect().end.x <= float(viewport_size.x), "close-up map stays horizontally bounded at %s" % viewport_size)
		if viewport_size.y > viewport_size.x:
			require(closeup_map != null and closeup_map.get_global_rect().size.y >= float(viewport_size.y) * 0.60, "portrait close-up materially fills the remaining scene at %s" % viewport_size)
		var maker_view: Dictionary = main._workshop_view_data("maker")
		for object in maker_view.objects:
			var hotspot := main.find_child("WorkshopObject%s" % str(object.id).capitalize(), true, false) as Button
			require(hotspot != null and hotspot.custom_minimum_size.x >= 44.0 and hotspot.custom_minimum_size.y >= 44.0, "%s keeps a valid close-up target at %s" % [str(object.id), viewport_size])
			require(hotspot != null and hotspot.find_child("WorkshopHotspotOverlay", true, false) != null, "%s uses a physical overlay at %s" % [str(object.id), viewport_size])
			if viewport_size.y > viewport_size.x and hotspot != null:
				hotspot.grab_focus()
				await get_tree().process_frame
				require(hotspot_in_map_view(hotspot, closeup_map), "%s focus pans it fully into the portrait map at %s (hotspot %s, map %s)" % [str(object.id), viewport_size, hotspot.get_global_rect(), closeup_map.get_global_rect()])
		if viewport_size.y > viewport_size.x:
			var pan_affordance := main.find_child("WorkshopPanAffordance", true, false) as Button
			require(pan_affordance != null and pan_affordance.text.is_empty() and pan_affordance.tooltip_text == "Swipe the workshop view to reach more tools", "portrait close-up has an accessible non-text pan affordance")
			main.open_workshop_view("terminal")
			await get_tree().process_frame
			var terminal_map := main.find_child("WorkshopCloseupMap", true, false) as Control
			var terminal_view: Dictionary = main._workshop_view_data("terminal")
			for object in terminal_view.objects:
				var terminal_hotspot := main.find_child("WorkshopObject%s" % str(object.id).capitalize(), true, false) as Button
				if terminal_hotspot != null:
					terminal_hotspot.grab_focus()
					await get_tree().process_frame
				require(terminal_hotspot != null and hotspot_in_map_view(terminal_hotspot, terminal_map), "%s focus pans it fully into the portrait map at %s" % [str(object.id), viewport_size])
			main.open_workshop_view("maker")
			await get_tree().process_frame
		require(get_viewport().gui_get_focus_owner() is Button, "render provides deterministic keyboard focus at %s" % viewport_size)
	GameManager.profile.settings.reduced_motion = true
	main.screen = "workshop"
	main.workshop_view = "printer"
	main.render()
	await get_tree().process_frame
	await get_tree().process_frame
	var reduced_live := main.find_child("WorkshopStationLiveLayer", true, false)
	require(reduced_live != null and not reduced_live.is_processing(), "reduced motion freezes the Printer station presentation (setting %s, layer %s, capture %s, processing %s)" % [main.settings().get("reduced_motion", false), reduced_live.reduced_motion if reduced_live != null else false, reduced_live.capture_frozen if reduced_live != null else false, reduced_live.is_processing() if reduced_live != null else false])
	main.workshop_view = "printer"
	main.workshop_drawer_object = ""
	main.render()
	await get_tree().process_frame
	await get_tree().process_frame
	var closeup_plane := main.find_child("WorkshopCloseupMapArtPlane", true, false)
	var ambient := closeup_plane.find_child("WorkshopAmbientLayer", true, false) if closeup_plane != null else null
	var frozen_phase: float = float(ambient.phase) if ambient != null else -1.0
	await get_tree().process_frame
	await get_tree().process_frame
	require(ambient != null and not bool(ambient.motion_enabled) and ambient.process_mode == Node.PROCESS_MODE_DISABLED and is_equal_approx(float(ambient.phase), frozen_phase), "reduced motion freezes workshop ambient processing")
	GameManager.profile.settings.reduced_motion = false
	var stable_coins: int = int(GameManager.profile.coins)
	var stable_revision: int = int(GameManager.profile.revision)
	main.workshop_view = "printer"
	main.workshop_drawer_object = ""
	main.render()
	await get_tree().process_frame
	var moving_plane := main.find_child("WorkshopCloseupMapArtPlane", true, false)
	var moving_ambient := moving_plane.find_child("WorkshopAmbientLayer", true, false) if moving_plane != null else null
	var moving_phase: float = float(moving_ambient.phase) if moving_ambient != null else -1.0
	await get_tree().create_timer(0.08).timeout
	require(moving_ambient != null and bool(moving_ambient.motion_enabled) and moving_ambient.process_mode != Node.PROCESS_MODE_DISABLED and not is_equal_approx(float(moving_ambient.phase), moving_phase), "normal motion advances the ambient phase")
	require(int(GameManager.profile.coins) == stable_coins and int(GameManager.profile.revision) == stable_revision, "ambient motion does not mutate profile or printer authority state")
	main.queue_free()
	if failures.is_empty(): print("PASS: spatial workshop navigation, nesting, accessibility, and responsive hotspots")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
