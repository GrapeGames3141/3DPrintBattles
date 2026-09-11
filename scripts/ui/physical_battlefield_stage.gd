class_name PhysicalBattlefieldStage
extends Control
## Portrait battle plate.  The chassis owns static material; every value and
## living print remains a native child anchored to its real slot.

const FACING_CACHE := preload("res://scripts/ui/battle_facing_sprite_cache.gd")
const VFX := preload("res://scripts/ui/battle_move_vfx.gd")
const CHASSIS_PATH := "res://assets/ui/physical_ui/m11/battle-continuous-floor-master-v1.png"
const CARD_BACK := preload("res://assets/cards/support_card_back_source_v1.png")
const SCHEMATIC := preload("res://scripts/ui/battle_wireframe.gdshader")
const RAW_FILAMENT := preload("res://assets/creatures/2d/battle-facing/battle_raw_filament.gdshader")
const PORTRAIT_PRESENTER := preload("res://scripts/ui/physical_portrait_plate_presenter.gd")
const DESIGN := Vector2(941, 1672)
const RIVAL_PRINTER := Rect2(18, 50, 254, 328)
const PLAYER_PRINTER := Rect2(18, 1160, 255, 318)
const RIVAL_SLOTS := [Rect2(90, 380, 190, 305), Rect2(375, 380, 190, 305), Rect2(660, 380, 190, 305)]
const PLAYER_SLOTS := [Rect2(60, 680, 210, 305), Rect2(365, 680, 210, 305), Rect2(670, 680, 210, 305)]

signal attack_contact
signal presentation_finished(token: int)

