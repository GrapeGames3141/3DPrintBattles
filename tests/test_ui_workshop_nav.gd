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

func _ready() -> void:
	var profile: Dictionary = ProfileRules.choose_starter(ProfileRules.new_profile(), "cinderpaw").profile
	profile.coins = 500
	GameManager.profile = profile
	var main := MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	require(main.screen == "workshop" and main.workshop_view == "overview", "new selected profile opens the workshop overview")
	var map := main.find_child("WorkshopMap", true, false) as Control
	require(map != null, "overview has a dedicated spatial workshop map")
	var zone_names := ["WorkshopZonePrinter", "WorkshopZoneMaker", "WorkshopZoneTerminal", "WorkshopZoneProving", "WorkshopZoneYard"]
	for zone_name in zone_names:
		var zone := main.find_child(str(zone_name), true, false) as Button
		require(zone != null and zone.text.is_empty() and not zone.tooltip_text.is_empty() and not zone.accessibility_name.is_empty(), "%s is an accessible unlabeled spatial zone" % zone_name)
		require(zone != null and zone.custom_minimum_size.x >= 44.0 and zone.custom_minimum_size.y >= 44.0, "%s preserves a 44-unit target" % zone_name)
	for view_id in ["printer", "maker", "terminal", "proving", "yard"]:
		main.open_workshop_view(view_id)
		await get_tree().process_frame
		var closeup := main.find_child("WorkshopCloseupMap", true, false) as Control
		require(main.workshop_view == view_id and closeup != null and main.find_child("WorkshopOverviewButton", true, false) is Button, "%s opens a close-up with an overview return" % view_id)
		var view: Dictionary = main._workshop_view_data(view_id)
		for object in view.objects:
			var object_button := main.find_child("WorkshopObject%s" % str(object.id).capitalize(), true, false) as Button
			require(object_button != null and object_button.text.is_empty() and not object_button.accessibility_name.is_empty(), "%s object hotspot is accessible without a plaque" % str(object.id))
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
	for entry in [{"target":"printer", "screen":"printer"}, {"target":"collection", "screen":"collection"}, {"target":"team", "screen":"team"}, {"target":"deck", "screen":"deck"}, {"target":"armor", "screen":"armor"}, {"target":"calibration", "screen":"calibration"}, {"target":"shop", "screen":"shop"}, {"target":"codex", "screen":"codex"}, {"target":"trade", "screen":"trade"}, {"target":"yard", "screen":"yard"}]:
		main.screen = "workshop"
		main.workshop_view = "overview"
		main._run_workshop_station(str(entry.target))
		await get_tree().process_frame
		require(main.screen == str(entry.screen), "%s remains routed through the contextual station action" % str(entry.target))
	for viewport_size in [Vector2i(1280, 720), Vector2i(720, 1280)]:
		get_viewport().size = viewport_size
		main.screen = "workshop"
		main.open_workshop_view("overview")
		await get_tree().process_frame
		for zone_name in zone_names:
			var zone := main.find_child(str(zone_name), true, false) as Control
			require(zone != null and control_in_view(zone, viewport_size), "%s stays in bounds at %s" % [zone_name, viewport_size])
		main.open_workshop_view("maker")
		await get_tree().process_frame
		var maker_view: Dictionary = main._workshop_view_data("maker")
		for object in maker_view.objects:
			var hotspot := main.find_child("WorkshopObject%s" % str(object.id).capitalize(), true, false) as Control
			require(hotspot != null and control_in_view(hotspot, viewport_size), "%s stays in close-up bounds at %s" % [str(object.id), viewport_size])
		require(get_viewport().gui_get_focus_owner() is Button, "render provides deterministic keyboard focus at %s" % viewport_size)
	main.queue_free()
	if failures.is_empty(): print("PASS: spatial workshop navigation, nesting, accessibility, and responsive hotspots")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
