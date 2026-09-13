class_name TeamPrototypeBattleVisual
extends Control
## Passive battlefield figures. The presenter supplies a single viewer-safe snapshot;
## this node never advances Rules, reads files, or requests a Runtime view per frame.

const Facing := preload("res://scripts/ui/battle_facing_sprite_cache.gd")
const PrintCompositor := preload("res://scripts/team_ui/team_prototype_print_compositor.gd")
const Seating := preload("res://scripts/team_ui/team_prototype_battle_seating.gd")

const ACTIVE_ROOTS := {"rival":Vector2(470.5, 620.3), "player":Vector2(470.5, 924.2)}
const READY_ROOTS := {
	"rival":[Vector2(442.8, 279.1), Vector2(749.9, 279.1)],
	"player":[Vector2(442.8, 1225.1), Vector2(749.9, 1225.1)],
}
const READY_ROOTS_LARGE := {
	"rival":[Vector2(442.8, 251.85), Vector2(749.9, 251.85)],
	"player":[Vector2(442.8, 1199.39), Vector2(749.9, 1199.39)],
}
const ACTIVE_SCALE := 202.60 / 380.0
const READY_SCALE_NORMAL := 86.60 / 380.0
const READY_SCALE_LARGE := 61.26 / 380.0
const ROOTS := {
	"cinderpaw":{"rival":[475, 475, 492], "player":[425, 426, 433]},
	"aquafin":{"rival":[487, 484, 484], "player":[421, 421, 404]},
	"mossmunk":{"rival":[486, 485, 488], "player":[425, 426, 434]},
	"voltwig":{"rival":[455, 455, 455], "player":[455, 455, 455]},
}

var _figures: Dictionary = {}
var _snapshot_key := ""
var _elapsed := 0.0
var _reduced_motion := false
var _printers: Dictionary = {}
var _equipment_textures: Dictionary = {}
var _last_companion_prints: Dictionary = {}
var _stage_progress_bps := 0
var _attack_sources: Dictionary = {}
var _defeated_ids: Dictionary = {}
var _entry_sources: Dictionary = {}
var _replacement_sources: Dictionary = {}
var _swap_sources: Dictionary = {}
var _previous_roots: Dictionary = {}
var _previous_scales: Dictionary = {}
var _stage_key := ""
var _stage_name := ""
var _enlarged := false
var _print_events: Dictionary = {}
var _awaken_events: Dictionary = {}
var _fit_events: Dictionary = {}
var _previous_stage: Dictionary = {}
var _print_configurations: Dictionary = {}
var _fit_configurations: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for seat_name in ["rival", "player"]:
		var printer := PrintCompositor.new()
		printer.name = "BattlePrinter_%s" % seat_name.capitalize()
		add_child(printer)
		_printers[seat_name] = printer


func set_projection(view: Dictionary, reduced_motion: bool, enlarged := false) -> void:
	_reduced_motion = reduced_motion
	_enlarged = enlarged
	var key := JSON.stringify(view)
	if key == _snapshot_key:
		return
	_snapshot_key = key
	var wanted := {}
	for seat_name in ["rival", "player"]:
		var seat: Dictionary = view.get("opponent", {}) if seat_name == "rival" else view.get("own", {})
		var seating: Dictionary = Seating.project(seat)
		var active := str(seating.get("active_id", ""))
		if not active.is_empty():
			var active_member := _member(seat, active)
			if not active_member.is_empty():
				wanted[active] = {"identity":active, "member":active_member, "seat":seat_name, "root":ACTIVE_ROOTS[seat_name], "slot":0}
		var bay_records: Array = seating.get("bays", [])
		for bay_index in bay_records.size():
			var member: Dictionary = bay_records[bay_index]
			if str(member.get("status", "")) == "Ready":
				var ready_id := str(member.get("identity_id", ""))
				wanted[ready_id] = {"identity":ready_id, "member":member, "seat":seat_name, "root":(_ready_roots(seat_name) as Array)[bay_index], "slot":bay_index + 1}
	for existing in _figures.keys():
		if not wanted.has(existing):
			var retired: Control = _figures[existing]
			if is_instance_valid(retired):
				retired.queue_free()
			_figures.erase(existing)
	for identity in wanted.keys():
		var record: Dictionary = wanted[identity]
		var node: Control = _figures.get(identity, null)
		if node == null or not is_instance_valid(node):
			node = _create_figure(str(identity))
			_figures[identity] = node
		_apply_figure(node, record)


