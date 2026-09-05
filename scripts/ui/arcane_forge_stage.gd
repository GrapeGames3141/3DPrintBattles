class_name ArcaneForgeStage
extends Control
## Purely visual Arcane Forge compositor. Profile and battle state never enter this node.

const CELL := Vector2i(384, 512)
const TIERED_ARMOR_ROSTER := preload("res://scripts/ui/tiered_armor_roster.gd")
# TIERED_ARMOR_ROSTER is the local alias for TieredArmorRoster.
const TIERED_ARMOR_PREVIEW := preload("res://scripts/ui/tiered_armor_palette_preview.gd")
const SCHEMATIC := preload("res://scripts/ui/blueprint_schematic.gdshader")

var creature_id := "cinderpaw"
var armor_id := ""
var core_id := ""
var phase := ArcaneForgeSequence.IDLE
var progress_bps := 0
var phase_progress_bps := 0
var reduced_motion := false
var high_contrast := false
var elapsed := 0.0
var raw: Texture2D
var living: Texture2D
var equipment_preview: Control
var _wireframe_clip: Control
var _wireframe: TextureRect
var _last_solid_rect := Rect2()
var _last_wireframe_rect := Rect2()
var _last_scan_count := 0
var _last_printable_rect := Rect2()
var _last_preview_band_limit := 0.0
var _raw_alpha_bounds := Rect2()
var _raw_alpha_bounds_ready := false
var _living_alpha_bounds := Rect2()
var _living_alpha_bounds_ready := false
# M8 test-visible alpha-mask facts. These describe real retained source rows,
# not merely the enclosing destination rectangle (which may have transparent
# padding above the creature silhouette).
var _last_opaque_source_bounds := Rect2()
var _last_revealed_opaque_rows := 0
var _last_unrevealed_opaque_rows := 0
var _last_unrevealed_logical_pixels := 0.0
var _last_scan_datum_y := 0.0

# One source-of-truth design contract for the approved 941x1672 enclosed station.
# The static plate and the dynamic compositor are both fitted by the same portrait
# presenter, so these authored coordinates never depend on window raster size.
const STATION_DESIGN_SIZE := Vector2(941.0, 1672.0)
const STATION_CHAMBER := Rect2(114.0, 280.0, 594.0, 620.0)
const STATION_BED := Rect2(178.0, 804.0, 466.0, 86.0)
const STATION_PRINTABLE := Rect2(310.0, 540.0, 320.0, 264.0)
const STATION_GUIDE_IDLE := Rect2(114.0, 280.0, 594.0, 168.0)
const STATION_HEAD_IDLE := Rect2(406.0, 294.0, 128.0, 266.0)
const STATION_HEAD_PARK := Rect2(132.0, 294.0, 128.0, 266.0)
const CONTINUITY_GUIDE_PATH := "res://assets/ui/physical_ui/forge-continuity/carriage-guide-v1.png"
const CONTINUITY_HEAD_PATH := "res://assets/ui/physical_ui/forge-continuity/carriage-head-v1.png"

var _continuity_station := false
var _continuity_guide: Texture2D
var _continuity_head: Texture2D

func _ready() -> void:
	# The portrait caller deliberately gives the forge more vertical room.
	# Landscape stays compact enough that its primary controls are on-screen.
	custom_minimum_size = Vector2(0, 330)
	equipment_preview = TIERED_ARMOR_PREVIEW.new(); equipment_preview.name = "ForgeEquipmentPalettePreview"; equipment_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(equipment_preview)
	_wireframe_clip = Control.new(); _wireframe_clip.name = "ForgePrintWireframeClip"; _wireframe_clip.clip_contents = true; _wireframe_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE; _wireframe_clip.z_index = 4; add_child(_wireframe_clip)
	_wireframe = TextureRect.new(); _wireframe.name = "ForgePrintWireframe"; _wireframe.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _wireframe.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; _wireframe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var wireframe_material := ShaderMaterial.new(); wireframe_material.shader = SCHEMATIC; _wireframe.material = wireframe_material
	_wireframe_clip.add_child(_wireframe)
	_load_assets()
	_update_motion_processing()
	queue_redraw()

