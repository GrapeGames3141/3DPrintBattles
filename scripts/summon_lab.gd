extends Node3D

const CREATURE_RESOURCE_PATH := "res://assets/models/ironbound_goblin_animated_v3.glb"
const BASE_RESOURCE_PATH := "res://assets/models/relic_bases_mobile.glb"
const LAYER_SHADER := preload("res://shaders/layer_print.gdshader")

const MODELS := [
	{
		"label": "Ironbound Goblin Warrior",
		"resource": CREATURE_RESOURCE_PATH,
		"stats": {
			"health": 24,
			"defense": 6,
			"offense": 8,
			"range": 0,
			"cost": 3,
			"attack_types": ["Melee"],
		},
	},
]

const BASE_Y := 0.14
const BASE_SCALE := Vector3(3.4, 1.8, 3.4)
const CREATURE_FOOT_Y := 0.29
const REVEAL_TOP_Y := 2.35
const SUMMON_DELAY := 0.65
const SUMMON_DURATION := 2.35
const DEFAULT_DISPLAY_POSITION := Vector3(1.35, 0.0, 0.0)
const DEFAULT_ORBIT_Y := -0.18
const DEFAULT_ORBIT_PITCH := -0.04
const DEFAULT_CAMERA_FOV := 38.0
const MIN_CAMERA_FOV := 24.0
const MAX_CAMERA_FOV := 58.0
const BASE_INSPECT_LIFT := Vector3(0.0, 0.78, 0.0)
const BASE_INSPECT_ANGLE := 3.9269908

const LOOPING_ANIMATIONS := ["Run", "Walk", "WalkBackward"]

const ANIMATION_LABELS := {
	"AlertTurnLeft": "Alert Turn Left",
	"Fall": "Fall",
	"Run": "Run",
	"StandUp": "Stand Up",
	"SwordSlash": "Sword Slash",
	"Walk": "Walk",
	"WalkBackward": "Walk Backward",
}

const RARITIES := [
	{"label": "Common — Reclaimed Wood", "node": "BaseWood", "material": "Reclaimed wood", "accent": Color("#78d88b")},
	{"label": "Uncommon — Carved Stone", "node": "BaseStone", "material": "Carved stone", "accent": Color("#a8c7d9")},
	{"label": "Rare — Cast Bronze", "node": "BaseBronze", "material": "Cast bronze", "accent": Color("#f0ad4e")},
	{"label": "Epic — Forged Steel", "node": "BaseSteel", "material": "Forged steel", "accent": Color("#58d8ff")},
	{"label": "Mythic — Carbon Composite", "node": "BaseCarbon", "material": "Carbon composite", "accent": Color("#c789ff")},
	{"label": "Legendary — Arcane Resin", "node": "BaseCrystal", "material": "Arcane resin", "accent": Color("#ffcf5a")},
]

const STRENGTHS := [
	{"label": "Weak — Rank I", "short": "Rank I / Weak"},
	{"label": "Normal — Rank II", "short": "Rank II / Normal"},
	{"label": "Elite — Rank III", "short": "Rank III / Elite"},
]

var display_root: Node3D
var base_flip_root: Node3D
var base_anchor: Node3D
var creature_anchor: Node3D
var badge_anchor: Node3D
var base_scene_instance: Node
var creature_scene_instance: Node
var base_meshes := {}
var creature_meshes := []
var summon_materials := []
var embedded_animations := []
var animation_player: AnimationPlayer
var scan_ring: MeshInstance3D
var spark_particles: GPUParticles3D
var rank_chevron_pairs := []
var current_tween: Tween
var view_tween: Tween
var summon_generation := 0
var stats_viewport: SubViewport
var stats_sprite: Sprite3D
var camera: Camera3D
var is_inspecting_base := false
var active_touches := {}
var pinch_distance := -1.0

var model_option: OptionButton
var rarity_option: OptionButton
var strength_option: OptionButton
var animation_option: OptionButton
var play_button: Button
var reset_button: Button
var status_label: Label
var accent_bar: ColorRect

var orbit_y := DEFAULT_ORBIT_Y
var orbit_pitch := DEFAULT_ORBIT_PITCH