func set_previous_projection(view: Dictionary, enlarged := false) -> void:
	_previous_roots = {}
	_previous_scales = {}
	_enlarged = enlarged
	for seat_name in ["rival", "player"]:
		var seat: Dictionary = view.get("opponent", {}) if seat_name == "rival" else view.get("own", {})
		var seating: Dictionary = Seating.project(seat)
		var active := str(seating.get("active_id", ""))
		if not active.is_empty():
			_previous_roots[active] = ACTIVE_ROOTS[seat_name]
			_previous_scales[active] = ACTIVE_SCALE
		var bays: Array = seating.get("bays", [])
		for index in bays.size():
			var identity := str((bays[index] as Dictionary).get("identity_id", ""))
			if not identity.is_empty():
				_previous_roots[identity] = (_ready_roots(seat_name) as Array)[index]
				_previous_scales[identity] = _ready_scale()


func set_previous_stage(stage: Dictionary) -> void:
	# Damage has only the defender-side result. Retain the prior AttackLock receipt
	# so the finite action still belongs to the attacker that locked this exact beat.
	_previous_stage = stage.duplicate(true)


func set_stage(stage: Dictionary, progress_bps: int, reduced_motion: bool, stage_identity := "") -> void:
	_stage_progress_bps = clampi(progress_bps, 0, 10000)
	var stage_key := stage_identity if not stage_identity.is_empty() else str(stage.get("name", ""))
	if stage_key != _stage_key:
		_stage_key = stage_key
		_stage_name = str(stage.get("name", ""))
		_prepare_stage_events(stage)
	for seat_name in ["rival", "player"]:
		var printer: Variant = _printers.get(seat_name, null)
		if printer == null:
			continue
		var event: Dictionary = _print_events.get(seat_name, {})
		if not event.is_empty():
			var head: Dictionary = event.get("head_before", {})
			if str(head.get("kind", "")) == "equipment":
				_render_equipment_print(printer, head, event, seat_name, progress_bps, reduced_motion)
				continue
			_render_companion_print(printer, event, seat_name, progress_bps, reduced_motion)
			continue
		if _awaken_events.has(seat_name):
			var awaken_event: Dictionary = _awaken_events[seat_name]
			var cached: Dictionary = _last_companion_prints.get(seat_name, {})
			if not cached.is_empty():
				_render_cached_awaken(printer, cached, progress_bps, reduced_motion)
			else:
				printer.render_state(null, Rect2(), Vector2.ZERO, Vector2.ZERO, 0.0, Rect2(), 0, 0, Vector2.ZERO, reduced_motion, false)
			continue
		if _fit_events.has(seat_name):
			_render_equipment_fit(printer, _fit_events[seat_name] as Dictionary, seat_name, progress_bps, reduced_motion)
			continue
		printer.render_state(null, Rect2(), Vector2.ZERO, Vector2.ZERO, 0.0, Rect2(), 0, 0, Vector2.ZERO, reduced_motion, false)
	for holder_value in _figures.values():
		if holder_value is Control and is_instance_valid(holder_value):
			_apply_pose(holder_value as Control)


