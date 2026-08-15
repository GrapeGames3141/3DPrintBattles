class_name ArcaneForgeStage
extends Control
## Purely visual Arcane Forge compositor. Profile and battle state never enter this node.

const PRINTER_PATH := "res://assets/ui/arcane_forge_printer.png"
const CELL := Vector2i(384, 512)

var creature_id := "cinderpaw"
var phase := ArcaneForgeSequence.IDLE
var progress_bps := 0
var reduced_motion := false
var high_contrast := false
var elapsed := 0.0
var printer: Texture2D
var raw: Texture2D
var living: Texture2D

func _ready() -> void:
	# Large enough for the printer/readable build plate while leaving 720p room for controls.
	custom_minimum_size = Vector2(0, 280)
	_load_assets()
	queue_redraw()

func configure(id: String, reduce_motion: bool, contrast: bool) -> void:
	creature_id = id
	reduced_motion = reduce_motion
	high_contrast = contrast
	_load_assets()
	queue_redraw()

func set_preview_phase(value: String, value_bps: int) -> void:
	phase = value
	progress_bps = clampi(value_bps, 0, 10000)
	queue_redraw()

func set_presentation_time(seconds: float) -> void:
	elapsed = maxf(0.0, seconds)
	queue_redraw()

func _process(delta: float) -> void:
	if not reduced_motion and phase in [ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.AWAKENING]:
		elapsed += delta
		queue_redraw()

func _load_assets() -> void:
	printer = ResourceLoader.load(PRINTER_PATH) as Texture2D
	var definition := Catalog.creature(creature_id)
	var raw_path := str(definition.get("raw_print", ""))
	if raw_path.is_empty() or not ResourceLoader.exists(raw_path): raw_path = str(Catalog.creature("mossmunk").get("raw_print", ""))
	raw = ResourceLoader.load(raw_path) as Texture2D
	living = ResourceLoader.load(BattleSpriteStage.sprite_path_for(creature_id)) as Texture2D

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("081526d9") if not high_contrast else Color("000000f5"), true)
	var printer_rect := _fit_rect(printer, Rect2(8, 4, size.x - 16, size.y - 8))
	if printer != null: draw_texture_rect(printer, printer_rect, false)
	var plate := Rect2(size.x * 0.39, size.y * 0.52, size.x * 0.27, size.y * 0.30)
	if phase in [ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.RAW_COMPLETE, ArcaneForgeSequence.AWAKENING]:
		_draw_raw(plate)
	if phase in [ArcaneForgeSequence.PRINTING, ArcaneForgeSequence.RAW_COMPLETE] and not reduced_motion:
		_draw_nozzle(plate)
	if phase in [ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.AWAKENED]:
		_draw_living(plate)
	if phase == ArcaneForgeSequence.AWAKENING and not reduced_motion: _draw_sparks(plate)
	if high_contrast: draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), Color.WHITE, false, 3.0)

func _fit_rect(texture: Texture2D, bounds: Rect2) -> Rect2:
	if texture == null: return bounds
	var factor := minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var fitted := Vector2(texture.get_width(), texture.get_height()) * factor
	return Rect2(bounds.position + (bounds.size - fitted) * 0.5, fitted)

func _draw_raw(plate: Rect2) -> void:
	if raw == null: return
	var rect := _fit_rect(raw, plate)
	var reveal := 10000 if phase in [ArcaneForgeSequence.RAW_COMPLETE, ArcaneForgeSequence.AWAKENING, ArcaneForgeSequence.AWAKENED] else clampi((progress_bps * 10000) / ArcaneForgeSequence.PRINT_COMPLETE_BPS, 0, 10000)
	var shown := rect.size.y * float(reveal) / 10000.0
	if shown <= 0.5: return
	var source_height := raw.get_height() * float(reveal) / 10000.0
	var source := Rect2(0, raw.get_height() - source_height, raw.get_width(), source_height)
	var destination := Rect2(rect.position + Vector2(0, rect.size.y - shown), Vector2(rect.size.x, shown))
	var raw_alpha := 1.0
	if phase == ArcaneForgeSequence.AWAKENING:
		raw_alpha = 1.0 - clampf(float(progress_bps - ArcaneForgeSequence.PRINT_COMPLETE_BPS) / 3000.0, 0.0, 1.0)
	draw_texture_rect_region(raw, destination, source, Color(1, 1, 1, raw_alpha))
	if phase == ArcaneForgeSequence.PRINTING:
		var scan_y := destination.position.y
		draw_line(Vector2(destination.position.x, scan_y), Vector2(destination.end.x, scan_y), Color("69efff"), 2.0)

func _draw_living(plate: Rect2) -> void:
	if living == null: return
	var alpha := 1.0 if phase == ArcaneForgeSequence.AWAKENED else clampf(float(progress_bps - ArcaneForgeSequence.PRINT_COMPLETE_BPS) / 3000.0, 0.0, 1.0)
	if reduced_motion and phase == ArcaneForgeSequence.AWAKENING: alpha = 0.65
	var source := Rect2(0, 0, CELL.x, CELL.y)
	# A sprite cell is portrait; build its height from the stage, not the shallow plate.
	# This keeps the awakened companion readable above the physical build surface.
	var height := size.y * 0.68
	var width := height * float(CELL.x) / float(CELL.y)
	var rect := Rect2(Vector2(plate.get_center().x - width * 0.5, plate.end.y - height), Vector2(width, height))
	draw_texture_rect_region(living, rect, source, Color(1, 1, 1, alpha))

func _draw_nozzle(plate: Rect2) -> void:
	var cycle := (sin(elapsed * 5.0) + 1.0) * 0.5
	var x := lerpf(plate.position.x, plate.end.x, cycle)
	var y := lerpf(plate.end.y, plate.position.y, clampf(float(progress_bps) / ArcaneForgeSequence.PRINT_COMPLETE_BPS, 0.0, 1.0))
	draw_circle(Vector2(x, y), 8.0, Color("ffc45f"))
	draw_line(Vector2(x, y - 18), Vector2(x, y + 8), Color("7defff"), 3.0)

func _draw_sparks(plate: Rect2) -> void:
	var intensity := clampf(float(progress_bps - ArcaneForgeSequence.PRINT_COMPLETE_BPS) / 3000.0, 0.0, 1.0)
	for index in 12:
		var angle := float(index) * TAU / 12.0
		var distance := lerpf(16.0, plate.size.x * 0.45, intensity)
		var center := plate.get_center() + Vector2(cos(angle), sin(angle)) * distance
		draw_circle(center, 3.0 + intensity * 3.0, Color("6defff") if index % 2 == 0 else Color("ffc15b"))
