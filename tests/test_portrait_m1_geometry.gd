extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _complete_profile() -> Dictionary:
	var profile := RULES.new_profile()
	profile = RULES.choose_starter(profile, "cinderpaw").profile
	return RULES.print_starter(profile).profile

func _in_bounds(control: Control, max_bottom: float, width: float) -> bool:
	if control == null or not control.is_visible_in_tree(): return false
	var rect := control.get_global_rect()
	return rect.position.x >= -0.5 and rect.end.x <= width + 0.5 and rect.end.y <= max_bottom + 0.5

func _inside_safe_top(control: Control, inset: float, viewport: Vector2) -> bool:
	if not _in_bounds(control, viewport.y, viewport.x): return false
	return control.get_global_rect().position.y >= inset - 0.5

func _mount(viewport: Vector2, stress: bool) -> Dictionary:
	var subviewport := SubViewport.new()
	subviewport.size = Vector2i(viewport)
	subviewport.size_2d_override = Vector2i(viewport)
	subviewport.size_2d_override_stretch = true
	subviewport.disable_3d = true
	add_child(subviewport)
	var canvas := Control.new()
	canvas.size = viewport
	subviewport.add_child(canvas)
	var main := MAIN.instantiate()
	main.screen = "title"
	if stress: main.set_meta("synthetic_admob_overlay_stress", true)
	canvas.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	return {"subviewport":subviewport, "main":main}

