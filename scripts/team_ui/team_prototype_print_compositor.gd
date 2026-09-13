class_name TeamPrototypePrintCompositor
extends Control
## Passive rooted printer renderer. Its caller owns time, persistence and phases.

const RawFilament := preload("res://assets/creatures/2d/battle-facing/battle_raw_filament.gdshader")
const Wireframe := preload("res://scripts/ui/battle_wireframe.gdshader")
const GuideTexture := preload("res://assets/ui/physical_ui/forge-continuity/carriage-guide-v1.png")
const HeadTexture := preload("res://assets/ui/physical_ui/forge-continuity/carriage-head-v1.png")

static var _alpha_bounds: Dictionary = {}

var solid_clip: Control
var wire_clip: Control
var solid: TextureRect
var wire: TextureRect
var living: TextureRect
var scan: ColorRect
var seed: ColorRect
var shadow: TextureRect
var guide: TextureRect
var head: TextureRect
var _raw_material: ShaderMaterial
var _atlas: AtlasTexture
var _atlas_key := ""
var _hardware_geometry: Dictionary = {}
var _last_snapshot: Dictionary = {}

func _ready() -> void:
	clip_contents = true
	solid_clip = _clip("PrototypePrintSolidClip")
	add_child(solid_clip)
	solid = _sprite("PrototypePrintRawSolid")
	_raw_material = ShaderMaterial.new()
	_raw_material.shader = RawFilament
	_raw_material.set_shader_parameter("filament_color", Color("a9a49a"))
	solid.material = _raw_material
	solid_clip.add_child(solid)
	wire_clip = _clip("PrototypePrintWireframeClip")
	add_child(wire_clip)
	wire = _sprite("PrototypePrintWireframe")
	var wire_material := ShaderMaterial.new()
	wire_material.shader = Wireframe
	wire.material = wire_material
	wire_material.set_shader_parameter("ink_gain", 1.65)
	wire_material.set_shader_parameter("alpha_edge_gain", 1.25)
	wire_clip.add_child(wire)
	living = _sprite("PrototypePrintLiving")
	living.hide()
	add_child(living)
	scan = ColorRect.new()
	scan.name = "PrototypePrintScan"
	scan.color = Color("67e7ef")
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scan)
	seed = ColorRect.new()
	seed.name = "PrototypePrintSeed"
	seed.color = Color("66ebf4")
	seed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(seed)
	shadow = TextureRect.new()
	shadow.name = "PrototypePrintContactShadow"
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.texture = _shadow_texture()
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(shadow)
	# Keep this soft footprint under every raw/living layer, never over paws.
	move_child(shadow, 0)
	guide = _sprite("PrototypePrintCarriageGuide")
	guide.texture = GuideTexture
	add_child(guide)
	head = _sprite("PrototypePrintCarriageHead")
	head.texture = HeadTexture
	add_child(head)

func render_state(subject: Texture2D, source_region: Rect2, source_root: Vector2, bed_root_global: Vector2, sprite_scale: float, aperture: Rect2, raw_progress_bps: int, living_blend_bps: int, departure_offset: Vector2, reduced_motion: bool, presentation_visible := true, presentation_opacity := 1.0, hardware_geometry: Dictionary = {}) -> void:
	position = aperture.position
	size = aperture.size
	_hardware_geometry = hardware_geometry.duplicate(true)
	if not _valid_source(subject, source_region, source_root, bed_root_global, sprite_scale, aperture):
		_hide_subject(false)
		return
	_set_subject(subject, source_region)
	var subject_rect := Rect2(bed_root_global - aperture.position - source_root * sprite_scale, source_region.size * sprite_scale)
	var planted_root := bed_root_global - aperture.position
	var bounds_result := _bounds_for(subject, source_region)
	if not bool(bounds_result.get("ok", false)):
		_hide_subject(false)
		return
	var alpha_bounds: Rect2 = bounds_result.rect
	var opaque_rect := Rect2(subject_rect.position + alpha_bounds.position * sprite_scale, alpha_bounds.size * sprite_scale)
	var raw_progress := clampi(raw_progress_bps, 0, 10000)
	var blend := clampi(living_blend_bps, 0, 10000)
	var revealed_rows := floori(alpha_bounds.size.y * float(raw_progress) / 10000.0) * sprite_scale
	var scan_y := opaque_rect.end.y - revealed_rows
	_place_hardware(aperture, scan_y, raw_progress > 0 and raw_progress < 10000 and bool(_hardware_geometry.get("tracking", false)))
	_set_clip(solid_clip, Rect2(0, scan_y, size.x, size.y - scan_y), subject_rect)
	_set_clip(wire_clip, Rect2(0, 0, size.x, scan_y), subject_rect)
	scan.position = Vector2(subject_rect.position.x, scan_y)
	scan.size = Vector2(subject_rect.size.x, 3)
	seed.position = Vector2(planted_root.x - 5, planted_root.y - 5)
	seed.size = Vector2(10, 10)
	seed.visible = raw_progress == 0 and blend == 0
	var grounded_departure := Vector2.ZERO if reduced_motion else departure_offset
	var opacity := clampf(presentation_opacity, 0.0, 1.0)
	var shadow_size := Vector2(132, 18) * (1.0 - float(blend) * 0.12 / 10000.0)
	shadow.size = shadow_size
	shadow.position = planted_root + grounded_departure + Vector2(0, -3) - shadow_size * 0.5
	shadow.modulate.a = opacity
	shadow.visible = presentation_visible and (raw_progress > 0 or blend > 0)
	living.position = subject_rect.position + grounded_departure
	living.size = subject_rect.size
	living.modulate.a = float(blend) * opacity / 10000.0
	living.visible = presentation_visible and blend > 0
	# Keep the raw base opaque through the living overlay crossfade; otherwise
	# blend=50% turns the same subject translucent against the dark chamber.
	solid.modulate.a = 1.0
	wire.modulate.a = 1.0
	var finished := raw_progress >= 10000 and blend >= 10000
	solid_clip.visible = presentation_visible and raw_progress > 0 and not finished
	wire_clip.visible = presentation_visible and raw_progress > 0 and not finished
	scan.visible = presentation_visible and raw_progress > 0 and raw_progress < 10000 and not finished
	_last_snapshot = {
		"valid": true,
		"source_region": source_region,
		"source_root": source_root,
		"bed_root": bed_root_global,
		"raw_progress_bps": raw_progress,
		"living_blend_bps": blend,
		"scan_global_y": aperture.position.y + scan_y,
		"scan_width": scan.size.x,
		"presentation_visible": presentation_visible,
		"presentation_opacity": opacity,
		"living_position": living.position,
		"shadow_position": shadow.position,
		"shadow_center": shadow.position + shadow.size * 0.5,
		"tracking": bool(_hardware_geometry.get("tracking", false)),
	}

