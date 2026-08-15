class_name WorkshopStationLiveLayer
extends Control
## Non-authoritative live presentation for the v3 Printer and Maker station views.

const PRINTER := "printer"
const MAKER := "maker"
const PRINTER_FRAME_PATHS := [
	"res://assets/ui/arcane_forge_printer_frame_01.png",
	"res://assets/ui/arcane_forge_printer_frame_02.png",
	"res://assets/ui/arcane_forge_printer_frame_03.png",
	"res://assets/ui/arcane_forge_printer_frame_04.png",
]
const CELL := Rect2(0, 0, 384, 512)

var station_id := PRINTER
var portrait := false
var reduced_motion := false
var high_contrast := false
var capture_frozen := false
var sequence := WorkshopLiveSequence.create(1)
var unlocked_ids: Array[String] = []
var team_ids: Array[String] = []
var printer_frames: Array[Texture2D] = []
var raw_textures: Dictionary = {}
var living_textures: Dictionary = {}
var tick_remainder := 0.0
var _last_draw_signature := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_motion_processing()

func configure(profile: Dictionary, station: String, is_portrait: bool, reduce_motion: bool, contrast: bool, fixed_seed := 17, freeze_for_capture := false) -> void:
	station_id = station
	portrait = is_portrait
	reduced_motion = reduce_motion
	high_contrast = contrast
	capture_frozen = freeze_for_capture
	sequence = WorkshopLiveSequence.create(fixed_seed)
	_last_draw_signature = ""
	unlocked_ids.clear()
	for creature_id in profile.get("blueprints", []):
		var id := str(creature_id)
		if not Catalog.creature(id).is_empty() and not unlocked_ids.has(id):
			unlocked_ids.append(id)
	team_ids = _team_creature_ids(profile)
	_load_assets()
	_update_motion_processing()
	queue_redraw()

func _update_motion_processing() -> void:
	var moving := station_id == PRINTER and not reduced_motion and not capture_frozen
	process_mode = Node.PROCESS_MODE_INHERIT if moving else Node.PROCESS_MODE_DISABLED
	set_process(moving)

func suspend() -> void:
	set_process(false)

func resume() -> void:
	_update_motion_processing()

func set_capture_progress(value_bps: int) -> void:
	sequence.set_capture_progress(value_bps)
	_last_draw_signature = _presentation_signature()
	queue_redraw()

func selected_creature_id() -> String:
	var index := sequence.selected_index(unlocked_ids.size())
	return unlocked_ids[index] if index >= 0 else ""

func _process(delta: float) -> void:
	tick_remainder += delta
	var ticks: int = int(floor(tick_remainder * 1000.0))
	if ticks <= 0:
		return
	tick_remainder -= float(ticks) / 1000.0
	sequence.advance(ticks, unlocked_ids.size())
	var next_signature := _presentation_signature()
	if next_signature != _last_draw_signature:
		_last_draw_signature = next_signature
		queue_redraw()

func _load_assets() -> void:
	printer_frames.clear()
	raw_textures.clear()
	living_textures.clear()
	if station_id == PRINTER:
		for path in PRINTER_FRAME_PATHS:
			var printer := CreatureSpriteCache.texture_for_path(path)
			if printer != null:
				printer_frames.append(printer)
	for id in unlocked_ids + team_ids:
		if raw_textures.has(id):
			continue
		var definition := Catalog.creature(id)
		var raw_path := str(definition.get("raw_print", ""))
		var living_path := str(definition.get("sprite_sheet", ""))
		raw_textures[id] = CreatureSpriteCache.texture_for_path(raw_path) if not raw_path.is_empty() else null
		living_textures[id] = CreatureSpriteCache.texture_for_path(living_path) if not living_path.is_empty() else null

func _presentation_signature() -> String:
	if station_id != PRINTER: return "maker:%s" % ",".join(team_ids)
	return "%s:%d:%d:%d" % [sequence.phase(), sequence.phase_progress_bps() / 100, sequence.printer_frame_index(reduced_motion), sequence.selected_index(unlocked_ids.size())]

func _team_creature_ids(profile: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for entry in ProfileRules.team_loadout(profile):
		var creature_id := str(entry.get("creature_id", ""))
		if not creature_id.is_empty() and result.size() < 3: result.append(creature_id)
	return result

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	if station_id == PRINTER:
		_draw_live_printer()
	elif station_id == MAKER:
		_draw_team_plinths()
	if high_contrast:
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE, false, 2.0)

func _printer_bounds() -> Rect2:
	# Landmark-anchored to the empty blue cutting mat on each distinct v3 plate.
	if portrait:
		return Rect2(size.x * 0.10, size.y * 0.38, size.x * 0.34, size.y * 0.26)
	return Rect2(size.x * 0.08, size.y * 0.42, size.x * 0.24, size.y * 0.42)