func _prepare_stage_events(stage: Dictionary) -> void:
	_print_events = {}
	_awaken_events = {}
	_fit_events = {}
	_print_configurations = {}
	_fit_configurations = {}
	_attack_sources = {}
	_defeated_ids = {}
	_entry_sources = {}
	_replacement_sources = {}
	_swap_sources = {}
	var stage_name := str(stage.get("name", ""))
	var locked_by_target_beat := {}
	var ambiguous_locks := {}
	if stage_name == "Damage" and str(_previous_stage.get("name", "")) == "AttackLock":
		for prior_value in _previous_stage.get("events", []):
			if not prior_value is Dictionary:
				continue
			var prior: Dictionary = prior_value
			if str(prior.get("type", "")) != "attack_locked":
				continue
			var pair_key := _attack_pair_key(prior)
			if locked_by_target_beat.has(pair_key):
				locked_by_target_beat.erase(pair_key)
				ambiguous_locks[pair_key] = true
			elif not ambiguous_locks.has(pair_key):
				locked_by_target_beat[pair_key] = prior
	for event_value in stage.get("events", []):
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		var event_type := str(event.get("type", ""))
		var seat := str(event.get("seat", ""))
		if event_type == "print_work":
			_print_events[seat] = event
			var head: Dictionary = event.get("head_before", {})
			if str(head.get("kind", "")) == "equipment":
				_print_configurations[seat] = _equipment_configuration(str(head.get("card_id", "")), seat)
			else:
				_print_configurations[seat] = _companion_configuration(str(event.get("member_identity_id", "")), seat)
		elif event_type == "awaken_ready":
			_awaken_events[seat] = event
			# An awakened companion may follow another completed print in the same
			# seat. Its cached subject must be keyed by this event identity, never
			# by whatever the seat printed previously.
			_last_companion_prints[seat] = _companion_configuration(str(event.get("member_identity_id", "")), seat)
		elif event_type == "equipment_fit":
			_fit_events[seat] = event
			_fit_configurations[seat] = _equipment_configuration(str(event.get("card_id", "")), seat, true)
		elif event_type == "attack_locked":
			_attack_sources[str(event.get("source_identity_id", ""))] = seat
		elif event_type == "damage":
			var pair_key := _damage_pair_key(event)
			var lock: Dictionary = {} if ambiguous_locks.has(pair_key) else locked_by_target_beat.get(pair_key, {})
			if not lock.is_empty():
				_attack_sources[str(lock.get("source_identity_id", ""))] = str(lock.get("seat", ""))
		elif event_type == "defeat":
			var defeated_id := str(event.get("member_identity_id", ""))
			_defeated_ids[defeated_id] = true
			_ensure_transient_figure(defeated_id, seat, _previous_roots.get(defeated_id, ACTIVE_ROOTS.get(seat, Vector2.ZERO)))
		elif event_type == "companion_entered":
			_entry_sources[str(event.get("member_identity_id", ""))] = _printer_bed(seat)
		elif event_type == "replacement":
			var replacement_id := str(event.get("member_identity_id", ""))
			_replacement_sources[replacement_id] = {
				"root": _previous_roots.get(replacement_id, Vector2.ZERO),
				"scale": float(_previous_scales.get(replacement_id, _ready_scale())),
			}
		elif event_type == "swap":
			# Both records remain living throughout Swap.  Their post-stage projection
			# already assigns the incoming Active and outgoing Ready roots; cache each
			# prior root once at this receipt boundary and interpolate identities only.
			var incoming_id := str(event.get("active_member_id", ""))
			var outgoing_id := str(event.get("reserve_member_id", ""))
			if not incoming_id.is_empty():
				_swap_sources[incoming_id] = {
					"root": _previous_roots.get(incoming_id, Vector2.ZERO),
					"scale": float(_previous_scales.get(incoming_id, _ready_scale())),
					"lane_x": 80.0,
				}
			if not outgoing_id.is_empty():
				_swap_sources[outgoing_id] = {
					"root": _previous_roots.get(outgoing_id, Vector2.ZERO),
					"scale": float(_previous_scales.get(outgoing_id, ACTIVE_SCALE)),
					"lane_x": -80.0,
				}