var chassis: Texture2D
var snapshot: Dictionary = {}
var event: Dictionary = {}
var _clips: Array[Control] = []
var _sprites: Array[TextureRect] = []
var _living_atlases: Array[AtlasTexture] = []
var _labels: Array[Label] = []
var _rival_backs: Array[TextureRect] = []
var _printer_clips: Array[Control] = []
var _printer_sprites: Array[TextureRect] = []
var _printer_facing_atlases: Array[AtlasTexture] = []
var _printer_filament_materials: Array[ShaderMaterial] = []
var _printer_schematic_clips: Array[Control] = []
var _printer_schematics: Array[TextureRect] = []
var _printer_fallbacks: Array[Label] = []
var _shadows: Array[Panel] = []
var _focus_marks: Array[Panel] = []
var _selection_marks: Array[Panel] = []
var _impact_marks: Array[Panel] = []
var _scan_lines: Array[ColorRect] = []
var _deploy_sprite: TextureRect
var _deploy_atlas: AtlasTexture
var _deploy_filament_material: ShaderMaterial
var _attack_sprite: TextureRect
var _attack_atlas: AtlasTexture
var _attack_overlay_index := -1
var _raw_texture_cache: Dictionary = {}
var _facing_fallbacks: Dictionary = {}
var _elapsed := 0.0
var _event_elapsed := 0.0
var _event_serial := -1
var _printed_preview := ""
var _preview_seat := 0
var _focus_seat := -1
var _focus_slot := -1
var _selected_seat := -1
var _selected_slot := -1
var _large_text_layout := false
var _attack_contact_emitted := false
var _presentation_finished_emitted := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	chassis = ResourceLoader.load(CHASSIS_PATH) as Texture2D
	for index in 6:
		var clip := Control.new(); clip.name = "BattleSlotClip%d" % index; clip.clip_contents = true; clip.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(clip); _clips.append(clip)
		var sprite := TextureRect.new()
		sprite.name = "LivingPrintSlot%d" % index
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		clip.add_child(sprite)
		_sprites.append(sprite)
		var living_atlas := AtlasTexture.new()
		_living_atlases.append(living_atlas)
		var caption := Label.new()
		caption.name = "LivingPrintCaption%d" % index
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.add_theme_font_size_override("font_size", 13)
		# Captions remain native feedback and must stay readable over the root-level
		# attack/deploy overlays (z 30/31) without changing combat geometry.
		caption.z_index = 32
		caption.add_theme_constant_override("outline_size", 2)
		caption.add_theme_color_override("font_outline_color", Color("111820"))
		add_child(caption)
		_labels.append(caption)
		var shadow := Panel.new(); shadow.name = "BattleGroundShadow%d" % index; shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE; shadow.z_index = 2; shadow.add_theme_stylebox_override("panel", _ground_shadow_style()); add_child(shadow); _shadows.append(shadow)
		var focus := Panel.new(); focus.name = "BattleFocusRing%d" % index; focus.mouse_filter = Control.MOUSE_FILTER_IGNORE; focus.z_index = 21; focus.add_theme_stylebox_override("panel", _ring_style(Color("71ecff"), 3)); add_child(focus); _focus_marks.append(focus)
		var selected := Panel.new(); selected.name = "BattleSelectionRing%d" % index; selected.mouse_filter = Control.MOUSE_FILTER_IGNORE; selected.z_index = 21; selected.add_theme_stylebox_override("panel", _ring_style(Color("f1be69"), 3)); add_child(selected); _selection_marks.append(selected)
		var impact := Panel.new(); impact.name = "BattleImpactCue%d" % index; impact.mouse_filter = Control.MOUSE_FILTER_IGNORE; impact.z_index = 23; impact.add_theme_stylebox_override("panel", _ring_style(Color("ffd77a99"), 4)); add_child(impact); _impact_marks.append(impact)
	for index in 5:
		var back := TextureRect.new()
		back.name = "RivalConcealedCard%d" % index
		back.texture = CARD_BACK
		back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(back)
		_rival_backs.append(back)
	for seat in 2:
		var chamber := Control.new(); chamber.name = "BattlePrinterClip%d" % seat; chamber.clip_contents = true; chamber.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(chamber); _printer_clips.append(chamber)
		var solid_clip := Control.new(); solid_clip.name = "BattlePrinterSolidClip%d" % seat; solid_clip.clip_contents = true; solid_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE; chamber.add_child(solid_clip)
		var raw := TextureRect.new(); raw.name = "BattlePrinterSolidRaw%d" % seat; raw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; raw.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; raw.mouse_filter = Control.MOUSE_FILTER_IGNORE; solid_clip.add_child(raw); _printer_sprites.append(raw)
		_printer_facing_atlases.append(AtlasTexture.new())
		var filament_material := ShaderMaterial.new(); filament_material.shader = RAW_FILAMENT; _printer_filament_materials.append(filament_material)
		var schematic_clip := Control.new(); schematic_clip.name = "BattlePrinterSchematicClip%d" % seat; schematic_clip.clip_contents = true; schematic_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE; schematic_clip.z_index = 2; chamber.add_child(schematic_clip); _printer_schematic_clips.append(schematic_clip)
		var schematic := TextureRect.new(); schematic.name = "BattlePrinterSchematic%d" % seat; schematic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; schematic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; schematic.mouse_filter = Control.MOUSE_FILTER_IGNORE; var material := ShaderMaterial.new(); material.shader = SCHEMATIC; schematic.material = material; schematic_clip.add_child(schematic); _printer_schematics.append(schematic)
		var scan := ColorRect.new(); scan.name = "BattlePrinterScanLine%d" % seat; scan.color = Color("7fefff"); scan.mouse_filter = Control.MOUSE_FILTER_IGNORE; scan.z_index = 4; chamber.add_child(scan); _scan_lines.append(scan)
		var fallback := Label.new(); fallback.name = "BattlePrinterArtFallback%d" % seat; fallback.text = "PRINT ART\nUNAVAILABLE"; fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; fallback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; fallback.add_theme_font_size_override("font_size", 10); fallback.add_theme_color_override("font_color", Color("9af4ff")); fallback.tooltip_text = "This printed item has no approved battle art. The checked battle continues."; fallback.accessibility_name = fallback.tooltip_text; fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE; fallback.z_index = 5; chamber.add_child(fallback); _printer_fallbacks.append(fallback)
	_deploy_sprite = TextureRect.new(); _deploy_sprite.name = "BattleDeploySprite"; _deploy_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _deploy_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; _deploy_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE; _deploy_sprite.z_index = 30; add_child(_deploy_sprite)
	_deploy_atlas = AtlasTexture.new()
	_deploy_filament_material = ShaderMaterial.new()
	_deploy_filament_material.shader = RAW_FILAMENT
	_attack_sprite = TextureRect.new(); _attack_sprite.name = "BattleContactPeakOverlay"; _attack_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _attack_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; _attack_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE; _attack_sprite.z_index = 31; add_child(_attack_sprite)
	_attack_atlas = AtlasTexture.new()
	queue_redraw()

func _ring_style(color: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0, 0, 0, 0); style.border_color = color; style.set_border_width_all(width); style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	return style

func _ground_shadow_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.01, 0.02, 0.03, .42)
	style.corner_radius_top_left = 99
	style.corner_radius_top_right = 99
	style.corner_radius_bottom_left = 99
	style.corner_radius_bottom_right = 99
	return style