func _draw_live_printer() -> void:
	if unlocked_ids.is_empty() or printer_frames.is_empty():
		return
	var printer := printer_frames[mini(sequence.printer_frame_index(reduced_motion), printer_frames.size() - 1)]
	var printer_rect := _fit_rect(printer, _printer_bounds())
	draw_texture_rect(printer, printer_rect, false)
	var plate := Rect2(printer_rect.position.x + printer_rect.size.x * 0.28, printer_rect.position.y + printer_rect.size.y * 0.57, printer_rect.size.x * 0.50, printer_rect.size.y * 0.13)
	var creature_id := selected_creature_id()
	match sequence.phase():
		WorkshopLiveSequence.PRINTING:
			_draw_raw(creature_id, plate, sequence.phase_progress_bps(), 1.0)
		WorkshopLiveSequence.RAW_HOLD:
			_draw_raw(creature_id, plate, 10000, 1.0)
		WorkshopLiveSequence.AWAKENING:
			var amount := float(sequence.phase_progress_bps()) / 10000.0
			_draw_raw(creature_id, plate, 10000, 1.0 - amount)
			_draw_living(creature_id, plate, amount, 0.0)
			if not reduced_motion:
				_draw_sparks(plate, amount)
		WorkshopLiveSequence.DEPARTING:
			_draw_living(creature_id, plate, 1.0, float(sequence.phase_progress_bps()) / 10000.0)

func _draw_raw(creature_id: String, plate: Rect2, reveal_bps: int, alpha: float) -> void:
	var raw := raw_textures.get(creature_id) as Texture2D
	if raw == null or reveal_bps <= 0:
		return
	var height := plate.size.y * 1.48
	var rect := Rect2(Vector2(plate.get_center().x - height * 0.5, plate.position.y + plate.size.y * 0.64 - height), Vector2(height, height))
	var visible_height := rect.size.y * float(reveal_bps) / 10000.0
	var source_height := raw.get_height() * float(reveal_bps) / 10000.0
	var source := Rect2(0, raw.get_height() - source_height, raw.get_width(), source_height)
	var destination := Rect2(rect.position + Vector2(0, rect.size.y - visible_height), Vector2(rect.size.x, visible_height))
	draw_texture_rect_region(raw, destination, source, Color(1, 1, 1, alpha))
	if sequence.phase() == WorkshopLiveSequence.PRINTING:
		draw_line(Vector2(destination.position.x, destination.position.y), Vector2(destination.end.x, destination.position.y), Color("69efff"), 1.5)

func _draw_living(creature_id: String, plate: Rect2, alpha: float, departure: float) -> void:
	var living := living_textures.get(creature_id) as Texture2D
	if living == null or alpha <= 0.0:
		return
	var height := (plate.size.y / 0.13) * 0.34
	var width := height * CELL.size.x / CELL.size.y
	var offset := Vector2(plate.size.x * departure, -height * 0.70 * departure)
	var rect := Rect2(Vector2(plate.get_center().x - width * 0.5, plate.position.y + plate.size.y * 0.64 - height) + offset, Vector2(width, height))
	draw_texture_rect_region(living, rect, CELL, Color(1, 1, 1, alpha))

func _draw_team_plinths() -> void:
	var positions := [Vector2(0.62, 0.50), Vector2(0.75, 0.525), Vector2(0.88, 0.55)] if portrait else [Vector2(0.67, 0.73), Vector2(0.75, 0.805), Vector2(0.84, 0.905)]
	var height := size.y * (0.095 if portrait else 0.13)
	for index in 3:
		if index >= team_ids.size():
			continue
		var living := living_textures.get(team_ids[index]) as Texture2D
		if living == null:
			continue
		var width := height * CELL.size.x / CELL.size.y
		var foot := Vector2(size.x * positions[index].x, size.y * positions[index].y)
		var rect := Rect2(Vector2(foot.x - width * 0.5, foot.y - height), Vector2(width, height))
		draw_texture_rect_region(living, rect, CELL)

func _draw_sparks(plate: Rect2, amount: float) -> void:
	for index in 8:
		var angle := float(index) * TAU / 8.0
		var point := plate.get_center() + Vector2(cos(angle), sin(angle)) * lerpf(8.0, plate.size.x * 0.55, amount)
		draw_circle(point, 2.0 + amount * 2.0, Color("6defff") if index % 2 == 0 else Color("ffc15b"))

func _fit_rect(texture: Texture2D, bounds: Rect2) -> Rect2:
	if texture == null:
		return bounds
	var factor := minf(bounds.size.x / texture.get_width(), bounds.size.y / texture.get_height())
	var fitted := Vector2(texture.get_width(), texture.get_height()) * factor
	return Rect2(bounds.position + (bounds.size - fitted) * 0.5, fitted)