func _test_viewport(viewport: Vector2, stress: bool) -> void:
	GameManager.profile = RULES.new_profile()
	var mounted := await _mount(viewport, stress)
	var main: Control = mounted.main
	var subviewport: SubViewport = mounted.subviewport
	var max_bottom := viewport.y - (96.0 if viewport.x == 576.0 and stress else 120.0 if viewport.x == 720.0 and stress else 180.0 if stress else 0.0)
	var enter := main.find_child("TitleContinue", true, false) as Button
	var settings := main.find_child("TitleSettings", true, false) as Button
	var version := main.find_child("TitleStatusVersion", true, false) as Label
	require(enter != null and settings != null and version != null, "Title supplies native enter, settings, and version nodes at %s." % viewport)
	require(enter != null and enter.custom_minimum_size.y >= 56.0 and _in_bounds(enter, max_bottom, viewport.x), "Title primary is touch-safe and above the content boundary at %s." % viewport)
	require(settings != null and settings.custom_minimum_size.y >= 48.0 and _in_bounds(settings, max_bottom, viewport.x), "Title settings is touch-safe and above the content boundary at %s." % viewport)
	require(version != null and _in_bounds(version, max_bottom, viewport.x), "Title native status remains above the content boundary at %s." % viewport)
	var title_plate := main.find_child("TitlePortraitPlate", true, false) as Control
	var title_content := main.find_child("PhysicalPlateContentLayer", true, false) as Control
	require(title_plate != null and title_content != null and title_content.size.x > 0.0 and title_content.size.y > 0.0, "Title physical plate exposes a nonzero native content layer at %s." % viewport)
	if title_plate != null and title_content != null:
		require(title_content.size.is_equal_approx(title_plate.fit_rect().size), "Title native layer matches fitted plate geometry at %s." % viewport)
	if stress:
		var band := main.find_child("SyntheticAdMobOverlayStress", true, false) as ColorRect
		var stress_label := main.find_child("SyntheticAdMobOverlayStressLabel", true, false) as Label
		require(band != null and stress_label != null and "Synthetic overlay stress" in stress_label.text, "Opt-in stress fixture mounts its explicit native label at %s." % viewport)
	else:
		require(main.find_child("SyntheticAdMobOverlayStress", true, false) == null, "Production title has no synthetic banner band at %s." % viewport)
	GameManager.profile = _complete_profile()
	main.screen = "workshop"
	main.workshop_view = "overview"
	main.render()
	await get_tree().process_frame
	var buttons := main.find_children("WorkshopHotspot*", "Button", true, false)
	require(buttons.size() == 6, "Workshop renders exactly six physical station hotspots at %s." % viewport)
	for prop_suffix in ["BattleArena", "CardArchive", "Deck", "Supplies", "Settings"]:
		var prop := main.find_child("WorkshopR2Prop%s" % prop_suffix, true, false) as TextureRect
		var station_label := main.find_child("WorkshopStationLabel%s" % prop_suffix, true, false) as Label
		require(prop != null and prop.mouse_filter == Control.MOUSE_FILTER_IGNORE and station_label != null and not station_label.text.is_empty(), "Approved R2 %s prop has passive art plus a native station label at %s." % [prop_suffix, viewport])
	for hotspot_name in ["WorkshopHotspotPrinter", "WorkshopHotspotBattleArena", "WorkshopHotspotCardArchive", "WorkshopHotspotDeck", "WorkshopHotspotSupplies", "WorkshopHotspotSettings"]:
		var hotspot := main.find_child(hotspot_name, true, false) as Button
		require(hotspot != null and not hotspot.accessibility_name.is_empty() and hotspot.focus_mode != Control.FOCUS_NONE, "%s is a native accessible focus target at %s." % [hotspot_name, viewport])
		if hotspot != null:
			require(hotspot.custom_minimum_size.x >= 48.0 and hotspot.custom_minimum_size.y >= 48.0 and _in_bounds(hotspot, max_bottom - (28.0 if stress else 0.0), viewport.x), "%s is touch-safe and inside its visual content boundary at %s." % [hotspot_name, viewport])
			var ring := hotspot.find_child("WorkshopHotspotTightFocusRing", true, false) as Panel
			require(ring != null and int(ring.get_meta("focus_stroke_width", 0)) == 3 and ring.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s owns a tight 3px native focus ring at %s." % [hotspot_name, viewport])
			if ring != null:
				for edge in ["Top", "Right", "Bottom", "Left"]:
					var stroke := ring.find_child("WorkshopHotspotTightFocusStroke%s" % edge, true, false) as Control
					require(stroke != null and stroke.mouse_filter == Control.MOUSE_FILTER_IGNORE and stroke.get_rect().size.x > 0.0 and stroke.get_rect().size.y > 0.0, "%s focus %s stroke is attached, passive, and nonzero at %s." % [hotspot_name, edge, viewport])
	require(main.find_child("WorkshopR2PropHotspotSheet", true, false) == null, "Rejected workshop hotspot sheet is absent at %s." % viewport)
	if stress:
		var band := main.find_child("SyntheticAdMobOverlayStress", true, false) as ColorRect
		var stress_label := main.find_child("SyntheticAdMobOverlayStressLabel", true, false) as Label
		require(band != null and stress_label != null, "Workshop keeps the opt-in labeled stress fixture at %s." % viewport)
	else:
		require(main.find_child("SyntheticAdMobOverlayStress", true, false) == null, "Production Workshop has no synthetic banner band at %s." % viewport)
	main.queue_free()
	await get_tree().process_frame
	subviewport.queue_free()
	await get_tree().process_frame

func _test_safe_top(viewport: Vector2) -> void:
	var inset := 84.0
	GameManager.profile = RULES.new_profile()
	var mounted := await _mount(viewport, false)
	var main: Control = mounted.main
	var subviewport: SubViewport = mounted.subviewport
	main.set_meta("presentation_safe_top_inset", inset)
	main.render()
	await get_tree().process_frame
	require(_inside_safe_top(main.find_child("TitleContinue", true, false) as Control, inset, viewport), "Safe-top Title control stays below the inset at %s." % viewport)
	GameManager.profile = _complete_profile()
	main.screen = "workshop"; main.render()
	await get_tree().process_frame
	require(_inside_safe_top(main.find_child("WorkshopHotspotPrinter", true, false) as Control, inset, viewport), "Safe-top Workshop hotspot stays below the inset at %s." % viewport)
	GameManager.profile = RULES.new_profile()
	main.screen = "onboarding"; main.render()
	await get_tree().process_frame
	require(_inside_safe_top(main.find_child("StarterConfirmFocused", true, false) as Control, inset, viewport), "Safe-top Starter confirm stays below the inset at %s." % viewport)
	main.starter_inspector_id = "cinderpaw"; main.render()
	await get_tree().process_frame
	require(_inside_safe_top(main.find_child("StarterInspectorClose", true, false) as Control, inset, viewport), "Safe-top Starter inspector action stays below the inset at %s." % viewport)
	GameManager.profile = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	require(_inside_safe_top(main.find_child("BeginCreaturePrint", true, false) as Control, inset, viewport), "Safe-top First Print action stays below the inset at %s." % viewport)
	main.queue_free(); await get_tree().process_frame
	subviewport.queue_free(); await get_tree().process_frame

func _ready() -> void:
	for viewport in [Vector2(576, 1024), Vector2(720, 1280), Vector2(1080, 2400)]:
		await _test_viewport(viewport, false)
		await _test_viewport(viewport, true)
	for viewport in [Vector2(576, 1024), Vector2(1080, 2400)]:
		await _test_safe_top(viewport)
	if failures.is_empty(): print("PASS: M1 title and Workshop geometry")
	get_tree().quit(0 if failures.is_empty() else 1)