func _ready() -> void:
	_build_world()
	_build_assets()
	_build_ui()
	_populate_animation_selector()
	_apply_rarity(0)
	_apply_strength(0)
	_show_creature_immediately()
	_update_status("Ready — choose options, then print the creature.")

	if Input.is_action_just_pressed("play_summon"):
		_play_selected_animation()

	var args := OS.get_cmdline_user_args()
	if "--smoke-test" in args:
		call_deferred("_run_smoke_test")
	else:
		var capture_path := ""
		var capture_clip := ""
		var capture_base_path := ""
		for arg in args:
			if arg.begins_with("--capture="):
				capture_path = arg.trim_prefix("--capture=")
			elif arg.begins_with("--capture-clip="):
				capture_clip = arg.trim_prefix("--capture-clip=")
			elif arg.begins_with("--capture-base="):
				capture_base_path = arg.trim_prefix("--capture-base=")
		if not capture_base_path.is_empty():
			call_deferred("_run_base_capture", capture_base_path)
		elif not capture_path.is_empty():
			if capture_clip.is_empty():
				call_deferred("_run_capture", capture_path)
			else:
				call_deferred("_run_animation_capture", capture_path, capture_clip)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("play_summon"):
		_play_selected_animation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			active_touches[event.index] = event.position
		else:
			active_touches.erase(event.index)
		pinch_distance = _current_pinch_distance()
	elif event is InputEventScreenDrag:
		active_touches[event.index] = event.position
		if active_touches.size() >= 2:
			var next_distance := _current_pinch_distance()
			if pinch_distance > 0.0 and next_distance > 0.0:
				_set_camera_fov(camera.fov - (next_distance - pinch_distance) * 0.035)
			pinch_distance = next_distance
			return
		if is_inspecting_base:
			return
		orbit_y -= event.relative.x * 0.009
		orbit_pitch = clamp(orbit_pitch - event.relative.y * 0.004, -0.18, 0.16)
		_apply_orbit()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not is_inspecting_base:
		orbit_y -= event.relative.x * 0.009
		orbit_pitch = clamp(orbit_pitch - event.relative.y * 0.004, -0.18, 0.16)
		_apply_orbit()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_camera_fov(camera.fov - 2.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_camera_fov(camera.fov + 2.0)
	elif event is InputEventMagnifyGesture:
		_set_camera_fov(camera.fov / maxf(event.factor, 0.1))


func _build_world() -> void:
	display_root = Node3D.new()
	display_root.name = "DisplayRoot"
	add_child(display_root)

	base_flip_root = Node3D.new()
	base_flip_root.name = "BaseFlipRoot"
	display_root.add_child(base_flip_root)

	base_anchor = Node3D.new()
	base_anchor.name = "BaseAnchor"
	base_flip_root.add_child(base_anchor)

	creature_anchor = Node3D.new()
	creature_anchor.name = "CreatureAnchor"
	creature_anchor.position.y = CREATURE_FOOT_Y
	display_root.add_child(creature_anchor)

	badge_anchor = Node3D.new()
	badge_anchor.name = "RankBadgeAnchor"
	base_flip_root.add_child(badge_anchor)

	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#07111f")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#9bc5e8")
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	world_environment.environment = environment
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "KeyLight"
	key_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	key_light.light_color = Color("#fff1d7")
	key_light.light_energy = 2.1
	key_light.shadow_enabled = true
	add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "ForgeFill"
	fill_light.position = Vector3(-2.1, 1.7, 2.4)
	fill_light.light_color = Color("#47cfff")
	fill_light.light_energy = 6.0
	fill_light.omni_range = 6.0
	add_child(fill_light)

	var rim_light := OmniLight3D.new()
	rim_light.name = "WarmRim"
	rim_light.position = Vector3(2.0, 2.1, -1.7)
	rim_light.light_color = Color("#ff9d4a")
	rim_light.light_energy = 4.0
	rim_light.omni_range = 5.0
	add_child(rim_light)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = DEFAULT_CAMERA_FOV
	camera.position = Vector3(3.05, 2.45, 5.15)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.92, 0.0), Vector3.UP)

	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "WorkshopFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(12.0, 12.0)
	floor_mesh.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("#111b2a")
	floor_material.metallic = 0.55
	floor_material.roughness = 0.48
	floor_mesh.material_override = floor_material
	floor_mesh.position.y = -0.005
	add_child(floor_mesh)

	_build_scan_effect()