func configure(public_view: Dictionary, receipt: Dictionary = {}) -> void:
	snapshot = public_view.duplicate(true)
	# Main re-renders once when an attack reaches visual contact so the native HUD
	# can switch to the resolved truth.  That snapshot refresh must not restart the
	# stage clock or replay the attack.  A receipt token/serial is the presentation
	# owner; content changes inside that same receipt are visual state updates.
	if not _same_presentation(receipt):
		event = receipt.duplicate(true); _event_elapsed = 0.0; _event_serial = _presentation_identity(event)
		_attack_contact_emitted = false
		_presentation_finished_emitted = false
		if bool(event.get("reduced_motion", false)): _event_elapsed = _event_duration()
		var requested_progress := int(event.get("presentation_progress_bps", -1))
		if requested_progress >= 0:
			_event_elapsed = _event_duration() * clampf(float(requested_progress) / 10000.0, 0.0, 1.0)
		_preview_seat = int(event.get("actor", 0))
		_printed_preview = ""
	_sync()
	set_process(true)

func _presentation_identity(receipt: Dictionary) -> int:
	return int(receipt.get("presentation_token", receipt.get("token", receipt.get("generation", -1))))

func _same_presentation(receipt: Dictionary) -> bool:
	var current_kind := str(event.get("kind", ""))
	var candidate_kind := str(receipt.get("kind", ""))
	if current_kind.is_empty() or candidate_kind.is_empty():
		return current_kind.is_empty() and candidate_kind.is_empty()
	return current_kind == candidate_kind and _presentation_identity(receipt) == _event_serial and int(receipt.get("generation", -1)) == int(event.get("generation", -2))

func anchors() -> Dictionary:
	return {"rival_printer":RIVAL_PRINTER, "player_printer":PLAYER_PRINTER, "rival_slots":RIVAL_SLOTS.duplicate(), "player_slots":PLAYER_SLOTS.duplicate()}

func set_focus(seat: int, slot: int) -> void:
	_focus_seat = seat; _focus_slot = slot; _sync()

func set_selected_slot(seat: int, slot: int) -> void:
	_selected_seat = seat; _selected_slot = slot; _sync()

func set_large_text_layout(enabled: bool) -> void:
	if _large_text_layout == enabled: return
	_large_text_layout = enabled
	_sync()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_sync()
		queue_redraw()

func _process(delta: float) -> void:
	_elapsed += delta
	if not str(event.get("kind", "")).is_empty():
		var duration := _event_duration()
		_event_elapsed = duration if bool(event.get("reduced_motion", false)) else minf(_event_elapsed + delta, duration)
		if _event_elapsed >= duration: _printed_preview = ""
		var active := _active_beat()
		if not _attack_contact_emitted and str((active.get("beat", {}) as Dictionary).get("kind", "")) == "attack" and float(active.get("progress", 0.0)) >= .42:
			_attack_contact_emitted = true
			attack_contact.emit()
		if _event_elapsed >= duration and not _presentation_finished_emitted:
			_presentation_finished_emitted = true
			presentation_finished.emit(int(event.get("presentation_token", event.get("token", _event_serial))))
	_sync()

func _fit() -> Rect2:
	return PORTRAIT_PRESENTER.composition_rect(size, DESIGN)

func _rect(design_rect: Rect2) -> Rect2:
	var fit := _fit()
	return Rect2(fit.position + design_rect.position * fit.size / DESIGN, design_rect.size * fit.size / DESIGN)

func _event_duration() -> float:
	return float(event.get("presentation_duration", VFX.event_duration(str(event.get("kind", "")))))

func attack_contact_reached() -> bool:
	return _attack_contact_emitted

func _active_beat() -> Dictionary:
	var beats: Array = event.get("presentation_beats", []) if event.get("presentation_beats", []) is Array else []
	if beats.is_empty() and not str(event.get("kind", "")).is_empty():
		var fallback_duration := maxf(.01, _event_duration())
		var fallback_work: Dictionary = {}
		var fallback_deployment: Dictionary = {}
		var fallback_events: Array = event.get("print_events", []) if event.get("print_events", []) is Array else []
		var fallback_deployments: Array = event.get("deployments", []) if event.get("deployments", []) is Array else []
		if not fallback_events.is_empty() and fallback_events[0] is Dictionary: fallback_work = fallback_events[0]
		if not fallback_deployments.is_empty() and fallback_deployments[0] is Dictionary: fallback_deployment = fallback_deployments[0]
		var fallback_beat := {"kind":str(event.get("kind", "")), "duration":fallback_duration, "work":fallback_work, "deployment":fallback_deployment, "card_id":str(event.get("card_id", event.get("print_card_id", ""))), "seat":int(event.get("actor", 0))}
		return {"index":0, "beat":fallback_beat, "elapsed":_event_elapsed, "duration":fallback_duration, "progress":clampf(_event_elapsed / fallback_duration, 0.0, 1.0)}
	var cursor := 0.0
	for index in beats.size():
		var beat: Dictionary = beats[index] if beats[index] is Dictionary else {}
		var duration := maxf(.01, float(beat.get("duration", 0.0)))
		if _event_elapsed < cursor + duration:
			return {"index":index, "beat":beat, "elapsed":maxf(0.0, _event_elapsed - cursor), "duration":duration, "progress":clampf((_event_elapsed - cursor) / duration, 0.0, 1.0)}
		cursor += duration
	return {}

