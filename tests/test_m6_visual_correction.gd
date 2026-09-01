extends Node

const PLATE := preload("res://scripts/ui/physical_portrait_plate_presenter.gd")
const FORGE := preload("res://scripts/ui/arcane_forge_stage.gd")
const STAGE := preload("res://scripts/ui/physical_battlefield_stage.gd")
const CARD := preload("res://scripts/ui/unified_card_view.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	var tall := PLATE.composition_rect(Vector2(1080, 2400), Vector2(941, 1672))
	var standard := PLATE.composition_rect(Vector2(576, 1024), Vector2(941, 1672))
	require(tall.position.is_zero_approx() and tall.size == Vector2(1080, 2400), "M6-TL-01 maps the named very-tall usable surface without a bottom reserve.")
	require(standard.size.y <= 1024.0 and standard.size.x <= 576.0, "M6 standard portrait keeps contain-fit geometry.")

	var forge := FORGE.new()
	forge.size = Vector2(576, 1024)
	add_child(forge)
	forge.configure("cinderpaw", false, false)
	forge.set_preview_phase(ArcaneForgeSequence.PRINTING, 4200)
	await get_tree().process_frame
	var wire_clip := forge.find_child("ForgePrintWireframeClip", true, false) as Control
	require(wire_clip != null and wire_clip.visible and forge._last_scan_count == 1 and forge._last_solid_rect.size.y > 0.0 and forge._last_wireframe_rect.size.y > 0.0 and is_equal_approx(forge._last_solid_rect.position.y, forge._last_wireframe_rect.end.y), "M6-PR-60 renders one shared scan boundary with solid below and technical wireframe above.")
	forge.set_preview_phase(ArcaneForgeSequence.PRINTING, 4200)
	forge.configure("cinderpaw", true, false)
	await get_tree().process_frame
	require(wire_clip.visible and forge._last_scan_count == 1, "M6 reduced motion holds the same semantic 60 percent print split.")

	var stage := STAGE.new()
	stage.size = Vector2(576, 1024)
	add_child(stage)
	stage.configure({"players":[{"slots":[{"card_id":"cinderpaw","name":"Cinderpaw","hp":100}],"hand":["cinderpaw"],"printer":{"hp":2000,"max_hp":2000}},{"slots":[null,{"card_id":"aquafin","name":"Aquafin","hp":100}],"hand_count":3,"printer":{"hp":1900,"max_hp":2000}}]}, {"kind":"attack","actor":0,"source_slot":0,"target_slot":1,"presentation_progress_bps":5000,"generation":6})
	await get_tree().process_frame
	var contact := stage.find_child("BattleContactPeakOverlay", true, false) as TextureRect
	var home := stage.find_child("LivingPrintSlot0", true, false) as TextureRect
	var target := stage.find_child("LivingPrintSlot4", true, false) as TextureRect
	var target_caption := stage.find_child("LivingPrintCaption4", true, false) as Label
	require(contact != null and contact.visible and home != null and not home.visible and target != null and target.visible and target_caption != null and not contact.get_global_rect().intersects(target_caption.get_global_rect()) and contact.get_global_rect().get_center().distance_to(target.get_global_rect().get_center()) < target.get_global_rect().size.length(), "M6-BA-CT-01 transfers the attacker to an unclipped target-contact overlay while preserving the target name/HP strip.")
	stage.configure(stage.snapshot, {"kind":"attack","actor":0,"source_slot":0,"target_slot":1,"reduced_motion":true,"generation":7})
	await get_tree().process_frame
	require(contact.visible and not home.visible, "M6 reduced motion uses the finite held contact pose rather than skipping the attack presentation.")

	var card := CARD.new()
	card.size = CARD.COMPACT_SIZE
	add_child(card)
	card.configure(RULES.card("cinderpaw"), 1, -1, "", true, true)
	await get_tree().process_frame
	card.grab_focus()
	await get_tree().process_frame
	var art_shell := card.find_child("UnifiedCardArtShell", true, false) as Control
	var ring := card.find_child("UnifiedCardFocusRing", true, false) as Panel
	var title := card.find_child("UnifiedCardTitlePlate", true, false) as Control
	require(ring != null and ring.visible and art_shell != null and title != null and art_shell.get_global_rect().encloses(ring.get_global_rect()) and not ring.get_global_rect().intersects(title.get_global_rect()) and ring.get_global_rect().position.distance_to(art_shell.get_global_rect().position) >= 4.0, "M6-FC-01 keeps a four-edge non-scaling focus ring in the art aperture with label clearance (ring=%s visible=%s ring_rect=%s art=%s title=%s)." % [str(ring), str(ring.visible if ring != null else false), str(ring.get_global_rect() if ring != null else Rect2()), str(art_shell.get_global_rect() if art_shell != null else Rect2()), str(title.get_global_rect() if title != null else Rect2())])
	var disabled := CARD.new()
	disabled.size = CARD.COMPACT_SIZE
	add_child(disabled)
	disabled.configure(RULES.card("cinderpaw"), 0, -1, "", true, false)
	await get_tree().process_frame
	require(not (disabled.find_child("UnifiedCardFocusRing", true, false) as Panel).visible, "M6 disabled cards never present an active focus ring.")
	if failures.is_empty(): print("PASS: M6 tall zero reserve, print split, battle contact, and card focus")
	get_tree().quit(0 if failures.is_empty() else 1)