func _build_assets() -> void:
	var base_resource := load(BASE_RESOURCE_PATH) as PackedScene
	if base_resource == null:
		push_error("Could not load base resource: %s" % BASE_RESOURCE_PATH)
		return
	base_scene_instance = base_resource.instantiate()
	base_anchor.add_child(base_scene_instance)

	for mesh in _collect_mesh_instances(base_scene_instance):
		if mesh.name == "SourceCrest":
			_setup_rank_badge(mesh)
		elif mesh.name.begins_with("Base"):
			mesh.scale = BASE_SCALE
			mesh.position.y = BASE_Y
			mesh.visible = false
			base_meshes[mesh.name] = mesh
	_build_stats_label()

	var creature_resource := load(CREATURE_RESOURCE_PATH) as PackedScene
	if creature_resource == null:
		push_error("Could not load creature resource: %s" % CREATURE_RESOURCE_PATH)
		return
	creature_scene_instance = creature_resource.instantiate()
	creature_anchor.add_child(creature_scene_instance)
	creature_meshes.clear()
	for mesh in _collect_mesh_instances(creature_scene_instance):
		if mesh.name.to_lower().contains("icosphere"):
			mesh.visible = false
			continue
		creature_meshes.append(mesh)
	_apply_layer_shader_to_creature()
	_discover_animation_players(creature_scene_instance)


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "UI"
	add_child(canvas)

	var safe_root := Control.new()
	safe_root.name = "SafeRoot"
	safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(safe_root)

	var panel := PanelContainer.new()
	panel.name = "ControlsPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 20.0
	panel.offset_top = 18.0
	panel.offset_right = 470.0
	panel.offset_bottom = 382.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.065, 0.105, 0.94)
	panel_style.border_color = Color("#31516e")
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel.add_theme_stylebox_override("panel", panel_style)
	safe_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var title := Label.new()
	title.text = "PRINTFORGE • SUMMON LAB"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#e9f7ff"))
	content.add_child(title)

	accent_bar = ColorRect.new()
	accent_bar.custom_minimum_size = Vector2(0.0, 4.0)
	content.add_child(accent_bar)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)

	model_option = _add_selector_row(grid, "Model")
	for model in MODELS:
		model_option.add_item(model["label"])
	model_option.item_selected.connect(_apply_model)

	rarity_option = _add_selector_row(grid, "Rarity / base")
	for rarity in RARITIES:
		rarity_option.add_item(rarity.label)
	rarity_option.item_selected.connect(_apply_rarity)

	strength_option = _add_selector_row(grid, "Strength")
	for strength in STRENGTHS:
		strength_option.add_item(strength.label)
	strength_option.item_selected.connect(_apply_strength)

	animation_option = _add_selector_row(grid, "Animation")

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	content.add_child(button_row)

	play_button = Button.new()
	play_button.text = "PRINT / PLAY"
	play_button.custom_minimum_size.y = 54.0
	play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_button.add_theme_font_size_override("font_size", 18)
	play_button.pressed.connect(_play_selected_animation)
	button_row.add_child(play_button)

	reset_button = Button.new()
	reset_button.text = "RESET"
	reset_button.custom_minimum_size = Vector2(112.0, 54.0)
	reset_button.add_theme_font_size_override("font_size", 16)
	reset_button.pressed.connect(_reset_all)
	button_row.add_child(reset_button)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color("#bcd3e4"))
	content.add_child(status_label)

	var hint := Label.new()
	hint.text = "Drag to rotate  •  Pinch or wheel to zoom  •  Reset restores the view"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_left = 18.0
	hint.offset_right = -18.0
	hint.offset_top = -70.0
	hint.offset_bottom = -18.0
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("#91afc5"))
	safe_root.add_child(hint)

	display_root.position = DEFAULT_DISPLAY_POSITION


func _add_selector_row(grid: GridContainer, label_text: String) -> OptionButton:
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 112.0
	label.add_theme_font_size_override("font_size", 15)
	grid.add_child(label)
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.custom_minimum_size.y = 38.0
	option.add_theme_font_size_override("font_size", 14)
	grid.add_child(option)
	return option