func _deployment_end_times() -> Dictionary:
	var ends := {}
	var cursor := 0.0
	var beats: Array = event.get("presentation_beats", []) if event.get("presentation_beats", []) is Array else []
	for raw in beats:
		var beat: Dictionary = raw if raw is Dictionary else {}
		cursor += maxf(.01, float(beat.get("duration", 0.0)))
		if str(beat.get("kind", "")) == "deploy": ends[str(beat.get("job_id", ""))] = cursor
	return ends

func _concealed_jobs() -> Dictionary:
	var jobs := {}
	var end_times := _deployment_end_times()
	for job_id in end_times:
		if _event_elapsed < float(end_times[job_id]): jobs[str(job_id)] = true
	return jobs

func _sync() -> void:
	if _sprites.is_empty(): return
	var players: Array = snapshot.get("players", []) if snapshot.get("players", []) is Array else []
	var concealed_jobs := _concealed_jobs()
	for seat in 2:
		var player: Dictionary = players[seat] if seat < players.size() and players[seat] is Dictionary else {}
		var slots: Array = player.get("slots", []) if player.get("slots", []) is Array else []
		var design_slots: Array = PLAYER_SLOTS if seat == 0 else RIVAL_SLOTS
		for slot in 3:
			var index := seat * 3 + slot
			var unit = slots[slot] if slot < slots.size() else null
			# Authority removes a defeated defender immediately. Its public pre-action
			# receipt remains visible through contact, then drops on the defeat beat.
			# A staged replacement can already occupy this anchor in the resolved
			# snapshot; receipt identity, rather than a null-slot check, owns the
			# contact window so the replacement cannot erase its defeated defender.
			var active_beat := _active_beat()
			var contact_window := str((active_beat.get("beat", {}) as Dictionary).get("kind", "")) == "attack" and float(active_beat.get("progress", 0.0)) < .72
			if contact_window and seat == 1 - int(event.get("actor", -1)) and slot == int(event.get("target_slot", -2)):
				unit = event.get("target", {})
			if unit is Dictionary and concealed_jobs.has(str((unit as Dictionary).get("job_id", ""))) and _event_elapsed < _event_duration():
				unit = null
			var rect := _rect(design_slots[slot])
			_clips[index].position = rect.position
			_clips[index].size = rect.size
			_sprites[index].position = Vector2.ZERO
			_sprites[index].size = rect.size
			_labels[index].position = rect.position + Vector2(0, rect.size.y * .78)
			_labels[index].size = Vector2(rect.size.x, rect.size.y * .18)
			_shadows[index].position = rect.position + Vector2(rect.size.x * .20, rect.size.y * .82)
			_shadows[index].size = Vector2(rect.size.x * .60, maxf(3.0, rect.size.y * .08))
			_shadows[index].visible = unit is Dictionary
			# Attack contact temporarily moves this existing ground shadow with the
			# flyover. Restore its normal anchor/material every sync before that
			# presentation-only override can apply.
			_shadows[index].modulate = Color.WHITE
			_focus_marks[index].position = rect.position + Vector2(3,3); _focus_marks[index].size = rect.size - Vector2(6,6); _focus_marks[index].visible = _focus_seat == seat and _focus_slot == slot
			_selection_marks[index].position = rect.position + Vector2(8,8); _selection_marks[index].size = rect.size - Vector2(16,16); _selection_marks[index].visible = _selected_seat == seat and _selected_slot == slot
			_impact_marks[index].position = rect.position + rect.size * .23; _impact_marks[index].size = rect.size * .54; _impact_marks[index].visible = false
			if unit is Dictionary:
				var id := str((unit as Dictionary).get("card_id", "mossmunk"))
				var atlas := _living_atlases[index]
				var active_kind := str((active_beat.get("beat", {}) as Dictionary).get("kind", ""))
				var facing_texture := FACING_CACHE.texture_for_creature(id)
				if facing_texture == null:
					_report_facing_fallback(id, seat, active_kind if not active_kind.is_empty() else "idle")
					_sprites[index].visible = false
					var facing_status := "%s facing art unavailable for seat %d during %s." % [str((unit as Dictionary).get("name", "Print")), seat, active_kind if not active_kind.is_empty() else "idle"]
					_labels[index].text = "%s  FACING ART UNAVAILABLE" % str((unit as Dictionary).get("name", "Print"))
					_labels[index].tooltip_text = facing_status
					_labels[index].accessibility_name = facing_status
					_labels[index].visible = true
					continue
				atlas.atlas = facing_texture
				var attacking_unit := active_kind == "attack" and seat == int(event.get("actor", -1)) and slot == int(event.get("source_slot", event.get("slot", -1)))
				atlas.region = FACING_CACHE.safe_source_region(FACING_CACHE.frame_for_creature(id, seat, _elapsed, active_kind if attacking_unit else "", float(active_beat.get("progress", 1.0))))
				_sprites[index].texture = atlas
				_sprites[index].position = _event_offset(seat, slot, rect.size)
				_sprites[index].scale = Vector2.ONE * _presentation_scale(id)
				_sprites[index].pivot_offset = rect.size * .5
				_sprites[index].modulate = Color.WHITE
				if active_kind == "attack" and seat == 1 - int(event.get("actor", -1)) and slot == int(event.get("target_slot", -2)):
					var hit_p := float(active_beat.get("progress", 0.0))
					if hit_p >= .38 and hit_p < .78:
						_sprites[index].modulate = Color("ffd28b")
						_sprites[index].position += Vector2(sin(hit_p * 60.0) * rect.size.x * .035, 0)
						_impact_marks[index].visible = true
					if bool(event.get("defeated", false)) and hit_p >= .55: _sprites[index].modulate.a = clampf(1.0 - (hit_p - .55) / .17, 0.0, 1.0)
				_sprites[index].visible = index != _attack_overlay_index
				_labels[index].text = "%s  %d HP" % [str((unit as Dictionary).get("name", "Print")), int((unit as Dictionary).get("hp", 0))]
				_labels[index].tooltip_text = _labels[index].text
				_labels[index].accessibility_name = _labels[index].text
				_labels[index].visible = true
			else:
				_sprites[index].visible = false
				_labels[index].visible = false
	var rival: Dictionary = players[1] if players.size() > 1 and players[1] is Dictionary else {}
	var count := clampi(int(rival.get("hand_count", 0)), 0, _rival_backs.size())
	for index in _rival_backs.size():
		var back := _rival_backs[index]
		back.visible = index < count
		# Large native title uses the upper plate; move the concealed support backs
		# below it with a visible gap, before the rival printer readouts begin.
		var back_rect := Rect2(330 + index * 72, 120, 70, 72) if _large_text_layout else Rect2(330 + index * 72, 70, 70, 95)
		back.position = _rect(back_rect).position
		back.size = _rect(back_rect).size
	for seat in 2:
		var chamber_rect := _rect(PLAYER_PRINTER if seat == 0 else RIVAL_PRINTER)
		_printer_clips[seat].position = chamber_rect.position + chamber_rect.size * Vector2(.18, .24)
		_printer_clips[seat].size = chamber_rect.size * Vector2(.64, .58)
		var chamber_size := _printer_clips[seat].size
		var active := _active_beat()
		var beat: Dictionary = active.get("beat", {}) if active.get("beat", {}) is Dictionary else {}
		var work: Dictionary = beat.get("work", {}) if beat.get("work", {}) is Dictionary else {}
		var printing := str(beat.get("kind", "")) == "print" and not work.is_empty()
		var preview_id := str(beat.get("card_id", ""))
		var preview_seat := int(beat.get("seat", event.get("actor", 0)))
		var visible := printing and not preview_id.is_empty() and preview_seat == seat
		var progress := 0.0
		if printing:
			var total := maxi(1, int(work.get("total_work", 1)))
			var start := 1.0 - float(int(work.get("remaining_before", total))) / total
			var finish := 1.0 - float(int(work.get("remaining_after", 0))) / total
			var print_fraction := float(active.get("progress", 0.0))
			progress = lerpf(start, finish, print_fraction)
		var cut := chamber_size.y * (1.0 - progress)
		_printer_sprites[seat].get_parent().position = Vector2(0, cut); _printer_sprites[seat].get_parent().size = Vector2(chamber_size.x, chamber_size.y - cut)
		_printer_sprites[seat].position = Vector2(0, -cut); _printer_sprites[seat].size = chamber_size
		_printer_schematic_clips[seat].position = Vector2.ZERO; _printer_schematic_clips[seat].size = Vector2(chamber_size.x, cut)
		_printer_schematics[seat].position = Vector2.ZERO; _printer_schematics[seat].size = chamber_size
		_printer_fallbacks[seat].position = Vector2.ZERO; _printer_fallbacks[seat].size = chamber_size
		_printer_sprites[seat].visible = visible; _printer_schematics[seat].visible = visible and cut > 1.0
		_scan_lines[seat].position = Vector2(0, maxf(0.0, cut - 2.0)); _scan_lines[seat].size = Vector2(chamber_size.x, 3); _scan_lines[seat].visible = visible and cut > 1.0
		_printer_fallbacks[seat].visible = false
		if visible:
			var creature := Catalog.creature(preview_id)
			var raw_texture: Texture2D = null
			if not creature.is_empty():
				var facing_texture := FACING_CACHE.texture_for_creature(preview_id)
				if facing_texture != null:
					var printer_atlas := _printer_facing_atlases[seat]
					printer_atlas.atlas = facing_texture
					printer_atlas.region = FACING_CACHE.safe_source_region(FACING_CACHE.raw_frame_for_creature(preview_id, seat))
					raw_texture = printer_atlas
					_printer_sprites[seat].material = _printer_filament_materials[seat]
				else:
					_report_facing_fallback(preview_id, seat, "print")
			else:
				raw_texture = _raw_texture_for(preview_id)
				_printer_sprites[seat].material = null
			if raw_texture == null:
				_printer_sprites[seat].visible = false; _printer_schematics[seat].visible = false; _scan_lines[seat].visible = false; _printer_fallbacks[seat].visible = true
			else:
				_printer_sprites[seat].texture = raw_texture; _printer_schematics[seat].texture = raw_texture
	_sync_deploy_overlay()
	_sync_attack_overlay()

