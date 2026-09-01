class_name PhysicalBattlefieldStage
extends Control
## Portrait battle plate.  The chassis owns static material; every value and
## living print remains a native child anchored to its real slot.

const CACHE := preload("res://scripts/ui/creature_sprite_cache.gd")
const VFX := preload("res://scripts/ui/battle_move_vfx.gd")
const CHASSIS := preload("res://assets/ui/physical_ui/m2/battle-chassis-base-text-free-v1.png")
const CARD_BACK := preload("res://assets/cards/support_card_back_source_v1.png")
const SCHEMATIC := preload("res://scripts/ui/blueprint_schematic.gdshader")
const PORTRAIT_PRESENTER := preload("res://scripts/ui/physical_portrait_plate_presenter.gd")
const DESIGN := Vector2(941, 1672)
const RIVAL_PRINTER := Rect2(18, 50, 254, 328)
const PLAYER_PRINTER := Rect2(18, 1160, 255, 318)
const RIVAL_SLOTS := [Rect2(88, 516, 214, 139), Rect2(367, 516, 195, 139), Rect2(638, 516, 214, 139)]
const PLAYER_SLOTS := [Rect2(43, 835, 249, 176), Rect2(351, 835, 226, 176), Rect2(653, 835, 240, 176)]

var chassis: Texture2D = CHASSIS
var snapshot: Dictionary = {}
var event: Dictionary = {}
var _clips: Array[Control] = []
var _sprites: Array[TextureRect] = []
var _living_atlases: Array[AtlasTexture] = []
var _labels: Array[Label] = []
var _rival_backs: Array[TextureRect] = []
var _printer_clips: Array[Control] = []
var _printer_sprites: Array[TextureRect] = []
var _printer_schematic_clips: Array[Control] = []
var _printer_schematics: Array[TextureRect] = []
var _slot_lips: Array[ColorRect] = []
var _focus_marks: Array[Panel] = []
var _selection_marks: Array[Panel] = []
var _impact_marks: Array[Panel] = []
var _scan_lines: Array[ColorRect] = []
var _deploy_sprite: TextureRect
var _deploy_atlas: AtlasTexture
var _attack_sprite: TextureRect
var _attack_atlas: AtlasTexture
var _attack_overlay_index := -1
var _raw_texture_cache: Dictionary = {}
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

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
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
		caption.z_index = 22
		add_child(caption)
		_labels.append(caption)
		var lip := ColorRect.new(); lip.name = "BattleSlotLip%d" % index; lip.color = Color("392519d9"); lip.mouse_filter = Control.MOUSE_FILTER_IGNORE; lip.z_index = 20; add_child(lip); _slot_lips.append(lip)
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
		var schematic_clip := Control.new(); schematic_clip.name = "BattlePrinterSchematicClip%d" % seat; schematic_clip.clip_contents = true; schematic_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE; schematic_clip.z_index = 2; chamber.add_child(schematic_clip); _printer_schematic_clips.append(schematic_clip)
		var schematic := TextureRect.new(); schematic.name = "BattlePrinterSchematic%d" % seat; schematic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; schematic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; schematic.mouse_filter = Control.MOUSE_FILTER_IGNORE; var material := ShaderMaterial.new(); material.shader = SCHEMATIC; schematic.material = material; schematic_clip.add_child(schematic); _printer_schematics.append(schematic)
		var scan := ColorRect.new(); scan.name = "BattlePrinterScanLine%d" % seat; scan.color = Color("7fefff"); scan.mouse_filter = Control.MOUSE_FILTER_IGNORE; scan.z_index = 4; chamber.add_child(scan); _scan_lines.append(scan)
	_deploy_sprite = TextureRect.new(); _deploy_sprite.name = "BattleDeploySprite"; _deploy_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _deploy_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; _deploy_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE; _deploy_sprite.z_index = 30; add_child(_deploy_sprite)
	_deploy_atlas = AtlasTexture.new()
	_attack_sprite = TextureRect.new(); _attack_sprite.name = "BattleContactPeakOverlay"; _attack_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _attack_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; _attack_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE; _attack_sprite.z_index = 31; add_child(_attack_sprite)
	_attack_atlas = AtlasTexture.new()
	queue_redraw()

