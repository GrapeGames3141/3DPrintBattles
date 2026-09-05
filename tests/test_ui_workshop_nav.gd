extends Node

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const PROFILES := preload("res://tests/m9_test_profile_factory.gd")

const PORTRAIT_SIZES := [Vector2i(576, 1024), Vector2i(720, 1280)]
const WORKSHOP_ROUTES := {
	"WorkshopHotspotPrinter": "printer",
	"WorkshopHotspotBattleArena": "proving",
	"WorkshopHotspotCardArchive": "unified_library",
	"WorkshopHotspotDeck": "unified_deck",
	"WorkshopHotspotSupplies": "unified_market",
	"WorkshopHotspotSettings": "settings",
}

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	await _run()

func _completed_profile() -> Dictionary:
	var profile: Dictionary = PROFILES.founder_ready("cinderpaw")
	RULES.grant_card(profile, "mossmunk")
	profile.forge_coins = 500
	return profile

func _profile_snapshot() -> String:
	return var_to_str(GameManager.profile)

func _mount(viewport_size: Vector2i, profile: Dictionary) -> Dictionary:
	GameManager.profile = profile.duplicate(true)
	GameManager.save_compatibility = {"compatible": true, "state": "ready"}
	var subviewport := SubViewport.new()
	subviewport.size = viewport_size
	subviewport.size_2d_override = viewport_size
	subviewport.size_2d_override_stretch = true
	subviewport.disable_3d = true
	add_child(subviewport)
	var canvas := Control.new()
	canvas.size = Vector2(viewport_size)
	subviewport.add_child(canvas)
	var main := MAIN.instantiate()
	# Tests mount the selected route directly. A completed profile is intentionally
	# not expected to bypass Title in production startup.
	main.screen = "workshop"
	main.workshop_view = "overview"
	canvas.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	# The fixture drives terminal phases directly below. Keep layout-frame waits
	# from advancing its accepted presentation behind exact state assertions.
	main.set_process(false)
	return {"main": main, "subviewport": subviewport}

func _unmount(mounted: Dictionary) -> void:
	var main = mounted.get("main")
	if is_instance_valid(main):
		main.queue_free()
	await get_tree().process_frame
	var subviewport := mounted.get("subviewport") as SubViewport
	if is_instance_valid(subviewport):
		subviewport.queue_free()
	await get_tree().process_frame

func _in_view(control: Control, subviewport: SubViewport) -> bool:
	if control == null or not control.is_visible_in_tree():
		return false
	var rect := control.get_global_rect()
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(subviewport.size))
	return rect.position.x >= viewport_rect.position.x and rect.position.y >= viewport_rect.position.y and rect.end.x <= viewport_rect.end.x and rect.end.y <= viewport_rect.end.y

func _target_ok(button: Button, subviewport: SubViewport) -> bool:
	if button == null:
		return false
	var rect := button.get_global_rect()
	return _in_view(button, subviewport) and button.focus_mode != Control.FOCUS_NONE and rect.size.x >= 48.0 and rect.size.y >= 48.0 and not button.tooltip_text.is_empty() and not button.accessibility_name.is_empty()

func _forge_target_ok(button: Button, subviewport: SubViewport) -> bool:
	if button == null:
		return false
	var rect := button.get_global_rect()
	return _in_view(button, subviewport) and button.focus_mode != Control.FOCUS_NONE and rect.size.x >= 48.0 and rect.size.y >= 48.0

func _escape(main) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = KEY_ESCAPE
	main._unhandled_key_input(event)
	await get_tree().process_frame

func _tap(subviewport: SubViewport, button: Button) -> bool:
	if button == null or not _forge_target_ok(button, subviewport):
		return false
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	subviewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = point
	press.global_position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	subviewport.push_input(press, true)
	var release := InputEventMouseButton.new()
	release.position = point
	release.global_position = point
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	subviewport.push_input(release, true)
	await get_tree().process_frame
	return true