func _setup_rank_badge(mesh: MeshInstance3D) -> void:
	mesh.reparent(badge_anchor)
	mesh.name = "RankBadgeShield"
	badge_anchor.position = Vector3(0.0, 0.265, 0.72)
	badge_anchor.rotation_degrees = Vector3.ZERO
	mesh.position = Vector3.ZERO
	mesh.rotation_degrees = Vector3.ZERO
	mesh.scale = Vector3.ONE * 0.9
	var badge_material := StandardMaterial3D.new()
	badge_material.albedo_color = Color("#182431")
	badge_material.metallic = 0.82
	badge_material.roughness = 0.28
	mesh.material_override = badge_material

	for rank_index in range(3):
		var pair := []
		var center_z := 0.05 - float(rank_index) * 0.05
		for side in [-1, 1]:
			var segment := MeshInstance3D.new()
			segment.name = "RankChevron_%d_%s" % [rank_index + 1, "L" if side == -1 else "R"]
			var bar := BoxMesh.new()
			bar.size = Vector3(0.058, 0.014, 0.016)
			segment.mesh = bar
			segment.position = Vector3(float(side) * 0.023, 0.108, -center_z)
			segment.rotation_degrees.y = -float(side) * 29.0
			badge_anchor.add_child(segment)
			pair.append(segment)
		rank_chevron_pairs.append(pair)


func _build_stats_label() -> void:
	stats_viewport = SubViewport.new()
	stats_viewport.name = "UnitStatsLabelViewport"
	stats_viewport.size = Vector2i(768, 420)
	stats_viewport.transparent_bg = true
	stats_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(stats_viewport)

	var paper_root := Control.new()
	paper_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stats_viewport.add_child(paper_root)

	var shadow := Panel.new()
	shadow.position = Vector2(28.0, 30.0)
	shadow.size = Vector2(720.0, 370.0)
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.10, 0.055, 0.025, 0.55)
	shadow_style.corner_radius_top_left = 26
	shadow_style.corner_radius_top_right = 18
	shadow_style.corner_radius_bottom_left = 18
	shadow_style.corner_radius_bottom_right = 28
	shadow.add_theme_stylebox_override("panel", shadow_style)
	paper_root.add_child(shadow)

	var panel := PanelContainer.new()
	panel.position = Vector2(18.0, 18.0)
	panel.size = Vector2(720.0, 370.0)
	var paper_style := StyleBoxFlat.new()
	paper_style.bg_color = Color("#d6b674")
	paper_style.border_color = Color("#57371f")
	paper_style.set_border_width_all(7)
	paper_style.corner_radius_top_left = 26
	paper_style.corner_radius_top_right = 18
	paper_style.corner_radius_bottom_left = 18
	paper_style.corner_radius_bottom_right = 28
	panel.add_theme_stylebox_override("panel", paper_style)
	paper_root.add_child(panel)

	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_left", 28)
	inset.add_theme_constant_override("margin_right", 28)
	inset.add_theme_constant_override("margin_top", 18)
	inset.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(inset)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	inset.add_child(column)

	var title := Label.new()
	title.text = "IRONBOUND GOBLIN WARRIOR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color("#3f2819"))
	column.add_child(title)

	var ledger := Label.new()
	ledger.text = "—  UNIT LEDGER  —"
	ledger.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ledger.add_theme_font_size_override("font_size", 22)
	ledger.add_theme_color_override("font_color", Color("#6d4425"))
	column.add_child(ledger)

	var rule := ColorRect.new()
	rule.color = Color("#6b4326")
	rule.custom_minimum_size.y = 3.0
	column.add_child(rule)

	var stats: Dictionary = MODELS[0]["stats"]
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 5)
	column.add_child(grid)
	_add_stat_cell(grid, "HEALTH", str(stats["health"]))
	_add_stat_cell(grid, "DEFENSE", str(stats["defense"]))
	_add_stat_cell(grid, "OFFENSE", str(stats["offense"]))
	_add_stat_cell(grid, "RANGE", str(stats["range"]))
	_add_stat_cell(grid, "COST", str(stats["cost"]))
	var attack_types: Array = stats["attack_types"]
	_add_stat_cell(grid, "ATTACK TYPE", ", ".join(attack_types).to_upper())

	stats_sprite = Sprite3D.new()
	stats_sprite.name = "ParchmentStatsSticker"
	stats_sprite.texture = stats_viewport.get_texture()
	stats_sprite.pixel_size = 0.00182
	stats_sprite.position = Vector3(0.0, -0.028, 0.0)
	stats_sprite.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	stats_sprite.double_sided = true
	stats_sprite.shaded = false
	stats_sprite.visible = false
	base_flip_root.add_child(stats_sprite)