func _raw_texture_for(card_id: String) -> Texture2D:
	if _raw_texture_cache.has(card_id): return _raw_texture_cache[card_id] as Texture2D
	var creature := Catalog.creature(card_id)
	var raw_path := str(creature.get("raw_print", ""))
	if raw_path.is_empty() and card_id == "iron_gem": raw_path = "res://assets/ui/physical_ui/m11/iron_gem-raw-alpha-v1.png"
	if raw_path.is_empty() and card_id.ends_with("_full_suit"):
		var suit_id := card_id.trim_suffix("_full_suit")
		for suit in Catalog.SUITS:
			if str((suit as Dictionary).get("id", "")) == suit_id:
				raw_path = str((suit as Dictionary).get("raw_print", ""))
				break
	if raw_path.is_empty() and card_id.ends_with("_gem"):
		for core in Catalog.CORE_BLUEPRINTS:
			raw_path = str((core as Dictionary).get("raw_print", ""))
			if not raw_path.is_empty(): break
	# Legal support cards without approved battle raw art remain truthful finite
	# fallbacks. Never ask ResourceLoader to resolve an empty path during a live turn.
	if raw_path.is_empty():
		_raw_texture_cache[card_id] = null
		return null
	var texture := ResourceLoader.load(raw_path) as Texture2D
	_raw_texture_cache[card_id] = texture
	return texture