func _native_forge_recipe_matches(main, id: String) -> bool:
	var definition: Dictionary = RULES.card(id)
	var recipe := main.find_child("ForgeRecipeInstrument", true, false) as Label
	var expected_price := int(RULES.WORKSHOP_PRINT_COSTS.get(str(definition.get("rarity", "common")), -1))
	return recipe != null and recipe.text.contains(str(definition.get("name", id))) and recipe.text.contains("%d FC" % expected_price)

func _cycle_to_blueprint(main, subviewport: SubViewport, target_id: String, learned_count: int) -> bool:
	# The native cartridge is cyclic. Bound this to the live learned list so an
	# unexpected selection can never turn a fixture failure into an endless loop.
	for _step in range(maxi(1, learned_count)):
		if main.printer_creature_id == target_id:
			return true
		var next := main.find_child("PrinterSelectNext", true, false) as Button
		var tapped: bool = await _tap(subviewport, next)
		if not tapped:
			return false
	return main.printer_creature_id == target_id

func _assert_workshop_owners(main, subviewport: SubViewport, viewport_size: Vector2i) -> void:
	var plate := main.find_child("WorkshopPortraitPlate", true, false) as Control
	var full_bleed := main.find_child("WorkshopFullBleed", true, false) as Control
	var progress := main.find_child("WorkshopProgressInstrument", true, false) as Control
	require(plate != null and full_bleed != null and progress != null and _in_view(plate, subviewport) and _in_view(full_bleed, subviewport) and _in_view(progress, subviewport), "Portrait Workshop owns its plate, full-bleed scenery, and compact progress instrument at %s." % viewport_size)
	var actual: Array = main.find_children("WorkshopHotspot*", "Button", true, false)
	require(actual.size() == WORKSHOP_ROUTES.size(), "Workshop exposes exactly six canonical physical Button owners at %s, got %d." % [viewport_size, actual.size()])
	for node_name in WORKSHOP_ROUTES:
		var button := main.find_child(str(node_name), true, false) as Button
		require(button != null and button.text.is_empty() and _target_ok(button, subviewport) and full_bleed.is_ancestor_of(button), "%s is an empty-text, focusable, accessible 48px physical target inside WorkshopFullBleed at %s." % [node_name, viewport_size])
		if button == null:
			continue
		var suffix := str(node_name).trim_prefix("WorkshopHotspot")
		var station_label := main.find_child("WorkshopStationLabel" + suffix, true, false) as Label
		require(station_label != null and button.get_global_rect().encloses(station_label.get_global_rect()), "%s native label is fully seated in its owning authored object at %s." % [node_name, viewport_size])
		var ring := button.find_child("WorkshopHotspotTightFocusRing", true, false) as Panel
		require(ring != null and ring.get_theme_stylebox("panel") is StyleBoxEmpty, "%s focus ring keeps a transparent center at %s." % [node_name, viewport_size])
		for edge in ["Top", "Right", "Bottom", "Left"]:
			var stroke := button.find_child("WorkshopHotspotTightFocusStroke" + edge, true, false) as Control
			require(stroke != null and stroke.mouse_filter == Control.MOUSE_FILTER_IGNORE and stroke.size.x > 0.0 and stroke.size.y > 0.0, "%s has a nonzero mouse-ignore %s focus stroke at %s." % [node_name, edge, viewport_size])