func configure(id: String, reduce_motion: bool, contrast: bool, armor_definition_id: String = "", core_definition_id: String = "") -> void:
	creature_id = id
	armor_id = armor_definition_id
	core_id = core_definition_id
	reduced_motion = reduce_motion
	high_contrast = contrast
	_load_assets()
	_update_motion_processing()
	queue_redraw()

func set_continuity_station(enabled: bool) -> void:
	if _continuity_station == enabled:
		return
	_continuity_station = enabled
	if enabled:
		_continuity_guide = CreatureSpriteCache.texture_for_path(CONTINUITY_GUIDE_PATH)
		_continuity_head = CreatureSpriteCache.texture_for_path(CONTINUITY_HEAD_PATH)
	_update_motion_processing()
	queue_redraw()

func set_preview_phase(value: String, value_bps: int, local_phase_bps := 0) -> void:
	var changed := phase != value or progress_bps != clampi(value_bps, 0, 10000) or phase_progress_bps != clampi(local_phase_bps, 0, 10000)
	phase = value
	progress_bps = clampi(value_bps, 0, 10000)
	phase_progress_bps = clampi(local_phase_bps, 0, 10000)
	_update_motion_processing()
	if changed: queue_redraw()

func _update_motion_processing() -> void:
	# Main advances awakening/departing by deterministic bps and calls
	# set_preview_phase(). Only printing consumes this node's elapsed time for
	# the moving carriage frame, so it is the only phase that needs _process.
	# Main already owns the finite presentation clock. In the continuity station
	# the compositor only redraws from that clock, so it cannot drift while a
	# route is frozen, paused, or reattached.
	set_process(not _continuity_station and not reduced_motion and phase == ArcaneForgeSequence.PRINTING)

func set_presentation_time(seconds: float) -> void:
	var next_time := maxf(0.0, seconds)
	if elapsed == next_time: return
	elapsed = next_time
	queue_redraw()

func _process(delta: float) -> void:
	if reduced_motion or not is_visible_in_tree() or phase != ArcaneForgeSequence.PRINTING: return
	elapsed += delta
	queue_redraw()

func _load_assets() -> void:
	var definition := Catalog.creature(creature_id)
	var raw_definition := ArmorCoreDefinitions.core_blueprint_definition(core_id) if not core_id.is_empty() else ProgressionRules.armor_def(armor_id)
	var raw_path := str(raw_definition.get("raw_print", "")) if not armor_id.is_empty() else str(definition.get("raw_print", ""))
	# A missing subject layer is a presentation fault, never permission to show a
	# different creature or retired machine. The continuity owner exposes a safe
	# caller-return surface instead of silently substituting Mossmunk.
	raw = CreatureSpriteCache.texture_for_path(raw_path) if not raw_path.is_empty() and ResourceLoader.exists(raw_path) else null
	_raw_alpha_bounds_ready = false
	_raw_alpha_bounds = Rect2()
	_refresh_raw_alpha_bounds()
	# Continuity presentation must never quietly substitute the cache's Mossmunk
	# fallback. A missing selected creature layer is handled by the caller-safe
	# surface, just like missing raw/carriage layers.
	var living_path := str(definition.get("sprite_sheet", ""))
	living = CreatureSpriteCache.texture_for_path(living_path) if armor_id.is_empty() and not living_path.is_empty() and ResourceLoader.exists(living_path) else null
	_living_alpha_bounds_ready = false
	_living_alpha_bounds = Rect2()
	_refresh_living_alpha_bounds()

func continuity_assets_ready() -> bool:
	return raw != null and _continuity_guide != null and _continuity_head != null and (not armor_id.is_empty() or living != null)

func _refresh_raw_alpha_bounds() -> void:
	if raw == null:
		_raw_alpha_bounds_ready = true
		return
	var image := raw.get_image()
	if image == null or image.is_empty():
		_raw_alpha_bounds = Rect2(0, 0, raw.get_width(), raw.get_height())
		_raw_alpha_bounds_ready = true
		return
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.01:
				min_x = mini(min_x, x); min_y = mini(min_y, y)
				max_x = maxi(max_x, x); max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		_raw_alpha_bounds = Rect2(0, 0, raw.get_width(), raw.get_height())
	else:
		_raw_alpha_bounds = Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	_raw_alpha_bounds_ready = true

