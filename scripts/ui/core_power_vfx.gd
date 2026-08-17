class_name CorePowerVFX
extends Control
## Image-authored helmet-gem activation. Atlas frames are tinted, never redrawn procedurally.

const CORE_DEFINITIONS := preload("res://scripts/core/armor_core_definitions.gd")
const ROSTER := preload("res://scripts/ui/tiered_armor_roster.gd")
const MASTER_PATH := "res://assets/armor/tiered/cinderpaw_tiered_armor_signature_green_alpha_v3.png"
const ATLAS_PATH := "res://assets/vfx/helmet_core_activation_grayscale_v1.png"
const ATLAS_SHADER := preload("res://assets/vfx/helmet_core_activation_additive.gdshader")
const ACTIVATION_DURATION := 0.9
const CELL_SIZE := Vector2i(384, 512)
## Measured against the square signature-green runtime master.
const HELMET_GEM_CENTER_NORMALIZED := Vector2(0.694, 0.241)
## The grayscale cells are image-authored but their nonblack content is not
## perfectly centered. These luminance-weighted content anchors map the real
## charge/peak/fade artwork (rather than each cell's geometric midpoint) onto
## the baked helmet gem.
const ATLAS_CONTENT_CENTERS := [
	Vector2(194.8, 246.1), Vector2(192.7, 247.8), Vector2(191.5, 249.2), Vector2(193.5, 244.6),
	Vector2(190.1, 223.5), Vector2(193.3, 227.4), Vector2(191.9, 232.2), Vector2(191.6, 230.6)
]

var core_id := ""
var core: Dictionary = {}
var creature_id := "cinderpaw"
var reduced_motion := false
var phase := "idle"
var activation_progress := 0.0
var activation_token := 0
var frame_index := -1
var _activation_active := false
var _effect: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effect = TextureRect.new()
	_effect.name = "HelmetCoreAtlasEffect"
	_effect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_effect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_effect)
	set_process(false)
	_refresh_effect()

func configure_core(next_core_id: String) -> void:
	core_id = next_core_id if CORE_DEFINITIONS.CORES.has(next_core_id) else ""
	core = CORE_DEFINITIONS.definition(core_id)
	show_idle()

func configure_creature(next_creature_id: String) -> void:
	creature_id = next_creature_id if ROSTER.ROSTER.has(next_creature_id) else "cinderpaw"
	_refresh_effect()

func gem_anchor() -> Vector2:
	return ROSTER.gem_anchor_for(creature_id)

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	if reduced_motion and _activation_active:
		_activation_active = false
		activation_progress = 1.0
		phase = "resolved"
		frame_index = -1
		set_process(false)
	_refresh_effect()

func show_idle() -> void:
	phase = "idle"
	activation_progress = 0.0
	frame_index = -1
	_activation_active = false
	set_process(false)
	_refresh_effect()

func show_peak() -> void:
	if core.is_empty():
		show_idle()
		return
	phase = "peak"
	activation_progress = 0.64
	frame_index = 5
	_activation_active = false
	set_process(false)
	_refresh_effect()

func show_snapshot(next_phase: String) -> void:
	phase = next_phase if next_phase in ["idle", "charging", "peak", "resolved"] else "idle"
	activation_progress = {"idle": 0.0, "charging": 0.30, "peak": 0.64, "resolved": 1.0}.get(phase, 0.0)
	frame_index = -1 if phase in ["idle", "resolved"] or core.is_empty() else atlas_frame_for_progress(activation_progress)
	_activation_active = false
	set_process(false)
	_refresh_effect()

func start_activation() -> int:
	activation_token += 1
	if core.is_empty():
		show_idle()
		return activation_token
	if reduced_motion:
		phase = "resolved"
		activation_progress = 1.0
		frame_index = -1
		_activation_active = false
		set_process(false)
		_refresh_effect()
		return activation_token
	phase = "charging"
	activation_progress = 0.0
	frame_index = 0
	_activation_active = true
	set_process(true)
	_refresh_effect()
	return activation_token

func is_activation_active() -> bool:
	return _activation_active

func has_moving_elements() -> bool:
	return _activation_active and not reduced_motion

func has_visible_socket() -> bool:
	return true

func has_embedded_gem() -> bool:
	# The authored signature-green master always contains the gem inside its bezel.
	return true