func _render_companion_print(printer: Variant, event: Dictionary, seat_name: String, progress_bps: int, reduced_motion: bool) -> void:
	var cached: Dictionary = _print_configurations.get(seat_name, {})
	if cached.is_empty():
		printer.render_state(null, Rect2(), Vector2.ZERO, Vector2.ZERO, 0.0, Rect2(), 0, 0, Vector2.ZERO, reduced_motion, false)
		return
	var total := maxi(int(event.get("work_total", 1)), 1)
	var before := clampi(int(event.get("work_before", total)), 0, total)
	var after := clampi(int(event.get("work_after", before)), 0, total)
	var completion := lerpf(float(total - before), float(total - after), float(clampi(progress_bps, 0, 10000)) / 10000.0)
	var raw := clampi(roundi(10000.0 * completion / float(total)), 0, 10000)
	_last_companion_prints[seat_name] = cached
	printer.render_state(cached.texture as Texture2D, cached.region as Rect2, cached.root as Vector2, cached.bed as Vector2, 117.62 / 380.0, cached.aperture as Rect2, raw, 0, Vector2.ZERO, reduced_motion, true, 1.0, {"tracking":false, "shadow_size":Vector2(111.13, 14.70)})


func _companion_configuration(identity: String, seat_name: String) -> Dictionary:
	var creature := identity.get_slice(":", 2)
	if creature.is_empty():
		return {}
	var texture := Facing.texture_for_creature(creature)
	var source_seat := 1 if seat_name == "rival" else 0
	var frame := Facing.raw_frame_for_creature(creature, source_seat)
	var region := Facing.safe_source_region_for_creature(creature, frame)
	if texture == null or region.size.x <= 1.0 or region.size.y <= 1.0:
		return {}
	return {
		"texture": texture,
		"region": region,
		"root": Vector2(190, _root_y(creature, seat_name, 0) - 2),
		"bed": _printer_bed(seat_name),
		"aperture": _printer_aperture(seat_name),
	}


func _printer_aperture(seat_name: String) -> Rect2:
	return Rect2(15, 140, 285, 300) if seat_name == "rival" else Rect2(15, 1055, 285, 300)


func _printer_bed(seat_name: String) -> Vector2:
	return Vector2(163.4, 333.3) if seat_name == "rival" else Vector2(163.4, 1310.6)


func _render_cached_awaken(printer: Variant, cached: Dictionary, progress_bps: int, reduced_motion: bool) -> void:
	printer.render_state(cached.texture as Texture2D, cached.region as Rect2, cached.root as Vector2, cached.bed as Vector2, 117.62 / 380.0, cached.aperture as Rect2, 10000, progress_bps, Vector2.ZERO, reduced_motion, true, 1.0, {"tracking":false, "shadow_size":Vector2(111.13, 14.70)})


func _render_equipment_print(printer: Variant, head: Dictionary, event: Dictionary, seat_name: String, progress_bps: int, reduced_motion: bool) -> void:
	var config: Dictionary = _print_configurations.get(seat_name, {})
	if config.is_empty():
		printer.render_state(null, Rect2(), Vector2.ZERO, Vector2.ZERO, 0.0, Rect2(), 0, 0, Vector2.ZERO, reduced_motion, false)
		return
	var total := maxi(int(event.get("work_total", 1)), 1)
	var before := clampi(int(event.get("work_before", total)), 0, total)
	var after := clampi(int(event.get("work_after", before)), 0, total)
	var completion := lerpf(float(total - before), float(total - after), float(clampi(progress_bps, 0, 10000)) / 10000.0)
	var raw := clampi(roundi(10000.0 * completion / float(total)), 0, 10000)
	printer.render_state(config.texture as Texture2D, config.region as Rect2, config.root as Vector2, config.bed as Vector2, float(config.scale), config.aperture as Rect2, raw, 0, Vector2.ZERO, reduced_motion, true, 1.0, {"tracking":false, "shadow_size":Vector2(111.13, 14.70)})