func _refresh_living_alpha_bounds() -> void:
	if living == null:
		_living_alpha_bounds_ready = true
		return
	_living_alpha_bounds = _alpha_bounds_for_region(living, Rect2(0, 0, CELL.x, CELL.y))
	_living_alpha_bounds_ready = true

func _alpha_bounds_for_region(texture: Texture2D, source: Rect2) -> Rect2:
	var image := texture.get_image()
	if image == null or image.is_empty():
		return source
	var min_x := int(source.end.x)
	var min_y := int(source.end.y)
	var max_x := -1
	var max_y := -1
	for y in range(int(source.position.y), int(source.end.y)):
		for x in range(int(source.position.x), int(source.end.x)):
			if image.get_pixel(x, y).a > 0.01:
				min_x = mini(min_x, x); min_y = mini(min_y, y)
				max_x = maxi(max_x, x); max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return source
	return Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _draw() -> void:
	# This is a transparent stage compositor.  The authored Workshop plate owns
	# the surrounding material; drawing a full canvas wash here made the printer
	# read as a generic black/glass card instead of a machine in that workshop.
	# These rects are test-visible presentation facts, never gameplay state. Clear
	# them before each draw so departure/completion cannot retain a prior raw mask.
	_last_solid_rect = Rect2()
	_last_wireframe_rect = Rect2()
	_last_scan_count = 0
	_last_opaque_source_bounds = Rect2()
	_last_revealed_opaque_rows = 0
	_last_unrevealed_opaque_rows = 0
	_last_unrevealed_logical_pixels = 0.0
	var printer_bounds := Rect2(size.x * 0.07, 0, size.x * 0.86, size.y)
	if equipment_preview != null:
		# The approved continuity station owns an empty IDLE bed for every subject
		# class. Its equipment palette would otherwise read as a completed print.
		equipment_preview.visible = not _continuity_station and not armor_id.is_empty() and phase == ArcaneForgeSequence.IDLE and TIERED_ARMOR_ROSTER.has_master(creature_id)
		equipment_preview.configure_creature(creature_id)
		equipment_preview.configure_tier(armor_id if core_id.is_empty() else "standard")
		equipment_preview.configure_core(core_id)
		equipment_preview.position = Vector2(size.x * 0.74, 12)
		equipment_preview.size = Vector2(112, 150)
	var plate := Rect2(printer_bounds.position.x + printer_bounds.size.x * 0.28, printer_bounds.position.y + printer_bounds.size.y * 0.57, printer_bounds.size.x * 0.50, printer_bounds.size.y * 0.13)
	if _continuity_station:
		plate = _station_rect(STATION_BED)
		_draw_continuity_hardware()
	# The dock, not the bed, owns the complete pre-print identity.  Before Start
	# the build plate is empty; a small local footprint is the only permitted cue.
	# During PRINTING the raw source is progressively revealed below one datum.
	if phase == ArcaneForgeSequence.IDLE:
		_last_solid_rect = Rect2()
		_last_wireframe_rect = Rect2()
		_last_scan_count = 0
		_last_printable_rect = Rect2()
		_last_preview_band_limit = 0.0
		_set_wireframe_split(Rect2(), Rect2(), false)
		_draw_seed(plate)
	elif phase in [ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.RAW_COMPLETE, ArcaneForgeSequence.RAW_HOLD, ArcaneForgeSequence.AWAKENING]:
		_draw_raw(plate)
	if armor_id.is_empty() and phase in [ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.DEPARTING, ArcaneForgeSequence.AWAKENED]:
		_draw_living(plate)
	if phase == ArcaneForgeSequence.AWAKENING and not reduced_motion: _draw_sparks(plate)
	# High contrast marks only the functional build aperture.  The scan datum and
	# progress rail already carry the other state cues; an outer printer frame was
	# visually indistinguishable from a giant stock rectangle around the machine.
	# The enclosed plate already supplies a strong physical aperture edge. A white
	# high-contrast outline turns the continuity bed into an inert target box.
	if high_contrast and not _continuity_station: draw_rect(plate.grow(2.0), Color.WHITE, false, 3.0)
	if phase != ArcaneForgeSequence.PRINTING or not armor_id.is_empty():
		_set_wireframe_split(Rect2(), Rect2(), false)