func _add_stat_cell(grid: GridContainer, stat_name: String, value: String) -> void:
	var name_label := Label.new()
	name_label.text = stat_name
	name_label.custom_minimum_size.x = 132.0
	name_label.add_theme_font_size_override("font_size", 23)
	name_label.add_theme_color_override("font_color", Color("#704727"))
	grid.add_child(name_label)
	var value_label := Label.new()
	value_label.text = value
	value_label.custom_minimum_size.x = 110.0
	value_label.add_theme_font_size_override("font_size", 31)
	value_label.add_theme_color_override("font_color", Color("#352116"))
	grid.add_child(value_label)


func _build_scan_effect() -> void:
	scan_ring = MeshInstance3D.new()
	scan_ring.name = "FilamentScanRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.74
	torus.outer_radius = 0.79
	torus.rings = 32
	torus.ring_segments = 8
	scan_ring.mesh = torus
	var ring_material := StandardMaterial3D.new()
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_material.albedo_color = Color(0.08, 0.84, 1.0, 0.75)
	ring_material.emission_enabled = true
	ring_material.emission = Color("#31dcff")
	ring_material.emission_energy_multiplier = 4.0
	scan_ring.material_override = ring_material
	scan_ring.visible = false
	display_root.add_child(scan_ring)

	spark_particles = GPUParticles3D.new()
	spark_particles.name = "FilamentSparks"
	spark_particles.amount = 40
	spark_particles.lifetime = 0.72
	spark_particles.randomness = 0.5
	spark_particles.visibility_aabb = AABB(Vector3(-1.0, -0.5, -1.0), Vector3(2.0, 1.0, 2.0))
	var process_material := ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(0.68, 0.01, 0.68)
	process_material.direction = Vector3(0.0, 1.0, 0.0)
	process_material.spread = 78.0
	process_material.initial_velocity_min = 0.18
	process_material.initial_velocity_max = 0.62
	process_material.gravity = Vector3(0.0, -0.65, 0.0)
	process_material.scale_min = 0.65
	process_material.scale_max = 1.35
	process_material.color = Color("#65e9ff")
	spark_particles.process_material = process_material
	var spark_mesh := BoxMesh.new()
	spark_mesh.size = Vector3(0.018, 0.045, 0.018)
	var spark_material := StandardMaterial3D.new()
	spark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_material.albedo_color = Color("#baf7ff")
	spark_material.emission_enabled = true
	spark_material.emission = Color("#4fe7ff")
	spark_material.emission_energy_multiplier = 5.0
	spark_mesh.material = spark_material
	spark_particles.draw_pass_1 = spark_mesh
	spark_particles.emitting = false
	display_root.add_child(spark_particles)


func _apply_layer_shader_to_creature() -> void:
	summon_materials.clear()
	for mesh_instance in creature_meshes:
		if mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var source: Material = mesh_instance.get_active_material(surface_index)
			var shader_material := ShaderMaterial.new()
			shader_material.shader = LAYER_SHADER
			shader_material.set_shader_parameter("reveal_height", 100.0)
			shader_material.set_shader_parameter("filament_color", Color("#32ddff"))
			if source is BaseMaterial3D:
				shader_material.set_shader_parameter("albedo_color", source.albedo_color)
				shader_material.set_shader_parameter("metallic_value", source.metallic)
				shader_material.set_shader_parameter("roughness_value", source.roughness)
				shader_material.set_shader_parameter("use_albedo_texture", source.albedo_texture != null)
				shader_material.set_shader_parameter("albedo_texture", source.albedo_texture)
				shader_material.set_shader_parameter("use_normal_texture", source.normal_texture != null)
				shader_material.set_shader_parameter("normal_texture", source.normal_texture)
				shader_material.set_shader_parameter("use_metallic_texture", source.metallic_texture != null)
				shader_material.set_shader_parameter("metallic_texture", source.metallic_texture)
				shader_material.set_shader_parameter("use_roughness_texture", source.roughness_texture != null)
				shader_material.set_shader_parameter("roughness_texture", source.roughness_texture)
				shader_material.set_shader_parameter("use_emission_texture", source.emission_texture != null)
				shader_material.set_shader_parameter("emission_texture", source.emission_texture)
				shader_material.set_shader_parameter("source_emission", source.emission)
			mesh_instance.set_surface_override_material(surface_index, shader_material)
			summon_materials.append(shader_material)


func _discover_animation_players(root: Node) -> void:
	for child in root.get_children():
		if child is AnimationPlayer and animation_player == null:
			animation_player = child
		_discover_animation_players(child)