func has_powered_core() -> bool:
	return not core.is_empty()

func has_active_glow() -> bool:
	return frame_index >= 0 and _effect != null and _effect.visible

func has_active_atlas_overlay() -> bool:
	return has_active_glow()

static func master_source_for_core(next_core_id: String) -> String:
	return MASTER_PATH if CORE_DEFINITIONS.CORES.has(next_core_id) else ""

static func master_source_for_creature_core(creature_id: String, next_core_id: String) -> String:
	return ROSTER.master_path_for(creature_id) if CORE_DEFINITIONS.CORES.has(next_core_id) else ""

static func atlas_source_for_core(next_core_id: String) -> String:
	return ATLAS_PATH if CORE_DEFINITIONS.CORES.has(next_core_id) else ""

static func fitted_master_rect_for_size(control_size: Vector2) -> Rect2:
	var unit := minf(control_size.x, control_size.y)
	var square := Vector2(unit, unit)
	return Rect2((control_size - square) * 0.5, square)

static func master_local_to_control(control_size: Vector2, normalized_point: Vector2) -> Vector2:
	var fitted := fitted_master_rect_for_size(control_size)
	return fitted.position + normalized_point * fitted.size

static func atlas_frame_for_progress(progress: float) -> int:
	return clampi(int(floor(clampf(progress, 0.0, 0.9999) * 8.0)), 0, 7)

static func atlas_content_center_for_frame(next_frame: int) -> Vector2:
	return ATLAS_CONTENT_CENTERS[clampi(next_frame, 0, ATLAS_CONTENT_CENTERS.size() - 1)]

func _process(delta: float) -> void:
	if not _activation_active:
		set_process(false)
		return
	activation_progress = minf(1.0, activation_progress + delta / ACTIVATION_DURATION)
	if activation_progress >= 1.0:
		activation_progress = 1.0
		phase = "resolved"
		frame_index = -1
		_activation_active = false
		set_process(false)
	else:
		phase = "charging" if activation_progress < 0.56 else "peak"
		frame_index = atlas_frame_for_progress(activation_progress)
	_refresh_effect()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_refresh_effect()

func _refresh_effect() -> void:
	if _effect == null:
		return
	# Reduced motion uses a single static peak rather than suppressing a material
	# Core trigger altogether.
	var visible := not core.is_empty() and frame_index >= 0
	_effect.visible = visible
	if not visible:
		queue_redraw()
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ATLAS_PATH) as Texture2D
	var cell_x := frame_index % 4
	var cell_y := frame_index / 4
	atlas.region = Rect2i(cell_x * CELL_SIZE.x, cell_y * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y)
	_effect.texture = atlas
	var material := ShaderMaterial.new()
	material.shader = ATLAS_SHADER
	material.set_shader_parameter("core_color", Color(core.get("color", Color.WHITE)))
	material.set_shader_parameter("intensity", _frame_intensity(frame_index))
	_effect.material = material
	var fitted := fitted_master_rect_for_size(size)
	var center := master_local_to_control(size, gem_anchor())
	var effect_size := Vector2(fitted.size.x * 0.235, fitted.size.x * 0.315)
	var content_anchor := atlas_content_center_for_frame(frame_index) / Vector2(CELL_SIZE)
	_effect.position = center - effect_size * content_anchor
	_effect.size = effect_size
	queue_redraw()

func _draw() -> void:
	if core.is_empty() or frame_index < 0: return
	var center := master_local_to_control(size, gem_anchor())
	var radius := minf(size.x, size.y) * (0.070 if phase == "peak" else 0.040)
	var color := Color(core.get("color", Color.WHITE))
	draw_circle(center, radius, Color(color.r, color.g, color.b, 0.42 if phase == "peak" else 0.16))
	draw_circle(center, radius * 0.58, Color(1.0, 0.94, 1.0, 0.26 if phase == "peak" else 0.08))
	draw_arc(center, radius * 1.18, 0.0, TAU, 20, Color(color.r, color.g, color.b, 0.96), 3.0, true)

func _frame_intensity(next_frame: int) -> float:
	var values := [0.32, 0.44, 0.58, 0.76, 1.00, 0.88, 0.62, 0.38]
	return float(values[clampi(next_frame, 0, values.size() - 1)])