func _fit_rect(texture: Texture2D, bounds: Rect2) -> Rect2:
	if texture == null: return bounds
	var factor := minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var fitted := Vector2(texture.get_width(), texture.get_height()) * factor
	return Rect2(bounds.position + (bounds.size - fitted) * 0.5, fitted)

func _station_rect(design_rect: Rect2) -> Rect2:
	var scale := size / STATION_DESIGN_SIZE
	return Rect2(design_rect.position * scale, design_rect.size * scale)

func _draw_continuity_hardware() -> void:
	var translation := Vector2.ZERO
	var head_target := STATION_HEAD_IDLE
	if phase in [ArcaneForgeSequence.RAW_HOLD, ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.DEPARTING, ArcaneForgeSequence.AWAKENED, ArcaneForgeSequence.FAILED]:
		head_target = STATION_HEAD_PARK
	elif phase == ArcaneForgeSequence.PRINTING:
		# Both source-derived pieces share the same vertical registration. The scan
		# datum comes from the exact alpha-aware/floor-quantized raw layout below;
		# the nozzle tip is kept two logical pixels above it.
		var scale_y := maxf(size.y / STATION_DESIGN_SIZE.y, 0.001)
		var scan_y := _continuity_scan_y() / scale_y
		# Match the visible nozzle tip, rather than the carriage crop edge, to the
		# scan datum. The source's lower brass outline reads a few pixels inside the
		# transparent crop at phone scale, so this keeps the visible gap at 1–3 px.
		translation.y = scan_y + (7.0 / scale_y) - STATION_HEAD_IDLE.end.y
		translation.x = 0.0 if reduced_motion else sin(elapsed * 2.2) * 76.0
		head_target = Rect2(STATION_HEAD_IDLE.position + translation, STATION_HEAD_IDLE.size)
	if _continuity_guide != null:
		# The fixed cabinet posts retain their x registration. Only the whole rail
		# assembly changes elevation; the head alone strokes along those rails.
		var guide_target := Rect2(STATION_GUIDE_IDLE.position + Vector2(0, translation.y), STATION_GUIDE_IDLE.size)
		draw_texture_rect(_continuity_guide, _station_rect(guide_target), false)
	if _continuity_head != null:
		draw_texture_rect(_continuity_head, _station_rect(head_target), false)

func _continuity_scan_y() -> float:
	var layout := _continuity_raw_layout()
	if layout.is_empty():
		return _plate_surface_y(_station_rect(STATION_BED))
	var alpha_source: Rect2 = layout.alpha_source
	var scale: Vector2 = layout.scale
	var opaque: Rect2 = layout.opaque
	# Use the same integer alpha rows as _draw_raw. This prevents the carriage
	# from tracking a fractional datum that the visible print cannot occupy.
	return floorf(opaque.end.y - float(_continuity_revealed_rows(alpha_source)) * scale.y)

func _continuity_raw_layout() -> Dictionary:
	if raw == null:
		return {}
	if not _raw_alpha_bounds_ready:
		_refresh_raw_alpha_bounds()
	var printable := _station_rect(STATION_PRINTABLE)
	var raw_height := minf(printable.size.y, printable.size.x * float(raw.get_height()) / float(raw.get_width()))
	var raw_width := raw_height * float(raw.get_width()) / float(raw.get_height())
	var bed := _station_rect(STATION_BED)
	var rect := Rect2(Vector2(bed.get_center().x - raw_width * 0.5, printable.end.y - raw_height), Vector2(raw_width, raw_height))
	var alpha_source := _raw_alpha_bounds if _raw_alpha_bounds.size.x > 0.5 and _raw_alpha_bounds.size.y > 0.5 else Rect2(0, 0, raw.get_width(), raw.get_height())
	var scale := Vector2(rect.size.x / float(raw.get_width()), rect.size.y / float(raw.get_height()))
	var opaque := Rect2(rect.position + alpha_source.position * scale, alpha_source.size * scale)
	# The opaque raft, not transparent PNG padding, meets the true bed surface.
	rect.position.y += _plate_surface_y(bed) - opaque.end.y
	opaque = Rect2(rect.position + alpha_source.position * scale, alpha_source.size * scale)
	return {"rect":rect, "opaque":opaque, "alpha_source":alpha_source, "scale":scale}