func _populate_animation_selector() -> void:
	animation_option.clear()
	animation_option.add_item("Summon — Layer Print")
	animation_option.set_item_metadata(0, {"kind": "summon"})
	animation_option.add_item("Static Showcase")
	animation_option.set_item_metadata(1, {"kind": "static"})
	animation_option.add_item("Show Base — Unit Stats")
	animation_option.set_item_metadata(2, {"kind": "inspect_base"})
	embedded_animations.clear()
	if animation_player != null:
		for library_name in animation_player.get_animation_library_list():
			var library := animation_player.get_animation_library(library_name)
			for animation_name in library.get_animation_list():
				if animation_name == "RESET":
					continue
				var full_name: String = animation_name if library_name.is_empty() else "%s/%s" % [library_name, animation_name]
				var friendly_name: String = ANIMATION_LABELS.get(animation_name, animation_name.replace("_", " "))
				var animation := library.get_animation(animation_name)
				animation.loop_mode = Animation.LOOP_LINEAR if animation_name in LOOPING_ANIMATIONS else Animation.LOOP_NONE
				embedded_animations.append(full_name)
				animation_option.add_item("Model — %s" % friendly_name)
				animation_option.set_item_metadata(animation_option.item_count - 1, {"kind": "embedded", "name": full_name})


func _apply_rarity(index: int) -> void:
	index = clampi(index, 0, RARITIES.size() - 1)
	for node_name in base_meshes:
		base_meshes[node_name].visible = node_name == RARITIES[index]["node"]
	if accent_bar != null:
		accent_bar.color = RARITIES[index]["accent"]
	for material in summon_materials:
		material.set_shader_parameter("filament_color", RARITIES[index]["accent"])
	if scan_ring != null and scan_ring.material_override is StandardMaterial3D:
		var ring_material := scan_ring.material_override as StandardMaterial3D
		ring_material.albedo_color = Color(RARITIES[index]["accent"], 0.78)
		ring_material.emission = RARITIES[index]["accent"]
	_update_status()


func _apply_model(index: int) -> void:
	model_option.select(clampi(index, 0, MODELS.size() - 1))
	_update_status()


func _apply_strength(index: int) -> void:
	index = clampi(index, 0, STRENGTHS.size() - 1)
	for chevron_index in range(rank_chevron_pairs.size()):
		var lit := chevron_index <= index
		for segment in rank_chevron_pairs[chevron_index]:
			var material := StandardMaterial3D.new()
			material.metallic = 0.62
			material.roughness = 0.26
			if lit:
				material.albedo_color = Color("#6eeaff")
				material.emission_enabled = true
				material.emission = Color("#36dcff")
				material.emission_energy_multiplier = 4.2
			else:
				material.albedo_color = Color("#243849")
				material.emission_enabled = true
				material.emission = Color("#102430")
				material.emission_energy_multiplier = 0.35
			segment.material_override = material
	_update_status()


func _play_selected_animation() -> void:
	if animation_option == null or animation_option.item_count == 0:
		return
	var metadata = animation_option.get_item_metadata(animation_option.selected)
	if metadata == null:
		return
	match metadata["kind"]:
		"summon":
			_play_layer_summon()
		"static":
			_show_creature_immediately()
			_update_status("Static showcase — drag to inspect the current model.")
		"inspect_base":
			_play_base_inspect()
		"embedded":
			_show_creature_immediately()
			if animation_player != null and animation_player.has_animation(metadata["name"]):
				animation_player.play(metadata["name"])
				_update_status("Playing embedded animation: %s" % metadata["name"])


func _play_layer_summon() -> void:
	summon_generation += 1
	var generation := summon_generation
	_restore_base_pose()
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
	if animation_player != null:
		animation_player.stop()
	creature_scene_instance.visible = false
	scan_ring.visible = false
	spark_particles.emitting = false
	_set_reveal_height(CREATURE_FOOT_Y)
	_update_status("Base locked • %s • %s" % [RARITIES[rarity_option.selected]["material"], STRENGTHS[strength_option.selected]["short"]])
	await get_tree().create_timer(SUMMON_DELAY).timeout
	if generation != summon_generation:
		return
	creature_scene_instance.visible = true
	scan_ring.visible = true
	spark_particles.restart()
	spark_particles.emitting = true
	_update_status("Printing creature in horizontal filament layers…")
	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_SINE)
	current_tween.set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_method(_set_reveal_height, CREATURE_FOOT_Y, REVEAL_TOP_Y, SUMMON_DURATION)
	current_tween.finished.connect(func() -> void:
		if generation != summon_generation:
			return
		_set_reveal_height(100.0)
		scan_ring.visible = false
		spark_particles.emitting = false
		_update_status("Summon complete • %s • %s" % [RARITIES[rarity_option.selected]["label"], STRENGTHS[strength_option.selected]["short"]])
	)