func _ring_style(color: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new(); style.bg_color = Color(0, 0, 0, 0); style.border_color = color; style.set_border_width_all(width); style.corner_radius_top_left = 8; style.corner_radius_top_right = 8; style.corner_radius_bottom_left = 8; style.corner_radius_bottom_right = 8
	return style

func configure(public_view: Dictionary, receipt: Dictionary = {}) -> void:
	snapshot = public_view.duplicate(true)
	if receipt != event:
		event = receipt.duplicate(true); _event_elapsed = 0.0; _event_serial = int(event.get("token", event.get("generation", _event_serial + 1)))
		if bool(event.get("reduced_motion", false)): _event_elapsed = VFX.event_duration(str(event.get("kind", "")))
		var requested_progress := int(event.get("presentation_progress_bps", -1))
		if requested_progress >= 0:
			_event_elapsed = VFX.event_duration(str(event.get("kind", ""))) * clampf(float(requested_progress) / 10000.0, 0.0, 1.0)
		_printed_preview = str(event.get("card_id", event.get("print_card_id", ""))) if str(event.get("kind", "")) in ["print", "deploy"] else ""
		_preview_seat = int(event.get("actor", 0))
	var pending: Dictionary = snapshot.get("pending", {}) if snapshot.get("pending", {}) is Dictionary else {}
	if _printed_preview.is_empty() and str(pending.get("kind", "")) == "place":
		_printed_preview = str((pending.get("unit", {}) as Dictionary).get("card_id", "")); _preview_seat = int(pending.get("seat", 0))
	_sync()
	set_process(true)

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
		var duration := VFX.event_duration(str(event.get("kind", "")))
		_event_elapsed = duration if bool(event.get("reduced_motion", false)) else minf(_event_elapsed + delta, duration)
		var pending: Dictionary = snapshot.get("pending", {}) if snapshot.get("pending", {}) is Dictionary else {}
		if _event_elapsed >= duration and str(pending.get("kind", "")) != "place": _printed_preview = ""
	_sync()

func _fit() -> Rect2:
	return PORTRAIT_PRESENTER.composition_rect(size, DESIGN)

func _rect(design_rect: Rect2) -> Rect2:
	var fit := _fit()
	return Rect2(fit.position + design_rect.position * fit.size / DESIGN, design_rect.size * fit.size / DESIGN)

func _sync() -> void:
	if _sprites.is_empty(): return
	var players: Array = snapshot.get("players", []) if snapshot.get("players", []) is Array else []
	for seat in 2:
		var player: Dictionary = players[seat] if seat < players.size() and players[seat] is Dictionary else {}
		var slots: Array = player.get("slots", []) if player.get("slots", []) is Array else []
		var design_slots: Array = PLAYER_SLOTS if seat == 0 else RIVAL_SLOTS
		for slot in 3:
			var index := seat * 3 + slot
			var unit = slots[slot] if slot < slots.size() else null
			# Authority removes a defeated defender immediately. Its public pre-action
			# receipt remains visible through contact, then drops on the defeat beat.
			if unit == null and str(event.get("kind", "")) == "attack" and seat == 1 - int(event.get("actor", -1)) and slot == int(event.get("target_slot", -2)) and _event_elapsed < VFX.event_duration("attack") * .72:
				unit = event.get("target", {})
			if str(event.get("kind", "")) == "deploy" and seat == int(event.get("actor", -1)) and slot == int(event.get("target_slot", -2)) and _event_elapsed < VFX.event_duration("deploy"):
				unit = null
			var rect := _rect(design_slots[slot])
			_clips[index].position = rect.position
			_clips[index].size = rect.size
			_sprites[index].position = Vector2.ZERO
			_sprites[index].size = rect.size
			_labels[index].position = rect.position + Vector2(0, rect.size.y * .78)
			_labels[index].size = Vector2(rect.size.x, rect.size.y * .18)
			_slot_lips[index].position = rect.position + Vector2(0, rect.size.y * .84)
			_slot_lips[index].size = Vector2(rect.size.x, rect.size.y * .16)
			_focus_marks[index].position = rect.position + Vector2(3,3); _focus_marks[index].size = rect.size - Vector2(6,6); _focus_marks[index].visible = _focus_seat == seat and _focus_slot == slot
			_selection_marks[index].position = rect.position + Vector2(8,8); _selection_marks[index].size = rect.size - Vector2(16,16); _selection_marks[index].visible = _selected_seat == seat and _selected_slot == slot
			_impact_marks[index].position = rect.position + rect.size * .23; _impact_marks[index].size = rect.size * .54; _impact_marks[index].visible = false
			if unit is Dictionary:
				var id := str((unit as Dictionary).get("card_id", "mossmunk"))
				var atlas := _living_atlases[index]
				atlas.atlas = CACHE.texture_for_creature(id)
				var frame := int(floor(_elapsed * 6.0)) % 4
				atlas.region = CACHE.safe_source_region(frame)
				_sprites[index].texture = atlas
				_sprites[index].position = _event_offset(seat, slot, rect.size)
				_sprites[index].scale = Vector2.ONE * _presentation_scale(id)
				_sprites[index].pivot_offset = rect.size * .5
				_sprites[index].modulate = Color.WHITE
				if str(event.get("kind", "")) == "attack" and seat == 1 - int(event.get("actor", -1)) and slot == int(event.get("target_slot", -2)):
					var hit_p := clampf(_event_elapsed / maxf(.01, VFX.event_duration("attack")), 0.0, 1.0)
					if hit_p >= .38 and hit_p < .78:
						_sprites[index].modulate = Color("ffd28b")
						_sprites[index].position += Vector2(sin(hit_p * 60.0) * rect.size.x * .035, 0)
						_impact_marks[index].visible = true
					if bool(event.get("defeated", false)) and hit_p >= .55: _sprites[index].modulate.a = clampf(1.0 - (hit_p - .55) / .17, 0.0, 1.0)
				_sprites[index].visible = index != _attack_overlay_index
				_labels[index].text = "%s  %d HP" % [str((unit as Dictionary).get("name", "Print")), int((unit as Dictionary).get("hp", 0))]
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
		var visible := not _printed_preview.is_empty() and _preview_seat == seat
		var chamber_size := _printer_clips[seat].size
		var pending: Dictionary = snapshot.get("pending", {}) if snapshot.get("pending", {}) is Dictionary else {}
		var progress := 1.0 if str(pending.get("kind", "")) == "place" else clampf(_event_elapsed / maxf(.01, VFX.event_duration("print")), 0.0, 1.0)
		var deploy_in_motion := str(event.get("kind", "")) == "deploy" and _preview_seat == seat and not bool(event.get("reduced_motion", false)) and _event_elapsed < VFX.event_duration("deploy")
		if str(event.get("kind", "")) == "deploy": progress = 1.0
		var cut := chamber_size.y * (1.0 - progress)
		_printer_sprites[seat].get_parent().position = Vector2(0, cut); _printer_sprites[seat].get_parent().size = Vector2(chamber_size.x, chamber_size.y - cut)
		_printer_sprites[seat].position = Vector2(0, -cut); _printer_sprites[seat].size = chamber_size
		_printer_schematic_clips[seat].position = Vector2.ZERO; _printer_schematic_clips[seat].size = Vector2(chamber_size.x, cut)
		_printer_schematics[seat].position = Vector2.ZERO; _printer_schematics[seat].size = chamber_size
		_printer_sprites[seat].visible = visible and not deploy_in_motion; _printer_schematics[seat].visible = visible and cut > 1.0 and not deploy_in_motion
		_scan_lines[seat].position = Vector2(0, maxf(0.0, cut - 2.0)); _scan_lines[seat].size = Vector2(chamber_size.x, 3); _scan_lines[seat].visible = visible and cut > 1.0 and not deploy_in_motion
		if visible:
			var raw_texture := _raw_texture_for(_printed_preview)
			_printer_sprites[seat].texture = raw_texture; _printer_schematics[seat].texture = raw_texture
	_sync_deploy_overlay()
	_sync_attack_overlay()

func _raw_texture_for(card_id: String) -> Texture2D:
	if _raw_texture_cache.has(card_id): return _raw_texture_cache[card_id] as Texture2D
	var texture := ResourceLoader.load(str(Catalog.creature(card_id).get("raw_print", ""))) as Texture2D
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
	if str(event.get("kind", "")) != "deploy" or bool(event.get("reduced_motion", false)): return
	var actor := int(event.get("actor", -1)); var target := int(event.get("target_slot", -1))
	if actor < 0 or actor > 1 or target < 0 or target > 2: return
	var p := clampf(_event_elapsed / maxf(.01, VFX.event_duration("deploy")), 0.0, 1.0)
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
	if p < .36: _deploy_sprite.texture = _raw_texture_for(_printed_preview)
	else:
		_deploy_atlas.atlas = CACHE.texture_for_creature(_printed_preview); _deploy_atlas.region = CACHE.safe_source_region(int(floor(_elapsed * 6.0)) % 4); _deploy_sprite.texture = _deploy_atlas
	_deploy_sprite.modulate = Color.WHITE; _deploy_sprite.scale = Vector2.ONE * (1.0 + sin(p * PI) * .08)

func _sync_attack_overlay() -> void:
	_attack_overlay_index = -1
	if _attack_sprite == null: return
	_attack_sprite.visible = false
	if str(event.get("kind", "")) != "attack": return
	var actor := int(event.get("actor", -1)); var source_slot := int(event.get("source_slot", event.get("slot", -1))); var target_slot := int(event.get("target_slot", -1))
	if actor < 0 or actor > 1 or source_slot < 0 or source_slot > 2: return
	var reduced := bool(event.get("reduced_motion", false))
	var p := 0.5 if reduced else clampf(_event_elapsed / maxf(.01, VFX.event_duration("attack")), 0.0, 1.0)
	if not reduced and (p < .42 or p > .58): return
	var source_rect := _rect((PLAYER_SLOTS if actor == 0 else RIVAL_SLOTS)[source_slot])
	var target_rect := _rect(RIVAL_PRINTER if actor == 0 else PLAYER_PRINTER) if target_slot < 0 else _rect((RIVAL_SLOTS if actor == 0 else PLAYER_SLOTS)[clampi(target_slot, 0, 2)])
	# Keep the contact clearly inside the target field but bias the root overlay
	# away from the bottom native name/HP strip. Rects are already stage-scaled,
	# so this remains the same physical relationship at both portrait sizes.
	var contact_center := target_rect.get_center() - Vector2(target_rect.size.x * .08, target_rect.size.y * .42)
	var contact_size := source_rect.size * 1.08
	_attack_sprite.position = contact_center - contact_size * .5
	_attack_sprite.size = contact_size
	var players: Array = snapshot.get("players", []) if snapshot.get("players", []) is Array else []
	var actor_slots: Array = (players[actor] as Dictionary).get("slots", []) if actor < players.size() and players[actor] is Dictionary else []
	var unit: Dictionary = actor_slots[source_slot] if source_slot < actor_slots.size() and actor_slots[source_slot] is Dictionary else {}
	var card_id := str(unit.get("card_id", event.get("card_id", "mossmunk")))
	_attack_atlas.atlas = CACHE.texture_for_creature(card_id)
	_attack_atlas.region = CACHE.safe_source_region(int(floor(_elapsed * 6.0)) % 4)
	_attack_sprite.texture = _attack_atlas
	_attack_sprite.modulate = Color("ffffff") if not reduced else Color("ffe5a8")
	_attack_sprite.visible = true
	_attack_overlay_index = actor * 3 + source_slot
	if _attack_overlay_index >= 0 and _attack_overlay_index < _sprites.size():
		_sprites[_attack_overlay_index].visible = false
		_labels[_attack_overlay_index].visible = false

func _event_offset(seat: int, slot: int, slot_size: Vector2) -> Vector2:
	if str(event.get("kind", "")) != "attack" or bool(event.get("reduced_motion", false)): return Vector2.ZERO
	if seat != int(event.get("actor", -1)) or slot != int(event.get("source_slot", event.get("slot", -1))): return Vector2.ZERO
	var progress := clampf(_event_elapsed / maxf(0.01, VFX.event_duration("attack")), 0.0, 1.0)
	# The root overlay owns the actual contact beat.  Retain the finite local
	# wind-up/recovery movement outside that beat so existing attack pacing stays
	# intact and only the home copy disappears while contact is presented.
	if progress >= .42 and progress <= .58: return Vector2.ZERO
	var target_slot := int(event.get("target_slot", -1))
	if target_slot > 2: return Vector2.ZERO
	var source_rect := _rect((PLAYER_SLOTS if seat == 0 else RIVAL_SLOTS)[slot])
	var target_rect := _rect(RIVAL_PRINTER if seat == 0 else PLAYER_PRINTER) if target_slot < 0 else _rect((RIVAL_SLOTS if seat == 0 else PLAYER_SLOTS)[target_slot])
	var direction := (target_rect.get_center() - source_rect.get_center()).normalized()
	return direction * slot_size.y * sin(progress * PI) * .52

func _draw() -> void:
	var fit := _fit()
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111b"), true)
	if chassis != null: draw_texture_rect(chassis, fit, false)