func _continuity_revealed_rows(alpha_source: Rect2) -> int:
	var opaque_rows := maxi(1, int(alpha_source.size.y))
	if phase != ArcaneForgeSequence.PRINTING:
		return opaque_rows
	var reveal := clampi((progress_bps * 10000) / ArcaneForgeSequence.PRINT_COMPLETE_BPS, 0, 10000)
	var requested_rows := int(floor(float(opaque_rows) * float(reveal) / 10000.0))
	# A single source row can raster below one logical pixel at phone scale and
	# reveal a completed silhouette before RAW_COMPLETE. Keep a visible top slice
	# withheld while preserving the canonical raw bounds and sequence timing.
	var layout := _continuity_raw_layout()
	var pixels_per_source_row := float(layout.get("scale", Vector2.ONE).y)
	var guard_rows := maxi(1, int(ceili(4.0 / maxf(pixels_per_source_row, 0.001))))
	return clampi(requested_rows, 0, opaque_rows - guard_rows)

func _draw_raw(plate: Rect2, preview_alpha := 1.0) -> void:
	if raw == null: return
	# The raw source has a small raft at its bottom. Align that raft to the actual
	# plate surface and keep the physical print at about one fifth of printer height.
	# The raw form must not shrink/pop when PRINTING reaches RAW_COMPLETE.  Every
	# raw-owning phase shares this one canonical printable rect; only its reveal
	# mask/alpha changes through the finite raw-hold and awakening handoff.
	var raw_height := plate.size.y * 2.90
	var rect := Rect2(Vector2(plate.get_center().x - raw_height * 0.5, _plate_surface_y(plate) - raw_height), Vector2(raw_height, raw_height))
	if _continuity_station:
		var continuity_layout := _continuity_raw_layout()
		if continuity_layout.is_empty(): return
		rect = continuity_layout.rect
	if not _raw_alpha_bounds_ready: _refresh_raw_alpha_bounds()
	var alpha_source := _raw_alpha_bounds if _raw_alpha_bounds.size.x > 0.5 and _raw_alpha_bounds.size.y > 0.5 else Rect2(0, 0, raw.get_width(), raw.get_height())
	var scale := Vector2(rect.size.x / float(raw.get_width()), rect.size.y / float(raw.get_height()))
	var opaque_rect := Rect2(rect.position + alpha_source.position * scale, alpha_source.size * scale)
	if _continuity_station:
		var continuity_layout := _continuity_raw_layout()
		alpha_source = continuity_layout.alpha_source
		scale = continuity_layout.scale
		opaque_rect = continuity_layout.opaque
	_last_printable_rect = opaque_rect
	_last_opaque_source_bounds = alpha_source
	var reveal := 10000 if phase != ArcaneForgeSequence.PRINTING else clampi((progress_bps * 10000) / ArcaneForgeSequence.PRINT_COMPLETE_BPS, 0, 10000)
	_last_scan_datum_y = opaque_rect.end.y - opaque_rect.size.y * float(reveal) / 10000.0
	var opaque_rows := maxi(1, int(alpha_source.size.y))
	var revealed_rows := _continuity_revealed_rows(alpha_source) if _continuity_station else (opaque_rows if reveal >= 10000 else clampi(int(floor(float(opaque_rows) * float(reveal) / 10000.0)), 0, opaque_rows - 1))
	_last_revealed_opaque_rows = revealed_rows
	_last_unrevealed_opaque_rows = opaque_rows - revealed_rows
	_last_unrevealed_logical_pixels = float(_last_unrevealed_opaque_rows) * scale.y
	_last_solid_rect = Rect2()
	_last_wireframe_rect = Rect2()
	_last_scan_count = 0
	# The contractual band is measured against visible printable alpha, not the
	# transparent canvas/padding surrounding it.
	_last_preview_band_limit = opaque_rect.size.y * 0.08
	if phase == ArcaneForgeSequence.PRINTING and progress_bps <= 70:
		_draw_seed(plate)
		# The footprint's local cyan datum is the single scan indication at the
		# first authoritative layer; there is no detached creature preview yet.
		_last_scan_count = 1
		_set_wireframe_split(Rect2(), Rect2(), false)
		return
	if revealed_rows <= 0:
		_set_wireframe_split(Rect2(), Rect2(), false)
		return
	# Map the reveal against the true alpha silhouette, not the source canvas.
	# Cropping keeps source/destination scale identical, so the 99%->raw-complete
	# handoff cannot resize or pop even when the PNG has transparent top padding.
	var source_y := alpha_source.end.y - float(revealed_rows)
	var source := Rect2(0, source_y, raw.get_width(), raw.get_height() - source_y)
	# Preserve one transparent pixel at the scan datum.  The solid print begins
	# strictly below it; shader preview is limited to a narrow band above it.
	var destination := Rect2(rect.position + Vector2(0, source_y * scale.y), Vector2(rect.size.x, (raw.get_height() - source_y) * scale.y))
	if destination.size.y <= 0.5:
		_draw_seed(plate)
		_set_wireframe_split(Rect2(), Rect2(), false)
		return
	_last_solid_rect = Rect2(opaque_rect.position + Vector2(0, opaque_rect.size.y - float(revealed_rows) * scale.y + 1.0), Vector2(opaque_rect.size.x, maxf(0.0, float(revealed_rows) * scale.y - 1.0)))
	var raw_alpha := 1.0
	if phase == ArcaneForgeSequence.AWAKENING:
		raw_alpha = 1.0 - clampf(float(phase_progress_bps) / 10000.0, 0.0, 1.0)
	draw_texture_rect_region(raw, destination, source, Color(1, 1, 1, raw_alpha * preview_alpha))
	if phase == ArcaneForgeSequence.PRINTING:
		var scan_y := _last_solid_rect.position.y - 1.0
		# Never project the entire unrevealed creature. The technical preview is one
		# contiguous, scan-adjacent band capped at 8% of printable height.
		var preview_height := minf(_last_preview_band_limit, maxf(0.0, scan_y - opaque_rect.position.y))
		var preview := Rect2(opaque_rect.position.x, scan_y - preview_height, opaque_rect.size.x, preview_height)
		_set_wireframe_split(preview, rect, preview_height > 0.5)
		_last_wireframe_rect = preview
		_last_scan_count = 1
		# One explicit, high-value cyan datum owns the complementary material split.
		# One unequivocal cyan datum separates raw filament below from technical
		# wireframe above. It is intentionally bright without covering the hardware.
		draw_line(Vector2(destination.position.x, scan_y), Vector2(destination.end.x, scan_y), Color("b4fbff"), 4.0)
	else:
		_set_wireframe_split(Rect2(), Rect2(), false)