func _play_base_inspect() -> void:
	summon_generation += 1
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
	if animation_player != null:
		animation_player.stop()
	_restore_base_pose()
	is_inspecting_base = true
	creature_scene_instance.visible = false
	stats_sprite.visible = true
	scan_ring.visible = false
	spark_particles.emitting = false
	_update_status("Turning the base over to reveal the unit ledger…")
	view_tween = create_tween().set_parallel(true)
	view_tween.set_trans(Tween.TRANS_CUBIC)
	view_tween.set_ease(Tween.EASE_IN_OUT)
	view_tween.tween_property(base_flip_root, "rotation", Vector3(BASE_INSPECT_ANGLE, 0.0, 0.0), 0.9)
	view_tween.tween_property(base_flip_root, "position", BASE_INSPECT_LIFT, 0.9)
	view_tween.finished.connect(func() -> void:
		var stats: Dictionary = MODELS[model_option.selected]["stats"]
		var attacks: Array = stats["attack_types"]
		_update_status("Unit ledger • HP %s • DEF %s • OFF %s • RNG %s • COST %s • %s" % [stats["health"], stats["defense"], stats["offense"], stats["range"], stats["cost"], ", ".join(attacks)])
	)


func _show_creature_immediately() -> void:
	summon_generation += 1
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
	_restore_base_pose()
	creature_scene_instance.visible = true
	_set_reveal_height(100.0)
	scan_ring.visible = false
	spark_particles.emitting = false


func _restore_base_pose() -> void:
	if view_tween != null and view_tween.is_valid():
		view_tween.kill()
	is_inspecting_base = false
	base_flip_root.position = Vector3.ZERO
	base_flip_root.rotation = Vector3.ZERO
	if stats_sprite != null:
		stats_sprite.visible = false


func _reset_all() -> void:
	_show_creature_immediately()
	if animation_player != null:
		animation_player.stop()
	model_option.select(0)
	rarity_option.select(0)
	strength_option.select(0)
	animation_option.select(0)
	_apply_model(0)
	_apply_rarity(0)
	_apply_strength(0)
	orbit_y = DEFAULT_ORBIT_Y
	orbit_pitch = DEFAULT_ORBIT_PITCH
	display_root.position = DEFAULT_DISPLAY_POSITION
	_apply_orbit()
	_set_camera_fov(DEFAULT_CAMERA_FOV)
	active_touches.clear()
	pinch_distance = -1.0
	_update_status("Reset complete — default model, base, rank, animation, rotation, and zoom restored.")


func _set_reveal_height(value: float) -> void:
	for material in summon_materials:
		material.set_shader_parameter("reveal_height", value)
	if scan_ring != null:
		scan_ring.position.y = value
	if spark_particles != null:
		spark_particles.position.y = value


func _apply_orbit() -> void:
	display_root.rotation = Vector3(orbit_pitch, orbit_y, 0.0)


func _set_camera_fov(value: float) -> void:
	if camera != null:
		camera.fov = clampf(value, MIN_CAMERA_FOV, MAX_CAMERA_FOV)


func _current_pinch_distance() -> float:
	if active_touches.size() < 2:
		return -1.0
	var positions: Array = active_touches.values()
	return (positions[0] as Vector2).distance_to(positions[1] as Vector2)


func _update_status(message := "") -> void:
	if status_label == null:
		return
	if not message.is_empty():
		status_label.text = message
		return
	if rarity_option == null or strength_option == null:
		return
	status_label.text = "%s • %s" % [RARITIES[rarity_option.selected]["material"], STRENGTHS[strength_option.selected]["short"]]


func _collect_mesh_instances(root: Node) -> Array:
	var result := []
	if root is MeshInstance3D:
		result.append(root)
	for child in root.get_children():
		result.append_array(_collect_mesh_instances(child))
	return result