func hardware_snapshot() -> Dictionary:
	return _hardware_geometry.duplicate(true)


func presentation_snapshot() -> Dictionary:
	return _last_snapshot.duplicate(true)


func _valid_source(subject: Texture2D, region: Rect2, source_root: Vector2, bed_root: Vector2, sprite_scale: float, aperture: Rect2) -> bool:
	if subject == null or not is_finite(sprite_scale) or sprite_scale <= 0.0:
		return false
	if not source_root.is_finite() or not bed_root.is_finite() or not aperture.position.is_finite() or not aperture.size.is_finite():
		return false
	if region.position.x < 0.0 or region.position.y < 0.0 or region.size.x <= 1.0 or region.size.y <= 1.0:
		return false
	if not region.position.is_finite() or not region.size.is_finite() or aperture.size.x <= 0.0 or aperture.size.y <= 0.0:
		return false
	var texture_size := subject.get_size()
	return region.end.x <= texture_size.x and region.end.y <= texture_size.y

func _place_hardware(aperture: Rect2, scan_y: float, tracking: bool) -> void:
	for pair in [[guide, "guide"], [head, "head"]]:
		var node: TextureRect = pair[0]
		var geometry: Variant = _hardware_geometry.get(str(pair[1]), Rect2())
		if geometry is Rect2:
			var rect: Rect2 = geometry
			if tracking:
				rect.position.y = aperture.position.y + scan_y + (-149 if str(pair[1]) == "guide" else -160)
			node.position = rect.position - aperture.position
			node.size = rect.size
			node.visible = not rect.size.is_zero_approx()

func _set_subject(subject: Texture2D, region: Rect2) -> void:
	var key := "%s:%s" % [str(subject.get_instance_id()) if subject != null else "", region]
	if key == _atlas_key:
		return
	_atlas_key = key
	_atlas = AtlasTexture.new()
	_atlas.atlas = subject
	_atlas.region = region
	for layer in [solid, wire, living]:
		layer.texture = _atlas

func _bounds_for(subject: Texture2D, region: Rect2) -> Dictionary:
	var key := "%s:%s" % [str(subject.get_instance_id()) if subject != null else "", region]
	if _alpha_bounds.has(key):
		return _alpha_bounds[key] as Dictionary
	var image := subject.get_image()
	if image == null or image.is_empty() or image.is_compressed():
		return _cache_bounds(key, false, Rect2())
	var left := int(region.end.x)
	var top := int(region.end.y)
	var right := int(region.position.x) - 1
	var bottom := int(region.position.y) - 1
	for y in range(int(region.position.y), int(region.end.y)):
		for x in range(int(region.position.x), int(region.end.x)):
			if image.get_pixel(x, y).a > 0.01:
				left = mini(left, x)
				right = maxi(right, x)
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if right < left or bottom < top:
		return _cache_bounds(key, false, Rect2())
	var bounds := Rect2(Vector2(left, top) - region.position, Vector2(maxi(1, right - left + 1), maxi(1, bottom - top + 1)))
	return _cache_bounds(key, true, bounds)


func _cache_bounds(key: String, ok: bool, bounds: Rect2) -> Dictionary:
	var result := {"ok": ok, "rect": bounds}
	_alpha_bounds[key] = result
	return result

func _set_clip(clip: Control, clip_rect: Rect2, subject_rect: Rect2) -> void:
	clip.position = clip_rect.position
	clip.size = clip_rect.size.max(Vector2.ZERO)
	var child := clip.get_child(0) as TextureRect
	child.position = subject_rect.position - clip.position
	child.size = subject_rect.size

func _hide_subject(valid_snapshot: bool) -> void:
	for node in [solid_clip, wire_clip, living, scan, seed, shadow, guide, head]:
		if node != null:
			node.hide()
	_last_snapshot = {"valid": valid_snapshot}


func _shadow_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.40, 1.0])
	gradient.colors = PackedColorArray([Color(0.01, 0.03, 0.05, 0.30), Color(0.01, 0.03, 0.05, 0.18), Color(0.01, 0.03, 0.05, 0.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture

func _clip(node_name: String) -> Control:
	var node := Control.new()
	node.name = node_name
	node.clip_contents = true
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func _sprite(node_name: String) -> TextureRect:
	var node := TextureRect.new()
	node.name = node_name
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node