func _draw_seed(plate: Rect2) -> void:
	# A local footprint is deliberately not a creature silhouette. It appears at
	# the build plane only, communicates dormant/first-layer state, and vanishes
	# under the progressive raw extrusion once enough filament exists.
	var y := _plate_surface_y(plate) - 2.0
	var width := maxf(14.0, plate.size.x * 0.16)
	var seed := Rect2(plate.get_center().x - width * 0.5, y - 2.0, width, 4.0)
	draw_rect(seed, Color("6defff"), false, 1.5)
	draw_line(Vector2(seed.position.x + width * 0.25, y), Vector2(seed.position.x + width * 0.75, y), Color("b4fbff"), 1.5)

func _set_wireframe_split(upper: Rect2, full_rect: Rect2, visible: bool) -> void:
	if _wireframe_clip == null or _wireframe == null: return
	_wireframe_clip.visible = visible and raw != null and upper.size.x > 0.5 and upper.size.y > 0.5
	if not _wireframe_clip.visible: return
	_wireframe_clip.position = upper.position
	_wireframe_clip.size = upper.size
	_wireframe.position = full_rect.position - upper.position
	_wireframe.size = full_rect.size
	_wireframe.texture = raw

func _draw_armor_part(plate: Rect2, preview_alpha := 1.0) -> void:
	if raw == null: return
	var reveal := 10000 if phase != ArcaneForgeSequence.PRINTING else clampi((progress_bps * 10000) / ArcaneForgeSequence.PRINT_COMPLETE_BPS, 0, 10000)
	var height := plate.size.y * 1.46
	var width := height * float(raw.get_width()) / float(raw.get_height())
	var rect := Rect2(Vector2(plate.get_center().x - width * 0.5, _plate_surface_y(plate) - height), Vector2(width, height))
	var shown := rect.size.y * float(reveal) / 10000.0
	if shown <= 0.5: return
	var source_height := raw.get_height() * float(reveal) / 10000.0
	var source := Rect2(0, raw.get_height() - source_height, raw.get_width(), source_height)
	var destination := Rect2(rect.position + Vector2(0, rect.size.y - shown), Vector2(rect.size.x, shown))
	draw_texture_rect_region(raw, destination, source, Color(1, 1, 1, preview_alpha))
	if phase == ArcaneForgeSequence.PRINTING: draw_line(Vector2(destination.position.x, destination.position.y), Vector2(destination.end.x, destination.position.y), Color("69efff"), 2.0)

