class_name ArcaneForgeStage
extends Control
## Purely visual Arcane Forge compositor. Profile and battle state never enter this node.

const PRINTER_FRAME_PATHS := [
	"res://assets/ui/arcane_forge_printer_frame_01.png",
	"res://assets/ui/arcane_forge_printer_frame_02.png",
	"res://assets/ui/arcane_forge_printer_frame_03.png",
	"res://assets/ui/arcane_forge_printer_frame_04.png",
]
const CELL := Vector2i(384, 512)

var creature_id := "cinderpaw"
var armor_id := ""
var phase := ArcaneForgeSequence.IDLE
var progress_bps := 0
var phase_progress_bps := 0
var reduced_motion := false
var high_contrast := false
var elapsed := 0.0
var printer_frames: Array[Texture2D] = []
var raw: Texture2D
var living: Texture2D
var _last_frame_index := -1

func _ready() -> void:
	# The portrait caller deliberately gives the forge more vertical room.
	# Landscape stays compact enough that its primary controls are on-screen.
	custom_minimum_size = Vector2(0, 330)
	_load_assets()
	_update_motion_processing()
	queue_redraw()

func configure(id: String, reduce_motion: bool, contrast: bool, armor_definition_id: String = "") -> void:
	creature_id = id
	armor_id = armor_definition_id
	reduced_motion = reduce_motion
	high_contrast = contrast
	_load_assets()
	_last_frame_index = -1
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
	set_process(not reduced_motion and phase == ArcaneForgeSequence.PRINTING)

func set_presentation_time(seconds: float) -> void:
	var next_time := maxf(0.0, seconds)
	if elapsed == next_time: return
	elapsed = next_time
	var next_frame := printer_frame_index()
	if next_frame != _last_frame_index:
		_last_frame_index = next_frame
		queue_redraw()

func printer_frame_index() -> int:
	if printer_frames.is_empty(): return 0
	if reduced_motion or phase != ArcaneForgeSequence.PRINTING: return 0
	# Ping-pong instead of looping across the print bed discontinuously.
	var pattern := [0, 1, 2, 3, 2, 1]
	return int(pattern[int(floor(elapsed * 2.4)) % pattern.size()])

func _process(delta: float) -> void:
	if reduced_motion or not is_visible_in_tree() or phase != ArcaneForgeSequence.PRINTING: return
	elapsed += delta
	var next_frame := printer_frame_index()
	if next_frame != _last_frame_index:
		_last_frame_index = next_frame
		queue_redraw()

func _load_assets() -> void:
	printer_frames.clear()
	for path in PRINTER_FRAME_PATHS:
		var texture := CreatureSpriteCache.texture_for_path(path)
		if texture != null: printer_frames.append(texture)
	var definition := Catalog.creature(creature_id)
	var raw_path := str(ProgressionRules.armor_def(armor_id).get("raw_print", "")) if not armor_id.is_empty() else str(definition.get("raw_print", ""))
	if raw_path.is_empty() or not ResourceLoader.exists(raw_path): raw_path = str(Catalog.creature("mossmunk").get("raw_print", ""))
	raw = CreatureSpriteCache.texture_for_path(raw_path)
	living = CreatureSpriteCache.texture_for_creature(creature_id)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("081526d9") if not high_contrast else Color("000000f5"), true)
	var printer := printer_frames[mini(printer_frame_index(), printer_frames.size() - 1)] if not printer_frames.is_empty() else null
	# Center a deliberately dominant square printer. These normalized bounds match
	# the visible gold build surface in the approved printer frames.
	var printer_bounds := Rect2(size.x * 0.17, 0, size.x * 0.66, size.y)
	var printer_rect := _fit_rect(printer, printer_bounds)
	if printer != null: draw_texture_rect(printer, printer_rect, false)
	var plate := Rect2(printer_rect.position.x + printer_rect.size.x * 0.28, printer_rect.position.y + printer_rect.size.y * 0.57, printer_rect.size.x * 0.50, printer_rect.size.y * 0.13)
	if phase in [ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.RAW_COMPLETE, ArcaneForgeSequence.RAW_HOLD, ArcaneForgeSequence.AWAKENING] or (not armor_id.is_empty() and phase == ArcaneForgeSequence.AWAKENED):
		_draw_raw(plate)
	if armor_id.is_empty() and phase in [ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.DEPARTING, ArcaneForgeSequence.AWAKENED]:
		_draw_living(plate)
	if phase == ArcaneForgeSequence.AWAKENING and not reduced_motion: _draw_sparks(plate)
	if high_contrast: draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), Color.WHITE, false, 3.0)

func _fit_rect(texture: Texture2D, bounds: Rect2) -> Rect2:
	if texture == null: return bounds
	var factor := minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var fitted := Vector2(texture.get_width(), texture.get_height()) * factor
	return Rect2(bounds.position + (bounds.size - fitted) * 0.5, fitted)

func _draw_raw(plate: Rect2) -> void:
	if not armor_id.is_empty():
		_draw_armor_part(plate)
		return
	if raw == null: return
	# The raw source has a small raft at its bottom. Align that raft to the actual
	# plate surface and keep the physical print at about one fifth of printer height.
	var raw_height := plate.size.y * 1.48
	var rect := Rect2(Vector2(plate.get_center().x - raw_height * 0.5, _plate_surface_y(plate) - raw_height), Vector2(raw_height, raw_height))
	var reveal := 10000 if phase != ArcaneForgeSequence.PRINTING else clampi((progress_bps * 10000) / ArcaneForgeSequence.PRINT_COMPLETE_BPS, 0, 10000)
	var shown := rect.size.y * float(reveal) / 10000.0
	if shown <= 0.5: return
	var source_height := raw.get_height() * float(reveal) / 10000.0
	var source := Rect2(0, raw.get_height() - source_height, raw.get_width(), source_height)
	var destination := Rect2(rect.position + Vector2(0, rect.size.y - shown), Vector2(rect.size.x, shown))
	var raw_alpha := 1.0
	if phase == ArcaneForgeSequence.AWAKENING:
		raw_alpha = 1.0 - clampf(float(phase_progress_bps) / 10000.0, 0.0, 1.0)
	draw_texture_rect_region(raw, destination, source, Color(1, 1, 1, raw_alpha))
	if phase == ArcaneForgeSequence.PRINTING:
		var scan_y := destination.position.y
		draw_line(Vector2(destination.position.x, scan_y), Vector2(destination.end.x, scan_y), Color("69efff"), 2.0)

func _draw_armor_part(plate: Rect2) -> void:
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
	draw_texture_rect_region(raw, destination, source)
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
	var rect := Rect2(Vector2(plate.get_center().x - width * 0.5, _plate_surface_y(plate) - height) + offset, Vector2(width, height))
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