func _render_equipment_fit(printer: Variant, event: Dictionary, seat_name: String, progress_bps: int, reduced_motion: bool) -> void:
	var config: Dictionary = _fit_configurations.get(seat_name, {})
	if config.is_empty():
		printer.render_state(null, Rect2(), Vector2.ZERO, Vector2.ZERO, 0.0, Rect2(), 0, 0, Vector2.ZERO, reduced_motion, false)
		return
	var opacity := 1.0 if reduced_motion else 1.0 - float(clampi(progress_bps, 0, 10000)) / 10000.0
	printer.render_state(config.texture as Texture2D, config.region as Rect2, config.root as Vector2, config.bed as Vector2, float(config.scale), config.aperture as Rect2, 10000, 10000, Vector2.ZERO, reduced_motion, opacity > 0.01, opacity, {"tracking":false, "shadow_size":Vector2(111.13, 14.70)})


func _equipment_configuration(card_id: String, seat_name: String, completed := false) -> Dictionary:
	var path := ""
	var root := Vector2(632, 1042)
	if card_id == "standard_full_suit":
		path = "res://assets/ui/physical_ui/team-prototype/EQ-R1-quadruped-armor-alpha-v1.png"
	elif card_id == "iron_gem":
		path = "res://assets/ui/physical_ui/m11/iron-gem-completed-transparent-imagegen-v1.png" if completed else "res://assets/ui/physical_ui/m11/iron_gem-raw-alpha-v1.png"
		root = Vector2(634.5, 1092)
	if path.is_empty():
		return {}
	var texture: Texture2D = _equipment_textures.get(path, null)
	if texture == null:
		texture = ResourceLoader.load(path) as Texture2D
		if texture != null:
			_equipment_textures[path] = texture
	if texture == null:
		return {}
	var aperture := Rect2(85, 204.2, 156.83, 156.83) if seat_name == "rival" else Rect2(85, 1181, 156.83, 156.83)
	var bed := Vector2(163.4, 333.3) if seat_name == "rival" else Vector2(163.4, 1310.6)
	return {"texture":texture, "region":Rect2(0, 0, 1254, 1254), "root":root, "bed":bed, "scale":156.83 / 1254.0, "aperture":aperture}


func _process(delta: float) -> void:
	if _reduced_motion:
		return
	_elapsed += minf(delta, 0.05)
	# Receipt poses are applied by set_stage from the controller-owned boundary.
	# Editable Plan has no stage callback, so this passive owner advances only idle
	# figures here without duplicating receipt pose updates.
	if _stage_name.is_empty():
		for record_value in _figures.values():
			if record_value is Control and is_instance_valid(record_value):
				_apply_pose(record_value as Control)


func printer_snapshot(seat_name: String) -> Dictionary:
	var printer: Variant = _printers.get(seat_name, null)
	if printer != null and printer.has_method("presentation_snapshot"):
		return printer.presentation_snapshot()
	return {"valid":false}


func figure_snapshot(identity: String) -> Dictionary:
	var holder: Control = _figures.get(identity, null)
	if holder == null or not is_instance_valid(holder):
		return {"valid":false}
	var sprite := holder.get_node_or_null("Sprite") as TextureRect
	var shadow := holder.get_node_or_null("Shadow") as TextureRect
	if sprite == null or shadow == null:
		return {"valid":false}
	return {
		"valid": true,
		"visible": holder.visible,
		"sprite_position": sprite.position,
		"sprite_size": sprite.size,
		"shadow_center": shadow.position + shadow.size * 0.5,
	}


