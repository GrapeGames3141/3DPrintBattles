extends Node

## Deterministic M7 P1 presentation guard. It exercises only the existing routes
## and presentation state; no button in this scene accepts a gameplay transaction.

const MAIN := preload("res://scenes/main.tscn")
const RULES := preload("res://scripts/core/unified_rules.gd")
const FORGE := preload("res://scripts/ui/arcane_forge_stage.gd")
const BATTLE_STAGE := preload("res://scripts/ui/physical_battlefield_stage.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _transparent_style(button: Button, key: String) -> bool:
	var style := button.get_theme_stylebox(key) as StyleBoxFlat
	return style != null and style.bg_color.a <= 0.01

func _ready() -> void:
	var starter_selected: Dictionary = RULES.choose_starter(RULES.new_profile(), "cinderpaw").profile
	GameManager.profile = starter_selected
	var viewport := SubViewport.new()
	viewport.size = Vector2i(576, 1024)
	viewport.size_2d_override = Vector2i(576, 1024)
	viewport.size_2d_override_stretch = true
	viewport.disable_3d = true
	add_child(viewport)
	var canvas := Control.new()
	canvas.size = Vector2(576, 1024)
	viewport.add_child(canvas)
	var main: Variant = MAIN.instantiate()
	canvas.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	await _first_print_cartridge(main)
	GameManager.profile = RULES.print_starter(starter_selected).profile
	await _deck_material_and_targets(main)
	await _workshop_hits(main)
	await _active_forge_instruments(main)
	await _reduced_motion_end_frame()
	if failures.is_empty():
		print("PASS: M7 first-print dock, deck parchment seats, workshop hits, forge instruments, and reduced-motion end frame")
	get_tree().quit(0 if failures.is_empty() else 1)

func _first_print_cartridge(main: Control) -> void:
	main.open_printer("cinderpaw")
	await get_tree().process_frame
	var dock := main.find_child("FirstPrintBlueprintDock", true, false) as Panel
	var paper_aperture := main.find_child("FirstPrintBlueprintPaperAperture", true, false) as Control
	var art := main.find_child("FirstPrintDockedBlueprint", true, false) as TextureRect
	var bed := main.find_child("FirstPrintEmptyBedProof", true, false) as Control
	var caption := main.find_child("FirstPrintDockCaption", true, false) as Label
	var dock_rect := dock.get_global_rect() if dock != null else Rect2()
	var aperture_rect := paper_aperture.get_global_rect() if paper_aperture != null else Rect2()
	var art_rect := art.get_global_rect() if art != null else Rect2()
	var caption_rect := caption.get_global_rect() if caption != null else Rect2()
	var caption_padding := minf(minf(caption_rect.position.x - aperture_rect.position.x, aperture_rect.end.x - caption_rect.end.x), minf(caption_rect.position.y - aperture_rect.position.y, aperture_rect.end.y - caption_rect.end.y))
	var caption_required_width := caption.get_minimum_size().x + 8.0 if caption != null else INF
	var dock_style := dock.get_theme_stylebox("panel") if dock != null else null
	var dock_material := art.material as ShaderMaterial if art != null else null
	require(dock != null and dock.clip_contents and dock_style is StyleBoxEmpty and paper_aperture != null and paper_aperture.clip_contents and art != null and art.texture != null and dock_material != null and is_equal_approx(float(dock_material.get_shader_parameter("ink_strength")), 0.82) and bool(art.get_meta("first_print_parchment_ink", false)) and caption != null and caption.text == "LOADED" and caption.get_theme_font_size("font_size") <= 7 and caption.autowrap_mode == TextServer.AUTOWRAP_OFF and dock_rect.encloses(aperture_rect) and aperture_rect.encloses(art_rect) and aperture_rect.encloses(caption_rect) and caption_padding >= 2.0 and caption_rect.size.x >= caption_required_width and art_rect.end.y <= caption_rect.position.y and dock_rect.size.x >= 48.0 and dock_rect.size.y >= 96.0 and not dock_rect.intersects(bed.get_global_rect()), "test_m7_first_print_cartridge_material keeps FirstPrintBlueprintDock as a transparent clipped cream-paper owner, encloses the ink and all six padded Loaded glyphs within its dedicated paper aperture, gives the native caption four-pixel side clearance, and keeps it above the brass lip (dock=%s aperture=%s art=%s caption=%s padding=%s required_width=%s)." % [str(dock_rect), str(aperture_rect), str(art_rect), str(caption_rect), str(caption_padding), str(caption_required_width)])

func _deck_material_and_targets(main: Control) -> void:
	main.screen = "unified_deck"
	main.render()
	await get_tree().process_frame
	var seats := main.find_children("Deck*BlueprintSeat*", "Control", true, false)
	var back := main.find_child("UnifiedFoundryWorkshopReturn", true, false) as Button
	var save := main.find_child("SaveActiveDeck", true, false) as Button
	var preprint := main.find_child("SavePrePrintLoadout", true, false) as Button
	var inspector_sheet := main.find_child("DeckInspectorLooseParchment", true, false) as Panel
	var inspector_count := main.find_child("DeckInspectorCount", true, false) as Label
	var inspector_count_seat := main.find_child("DeckInspectorCountSeat", true, false) as Panel
	var inspector_art := main.find_child("DeckInspectorCatalogArt", true, false) as TextureRect
	var legality := main.find_child("DeckLegalityStatus", true, false) as Label
	var parchment := true
	var deck_ink := true
	var treated_blueprints := 0
	for seat_variant in seats:
		var seat := seat_variant as Control
		parchment = parchment and seat != null and seat.clip_contents and not (seat is Panel)
	for art_variant in main.find_children("Deck*CatalogArt", "TextureRect", true, false):
		var deck_art := art_variant as TextureRect
		if bool(deck_art.get_meta("deck_blueprint_ink_treatment", false)):
			treated_blueprints += 1
			deck_ink = deck_ink and deck_art.material is ShaderMaterial
	var keycaps := back != null and save != null and preprint != null and back.get_theme_stylebox("normal") is StyleBoxTexture and save.get_theme_stylebox("normal") is StyleBoxTexture and preprint.get_theme_stylebox("normal") is StyleBoxTexture
	var count_is_separate := inspector_count != null and inspector_count_seat != null and inspector_art != null and not inspector_count.get_global_rect().intersects(inspector_art.get_global_rect()) and (inspector_count_seat.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a > 0.5
	require(not seats.is_empty() and parchment and treated_blueprints > 0 and deck_ink and inspector_sheet != null and inspector_sheet.clip_contents and inspector_sheet.get_theme_stylebox("panel") is StyleBoxFlat and keycaps and count_is_separate and legality != null and legality.text == "40 · LEGAL" and legality.accessibility_name.contains("40 cards") and back != null and save != null and preprint != null and back.get_global_rect().size.x >= 48.0 and back.get_global_rect().size.y >= 48.0 and save.get_global_rect().size.x >= 48.0 and save.get_global_rect().size.y >= 48.0 and preprint.get_global_rect().size.x >= 48.0 and preprint.get_global_rect().size.y >= 48.0, "test_m7_deck_blueprint_material_and_targets keeps blueprint seats transparent over authored parchment, uses one square clipped inspector sheet plus a separate readable count fact, and applies full-size Foundry keycaps to Back, Save, and Pre-Print.")

func _workshop_hits(main: Control) -> void:
	main.screen = "workshop"
	main.render()
	await get_tree().process_frame
	var expected := ["WorkshopHotspotPrinter", "WorkshopHotspotBattleArena", "WorkshopHotspotCardArchive", "WorkshopHotspotDeck", "WorkshopHotspotSupplies", "WorkshopHotspotSettings"]
	var all_transparent := true
	var all_inset := true
	for node_name in expected:
		var button := main.find_child(node_name, true, false) as Button
		var ring := button.find_child("WorkshopHotspotTightFocusRing", true, false) as Panel if button != null else null
		all_transparent = all_transparent and button != null and _transparent_style(button, "normal") and _transparent_style(button, "focus") and _transparent_style(button, "pressed")
		all_inset = all_inset and ring != null and ring.anchor_left > 0.0 and ring.anchor_top > 0.0 and ring.anchor_right < 1.0 and ring.anchor_bottom < 1.0 and ring.get_theme_stylebox("panel") is StyleBoxEmpty and ring.get_child_count() == 4
	var printer := main.find_child("WorkshopHotspotPrinter", true, false) as Button
	var printer_ring := printer.find_child("WorkshopHotspotTightFocusRing", true, false) as Panel if printer != null else null
	var printer_bed_ring := printer != null and printer_ring != null and printer_ring.get_global_rect().size.x >= 48.0 and printer_ring.get_global_rect().size.y >= 48.0 and printer_ring.get_global_rect().size.x >= printer.get_global_rect().size.x * 0.40 and printer_ring.get_global_rect().size.x <= printer.get_global_rect().size.x * 0.46 and printer_ring.get_global_rect().size.y >= printer.get_global_rect().size.y * 0.15 and printer_ring.get_global_rect().size.y <= printer.get_global_rect().size.y * 0.20
	require(all_transparent and all_inset and printer_bed_ring, "test_m7_workshop_physical_hit_regions keeps all six authored Workshop objects transparent with four transparent-center edge rings, and traces the full Printer build-bed inset rather than a generic chamber rectangle.")

func _active_forge_instruments(main: Variant) -> void:
	# Seed presentation only: no print transaction is invoked for the 60% route.
	main.screen = "printer"
	main.printer_creature_id = "cinderpaw"
	main.printer_sequence = ArcaneForgeSequence.create(false)
	main.printer_sequence.begin()
	main.printer_sequence.progress_bps = 4200
	main.render()
	await get_tree().process_frame
	var shell := main.find_child("FeedbackForgeStage", true, false) as PanelContainer
	var readout := main.find_child("ForgeActiveReadout", true, false) as PanelContainer
	var rail := main.find_child("ForgeActiveRail", true, false) as PanelContainer
	var skip := main.find_child("SkipPrinterAnimation", true, false) as Button
	var progress := main.find_child("PrinterProgressBar", true, false) as ProgressBar
	var shell_style := shell.get_theme_stylebox("panel") if shell != null else null
	var readout_style := readout.get_theme_stylebox("panel") as StyleBoxFlat if readout != null else null
	var rail_style := rail.get_theme_stylebox("panel") as StyleBoxFlat if rail != null else null
	var physical_progress := progress != null and progress.get_theme_stylebox("background") is StyleBoxTexture and progress.get_theme_stylebox("fill") is StyleBoxFlat
	var compact_skip := skip != null and skip.custom_minimum_size.x >= 56.0 and skip.get_theme_stylebox("normal") is StyleBoxTexture and skip.get_global_rect().size.x < rail.get_global_rect().size.x * 0.45
	require(shell != null and shell_style is StyleBoxEmpty and shell.anchor_left <= 0.03 and shell.anchor_right >= 0.97 and shell.anchor_bottom >= 0.79 and shell.anchor_bottom <= 0.81 and readout_style != null and rail_style != null and rail.anchor_top >= 0.80 and rail.anchor_top <= 0.81 and rail.anchor_bottom >= 0.93 and rail.anchor_bottom <= 0.95 and readout_style.border_color.r > readout_style.border_color.b and rail_style.border_color.r > rail_style.border_color.b and physical_progress and compact_skip, "test_m7_active_print_physical_instruments keeps the active stage transparent over the Workshop, then seats its brass/navy progress instrument and compact Skip keycap directly below a dominant 60% printer with no deep bottom void.")
	var forge := FORGE.new()
	forge.size = Vector2(576, 700)
	add_child(forge)
	forge.configure("cinderpaw", false, false)
	forge.set_preview_phase(ArcaneForgeSequence.PRINTING, 4200)
	await get_tree().process_frame
	require(forge._last_scan_count == 1 and forge._last_solid_rect.size.y > 0.0 and forge._last_wireframe_rect.size.y > 0.0 and forge._last_wireframe_rect.size.x > 100.0, "test_m7_active_print_physical_instruments keeps the exact 60% split and a dominant physical printer footprint.")
	var forge_source := FileAccess.get_file_as_string("res://scripts/ui/arcane_forge_stage.gd")
	require(not forge_source.contains("draw_rect(printer_rect.grow") and forge_source.contains("draw_rect(plate.grow(2.0)"), "test_m7_active_print_physical_instruments rejects a full-printer contrast border and requires the local build-aperture cue.")

func _reduced_motion_end_frame() -> void:
	var stage := BATTLE_STAGE.new()
	stage.size = Vector2(576, 1024)
	add_child(stage)
	stage.configure({"players":[{"slots":[{"card_id":"cinderpaw","name":"Cinderpaw","hp":100}],"hand":["cinderpaw"],"printer":{"hp":2000,"max_hp":2000}},{"slots":[null,{"card_id":"aquafin","name":"Aquafin","hp":75}],"hand_count":3,"printer":{"hp":1900,"max_hp":2000}}]}, {"kind":"attack","actor":0,"source_slot":0,"target_slot":1,"reduced_motion":true,"generation":91})
	await get_tree().process_frame
	var overlay := stage.find_child("BattleContactPeakOverlay", true, false) as TextureRect
	var attacker := stage.find_child("LivingPrintSlot0", true, false) as TextureRect
	var target := stage.find_child("LivingPrintSlot4", true, false) as TextureRect
	var attacker_caption := stage.find_child("LivingPrintCaption0", true, false) as Label
	var target_caption := stage.find_child("LivingPrintCaption4", true, false) as Label
	require(overlay != null and not overlay.visible and attacker != null and attacker.visible and attacker.position.is_zero_approx() and target != null and target.visible and attacker_caption != null and attacker_caption.visible and target_caption != null and target_caption.visible, "test_m7_reduced_motion_battle_end_readability keeps Cinderpaw at home and damaged Aquafin readable without contact overlay or trail.")