func _draw_living(plate: Rect2) -> void:
	if living == null: return
	var alpha := 1.0
	if phase == ArcaneForgeSequence.AWAKENING:
		alpha = 0.65 if reduced_motion else clampf(float(phase_progress_bps) / 10000.0, 0.0, 1.0)
	if phase == ArcaneForgeSequence.DEPARTING:
		alpha = 1.0 - clampf(float(phase_progress_bps) / 14000.0, 0.0, 0.7)
	if phase == ArcaneForgeSequence.AWAKENED: alpha = 0.0
	var source := Rect2(0, 0, CELL.x, CELL.y)
	# Awakened form is larger than the dormant print but remains about 36% of the
	# printer height instead of filling the gantry.
	var height := (plate.size.y / 0.13) * 0.36
	var width := height * float(CELL.x) / float(CELL.y)
	var offset := Vector2.ZERO
	if phase == ArcaneForgeSequence.DEPARTING:
		var amount := float(phase_progress_bps) / 10000.0
		# Clear diagonal departure visibly takes the living creature off the plate.
		offset = Vector2(plate.size.x * amount, -height * 0.80 * amount)
	var rect := Rect2(Vector2(plate.get_center().x - width * 0.5, _plate_surface_y(plate) - height), Vector2(width, height))
	if not _living_alpha_bounds_ready:
		_refresh_living_alpha_bounds()
	var scale := Vector2(rect.size.x / float(CELL.x), rect.size.y / float(CELL.y))
	var opaque := Rect2(rect.position + _living_alpha_bounds.position * scale, _living_alpha_bounds.size * scale)
	# The real sprite feet meet the same authored bed datum as the raw raft; do
	# not anchor transparent atlas padding and leave a visible hover gap.
	rect.position.y += _plate_surface_y(plate) - opaque.end.y
	rect.position += offset
	draw_texture_rect_region(living, rect, source, Color(1, 1, 1, alpha))

func _plate_surface_y(plate: Rect2) -> float:
	# Source perspective places the printable surface just behind the front rim.
	return plate.position.y + plate.size.y * 0.64

func _draw_sparks(plate: Rect2) -> void:
	var intensity := clampf(float(phase_progress_bps) / 10000.0, 0.0, 1.0)
	for index in 12:
		var angle := float(index) * TAU / 12.0
		var distance := lerpf(16.0, plate.size.x * 0.58, intensity)
		var center := plate.get_center() + Vector2(cos(angle), sin(angle)) * distance
		draw_circle(center, 3.0 + intensity * 3.0, Color("6defff") if index % 2 == 0 else Color("ffc15b"))