func _create_figure(identity: String) -> Control:
	var holder := Control.new()
	holder.name = "BattleFigure_%s" % identity.replace(":", "_")
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow := _shadow()
	shadow.name = "Shadow"
	holder.add_child(shadow)
	var sprite := TextureRect.new()
	sprite.name = "Sprite"
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(sprite)
	add_child(holder)
	return holder


func _apply_figure(holder: Control, record: Dictionary) -> void:
	var member: Dictionary = record.member
	var creature := str(member.get("member_id", ""))
	var seat := str(record.seat)
	var source_seat := 1 if seat == "rival" else 0
	var frame := Facing.frame_for_creature(creature, source_seat, _elapsed)
	var texture := Facing.texture_for_creature(creature)
	if texture == null or frame < 0:
		holder.hide()
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Facing.safe_source_region_for_creature(creature, frame)
	var root_y := _root_y(creature, seat, _pose_index(frame))
	var scale := ACTIVE_SCALE if int(record.slot) == 0 else _ready_scale()
	var root: Vector2 = record.root
	var sprite := holder.get_node("Sprite") as TextureRect
	var shadow := holder.get_node("Shadow") as TextureRect
	sprite.texture = atlas
	sprite.size = atlas.region.size * scale
	sprite.position = root - Vector2(190.0, root_y - 2.0) * scale
	shadow.size = _shadow_size(int(record.slot), scale)
	shadow.position = root - shadow.size * 0.5 + Vector2(0, -3)
	holder.set_meta("creature", creature)
	holder.set_meta("identity", str(record.get("identity", "")))
	holder.set_meta("seat", seat)
	holder.set_meta("root", root)
	holder.set_meta("scale", scale)
	holder.set_meta("slot", int(record.slot))
	holder.show()


func _apply_pose(holder: Control) -> void:
	var creature := str(holder.get_meta("creature", ""))
	var seat := str(holder.get_meta("seat", "player"))
	var source_seat := 1 if seat == "rival" else 0
	var sprite := holder.get_node_or_null("Sprite") as TextureRect
	if sprite == null or creature.is_empty():
		return
	var identity := str(holder.get_meta("identity", ""))
	var attacking := _attack_sources.has(identity)
	var beat_progress := _attack_progress()
	var frame := Facing.frame_for_creature(creature, source_seat, _elapsed, "attack" if attacking else "", beat_progress)
	var atlas := sprite.texture as AtlasTexture
	if atlas == null or frame < 0:
		return
	atlas.region = Facing.safe_source_region_for_creature(creature, frame)
	var root: Vector2 = holder.get_meta("root", Vector2.ZERO)
	var scale: float = float(holder.get_meta("scale", ACTIVE_SCALE))
	if _entry_sources.has(identity):
		root = _entry_sources[identity].lerp(root, 1.0 if _reduced_motion else _stage_progress_bps / 10000.0)
	elif _replacement_sources.has(identity):
		var replacement: Dictionary = _replacement_sources[identity]
		var replacement_q := 1.0 if _reduced_motion else float(_stage_progress_bps) / 10000.0
		var replacement_root: Vector2 = replacement.get("root", Vector2.ZERO)
		if replacement_root != Vector2.ZERO:
			root = replacement_root.lerp(root, replacement_q)
			scale = lerpf(float(replacement.get("scale", _ready_scale())), scale, replacement_q)
	elif _swap_sources.has(identity):
		var swap: Dictionary = _swap_sources[identity]
		var source_root: Vector2 = swap.get("root", Vector2.ZERO)
		var source_scale := float(swap.get("scale", scale))
		var q := 1.0 if _reduced_motion else float(_stage_progress_bps) / 10000.0
		if source_root != Vector2.ZERO:
			root = source_root.lerp(root, q)
			scale = lerpf(source_scale, scale, q)
		var lane_x := 0.0 if _reduced_motion else float(swap.get("lane_x", 0.0)) * sin(PI * q)
		root += Vector2(lane_x, 0.0)
	var offset := _stage_offset(identity, seat)
	sprite.size = atlas.region.size * scale
	sprite.position = root - Vector2(190.0, _root_y(creature, seat, _pose_index(frame)) - 2.0) * scale + offset
	var shadow := holder.get_node_or_null("Shadow") as TextureRect
	if shadow != null:
		shadow.size = _shadow_size(int(holder.get_meta("slot", 0)), scale)
		shadow.position = root - shadow.size * 0.5 + Vector2(0, -3) + offset
	var defeat_visibility := 1.0 - (float(_stage_progress_bps) / 10000.0) if _defeated_ids.has(identity) else 1.0
	holder.modulate.a = defeat_visibility
	holder.visible = holder.modulate.a > 0.01