func _presentation_scale(card_id: String) -> float:
	# Tuned once against the stable safe source regions, never by per-frame image
	# scanning.  Mossmunk's authored art has larger transparent shoulders; it needs
	# a larger multiplier to occupy the same 55–70% usable-slot band.
	match card_id:
		"mossmunk": return 1.06
		"aquafin": return .92
		"cinderpaw": return .96
	return .94

func _sync_deploy_overlay() -> void:
	if _deploy_sprite == null: return
	_deploy_sprite.visible = false
	if bool(event.get("reduced_motion", false)): return
	var active := _active_beat()
	var beat: Dictionary = active.get("beat", {}) if active.get("beat", {}) is Dictionary else {}
	if str(beat.get("kind", "")) != "deploy": return
	var deployment: Dictionary = beat.get("deployment", {}) if beat.get("deployment", {}) is Dictionary else {}
	var actor := int(deployment.get("seat", -1)); var target := int(deployment.get("slot", -1))
	if actor < 0 or actor > 1 or target < 0 or target > 2: return
	var p := float(active.get("progress", 0.0))
	if p >= 1.0: return
	# The chamber is nested under a printer Control. Convert the screen-space
	# chamber rect back through this root stage transform, rather than assigning
	# child-local coordinates to the root deploy overlay.
	var chamber_global := _printer_clips[actor].get_global_rect()
	var stage_inverse := get_global_transform().affine_inverse()
	var source_origin := stage_inverse * chamber_global.position
	var source_end := stage_inverse * chamber_global.end
	var source := Rect2(source_origin, source_end - source_origin)
	var target_rect := _rect((PLAYER_SLOTS if actor == 0 else RIVAL_SLOTS)[target])
	var travel := clampf((p - .22) / .78, 0.0, 1.0)
	var rect := Rect2(source.position.lerp(target_rect.position, travel), source.size.lerp(target_rect.size, travel))
	# Keep the printed creature clear of the chamber chrome while it steps onto
	# the board.  This is stage-local geometry, so it remains correct when the
	# full 9:16 chassis is contained in a safe content rect.
	rect.position.y -= sin(travel * PI) * minf(source.size.y, target_rect.size.y) * .68
	_deploy_sprite.position = rect.position; _deploy_sprite.size = rect.size; _deploy_sprite.visible = true
	var card_id := str(beat.get("card_id", ""))
	var creature := Catalog.creature(card_id)
	if p < .36 and not creature.is_empty():
		var raw_facing_texture := FACING_CACHE.texture_for_creature(card_id)
		if raw_facing_texture == null:
			_report_facing_fallback(card_id, actor, "deploy_raw")
			_deploy_sprite.visible = false
			return
		_deploy_atlas.atlas = raw_facing_texture
		_deploy_atlas.region = FACING_CACHE.safe_source_region(FACING_CACHE.raw_frame_for_creature(card_id, actor))
		_deploy_sprite.texture = _deploy_atlas
		_deploy_sprite.material = _deploy_filament_material
	elif p < .36:
		_deploy_sprite.texture = _raw_texture_for(card_id)
		_deploy_sprite.material = null
	else:
		var facing_texture := FACING_CACHE.texture_for_creature(card_id)
		if facing_texture == null:
			_report_facing_fallback(card_id, actor, "deploy_awaken")
			_deploy_sprite.visible = false
			return
		_deploy_atlas.atlas = facing_texture
		_deploy_atlas.region = FACING_CACHE.safe_source_region(FACING_CACHE.frame_for_creature(card_id, actor, _elapsed, "deploy", p))
		_deploy_sprite.texture = _deploy_atlas
		_deploy_sprite.material = null
	_deploy_sprite.modulate = Color.WHITE; _deploy_sprite.scale = Vector2.ONE * (1.0 + sin(p * PI) * .08)