func _assert_workshop_dispatch(main, subviewport: SubViewport, base_profile: Dictionary) -> void:
	for node_name in WORKSHOP_ROUTES:
		GameManager.profile = base_profile.duplicate(true)
		main.screen = "workshop"
		main.workshop_view = "overview"
		main.render()
		await get_tree().process_frame
		var button := main.find_child(str(node_name), true, false) as Button
		require(_target_ok(button, subviewport), "%s stays dispatchable after a clean Workshop rerender." % node_name)
		if button != null:
			button.emit_signal("pressed")
			await get_tree().process_frame
			require(main.screen == str(WORKSHOP_ROUTES[node_name]), "%s dispatches directly to %s." % [node_name, WORKSHOP_ROUTES[node_name]])
	GameManager.profile = base_profile.duplicate(true)
	main.screen = "workshop"
	main.workshop_view = "overview"
	main.render()
	await get_tree().process_frame
	var before_unknown := _profile_snapshot()
	var revision_before_unknown := int(GameManager.profile.get("revision", 0))
	main._run_workshop_station("unavailable_fixture")
	await get_tree().process_frame
	require(main.screen == "workshop" and main.toast.to_lower().contains("unavailable") and _profile_snapshot() == before_unknown and int(GameManager.profile.get("revision", 0)) == revision_before_unknown, "Unavailable Workshop station remains on the physical hub with a native reason and zero profile mutation.")