func _ensure_transient_figure(identity: String, seat: String, root: Vector2) -> void:
	var holder: Control = _figures.get(identity, null)
	if holder == null or not is_instance_valid(holder):
		holder = _create_figure(identity)
		_figures[identity] = holder
	var creature := identity.get_slice(":", 2)
	_apply_figure(holder, {
		"identity": identity,
		"member": {"member_id": creature},
		"seat": seat,
		"root": root,
		"slot": 0,
	})


func _stage_offset(identity: String, seat: String) -> Vector2:
	if _reduced_motion or not _attack_sources.has(identity):
		return Vector2.ZERO
	var phase := sin(_attack_progress() * PI)
	return Vector2(0, 70.0 * phase if seat == "rival" else -70.0 * phase)


func _attack_progress() -> float:
	var progress := float(_stage_progress_bps) / 10000.0
	if _stage_name == "AttackLock":
		return progress * 0.42
	if _stage_name == "Damage":
		return 0.42 + progress * 0.58
	return progress


func _attack_pair_key(event: Dictionary) -> String:
	return "%s|%s" % [str(event.get("beat_id", "")), str(event.get("target_identity_id", ""))]


func _damage_pair_key(event: Dictionary) -> String:
	return "%s|%s" % [str(event.get("beat_id", "")), str(event.get("target_identity_id", ""))]


func _root_y(creature: String, seat: String, pose: int) -> int:
	var side: Variant = (ROOTS.get(creature, {}) as Dictionary).get(seat, [])
	if side is Array and side.size() > pose:
		return int(side[pose])
	return 455


func _ready_roots(seat_name: String) -> Array:
	return (READY_ROOTS_LARGE if _enlarged else READY_ROOTS).get(seat_name, [])


func _ready_scale() -> float:
	return READY_SCALE_LARGE if _enlarged else READY_SCALE_NORMAL


func _shadow_size(_slot: int, scale: float) -> Vector2:
	# During Swap/Replace the figure's role scale is interpolated.  Derive the
	# shadow from that same continuous scale instead of the destination slot, so
	# neither endpoint pops from an Active shadow to a Ready shadow.
	var ready_shadow := Vector2(62.0, 9.0) * (_ready_scale() / READY_SCALE_NORMAL)
	var active_weight := clampf(inverse_lerp(_ready_scale(), ACTIVE_SCALE, scale), 0.0, 1.0)
	return ready_shadow.lerp(Vector2(106.0, 14.0), active_weight)


func _pose_index(frame: int) -> int:
	var column := posmod(frame, 4)
	return 0 if column == 0 else (1 if column == 1 else 2)


func _member(seat: Dictionary, identity_id: String) -> Dictionary:
	for member_value in seat.get("members", []):
		if member_value is Dictionary and str(member_value.get("identity_id", "")) == identity_id:
			return (member_value as Dictionary).duplicate(true)
	return {}


func _shadow() -> TextureRect:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color(0.01, 0.03, 0.05, 0.28), Color(0.01, 0.03, 0.05, 0.15), Color(0.01, 0.03, 0.05, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var shadow := TextureRect.new()
	shadow.texture = texture
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return shadow