func _sync_attack_overlay() -> void:
	_attack_overlay_index = -1
	if _attack_sprite == null: return
	_attack_sprite.visible = false
	var active := _active_beat()
	var beat: Dictionary = active.get("beat", {}) if active.get("beat", {}) is Dictionary else {}
	if str(beat.get("kind", "")) != "attack": return
	var actor := int(event.get("actor", -1)); var source_slot := int(event.get("source_slot", event.get("slot", -1))); var target_slot := int(event.get("target_slot", -1))
	if actor < 0 or actor > 1 or source_slot < 0 or source_slot > 2: return
	var reduced := bool(event.get("reduced_motion", false))
	# Reduced motion owns the resolved combat frame, not an abbreviated contact
	# flyover. Leave the awakened attacker in its home slot and expose the damaged
	# target, printers, hands, and native HP labels together.
	if reduced:
		return
	var p := float(active.get("progress", 0.0))
	if p >= .94: return
	var source_rect := _rect((PLAYER_SLOTS if actor == 0 else RIVAL_SLOTS)[source_slot])
	var target_rect := _rect(RIVAL_PRINTER if actor == 0 else PLAYER_PRINTER) if target_slot < 0 else _rect((RIVAL_SLOTS if actor == 0 else PLAYER_SLOTS)[clampi(target_slot, 0, 2)])
	# Creature contact belongs at the target's physical center. Printer targets
	# retain their existing elevated reach so their internal hardware remains the
	# contact point instead of the machine's base.
	var contact_center := target_rect.get_center()
	if target_slot < 0:
		contact_center -= Vector2(target_rect.size.x * .08, target_rect.size.y * .42)
	var contact_size := source_rect.size * 1.08
	var travel := p / .48 if p < .48 else (1.0 - p) / .46
	var attack_origin := source_rect.get_center() - contact_size * .5
	var attack_position := attack_origin.lerp(contact_center - contact_size * .5, clampf(travel, 0.0, 1.0))
	# The contact sprite is a root overlay, not a chassis child. Keep creature
	# target contact within the battlefield slot span so it cannot enter either
	# printer or furniture. Printer-target attacks retain their intended reach.
	if target_slot >= 0:
		var battle_span := _rect(Rect2(0, RIVAL_SLOTS[0].position.y + 10.0, DESIGN.x, PLAYER_SLOTS[2].end.y - RIVAL_SLOTS[0].position.y - 10.0))
		var max_position := battle_span.end - contact_size
		attack_position = Vector2(clampf(attack_position.x, battle_span.position.x, max_position.x), clampf(attack_position.y, battle_span.position.y, max_position.y))
	_attack_sprite.position = attack_position
	_attack_sprite.size = contact_size
	var players: Array = snapshot.get("players", []) if snapshot.get("players", []) is Array else []
	var actor_slots: Array = (players[actor] as Dictionary).get("slots", []) if actor < players.size() and players[actor] is Dictionary else []
	var unit: Dictionary = actor_slots[source_slot] if source_slot < actor_slots.size() and actor_slots[source_slot] is Dictionary else {}
	var card_id := str(unit.get("card_id", event.get("card_id", "mossmunk")))
	var facing_texture := FACING_CACHE.texture_for_creature(card_id)
	if facing_texture == null:
		_report_facing_fallback(card_id, actor, "attack_contact")
		return
	_attack_atlas.atlas = facing_texture
	_attack_atlas.region = FACING_CACHE.safe_source_region(FACING_CACHE.frame_for_creature(card_id, actor, _elapsed, "attack", p))
	_attack_sprite.texture = _attack_atlas
	_attack_sprite.modulate = Color("ffffff") if not reduced else Color("ffe5a8")
	_attack_sprite.visible = true
	_attack_overlay_index = actor * 3 + source_slot
	if _attack_overlay_index >= 0 and _attack_overlay_index < _sprites.size():
		_sprites[_attack_overlay_index].visible = false
		_labels[_attack_overlay_index].visible = false
		var shadow := _shadows[_attack_overlay_index]
		shadow.position = attack_position + Vector2(contact_size.x * .20, contact_size.y * .82)
		shadow.size = Vector2(contact_size.x * .60, maxf(3.0, contact_size.y * .08))
		shadow.modulate = Color(1.0, 1.0, 1.0, lerpf(1.0, .45, clampf(travel, 0.0, 1.0)))
		shadow.visible = true