func _assert_integrated_forge(main, subviewport: SubViewport, base_profile: Dictionary, viewport_size: Vector2i) -> void:
	GameManager.profile = base_profile.duplicate(true)
	main.screen = "workshop"
	main.workshop_view = "overview"
	main.render()
	await get_tree().process_frame
	var before_open := _profile_snapshot()
	main.open_printer_picker()
	await get_tree().process_frame
	await get_tree().process_frame
	var cartridge := main.find_child("ForgeBlueprintCartridgeAperture", true, false) as Control
	var previous := main.find_child("PrinterSelectPrevious", true, false) as Button
	var next := main.find_child("PrinterSelectNext", true, false) as Button
	var begin := main.find_child("BeginCreaturePrint", true, false) as Button
	var back := main.find_child("ArcaneForgeBack", true, false) as Button
	var learned_ids: Array[String] = main.printer_blueprint_ids()
	require(main.screen == "printer" and main.printer_sequence != null and main.printer_sequence.phase == ArcaneForgeSequence.IDLE and cartridge != null and _in_view(cartridge, subviewport), "Idle integrated Forge exposes one in-bounds ForgeBlueprintCartridgeAperture at %s." % viewport_size)
	require(learned_ids.has("cinderpaw") and learned_ids.has("mossmunk") and _forge_target_ok(previous, subviewport) and _forge_target_ok(next, subviewport) and not previous.get_global_rect().intersects(next.get_global_rect()) and _forge_target_ok(begin, subviewport) and _forge_target_ok(back, subviewport) and _native_forge_recipe_matches(main, main.printer_creature_id), "Integrated Forge exposes one native cartridge with non-overlapping focusable 48px Previous/Next selectors, current blueprint/price, Begin, and Back at %s." % viewport_size)
	require(main.find_child("WorkshopCloseupMap", true, false) == null and main.find_child("WorkshopStationLiveLayer", true, false) == null and main.find_child("PrinterBlueprintTray", true, false) == null and main.find_child("PrinterBlueprintDetail", true, false) == null and main.find_child("PrinterPreviewMossmunk", true, false) == null, "Integrated Forge has no retired close-up, tray, duplicate detail, or preview owner.")
	var expected_price := int(RULES.WORKSHOP_PRINT_COSTS.get(str(Catalog.creature("mossmunk").get("rarity", "common")), -1))
	# Prove both cartridge directions through real input before searching a fixture
	# with potentially more learned founder blueprints than the two named cards.
	var initial_selection: String = main.printer_creature_id
	var tapped_next: bool = await _tap(subviewport, next)
	var after_next: String = main.printer_creature_id
	previous = main.find_child("PrinterSelectPrevious", true, false) as Button
	var tapped_previous: bool = await _tap(subviewport, previous)
	require(tapped_next and tapped_previous and after_next != initial_selection and main.printer_creature_id == initial_selection and _profile_snapshot() == before_open, "Actual cartridge Previous is the inverse of a real Next selection with zero profile mutation.")
	var found_moss := await _cycle_to_blueprint(main, subviewport, "mossmunk", learned_ids.size())
	require(found_moss and main.printer_creature_id == "mossmunk" and main.printer_price == expected_price and _native_forge_recipe_matches(main, "mossmunk") and _profile_snapshot() == before_open, "Actual cartridge Next selection cycles to Mossmunk and updates only native Forge price/selection with zero profile mutation.")
	var restored_cinder := await _cycle_to_blueprint(main, subviewport, "cinderpaw", learned_ids.size())
	require(restored_cinder and main.printer_creature_id == "cinderpaw" and _native_forge_recipe_matches(main, "cinderpaw") and _profile_snapshot() == before_open, "Actual cartridge selection cycles back to Cinderpaw with its native current definition and price.")
	found_moss = await _cycle_to_blueprint(main, subviewport, "mossmunk", learned_ids.size())
	require(found_moss and main.printer_creature_id == "mossmunk", "Actual cartridge selection restores Mossmunk before its print lifecycle assertion.")
	begin = main.find_child("BeginCreaturePrint", true, false) as Button
	if begin != null:
		await _tap(subviewport, begin)
	await get_tree().process_frame
	require(main.printer_sequence != null and main.printer_sequence.phase == ArcaneForgeSequence.PRINTING and main.find_child("PrinterSelectPrevious", true, false) == null and main.find_child("PrinterSelectNext", true, false) == null and main.find_child("ForgeBlueprintCartridgeAperture", true, false) != null, "Begin enters PRINTING, hides the cartridge selectors, and retains the cartridge art.")
	var accepted_sequence: Variant = main.printer_sequence
	var accepted_progress: int = int(main.printer_sequence.progress_bps)
	await _escape(main)
	require(main.screen == "workshop" and main.printer_sequence != null and main.printer_sequence.phase == ArcaneForgeSequence.PRINTING, "Escape pauses an active Forge print at its safe caller without cancelling it.")
	var resume := main.find_child("WorkshopHotspotPrinter", true, false) as Button
	var tapped_resume: bool = await _tap(subviewport, resume)
	require(tapped_resume and main.screen == "printer" and main.printer_sequence == accepted_sequence and int(main.printer_sequence.progress_bps) == accepted_progress, "Actual Workshop printer hotspot resumes the accepted Forge sequence before terminal projection.")
	main.printer_sequence.phase = ArcaneForgeSequence.AWAKENED
	main.render()
	await get_tree().process_frame
	var another := main.find_child("ForgeTerminalPrimary", true, false) as Button
	require(another != null and another.text.contains("PRINT"), "Completed Forge exposes its native Print Another terminal action.")
	if another != null:
		await _tap(subviewport, another)
	await get_tree().process_frame
	require(main.screen == "printer" and main.printer_sequence != null and main.printer_sequence.phase == ArcaneForgeSequence.IDLE and main.printer_creature_id == "mossmunk" and main.find_child("ForgeBlueprintCartridgeAperture", true, false) != null and main.find_child("PrinterSelectPrevious", true, false) != null and main.find_child("PrinterSelectNext", true, false) != null and _native_forge_recipe_matches(main, "mossmunk"), "Awakened Print Another restores the same native cartridge selection and idle Forge controls.")
	await _escape(main)
	require(main.screen == "workshop" and main.workshop_view == "overview", "Idle Forge Escape returns to Workshop overview.")

func _run() -> void:
	var base_profile := _completed_profile()
	require(RULES.has_printable_blueprint(base_profile, "mossmunk"), "Workshop Forge fixture owns the learned Mossmunk blueprint.")
	for viewport_size in PORTRAIT_SIZES:
		var mounted := await _mount(viewport_size, base_profile)
		var main = mounted.get("main")
		var subviewport := mounted.get("subviewport") as SubViewport
		_assert_workshop_owners(main, subviewport, viewport_size)
		await _assert_workshop_dispatch(main, subviewport, base_profile)
		await _assert_integrated_forge(main, subviewport, base_profile, viewport_size)
		await _unmount(mounted)
	if failures.is_empty():
		print("PASS: portrait physical Workshop navigation and integrated Forge")
	get_tree().quit(0 if failures.is_empty() else 1)