func _run_smoke_test() -> void:
	await get_tree().process_frame
	assert(base_meshes.size() == 6, "Expected six selectable bases")
	assert(model_option.item_count == 1, "Expected the initial goblin model entry")
	assert(model_option.get_item_text(0) == MODELS[0]["label"], "Unexpected initial model label")
	var goblin_stats: Dictionary = MODELS[0]["stats"]
	assert(goblin_stats["health"] == 24 and goblin_stats["defense"] == 6, "Unexpected goblin durability stats")
	assert(goblin_stats["offense"] == 8 and goblin_stats["range"] == 0 and goblin_stats["cost"] == 3, "Unexpected goblin combat stats")
	assert((goblin_stats["attack_types"] as Array).has("Melee"), "Expected melee attack type")
	assert(creature_meshes.size() > 0, "Expected a creature mesh")
	assert(summon_materials.size() > 0, "Expected summon shader materials")
	assert(rank_chevron_pairs.size() == 3, "Expected three rank chevrons")
	assert(stats_sprite != null, "Expected a parchment stats sticker")
	var orbit_before := orbit_y
	var synthetic_drag := InputEventScreenDrag.new()
	synthetic_drag.relative = Vector2(24.0, 0.0)
	_unhandled_input(synthetic_drag)
	assert(not is_equal_approx(orbit_before, orbit_y), "Expected drag input to rotate the display")
	var fov_before := camera.fov
	_set_camera_fov(fov_before - 5.0)
	assert(camera.fov < fov_before, "Expected zoom input to change the camera FOV")
	for rarity_index in range(RARITIES.size()):
		rarity_option.select(rarity_index)
		_apply_rarity(rarity_index)
	for strength_index in range(STRENGTHS.size()):
		strength_option.select(strength_index)
		_apply_strength(strength_index)
	if animation_player != null:
		for animation_name in embedded_animations:
			assert(animation_player.has_animation(animation_name), "Missing discovered animation: %s" % animation_name)
			animation_player.play(animation_name)
			await get_tree().process_frame
		animation_player.stop()
	rarity_option.select(3)
	_apply_rarity(3)
	strength_option.select(2)
	_apply_strength(2)
	_play_layer_summon()
	await get_tree().create_timer(SUMMON_DELAY + SUMMON_DURATION + 0.4).timeout
	_play_base_inspect()
	await get_tree().create_timer(1.05).timeout
	assert(stats_sprite.visible, "Expected the underside stats label during base inspection")
	assert(is_equal_approx(base_flip_root.rotation.x, BASE_INSPECT_ANGLE), "Expected the base to flip toward the camera")
	_reset_all()
	assert(not stats_sprite.visible and creature_scene_instance.visible, "Expected reset to restore the creature view")
	assert(is_equal_approx(camera.fov, DEFAULT_CAMERA_FOV), "Expected reset to restore zoom")
	assert(is_equal_approx(orbit_y, DEFAULT_ORBIT_Y) and is_equal_approx(orbit_pitch, DEFAULT_ORBIT_PITCH), "Expected reset to restore orientation")
	print("SUMMON_LAB_SMOKE_TEST_OK bases=%d creature_meshes=%d materials=%d embedded_animations=%d" % [base_meshes.size(), creature_meshes.size(), summon_materials.size(), embedded_animations.size()])
	get_tree().quit(0)


func _run_capture(path: String) -> void:
	await get_tree().process_frame
	rarity_option.select(3)
	_apply_rarity(3)
	strength_option.select(2)
	_apply_strength(2)
	_play_layer_summon()
	await get_tree().create_timer(SUMMON_DELAY + SUMMON_DURATION * 0.52).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("SUMMON_LAB_CAPTURE path=%s error=%d" % [path, error])
	get_tree().quit(0 if error == OK else 2)


func _run_animation_capture(path: String, clip_name: String) -> void:
	await get_tree().process_frame
	_show_creature_immediately()
	if animation_player == null or not animation_player.has_animation(clip_name):
		push_error("Capture clip not found: %s" % clip_name)
		get_tree().quit(3)
		return
	var clip: Animation = animation_player.get_animation(clip_name)
	animation_player.play(clip_name)
	await get_tree().create_timer(maxf(0.1, clip.length * 0.52)).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("SUMMON_LAB_ANIMATION_CAPTURE clip=%s path=%s error=%d" % [clip_name, path, error])
	get_tree().quit(0 if error == OK else 2)


func _run_base_capture(path: String) -> void:
	await get_tree().process_frame
	_play_base_inspect()
	await get_tree().create_timer(1.05).timeout
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("SUMMON_LAB_BASE_CAPTURE path=%s error=%d" % [path, error])
	get_tree().quit(0 if error == OK else 2)