func _event_offset(seat: int, slot: int, slot_size: Vector2) -> Vector2:
	if str(event.get("kind", "")) != "attack" or bool(event.get("reduced_motion", false)): return Vector2.ZERO
	var active := _active_beat()
	if str((active.get("beat", {}) as Dictionary).get("kind", "")) != "attack": return Vector2.ZERO
	if seat != int(event.get("actor", -1)) or slot != int(event.get("source_slot", event.get("slot", -1))): return Vector2.ZERO
	var progress := float(active.get("progress", 0.0))
	# The root overlay owns the actual contact beat.  Retain the finite local
	# wind-up/recovery movement outside that beat so existing attack pacing stays
	# intact and only the home copy disappears while contact is presented.
	if progress <= .94: return Vector2.ZERO
	var target_slot := int(event.get("target_slot", -1))
	if target_slot > 2: return Vector2.ZERO
	var source_rect := _rect((PLAYER_SLOTS if seat == 0 else RIVAL_SLOTS)[slot])
	var target_rect := _rect(RIVAL_PRINTER if seat == 0 else PLAYER_PRINTER) if target_slot < 0 else _rect((RIVAL_SLOTS if seat == 0 else PLAYER_SLOTS)[target_slot])
	var direction := (target_rect.get_center() - source_rect.get_center()).normalized()
	return direction * slot_size.y * sin(progress * PI) * .52

func _report_facing_fallback(creature_id: String, seat: int, beat: String) -> void:
	var key := "%s:%d:%s" % [creature_id, seat, beat]
	if _facing_fallbacks.has(key):
		return
	_facing_fallbacks[key] = true
	push_error("Battle-facing presentation fallback: creature=%s seat=%d beat=%s. The accepted receipt will finish without legacy side-view substitution." % [creature_id, seat, beat])

func _draw() -> void:
	var fit := _fit()
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111b"), true)
	if chassis != null: draw_texture_rect(chassis, fit, false)
