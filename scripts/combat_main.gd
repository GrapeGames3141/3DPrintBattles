extends Node3D

const CombatDataScript := preload("res://scripts/combat_data.gd")
const TERRAIN_KIT_SCENE: PackedScene = preload("res://assets/models/enchanted_terrain_kit_runtime.glb")

const MAP_WIDTH := 25
const MAP_HEIGHT := 33
const CELL_SIZE := 1.75
const PRINTER_HP := 50
const PRINTER_DEFENSE := 8
const STARTING_FILAMENT := 6
const FILAMENT_PER_ROUND := 2
const MAX_FILAMENT := 10
const PLAYER_DEFAULT_FACTION := "elves"
const CAMERA_FOCUS := Vector3(0.0, 0.0, 4.0)
const DEFAULT_CAMERA_DISTANCE := 55.0
const MIN_CAMERA_DISTANCE := 8.0
const MAX_CAMERA_DISTANCE := 72.0
const CAMERA_DEFAULT_OFFSET := Vector3(0.0, 44.0, 51.0)
const DEFAULT_CAMERA_PITCH_DEGREES := 40.78
const MIN_CAMERA_PITCH_DEGREES := 24.0
const MAX_CAMERA_PITCH_DEGREES := 72.0
const CAMERA_TOUCH_PAN_SPEED := 0.035
const CAMERA_MOUSE_PAN_SPEED := 0.028
const CAMERA_ORBIT_SPEED := 0.18
const TOUCH_DRAG_THRESHOLD := 12.0

const TERRAIN_GRASS := "grass"
const TERRAIN_ROAD := "road"
const TERRAIN_WATER := "water"
const TERRAIN_BRIDGE := "bridge"

const NORTH_PRINTER_CELLS := [Vector2i(11, 1), Vector2i(12, 1), Vector2i(11, 2), Vector2i(12, 2)]
const SOUTH_PRINTER_CELLS := [Vector2i(11, 30), Vector2i(12, 30), Vector2i(11, 31), Vector2i(12, 31)]
const NORTH_SPAWN_CELLS := [Vector2i(10, 3), Vector2i(11, 3), Vector2i(12, 3), Vector2i(13, 3), Vector2i(14, 3), Vector2i(10, 4), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 4), Vector2i(14, 4)]
const SOUTH_SPAWN_CELLS := [Vector2i(10, 28), Vector2i(11, 28), Vector2i(12, 28), Vector2i(13, 28), Vector2i(14, 28), Vector2i(10, 29), Vector2i(11, 29), Vector2i(12, 29), Vector2i(13, 29), Vector2i(14, 29)]

const TREE_CELLS := [
	Vector2i(2, 5), Vector2i(5, 8), Vector2i(18, 5), Vector2i(21, 8),
	Vector2i(3, 12), Vector2i(7, 13), Vector2i(17, 12), Vector2i(21, 13),
	Vector2i(3, 20), Vector2i(7, 19), Vector2i(17, 20), Vector2i(21, 19),
	Vector2i(2, 27), Vector2i(6, 24), Vector2i(18, 27), Vector2i(22, 24),
]

const BOULDER_CELLS := [
	Vector2i(8, 6), Vector2i(16, 6), Vector2i(5, 15), Vector2i(19, 15),
	Vector2i(5, 17), Vector2i(19, 17), Vector2i(8, 26), Vector2i(16, 26),
	Vector2i(1, 10), Vector2i(23, 10), Vector2i(1, 22), Vector2i(23, 22),
]

const HILL_CELLS := [Vector2i(4, 4), Vector2i(20, 4), Vector2i(3, 16), Vector2i(21, 16), Vector2i(4, 28), Vector2i(20, 28)]

var terrain := {}
var obstacles := {}
var printer_cells := {}
var units := {}
var cell_occupants := {}
var printers := {}
var faction_state := {}

var player_faction := PLAYER_DEFAULT_FACTION
var ai_faction := "goblins"
var first_faction := "elves"
var round_number := 1
var phase := "setup"
var initiative_queue: Array[String] = []
var active_unit_id := ""
var selected_unit_id := ""
var input_mode := "inspect"
var reachable_cache := {}
var target_cache: Array[Vector2i] = []
var battle_over := false
var action_counter := 0
var smoke_mode := false
var capture_mode := false
var capture_path := ""
var autoplay_both := false
var rng := RandomNumberGenerator.new()

var camera_rig: Node3D
var camera: Camera3D
var camera_distance := DEFAULT_CAMERA_DISTANCE
var camera_focus := CAMERA_FOCUS
var camera_yaw_degrees := 0.0
var camera_pitch_degrees := DEFAULT_CAMERA_PITCH_DEGREES
var camera_dragging := false
var camera_rotation_dragging := false
var active_touches := {}
var touch_start_positions := {}
var touch_dragged := {}
var pinch_distance := -1.0
var pinch_active := false
var two_finger_angle := 0.0
var two_finger_centroid := Vector2.ZERO
var world_root: Node3D
var terrain_root: Node3D
var prop_root: Node3D
var unit_root: Node3D
var overlay_root: Node3D

var top_status: Label
var round_label: Label
var filament_label: Label
var printer_label: Label
var active_label: Label
var inspector_title: Label
var inspector_portrait: TextureRect
var inspector_body: Label
var roster_panel: VBoxContainer
var action_panel: HBoxContainer
var ability_button: Button
var attack_button: Button
var wait_button: Button
var skip_spawn_button: Button
var faction_overlay: Control
var winner_overlay: Control
var winner_label: Label

var tile_meshes := {}
var tile_materials := {}
var terrain_asset_meshes := {}
var terrain_instance_counts := {}


func _ready() -> void:
	CombatDataScript.validate()
	rng.seed = 1337
	_parse_command_line()
	_build_world()
	_build_ui()
	if smoke_mode or capture_mode:
		call_deferred("_begin_match", PLAYER_DEFAULT_FACTION)
	else:
		_show_faction_choice()


func _parse_command_line() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--combat-smoke-test":
			smoke_mode = true
			autoplay_both = true
		elif arg.begins_with("--combat-capture="):
			capture_mode = true
			capture_path = arg.trim_prefix("--combat-capture=")


func _build_world() -> void:
	world_root = Node3D.new()
	world_root.name = "CombatWorld"
	add_child(world_root)

	terrain_root = Node3D.new()
	terrain_root.name = "Terrain"
	world_root.add_child(terrain_root)
	prop_root = Node3D.new()
	prop_root.name = "Props"
	world_root.add_child(prop_root)
	unit_root = Node3D.new()
	unit_root.name = "Units"
	world_root.add_child(unit_root)
	overlay_root = Node3D.new()
	overlay_root.name = "GridOverlays"
	world_root.add_child(overlay_root)

	_build_environment()
	_build_camera()
	_build_map()
	_build_printers()


func _build_environment() -> void:
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#0b1422")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b8d2e7")
	environment.ambient_light_energy = 0.38
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment_node.environment = environment
	add_child(environment_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-56.0, -28.0, 0.0)
	sun.light_color = Color("#fff0cf")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-32.0, 148.0, 0.0)
	fill.light_color = Color("#68bfff")
	fill.light_energy = 0.28
	add_child(fill)


func _build_camera() -> void:
	camera_rig = Node3D.new()
	camera_rig.name = "TacticalCameraRig"
	add_child(camera_rig)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 45.0
	camera_rig.add_child(camera)
	_update_camera_transform()


func _build_map() -> void:
	_prepare_terrain_assets()
	_prepare_tile_assets()
	for z in range(MAP_HEIGHT):
		for x in range(MAP_WIDTH):
			var cell := Vector2i(x, z)
			var kind := TERRAIN_GRASS
			if z in [15, 16]:
				kind = TERRAIN_BRIDGE if x in [11, 12, 13] else TERRAIN_WATER
			elif x in [11, 12, 13]:
				kind = TERRAIN_ROAD
			terrain[cell] = kind
			_add_tile(cell, kind)
	_add_surface_terrain()

	for cell in TREE_CELLS:
		obstacles[cell] = "tree"
		_add_tree(cell)
	for cell in BOULDER_CELLS:
		obstacles[cell] = "boulder"
		_add_boulder(cell)
	for cell in HILL_CELLS:
		_add_hill(cell)


func _prepare_terrain_assets() -> void:
	var library := TERRAIN_KIT_SCENE.instantiate()
	for child in library.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		terrain_asset_meshes[str(mesh_instance.name)] = mesh_instance.mesh
	library.free()
	var expected := [
		"BroadleafTree", "PineTree", "DeadStump", "RoundedBoulder", "JaggedBoulders",
		"RollingHill", "RoadTile", "StreamTile", "BridgeTile",
	]
	for asset_name in expected:
		assert(terrain_asset_meshes.has(asset_name), "Missing runtime terrain mesh: %s" % asset_name)


func _prepare_tile_assets() -> void:
	var colors := {
		TERRAIN_GRASS: Color("#4f7044"),
		TERRAIN_ROAD: Color("#806044"),
		TERRAIN_WATER: Color(0.12, 0.48, 0.66, 0.80),
		TERRAIN_BRIDGE: Color("#8d6138"),
	}
	for kind in colors:
		var box := BoxMesh.new()
		box.size = Vector3(CELL_SIZE - 0.045, 0.12 if kind != TERRAIN_WATER else 0.055, CELL_SIZE - 0.045)
		tile_meshes[kind] = box
		var material := StandardMaterial3D.new()
		material.albedo_color = colors[kind]
		material.roughness = 0.78
		if kind == TERRAIN_WATER:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.metallic = 0.22
		else:
			material.metallic = 0.04
		tile_materials[kind] = material


func _add_tile(cell: Vector2i, kind: String) -> void:
	var tile := MeshInstance3D.new()
	tile.name = "Tile_%d_%d_%s" % [cell.x, cell.y, kind]
	tile.mesh = tile_meshes[kind]
	tile.material_override = tile_materials[kind]
	tile.position = _cell_to_world(cell)
	tile.position.y = -0.075 if kind != TERRAIN_WATER else -0.105
	terrain_root.add_child(tile)


func _add_surface_terrain() -> void:
	for z in range(MAP_HEIGHT):
		if z in [15, 16]:
			continue
		_add_fitted_terrain_mesh(
			"RoadTile",
			terrain_root,
			_cell_to_world(Vector2i(12, z)) + Vector3(0.0, -0.105, 0.0),
			CELL_SIZE * 3.0 - 0.04,
			CELL_SIZE - 0.035,
			1.7
		)
	var river_center_z := (_cell_to_world(Vector2i(0, 15)).z + _cell_to_world(Vector2i(0, 16)).z) * 0.5
	for x in range(MAP_WIDTH):
		if x in [11, 12, 13]:
			continue
		_add_fitted_terrain_mesh(
			"StreamTile",
			terrain_root,
			Vector3(_cell_to_world(Vector2i(x, 15)).x, -0.08, river_center_z),
			CELL_SIZE - 0.035,
			CELL_SIZE * 2.0 - 0.04,
			1.55
		)
	_add_fitted_terrain_mesh(
		"BridgeTile",
		terrain_root,
		Vector3(_cell_to_world(Vector2i(12, 15)).x, -0.22, river_center_z),
		CELL_SIZE * 2.0 - 0.04,
		CELL_SIZE * 3.0 - 0.04,
		1.8,
		90.0
	)


func _add_fitted_terrain_mesh(
	asset_name: String,
	parent: Node3D,
	position: Vector3,
	width: float,
	depth: float,
	vertical_scale: float,
	rotation_y_degrees := 0.0
) -> MeshInstance3D:
	var mesh: Mesh = terrain_asset_meshes[asset_name]
	var size := mesh.get_aabb().size
	var instance := MeshInstance3D.new()
	instance.name = asset_name
	instance.mesh = mesh
	instance.position = position
	instance.scale = Vector3(width / maxf(size.x, 0.001), vertical_scale, depth / maxf(size.z, 0.001))
	instance.rotation_degrees.y = rotation_y_degrees
	parent.add_child(instance)
	terrain_instance_counts[asset_name] = int(terrain_instance_counts.get(asset_name, 0)) + 1
	return instance


func _add_tree(cell: Vector2i) -> void:
	var root := Node3D.new()
	root.name = "Tree_%d_%d" % [cell.x, cell.y]
	root.position = _cell_to_world(cell)
	prop_root.add_child(root)
	var variant := posmod(cell.x * 7 + cell.y * 3, 5)
	var asset_name := "BroadleafTree"
	var horizontal_scale := 3.0
	var vertical_scale := 4.3
	if variant in [1, 3]:
		asset_name = "PineTree"
		horizontal_scale = 4.5
		vertical_scale = 5.8
	elif variant == 4:
		asset_name = "DeadStump"
		horizontal_scale = 2.9
		vertical_scale = 3.8
	var tree := MeshInstance3D.new()
	tree.name = asset_name
	tree.mesh = terrain_asset_meshes[asset_name]
	tree.scale = Vector3(horizontal_scale, vertical_scale, horizontal_scale)
	tree.position.y = -0.035
	tree.rotation_degrees.y = float(posmod(cell.x * 31 + cell.y * 17, 4)) * 90.0
	root.add_child(tree)
	_add_obstacle_collision(root, 0.55, 2.1)


func _add_boulder(cell: Vector2i) -> void:
	var root := Node3D.new()
	root.name = "Boulder_%d_%d" % [cell.x, cell.y]
	root.position = _cell_to_world(cell)
	prop_root.add_child(root)
	var asset_name := "RoundedBoulder" if posmod(cell.x + cell.y, 2) == 0 else "JaggedBoulders"
	var rock := MeshInstance3D.new()
	rock.name = asset_name
	rock.mesh = terrain_asset_meshes[asset_name]
	rock.scale = Vector3(2.3, 3.0, 2.3)
	rock.position.y = -0.035
	rock.rotation_degrees.y = float(posmod(cell.x * 19 + cell.y * 11, 4)) * 90.0
	root.add_child(rock)
	_add_obstacle_collision(root, 0.65, 0.95)


func _add_hill(cell: Vector2i) -> void:
	var hill := MeshInstance3D.new()
	hill.name = "RollingHill_%d_%d" % [cell.x, cell.y]
	hill.mesh = terrain_asset_meshes["RollingHill"]
	hill.scale = Vector3(2.3, 3.0, 2.3)
	hill.position = _cell_to_world(cell) + Vector3(0.0, -0.05, 0.0)
	hill.rotation_degrees.y = float(posmod(cell.x + cell.y, 4)) * 90.0
	prop_root.add_child(hill)


func _add_obstacle_collision(parent: Node3D, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.name = "GridObstacleCollision"
	body.collision_layer = 2
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	collision.position.y = height * 0.5
	body.add_child(collision)
	parent.add_child(body)


func _build_printers() -> void:
	_create_printer(CombatDataScript.FACTION_GOBLINS, NORTH_PRINTER_CELLS)
	_create_printer(CombatDataScript.FACTION_ELVES, SOUTH_PRINTER_CELLS)


func _create_printer(faction: String, cells: Array) -> void:
	var root := Node3D.new()
	root.name = CombatDataScript.FACTIONS[faction]["printer_name"]
	root.position = _cells_center(cells)
	prop_root.add_child(root)
	var faction_color: Color = CombatDataScript.FACTIONS[faction]["color"]
	var dark_color: Color = CombatDataScript.FACTIONS[faction]["dark"]

	var platform := MeshInstance3D.new()
	var platform_mesh := BoxMesh.new()
	platform_mesh.size = Vector3(CELL_SIZE * 1.82, 0.32, CELL_SIZE * 1.82)
	platform.mesh = platform_mesh
	platform.position.y = 0.16
	platform.material_override = _material(dark_color, 0.42, 0.58)
	root.add_child(platform)
	for side in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.34, 2.25, 0.42)
		post.mesh = post_mesh
		post.position = Vector3(side * 1.15, 1.32, 0.0)
		post.material_override = _material(dark_color.lightened(0.18), 0.36, 0.68)
		root.add_child(post)
	var gantry := MeshInstance3D.new()
	var gantry_mesh := BoxMesh.new()
	gantry_mesh.size = Vector3(2.65, 0.34, 0.44)
	gantry.mesh = gantry_mesh
	gantry.position = Vector3(0.0, 2.35, 0.0)
	gantry.material_override = _material(dark_color.lightened(0.22), 0.33, 0.70)
	root.add_child(gantry)
	var nozzle := MeshInstance3D.new()
	var nozzle_mesh := CylinderMesh.new()
	nozzle_mesh.top_radius = 0.19
	nozzle_mesh.bottom_radius = 0.10
	nozzle_mesh.height = 0.65
	nozzle.mesh = nozzle_mesh
	nozzle.position = Vector3(0.0, 1.92, 0.0)
	nozzle.material_override = _emissive_material(faction_color, 2.8)
	root.add_child(nozzle)
	var spool := MeshInstance3D.new()
	var spool_mesh := TorusMesh.new()
	spool_mesh.inner_radius = 0.42
	spool_mesh.outer_radius = 0.69
	spool.mesh = spool_mesh
	spool.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	spool.position = Vector3(0.0, 2.85, 0.0)
	spool.material_override = _emissive_material(faction_color, 1.5)
	root.add_child(spool)

	printers[faction] = {"hp": PRINTER_HP, "max_hp": PRINTER_HP, "defense": PRINTER_DEFENSE, "cells": cells, "node": root}
	for cell in cells:
		printer_cells[cell] = faction


func _material(color: Color, roughness := 0.65, metallic := 0.08) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _material(color, 0.28, 0.48)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3((float(cell.x) - 12.0) * CELL_SIZE, 0.0, (float(cell.y) - 16.0) * CELL_SIZE)


func _cells_center(cells: Array) -> Vector3:
	var result := Vector3.ZERO
	for cell in cells:
		result += _cell_to_world(cell)
	return result / float(cells.size())


func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "CombatUI"
	add_child(canvas)

	var top_bar := PanelContainer.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_bottom = 58.0
	top_bar.add_theme_stylebox_override("panel", _panel_style(Color("#101b2dda"), Color("#d7bb75")))
	canvas.add_child(top_bar)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 28)
	top_bar.add_child(top_row)
	top_status = _label("PRINTFORGE // COMBAT PROOF", 20, Color("#ffd886"))
	top_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(top_status)
	round_label = _label("ROUND 1", 18, Color.WHITE)
	top_row.add_child(round_label)
	printer_label = _label("FORGES G50 • E50", 16, Color("#ffb49c"))
	top_row.add_child(printer_label)
	filament_label = _label("FILAMENT", 18, Color("#7de3b0"))
	top_row.add_child(filament_label)
	active_label = _label("DEPLOYMENT", 18, Color("#8ccfff"))
	active_label.custom_minimum_size.x = 290.0
	top_row.add_child(active_label)
	var reset_view_button := _action_button("RESET VIEW")
	reset_view_button.custom_minimum_size = Vector2(112.0, 38.0)
	reset_view_button.pressed.connect(_reset_camera_view)
	top_row.add_child(reset_view_button)

	var roster_box := PanelContainer.new()
	roster_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	roster_box.position = Vector2(16.0, -245.0)
	roster_box.size = Vector2(300.0, 490.0)
	roster_box.add_theme_stylebox_override("panel", _panel_style(Color("#101b2ded"), Color("#53718b")))
	canvas.add_child(roster_box)
	var roster_margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		roster_margin.add_theme_constant_override(side, 12)
	roster_box.add_child(roster_margin)
	roster_panel = VBoxContainer.new()
	roster_panel.add_theme_constant_override("separation", 8)
	roster_margin.add_child(roster_panel)

	var inspector_box := PanelContainer.new()
	inspector_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	inspector_box.position = Vector2(-316.0, -245.0)
	inspector_box.size = Vector2(300.0, 490.0)
	inspector_box.add_theme_stylebox_override("panel", _panel_style(Color("#101b2ded"), Color("#53718b")))
	canvas.add_child(inspector_box)
	var inspector_margin := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		inspector_margin.add_theme_constant_override(side, 14)
	inspector_box.add_child(inspector_margin)
	var inspector_column := VBoxContainer.new()
	inspector_column.add_theme_constant_override("separation", 8)
	inspector_margin.add_child(inspector_column)
	inspector_title = _label("SELECT A UNIT", 22, Color("#ffd886"))
	inspector_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_column.add_child(inspector_title)
	inspector_portrait = TextureRect.new()
	inspector_portrait.custom_minimum_size.y = 92.0
	inspector_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inspector_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inspector_column.add_child(inspector_portrait)
	inspector_body = _label("Choose a roster card to deploy, or click a figure on the field.", 14, Color("#d8e2ed"))
	inspector_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inspector_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inspector_column.add_child(inspector_body)

	var bottom_box := PanelContainer.new()
	bottom_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bottom_box.position = Vector2(-350.0, -82.0)
	bottom_box.size = Vector2(700.0, 66.0)
	bottom_box.add_theme_stylebox_override("panel", _panel_style(Color("#101b2ded"), Color("#d7bb75")))
	canvas.add_child(bottom_box)
	action_panel = HBoxContainer.new()
	action_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	action_panel.add_theme_constant_override("separation", 12)
	bottom_box.add_child(action_panel)
	attack_button = _action_button("BASIC ATTACK")
	attack_button.pressed.connect(_on_attack_pressed)
	action_panel.add_child(attack_button)
	ability_button = _action_button("ABILITY")
	ability_button.pressed.connect(_on_ability_pressed)
	action_panel.add_child(ability_button)
	wait_button = _action_button("WAIT")
	wait_button.pressed.connect(_on_wait_pressed)
	action_panel.add_child(wait_button)
	skip_spawn_button = _action_button("SKIP SPAWN")
	skip_spawn_button.pressed.connect(_on_skip_spawn_pressed)
	action_panel.add_child(skip_spawn_button)

	faction_overlay = _build_modal(canvas, "CHOOSE YOUR ARMY", "The other army is controlled by the tactical AI.")
	var modal_buttons: HBoxContainer = faction_overlay.get_node("Panel/Margin/Column/Buttons")
	var elves_button := _action_button("PLAY ELVES")
	elves_button.pressed.connect(_begin_match.bind("elves"))
	modal_buttons.add_child(elves_button)
	var goblins_button := _action_button("PLAY GOBLINS")
	goblins_button.pressed.connect(_begin_match.bind("goblins"))
	modal_buttons.add_child(goblins_button)

	winner_overlay = _build_modal(canvas, "BATTLE COMPLETE", "")
	winner_label = winner_overlay.get_node("Panel/Margin/Column/Body")
	var winner_buttons: HBoxContainer = winner_overlay.get_node("Panel/Margin/Column/Buttons")
	var rematch := _action_button("REMATCH")
	rematch.pressed.connect(_reload_scene)
	winner_buttons.add_child(rematch)
	winner_overlay.visible = false
	_update_ui()


func _build_modal(canvas: CanvasLayer, heading: String, body: String) -> Control:
	var shade := ColorRect.new()
	shade.color = Color("#07101bd9")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas.add_child(shade)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-270.0, -125.0)
	panel.size = Vector2(540.0, 250.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#132238"), Color("#d7bb75"), 3))
	shade.add_child(panel)
	var margin := MarginContainer.new()
	margin.name = "Margin"
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.name = "Column"
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var title := _label(heading, 28, Color("#ffd886"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var body_label := _label(body, 17, Color("#d8e2ed"))
	body_label.name = "Body"
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body_label)
	var buttons := HBoxContainer.new()
	buttons.name = "Buttons"
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)
	return shade


func _panel_style(color: Color, border: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	return style


func _label(text_value: String, size: int, color: Color) -> Label:
	var result := Label.new()
	result.text = text_value
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	return result


func _action_button(text_value: String) -> Button:
	var result := Button.new()
	result.text = text_value
	result.custom_minimum_size = Vector2(145.0, 42.0)
	result.add_theme_font_size_override("font_size", 15)
	return result


func _show_faction_choice() -> void:
	phase = "setup"
	faction_overlay.visible = true


func _reload_scene() -> void:
	get_tree().reload_current_scene()


func _begin_match(chosen_faction: String) -> void:
	player_faction = chosen_faction
	ai_faction = CombatDataScript.enemy_faction(player_faction)
	faction_overlay.visible = false
	first_faction = CombatDataScript.FACTION_ELVES if rng.randi_range(0, 1) == 0 else CombatDataScript.FACTION_GOBLINS
	faction_state.clear()
	for faction in CombatDataScript.ROSTERS.keys():
		faction_state[faction] = {
			"filament": STARTING_FILAMENT,
			"reserve": CombatDataScript.ROSTERS[faction].duplicate(),
			"spawned": false,
		}
	phase = "spawn"
	round_number = 1
	if capture_mode:
		_setup_capture_armies()
		call_deferred("_capture_validation_frame")
		return
	_start_spawn_phase()
	if OS.has_feature("mobile"):
		_set_notice("Touch: one finger pans; two-finger twist rotates; two-finger slide tilts; pinch zooms.")
	if smoke_mode:
		call_deferred("_run_smoke_test")


func _start_spawn_phase() -> void:
	phase = "spawn"
	active_unit_id = ""
	selected_unit_id = ""
	for faction in faction_state.keys():
		faction_state[faction]["spawned"] = false
	_build_roster_cards()
	if autoplay_both:
		_ai_spawn(first_faction)
		_ai_spawn(CombatDataScript.enemy_faction(first_faction))
	else:
		_ai_spawn(ai_faction)
		if not _has_affordable_reserve(player_faction):
			_complete_spawn(player_faction)
	_update_ui()


func _build_roster_cards() -> void:
	for child in roster_panel.get_children():
		child.queue_free()
	var heading := _label("%s RESERVES" % CombatDataScript.FACTIONS[player_faction]["short"], 20, CombatDataScript.FACTIONS[player_faction]["color"])
	roster_panel.add_child(heading)
	if phase != "spawn":
		var hint := _label("Deployment closes while initiative resolves.", 15, Color("#aebdcb"))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		roster_panel.add_child(hint)
		return
	var reserve: Array = faction_state[player_faction]["reserve"]
	if reserve.is_empty():
		roster_panel.add_child(_label("All units deployed.", 16, Color("#aebdcb")))
	for unit_key in reserve:
		var data: Dictionary = CombatDataScript.UNITS[unit_key]
		var button := Button.new()
		button.text = "%s  [%s]\n%s  •  %d filament" % [data["name"], data["rarity"], " / ".join(data["roles"]), data["cost"]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(255.0, 58.0)
		button.disabled = int(data["cost"]) > int(faction_state[player_faction]["filament"]) or bool(faction_state[player_faction]["spawned"])
		button.pressed.connect(_request_player_spawn.bind(unit_key))
		roster_panel.add_child(button)


func _request_player_spawn(unit_key: String) -> void:
	if phase != "spawn" or bool(faction_state[player_faction]["spawned"]):
		return
	var cell := _first_free_spawn_cell(player_faction)
	if cell.x < 0:
		return
	_spawn_unit(player_faction, unit_key, cell, not smoke_mode)
	_complete_spawn(player_faction)


func _ai_spawn(faction: String) -> void:
	if bool(faction_state[faction]["spawned"]):
		return
	var reserve: Array = faction_state[faction]["reserve"]
	var affordable: Array[String] = []
	for unit_key in reserve:
		if int(CombatDataScript.UNITS[unit_key]["cost"]) <= int(faction_state[faction]["filament"]):
			affordable.append(unit_key)
	if not affordable.is_empty():
		affordable.sort_custom(func(a: String, b: String) -> bool: return int(CombatDataScript.UNITS[a]["cost"]) > int(CombatDataScript.UNITS[b]["cost"]))
		var cell := _first_free_spawn_cell(faction)
		if cell.x >= 0:
			_spawn_unit(faction, affordable[0], cell, not smoke_mode)
	_complete_spawn(faction)


func _complete_spawn(faction: String) -> void:
	if not faction_state.has(faction):
		return
	faction_state[faction]["spawned"] = true
	_build_roster_cards()
	_update_ui()
	if bool(faction_state[CombatDataScript.FACTION_GOBLINS]["spawned"]) and bool(faction_state[CombatDataScript.FACTION_ELVES]["spawned"]):
		call_deferred("_start_initiative_phase")


func _has_affordable_reserve(faction: String) -> bool:
	for unit_key in faction_state[faction]["reserve"]:
		if int(CombatDataScript.UNITS[unit_key]["cost"]) <= int(faction_state[faction]["filament"]):
			return true
	return false


func _first_free_spawn_cell(faction: String) -> Vector2i:
	var choices: Array = NORTH_SPAWN_CELLS if faction == CombatDataScript.FACTION_GOBLINS else SOUTH_SPAWN_CELLS
	for cell in choices:
		if not cell_occupants.has(cell):
			return cell
	return Vector2i(-1, -1)


func _spawn_unit(faction: String, unit_key: String, cell: Vector2i, animate: bool) -> String:
	var data: Dictionary = CombatDataScript.UNITS[unit_key]
	if int(faction_state[faction]["filament"]) < int(data["cost"]):
		return ""
	var id := "%s_%s_%02d" % [faction, unit_key, units.size() + 1]
	var node := _build_unit_figure(id, data, faction)
	node.position = _cell_to_world(cell)
	unit_root.add_child(node)
	var entry := {
		"id": id,
		"key": unit_key,
		"faction": faction,
		"cell": cell,
		"hp": int(data["hp"]),
		"max_hp": int(data["hp"]),
		"cooldown": 0,
		"acted": false,
		"moved": 0,
		"statuses": {},
		"node": node,
	}
	units[id] = entry
	cell_occupants[cell] = id
	faction_state[faction]["filament"] = int(faction_state[faction]["filament"]) - int(data["cost"])
	var reserve: Array = faction_state[faction]["reserve"]
	reserve.erase(unit_key)
	if animate:
		_play_print_animation(node, CombatDataScript.FACTIONS[faction]["color"])
	return id


func _build_unit_figure(id: String, data: Dictionary, faction: String) -> Node3D:
	var root := Node3D.new()
	root.name = id
	var style: Dictionary = CombatDataScript.RARITY_STYLE[data["rarity"]]
	var base := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.65
	disc.bottom_radius = 0.72
	disc.height = 0.20
	base.mesh = disc
	base.position.y = 0.10
	base.material_override = _material(style["color"], 0.55, 0.32 if data["rarity"] == "Rare" else 0.06)
	root.add_child(base)
	for index in range(int(style["chevrons"])):
		var mark := MeshInstance3D.new()
		var mark_mesh := BoxMesh.new()
		mark_mesh.size = Vector3(0.16, 0.035, 0.05)
		mark.mesh = mark_mesh
		mark.position = Vector3((float(index) - float(style["chevrons"] - 1) * 0.5) * 0.20, 0.225, 0.54)
		mark.rotation_degrees.y = -18.0 if index % 2 == 0 else 18.0
		mark.material_override = _emissive_material(style["edge"], 1.6)
		root.add_child(mark)

	var visual_anchor := Node3D.new()
	visual_anchor.name = "Visual"
	visual_anchor.position.y = 0.21
	root.add_child(visual_anchor)
	if not smoke_mode and data.has("scene") and ResourceLoader.exists(data["scene"]):
		var resource := load(data["scene"]) as PackedScene
		if resource != null:
			var model := resource.instantiate()
			visual_anchor.add_child(model)
			_hide_helper_meshes(model)
			_fit_model_to_base(model)
			_start_model_idle(model)
	else:
		_build_procedural_standee(visual_anchor, data, faction)
	return root


func _start_model_idle(model: Node) -> void:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	for candidate in players:
		var player := candidate as AnimationPlayer
		if player == null:
			continue
		for preferred in ["Idle_6", "Idle", "idle", "Armature|clip0|baselayer"]:
			if player.has_animation(preferred):
				player.play(preferred)
				return


func _play_unit_animation(id: String, preferred: Array[String]) -> void:
	if not units.has(id):
		return
	var figure := units[id]["node"] as Node
	for candidate in figure.find_children("*", "AnimationPlayer", true, false):
		var player := candidate as AnimationPlayer
		if player == null:
			continue
		for animation_name in preferred:
			if player.has_animation(animation_name):
				player.play(animation_name)
				return


func _resume_unit_idle(id: String) -> void:
	if not units.has(id):
		return
	var figure := units[id]["node"] as Node
	for candidate in figure.find_children("*", "AnimationPlayer", true, false):
		var player := candidate as AnimationPlayer
		if player == null:
			continue
		for animation_name in ["Idle_6", "Idle", "idle", "RESET"]:
			if player.has_animation(animation_name):
				player.play(animation_name)
				return


func _build_procedural_standee(anchor: Node3D, data: Dictionary, faction: String) -> void:
	var faction_color: Color = CombatDataScript.FACTIONS[faction]["color"]
	var rarity_color: Color = CombatDataScript.RARITY_STYLE[data["rarity"]]["edge"]
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.28
	body_mesh.height = 1.12
	body.mesh = body_mesh
	body.position.y = 0.72
	body.material_override = _material(faction_color.darkened(0.18), 0.66, 0.12)
	anchor.add_child(body)
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.24
	head_mesh.height = 0.48
	head.mesh = head_mesh
	head.position.y = 1.50
	head.material_override = _material(faction_color.lightened(0.16), 0.72, 0.02)
	anchor.add_child(head)
	var weapon := MeshInstance3D.new()
	var weapon_mesh := BoxMesh.new()
	weapon_mesh.size = Vector3(0.09, 1.20, 0.09)
	weapon.mesh = weapon_mesh
	weapon.position = Vector3(0.42, 0.92, 0.0)
	weapon.rotation_degrees.z = -13.0
	weapon.material_override = _emissive_material(rarity_color, 1.0)
	anchor.add_child(weapon)
	var crest := Label3D.new()
	crest.text = str(data["name"]).left(2).to_upper()
	crest.font_size = 48
	crest.outline_size = 10
	crest.modulate = Color.WHITE
	crest.position = Vector3(0.0, 1.0, 0.30)
	crest.pixel_size = 0.006
	anchor.add_child(crest)


func _hide_helper_meshes(node: Node) -> void:
	if node is MeshInstance3D and str(node.name).to_lower().contains("icosphere"):
		node.visible = false
	for child in node.get_children():
		_hide_helper_meshes(child)


func _fit_model_to_base(model: Node3D) -> void:
	model.scale = Vector3.ONE
	model.position = Vector3.ZERO
	var combined := AABB()
	var has_bounds := false
	for candidate in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := candidate as MeshInstance3D
		if mesh == null or not mesh.visible or mesh.mesh == null:
			continue
		# Meshy skins retain a 0.01 armature-parent scale that is already handled by
		# skinning at render time. Applying that parent transform to the authored
		# mesh AABB makes the character appear 100x smaller than its real visual size.
		var bounds := mesh.get_aabb()
		combined = combined.merge(bounds) if has_bounds else bounds
		has_bounds = true
	if not has_bounds or combined.size.y <= 0.001:
		model.scale = Vector3.ONE * 0.72
		return
	var horizontal_span := maxf(combined.size.x, combined.size.z)
	var height_scale := 1.72 / combined.size.y
	var width_scale := 1.05 / horizontal_span if horizontal_span > 0.001 else height_scale
	var fit_scale := minf(height_scale, width_scale)
	model.scale = Vector3.ONE * fit_scale
	model.position = Vector3(
		-(combined.position.x + combined.size.x * 0.5) * fit_scale,
		-combined.position.y * fit_scale,
		-(combined.position.z + combined.size.z * 0.5) * fit_scale
	)


func _play_print_animation(node: Node3D, color: Color) -> void:
	var visual: Node3D = node.get_node("Visual")
	visual.scale = Vector3(1.0, 0.01, 1.0)
	var scan := MeshInstance3D.new()
	var scan_mesh := CylinderMesh.new()
	scan_mesh.top_radius = 0.76
	scan_mesh.bottom_radius = 0.76
	scan_mesh.height = 0.035
	scan.mesh = scan_mesh
	scan.position.y = 0.24
	scan.material_override = _emissive_material(color, 4.0)
	node.add_child(scan)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale:y", 1.0, 0.75)
	tween.tween_property(scan, "position:y", 2.25, 0.75)
	tween.chain().tween_callback(scan.queue_free)


func _start_initiative_phase() -> void:
	if battle_over:
		return
	phase = "initiative"
	initiative_queue.clear()
	for id in units.keys():
		if int(units[id]["hp"]) > 0:
			units[id]["acted"] = false
			initiative_queue.append(id)
	initiative_queue.sort_custom(_initiative_before)
	_build_roster_cards()
	_next_activation()


func _initiative_before(a: String, b: String) -> bool:
	var a_data: Dictionary = _unit_data(a)
	var b_data: Dictionary = _unit_data(b)
	if int(a_data["initiative"]) != int(b_data["initiative"]):
		return int(a_data["initiative"]) > int(b_data["initiative"])
	var a_first := str(units[a]["faction"]) == first_faction
	var b_first := str(units[b]["faction"]) == first_faction
	if a_first != b_first:
		return a_first
	return a < b


func _next_activation() -> void:
	_clear_overlays()
	if _check_victory():
		return
	while not initiative_queue.is_empty():
		var id: String = initiative_queue.pop_front()
		if units.has(id) and int(units[id]["hp"]) > 0:
			_begin_activation(id)
			return
	_end_round()


func _begin_activation(id: String) -> void:
	active_unit_id = id
	selected_unit_id = id
	action_counter += 1
	var unit: Dictionary = units[id]
	unit["moved"] = 0
	if int(unit["cooldown"]) > 0:
		unit["cooldown"] = int(unit["cooldown"]) - 1
	var statuses: Dictionary = unit["statuses"]
	if statuses.has("regen"):
		_heal_unit(id, int(statuses["regen"]["amount"]))
	_show_unit_in_inspector(id)
	if autoplay_both or str(unit["faction"]) == ai_faction:
		input_mode = "busy"
		_update_ui()
		call_deferred("_run_ai_activation", id)
	else:
		input_mode = "move"
		reachable_cache = _reachable_cells(id)
		_show_cells(reachable_cache.keys(), Color("#4cb7ff66"), 0.045)
		_update_ui()


func _end_activation() -> void:
	if active_unit_id == "" or not units.has(active_unit_id):
		_next_activation()
		return
	var unit: Dictionary = units[active_unit_id]
	unit["acted"] = true
	var statuses: Dictionary = unit["statuses"]
	for status_name in statuses.keys().duplicate():
		var status: Dictionary = statuses[status_name]
		status["turns"] = int(status.get("turns", 1)) - 1
		if int(status["turns"]) <= 0:
			statuses.erase(status_name)
			if status_name == "forest_shield":
				unit["hp"] = mini(int(unit["hp"]), _effective_max_hp(active_unit_id))
	active_unit_id = ""
	input_mode = "busy"
	_update_ui()
	call_deferred("_next_activation")


func _end_round() -> void:
	if _check_victory():
		return
	round_number += 1
	first_faction = CombatDataScript.enemy_faction(first_faction)
	for faction in faction_state.keys():
		faction_state[faction]["filament"] = mini(MAX_FILAMENT, int(faction_state[faction]["filament"]) + FILAMENT_PER_ROUND)
	_start_spawn_phase()


func _on_skip_spawn_pressed() -> void:
	if phase == "spawn" and faction_state.has(player_faction):
		_complete_spawn(player_faction)


func _on_attack_pressed() -> void:
	if not _player_can_act():
		return
	var valid_targets := _valid_attack_cells(active_unit_id)
	if valid_targets.is_empty():
		_set_notice("No enemy is in attack range.")
		return
	_start_target_selection(valid_targets, "attack", Color("#ff4c4c88"))


func _on_ability_pressed() -> void:
	if not _player_can_act():
		return
	var unit: Dictionary = units[active_unit_id]
	if int(unit["cooldown"]) > 0:
		_set_notice("Ability is cooling down for %d more activation(s)." % int(unit["cooldown"]))
		return
	_begin_ability(active_unit_id)


func _on_wait_pressed() -> void:
	if _player_can_act():
		_end_activation()


func _player_can_act() -> bool:
	return phase == "initiative" and active_unit_id != "" and units.has(active_unit_id) and str(units[active_unit_id]["faction"]) == player_faction and not autoplay_both


func _begin_ability(id: String) -> void:
	var ability_id := str(_unit_data(id)["ability_id"])
	match ability_id:
		"brace":
			_apply_status(id, "defense_bonus", {"amount": 4, "turns": 2})
			_finish_ability(id, "Braced: +4 Defense until the next activation.")
		"bloodlust":
			var targets := _allies_in_range(id, 1, true)
			for target_id in targets:
				_apply_status(target_id, "offense_bonus", {"amount": 3, "turns": 2})
				_apply_status(target_id, "movement_bonus", {"amount": 2, "turns": 2})
			_finish_ability(id, "Bloodlust raised nearby Offense and Movement.")
		"hold_line":
			_apply_status(id, "defense_bonus", {"amount": 3, "turns": 2})
			for target_id in _allies_in_range(id, 1, false):
				_apply_status(target_id, "defense_bonus", {"amount": 3, "turns": 2})
			_finish_ability(id, "Hold the Line raised nearby Defense.")
		"forest_shield":
			for target_id in _allies_in_range(id, 1, true):
				_apply_status(target_id, "defense_bonus", {"amount": 3, "turns": 2})
				_apply_status(target_id, "forest_shield", {"amount": 6, "turns": 2})
				units[target_id]["hp"] = int(units[target_id]["hp"]) + 6
			_finish_ability(id, "Forest Shield granted nearby allies temporary Health and Defense.")
		"stitch", "renew":
			_start_targeted_ability(_ally_cells_in_range(id, int(_unit_data(id)["range"]), true), Color("#55f0a488"))
		_:
			_start_targeted_ability(_valid_attack_cells(id), Color("#c96dff88"))


func _start_targeted_ability(cells: Array[Vector2i], color: Color) -> void:
	if cells.is_empty():
		_set_notice("No valid ability target is in range.")
		return
	_start_target_selection(cells, "ability", color)


func _start_target_selection(cells: Array[Vector2i], mode: String, color: Color) -> void:
	_clear_overlays()
	target_cache.append_array(cells)
	input_mode = mode
	_show_cells(target_cache, color, 0.065 if mode == "ability" else 0.06)
	_update_ui()


func _resolve_targeted_ability(target_cell: Vector2i) -> void:
	if active_unit_id == "" or not cell_occupants.has(target_cell):
		return
	var actor_id := active_unit_id
	var target_id: String = cell_occupants[target_cell]
	var ability_id := str(_unit_data(actor_id)["ability_id"])
	if ability_id in ["stitch", "renew", "bloodlust", "forest_shield"]:
		_play_unit_animation(actor_id, ["mage_soell_cast_4", "Spell_Cast", "Cast", "Thrust_Slash", "SwordSlash"])
	else:
		_play_unit_animation(actor_id, ["Double_Blade_Spin", "Thrust_Slash", "SwordSlash"])
	match ability_id:
		"stitch":
			_heal_unit(target_id, _effective_stat(actor_id, "offense") * 2)
			units[target_id]["statuses"].erase("slow")
			_finish_ability(actor_id, "Bogbrew Stitch healed double Offense and cleansed Pin.")
		"renew":
			_heal_unit(target_id, _effective_stat(actor_id, "offense") * 2)
			_apply_status(target_id, "regen", {"amount": 3, "turns": 2})
			_finish_ability(actor_id, "Renew healed double Offense and granted 3 regeneration.")
		"cleave":
			var full_damage := _deal_damage(actor_id, target_id, false)
			for enemy_id in _enemies_in_range(actor_id, 1):
				if enemy_id != target_id:
					_apply_raw_damage(enemy_id, maxi(1, floori(float(full_damage) / 2.0)))
			_finish_ability(actor_id, "Cleave dealt full damage to the target and half beside it.")
		"pin":
			_deal_damage(actor_id, target_id, false)
			if units.has(target_id):
				_apply_status(target_id, "slow", {"amount": 2, "turns": 2})
			_finish_ability(actor_id, "Pin dealt damage and reduced movement by 2.")
		"ambush":
			_deal_damage(actor_id, target_id, int(units[actor_id]["moved"]) >= 3)
			_finish_ability(actor_id, "Ambush ignored Defense after a 3-square approach." if int(units[actor_id]["moved"]) >= 3 else "Ambush struck before a full approach.")
		_:
			_deal_damage(actor_id, target_id, false)
			_finish_ability(actor_id, str(_unit_data(actor_id)["ability"]))


func _finish_ability(id: String, notice: String) -> void:
	if units.has(id):
		units[id]["cooldown"] = int(_unit_data(id)["cooldown"])
	_set_notice(notice)
	_end_activation()


func _resolve_basic_attack(target_cell: Vector2i) -> void:
	if active_unit_id == "":
		return
	_play_unit_animation(active_unit_id, ["Thrust_Slash", "SwordSlash", "Double_Blade_Spin"])
	if cell_occupants.has(target_cell):
		_deal_damage(active_unit_id, cell_occupants[target_cell], false)
	elif printer_cells.has(target_cell):
		_deal_printer_damage(active_unit_id, str(printer_cells[target_cell]))
	_end_activation()


func _deal_damage(attacker_id: String, target_id: String, ignore_defense: bool) -> int:
	if not units.has(attacker_id) or not units.has(target_id):
		return 0
	var offense := _effective_stat(attacker_id, "offense")
	var defense := 0 if ignore_defense else _effective_stat(target_id, "defense")
	var amount := maxi(1, offense - floori(float(defense) / 2.0))
	units[target_id]["hp"] = int(units[target_id]["hp"]) - amount
	_flash_figure(units[target_id]["node"], Color("#ff4a4a"))
	if int(units[target_id]["hp"]) <= 0:
		_remove_unit(target_id)
	_check_victory()
	return amount


func _deal_printer_damage(attacker_id: String, target_faction: String) -> int:
	if str(units[attacker_id]["faction"]) == target_faction:
		return 0
	var amount := maxi(1, _effective_stat(attacker_id, "offense") - floori(float(PRINTER_DEFENSE) / 2.0))
	printers[target_faction]["hp"] = int(printers[target_faction]["hp"]) - amount
	_flash_figure(printers[target_faction]["node"], Color("#ff4a4a"))
	_check_victory()
	return amount


func _apply_raw_damage(target_id: String, amount: int) -> void:
	if not units.has(target_id):
		return
	units[target_id]["hp"] = int(units[target_id]["hp"]) - amount
	_flash_figure(units[target_id]["node"], Color("#ff4a4a"))
	if int(units[target_id]["hp"]) <= 0:
		_remove_unit(target_id)
	_check_victory()


func _heal_unit(id: String, amount: int) -> void:
	if units.has(id):
		units[id]["hp"] = mini(_effective_max_hp(id), int(units[id]["hp"]) + amount)
		_flash_figure(units[id]["node"], Color("#55f0a4"))


func _apply_status(id: String, status_name: String, payload: Dictionary) -> void:
	if units.has(id):
		units[id]["statuses"][status_name] = payload.duplicate(true)


func _effective_stat(id: String, stat: String) -> int:
	var value := int(_unit_data(id)[stat])
	var statuses: Dictionary = units[id]["statuses"]
	if stat == "defense" and statuses.has("defense_bonus"):
		value += int(statuses["defense_bonus"]["amount"])
	elif stat == "offense" and statuses.has("offense_bonus"):
		value += int(statuses["offense_bonus"]["amount"])
	elif stat == "movement":
		if statuses.has("movement_bonus"):
			value += int(statuses["movement_bonus"]["amount"])
		if statuses.has("slow"):
			value -= int(statuses["slow"]["amount"])
		value = maxi(1, value)
	return value


func _effective_max_hp(id: String) -> int:
	var value := int(units[id]["max_hp"])
	if units[id]["statuses"].has("forest_shield"):
		value += int(units[id]["statuses"]["forest_shield"]["amount"])
	return value


func _unit_data(id: String) -> Dictionary:
	return CombatDataScript.UNITS[units[id]["key"]]


func _remove_unit(id: String) -> void:
	if not units.has(id):
		return
	cell_occupants.erase(units[id]["cell"])
	units[id]["node"].queue_free()
	units.erase(id)
	initiative_queue.erase(id)
	if selected_unit_id == id:
		selected_unit_id = ""


func _flash_figure(node: Node3D, color: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 5.0
	light.omni_range = 2.4
	light.position.y = 1.0
	node.add_child(light)
	var tween := create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.32)
	tween.tween_callback(light.queue_free)


func _reachable_cells(id: String) -> Dictionary:
	var start: Vector2i = units[id]["cell"]
	var allowance := _effective_stat(id, "movement")
	var costs := {start: 0}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		frontier.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return int(costs[a]) < int(costs[b]))
		var current: Vector2i = frontier.pop_front()
		for neighbor in _neighbors(current):
			if not _is_walkable(neighbor, id):
				continue
			var next_cost := int(costs[current]) + _movement_cost(id, neighbor)
			if next_cost > allowance:
				continue
			if not costs.has(neighbor) or next_cost < int(costs[neighbor]):
				costs[neighbor] = next_cost
				if not frontier.has(neighbor):
					frontier.append(neighbor)
	return costs


func _find_path(id: String, destination: Vector2i) -> Array[Vector2i]:
	var start: Vector2i = units[id]["cell"]
	if start == destination:
		return [start]
	var allowance := _effective_stat(id, "movement")
	var costs := {start: 0}
	var came_from := {}
	var frontier: Array[Vector2i] = [start]
	while not frontier.is_empty():
		frontier.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return int(costs[a]) < int(costs[b]))
		var current: Vector2i = frontier.pop_front()
		if current == destination:
			break
		for neighbor in _neighbors(current):
			if not _is_walkable(neighbor, id):
				continue
			var next_cost := int(costs[current]) + _movement_cost(id, neighbor)
			if next_cost > allowance:
				continue
			if not costs.has(neighbor) or next_cost < int(costs[neighbor]):
				costs[neighbor] = next_cost
				came_from[neighbor] = current
				if not frontier.has(neighbor):
					frontier.append(neighbor)
	if not costs.has(destination):
		return []
	var path: Array[Vector2i] = [destination]
	var cursor := destination
	while cursor != start:
		cursor = came_from[cursor]
		path.push_front(cursor)
	return path


func _move_unit(id: String, destination: Vector2i, animate: bool) -> void:
	var path := _find_path(id, destination)
	if path.is_empty():
		return
	var old_cell: Vector2i = units[id]["cell"]
	var spent := 0
	for index in range(1, path.size()):
		spent += _movement_cost(id, path[index])
	cell_occupants.erase(old_cell)
	units[id]["cell"] = destination
	units[id]["moved"] = spent
	cell_occupants[destination] = id
	if animate:
		_play_unit_animation(id, ["Running", "Run", "Walking_Woman", "Walking", "Walk"])
		var tween := create_tween()
		tween.tween_property(units[id]["node"], "position", _cell_to_world(destination), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(_resume_unit_idle.bind(id))
	else:
		units[id]["node"].position = _cell_to_world(destination)


func _movement_cost(id: String, cell: Vector2i) -> int:
	if terrain.get(cell, TERRAIN_GRASS) == TERRAIN_WATER and not units[id]["statuses"].has("riverstep"):
		return 3
	return 1


func _is_walkable(cell: Vector2i, mover_id := "") -> bool:
	if cell.x < 0 or cell.x >= MAP_WIDTH or cell.y < 0 or cell.y >= MAP_HEIGHT:
		return false
	if obstacles.has(cell) or printer_cells.has(cell):
		return false
	if cell_occupants.has(cell) and str(cell_occupants[cell]) != mover_id:
		return false
	return true


func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [cell + Vector2i.LEFT, cell + Vector2i.RIGHT, cell + Vector2i.UP, cell + Vector2i.DOWN]


func _valid_attack_cells(id: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var source: Vector2i = units[id]["cell"]
	var faction := str(units[id]["faction"])
	var attack_range := maxi(1, int(_unit_data(id)["range"]))
	for other_id in units.keys():
		if str(units[other_id]["faction"]) == faction:
			continue
		var target: Vector2i = units[other_id]["cell"]
		if _grid_distance(source, target) <= attack_range and _has_line_of_sight(source, target):
			cells.append(target)
	var enemy_faction := CombatDataScript.enemy_faction(faction)
	for cell in printers[enemy_faction]["cells"]:
		if _grid_distance(source, cell) <= attack_range and _has_line_of_sight(source, cell) and not cells.has(cell):
			cells.append(cell)
	return cells


func _ally_cells_in_range(id: String, radius: int, include_self: bool) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for ally_id in units.keys():
		if str(units[ally_id]["faction"]) != str(units[id]["faction"]):
			continue
		if not include_self and ally_id == id:
			continue
		if _grid_distance(units[id]["cell"], units[ally_id]["cell"]) <= maxi(1, radius):
			result.append(units[ally_id]["cell"])
	return result


func _allies_in_range(id: String, radius: int, include_self: bool) -> Array[String]:
	var result: Array[String] = []
	for ally_id in units.keys():
		if str(units[ally_id]["faction"]) == str(units[id]["faction"]) and (include_self or ally_id != id) and _grid_distance(units[id]["cell"], units[ally_id]["cell"]) <= radius:
			result.append(ally_id)
	return result


func _enemies_in_range(id: String, radius: int) -> Array[String]:
	var result: Array[String] = []
	for enemy_id in units.keys():
		if str(units[enemy_id]["faction"]) != str(units[id]["faction"]) and _grid_distance(units[id]["cell"], units[enemy_id]["cell"]) <= radius:
			result.append(enemy_id)
	return result


func _grid_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


func _has_line_of_sight(source: Vector2i, target: Vector2i) -> bool:
	var delta := target - source
	var steps := maxi(absi(delta.x), absi(delta.y))
	if steps <= 1:
		return true
	for index in range(1, steps):
		var sample := Vector2(float(source.x) + float(delta.x) * float(index) / float(steps), float(source.y) + float(delta.y) * float(index) / float(steps))
		var cell := Vector2i(roundi(sample.x), roundi(sample.y))
		if obstacles.has(cell):
			return false
	return true


func _run_ai_activation(id: String) -> void:
	if not smoke_mode:
		await get_tree().create_timer(0.22).timeout
	if not units.has(id) or battle_over:
		_end_activation()
		return
	if _try_ai_ability(id):
		return
	var attack_cells := _valid_attack_cells(id)
	if not attack_cells.is_empty():
		_resolve_ai_attack(id, attack_cells[0])
		return
	var reachable := _reachable_cells(id)
	var destination: Vector2i = units[id]["cell"]
	var best_distance := 99999
	for cell in reachable.keys():
		var distance := _distance_to_nearest_enemy_or_printer(id, cell)
		if distance < best_distance:
			best_distance = distance
			destination = cell
	if destination != units[id]["cell"]:
		_move_unit(id, destination, not smoke_mode)
		if not smoke_mode:
			await get_tree().create_timer(0.32).timeout
	attack_cells = _valid_attack_cells(id)
	if not attack_cells.is_empty():
		_resolve_ai_attack(id, attack_cells[0])
	else:
		_end_activation()


func _try_ai_ability(id: String) -> bool:
	if int(units[id]["cooldown"]) > 0:
		return false
	var ability_id := str(_unit_data(id)["ability_id"])
	if ability_id in ["stitch", "renew"]:
		var hurt_id := ""
		var largest_gap := 0
		for ally_id in _allies_in_range(id, maxi(1, int(_unit_data(id)["range"])), true):
			var gap := int(units[ally_id]["max_hp"]) - int(units[ally_id]["hp"])
			if gap > largest_gap:
				largest_gap = gap
				hurt_id = ally_id
		if hurt_id != "":
			active_unit_id = id
			_resolve_targeted_ability(units[hurt_id]["cell"])
			return true
	elif ability_id in ["brace", "bloodlust", "hold_line", "forest_shield"]:
		if round_number % 2 == 1:
			_begin_ability(id)
			return true
	else:
		var valid := _valid_attack_cells(id)
		if not valid.is_empty():
			active_unit_id = id
			_resolve_targeted_ability(valid[0])
			return true
	return false


func _resolve_ai_attack(id: String, cell: Vector2i) -> void:
	active_unit_id = id
	_resolve_basic_attack(cell)


func _distance_to_nearest_enemy_or_printer(id: String, from_cell: Vector2i) -> int:
	var result := 99999
	var faction := str(units[id]["faction"])
	for enemy_id in units.keys():
		if str(units[enemy_id]["faction"]) != faction:
			result = mini(result, _grid_distance(from_cell, units[enemy_id]["cell"]))
	var enemy_faction := CombatDataScript.enemy_faction(faction)
	for cell in printers[enemy_faction]["cells"]:
		result = mini(result, _grid_distance(from_cell, cell))
	return result


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event)
	elif event is InputEventMouseButton:
		# Android also emits an emulated left click for touch input. Board taps are
		# resolved from ScreenTouch so a camera drag cannot move or attack by accident.
		if OS.has_feature("mobile") and event.button_index == MOUSE_BUTTON_LEFT:
			return
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			camera_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			camera_rotation_dragging = event.pressed
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_camera_distance(camera_distance - 2.0)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_camera_distance(camera_distance + 2.0)
		elif event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var cell := _screen_to_cell(event.position)
			if cell.x >= 0:
				_on_cell_clicked(cell)
	elif event is InputEventMouseMotion and camera_dragging:
		_pan_camera(event.relative, CAMERA_MOUSE_PAN_SPEED)
	elif event is InputEventMouseMotion and camera_rotation_dragging:
		_orbit_camera(event.relative)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			camera_yaw_degrees -= 45.0
			_update_camera_transform()
		elif event.keycode == KEY_E:
			camera_yaw_degrees += 45.0
			_update_camera_transform()
		elif event.keycode == KEY_HOME:
			_reset_camera_view()
		elif event.keycode == KEY_ESCAPE and _player_can_act():
			input_mode = "move"
			reachable_cache = _reachable_cells(active_unit_id)
			_clear_overlays()
			_show_cells(reachable_cache.keys(), Color("#4cb7ff66"), 0.045)
			_update_ui()


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		active_touches[event.index] = event.position
		touch_start_positions[event.index] = event.position
		touch_dragged[event.index] = false
		if active_touches.size() >= 2:
			pinch_active = true
			pinch_distance = _current_pinch_distance()
			two_finger_angle = _current_two_finger_angle()
			two_finger_centroid = _current_touch_centroid()
			for touch_index in touch_dragged.keys():
				touch_dragged[touch_index] = true
		return
	var was_gesture := pinch_active or bool(touch_dragged.get(event.index, false)) or active_touches.size() > 1
	active_touches.erase(event.index)
	touch_start_positions.erase(event.index)
	touch_dragged.erase(event.index)
	if active_touches.size() < 2:
		pinch_distance = -1.0
		two_finger_angle = 0.0
		two_finger_centroid = Vector2.ZERO
	if active_touches.is_empty():
		pinch_active = false
	if not was_gesture:
		var cell := _screen_to_cell(event.position)
		if cell.x >= 0:
			_on_cell_clicked(cell)


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	active_touches[event.index] = event.position
	var start_position: Vector2 = touch_start_positions.get(event.index, event.position)
	if start_position.distance_to(event.position) >= TOUCH_DRAG_THRESHOLD:
		touch_dragged[event.index] = true
	if active_touches.size() >= 2:
		pinch_active = true
		for touch_index in touch_dragged.keys():
			touch_dragged[touch_index] = true
		var next_distance := _current_pinch_distance()
		var next_angle := _current_two_finger_angle()
		var next_centroid := _current_touch_centroid()
		if pinch_distance > 0.0 and next_distance > 0.0:
			_set_camera_distance(camera_distance - (next_distance - pinch_distance) * 0.15)
		var angle_delta := wrapf(next_angle - two_finger_angle, -PI, PI)
		camera_yaw_degrees -= rad_to_deg(angle_delta)
		camera_pitch_degrees = clampf(
			camera_pitch_degrees - (next_centroid.y - two_finger_centroid.y) * CAMERA_ORBIT_SPEED,
			MIN_CAMERA_PITCH_DEGREES,
			MAX_CAMERA_PITCH_DEGREES
		)
		pinch_distance = next_distance
		two_finger_angle = next_angle
		two_finger_centroid = next_centroid
		_update_camera_transform()
		return
	if not pinch_active and bool(touch_dragged.get(event.index, false)):
		_pan_camera(event.relative, CAMERA_TOUCH_PAN_SPEED)


func _pan_camera(screen_delta: Vector2, speed: float) -> void:
	var right := camera.global_transform.basis.x
	var forward := -camera.global_transform.basis.z
	right.y = 0.0
	forward.y = 0.0
	if right.length_squared() < 0.0001 or forward.length_squared() < 0.0001:
		return
	var zoom_scale := clampf(camera_distance / DEFAULT_CAMERA_DISTANCE, 0.35, 1.35)
	camera_focus += (-right.normalized() * screen_delta.x - forward.normalized() * screen_delta.y) * speed * zoom_scale
	var x_limit := float(MAP_WIDTH - 1) * CELL_SIZE * 0.55
	var z_limit := float(MAP_HEIGHT - 1) * CELL_SIZE * 0.55
	camera_focus.x = clampf(camera_focus.x, -x_limit, x_limit)
	camera_focus.z = clampf(camera_focus.z, -z_limit, z_limit)
	_update_camera_transform()


func _orbit_camera(screen_delta: Vector2) -> void:
	camera_yaw_degrees -= screen_delta.x * CAMERA_ORBIT_SPEED
	camera_pitch_degrees = clampf(
		camera_pitch_degrees - screen_delta.y * CAMERA_ORBIT_SPEED,
		MIN_CAMERA_PITCH_DEGREES,
		MAX_CAMERA_PITCH_DEGREES
	)
	_update_camera_transform()


func _reset_camera_view() -> void:
	camera_focus = CAMERA_FOCUS
	camera_distance = DEFAULT_CAMERA_DISTANCE
	camera_yaw_degrees = 0.0
	camera_pitch_degrees = DEFAULT_CAMERA_PITCH_DEGREES
	_update_camera_transform()


func _update_camera_transform() -> void:
	if camera == null or camera_rig == null:
		return
	camera_rig.position = camera_focus
	camera_rig.rotation_degrees.y = camera_yaw_degrees
	var orbit_length := CAMERA_DEFAULT_OFFSET.length() * camera_distance / DEFAULT_CAMERA_DISTANCE
	var pitch_radians := deg_to_rad(camera_pitch_degrees)
	camera.position = Vector3(0.0, sin(pitch_radians) * orbit_length, cos(pitch_radians) * orbit_length)
	camera.look_at(camera_focus, Vector3.UP)


func _set_camera_distance(value: float) -> void:
	camera_distance = clampf(value, MIN_CAMERA_DISTANCE, MAX_CAMERA_DISTANCE)
	_update_camera_transform()


func _current_pinch_distance() -> float:
	if active_touches.size() < 2:
		return -1.0
	var positions: Array = active_touches.values()
	return (positions[0] as Vector2).distance_to(positions[1] as Vector2)


func _current_two_finger_angle() -> float:
	if active_touches.size() < 2:
		return 0.0
	var positions: Array = active_touches.values()
	var first: Vector2 = positions[0]
	var second: Vector2 = positions[1]
	return (second - first).angle()


func _current_touch_centroid() -> Vector2:
	if active_touches.is_empty():
		return Vector2.ZERO
	var result := Vector2.ZERO
	for position in active_touches.values():
		result += position as Vector2
	return result / float(active_touches.size())


func _screen_to_cell(screen_position: Vector2) -> Vector2i:
	var origin := camera.project_ray_origin(screen_position)
	var direction := camera.project_ray_normal(screen_position)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if hit == null:
		return Vector2i(-1, -1)
	var local_hit: Vector3 = world_root.to_local(hit)
	var x := roundi(local_hit.x / CELL_SIZE + 12.0)
	var y := roundi(local_hit.z / CELL_SIZE + 16.0)
	if x < 0 or x >= MAP_WIDTH or y < 0 or y >= MAP_HEIGHT:
		return Vector2i(-1, -1)
	return Vector2i(x, y)


func _on_cell_clicked(cell: Vector2i) -> void:
	if battle_over:
		return
	if input_mode == "attack" and target_cache.has(cell):
		_resolve_basic_attack(cell)
		return
	if input_mode == "ability" and target_cache.has(cell):
		_resolve_targeted_ability(cell)
		return
	if _player_can_act() and input_mode == "move" and reachable_cache.has(cell):
		_move_unit(active_unit_id, cell, true)
		input_mode = "inspect"
		_clear_overlays()
		_update_ui()
		return
	if cell_occupants.has(cell):
		selected_unit_id = cell_occupants[cell]
		_show_unit_in_inspector(selected_unit_id)


func _show_cells(cells: Array, color: Color, height: float) -> void:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	for cell in cells:
		var marker := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(CELL_SIZE * 0.84, 0.035, CELL_SIZE * 0.84)
		marker.mesh = mesh
		marker.position = _cell_to_world(cell) + Vector3.UP * height
		marker.material_override = material
		overlay_root.add_child(marker)


func _clear_overlays() -> void:
	for child in overlay_root.get_children():
		child.queue_free()
	target_cache.clear()


func _update_ui() -> void:
	if top_status == null:
		return
	round_label.text = "ROUND %d" % round_number
	printer_label.text = "FORGES  G%d • E%d" % [int(printers[CombatDataScript.FACTION_GOBLINS]["hp"]), int(printers[CombatDataScript.FACTION_ELVES]["hp"])]
	if faction_state.has(player_faction):
		filament_label.text = "FILAMENT %d/%d" % [int(faction_state[player_faction]["filament"]), MAX_FILAMENT]
	else:
		filament_label.text = "FILAMENT --"
	if phase == "spawn":
		active_label.text = "DEPLOY ONE UNIT OR SKIP"
	elif active_unit_id != "" and units.has(active_unit_id):
		active_label.text = "ACTIVE: %s" % str(_unit_data(active_unit_id)["name"]).to_upper()
	else:
		active_label.text = "RESOLVING INITIATIVE"
	var can_act := _player_can_act()
	attack_button.visible = phase == "initiative"
	ability_button.visible = phase == "initiative"
	wait_button.visible = phase == "initiative"
	skip_spawn_button.visible = phase == "spawn"
	attack_button.disabled = not can_act
	ability_button.disabled = not can_act or (can_act and int(units[active_unit_id]["cooldown"]) > 0)
	wait_button.disabled = not can_act
	if can_act:
		ability_button.text = "%s%s" % [_unit_data(active_unit_id)["ability"], " (CD %d)" % int(units[active_unit_id]["cooldown"]) if int(units[active_unit_id]["cooldown"]) > 0 else ""]
	else:
		ability_button.text = "ABILITY"


func _show_unit_in_inspector(id: String) -> void:
	if not units.has(id):
		return
	var unit: Dictionary = units[id]
	var data: Dictionary = _unit_data(id)
	inspector_title.text = "%s\n%s • %s" % [data["name"], data["rarity"], " / ".join(data["roles"])]
	if not smoke_mode and ResourceLoader.exists(data["concept"]):
		inspector_portrait.texture = load(data["concept"])
	var status_lines: Array[String] = []
	for status_name in unit["statuses"].keys():
		status_lines.append(str(status_name).replace("_", " ").capitalize())
	var status_text := "None" if status_lines.is_empty() else ", ".join(status_lines)
	inspector_body.text = "HP  %d / %d\nDEF  %d    OFF  %d\nRANGE  %d    MOVE  %d\nINITIATIVE  %d    COST  %d\n\n%s\n%s\nCooldown: %d\nStatuses: %s" % [
		int(unit["hp"]), _effective_max_hp(id), _effective_stat(id, "defense"), _effective_stat(id, "offense"), int(data["range"]), _effective_stat(id, "movement"), int(data["initiative"]), int(data["cost"]), data["ability"], data["ability_text"], int(unit["cooldown"]), status_text,
	]


func _set_notice(message: String) -> void:
	top_status.text = message
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func() -> void: top_status.text = "PRINTFORGE // COMBAT PROOF")


func _check_victory() -> bool:
	if battle_over:
		return true
	var loser := ""
	for faction in CombatDataScript.ROSTERS.keys():
		if int(printers[faction]["hp"]) <= 0:
			loser = faction
			break
		var living_units := 0
		for id in units.keys():
			if str(units[id]["faction"]) == faction and int(units[id]["hp"]) > 0:
				living_units += 1
		if living_units == 0 and faction_state.has(faction) and faction_state[faction]["reserve"].is_empty():
			loser = faction
			break
	if loser == "":
		return false
	battle_over = true
	phase = "complete"
	var victor := CombatDataScript.enemy_faction(loser)
	winner_label.text = "%s wins.\n%s was destroyed or exhausted." % [CombatDataScript.FACTIONS[victor]["name"], CombatDataScript.FACTIONS[loser]["name"]]
	winner_overlay.visible = not smoke_mode
	_update_ui()
	return true


func _setup_capture_armies() -> void:
	for faction in faction_state.keys():
		faction_state[faction]["filament"] = 99
	var goblin_cells := [Vector2i(7, 12), Vector2i(9, 13), Vector2i(10, 14), Vector2i(8, 17), Vector2i(10, 18)]
	var elf_cells := [Vector2i(17, 20), Vector2i(15, 19), Vector2i(14, 18), Vector2i(16, 15), Vector2i(14, 14)]
	for index in range(CombatDataScript.ROSTERS[CombatDataScript.FACTION_GOBLINS].size()):
		_spawn_unit(CombatDataScript.FACTION_GOBLINS, CombatDataScript.ROSTERS[CombatDataScript.FACTION_GOBLINS][index], goblin_cells[index], false)
	for index in range(CombatDataScript.ROSTERS[CombatDataScript.FACTION_ELVES].size()):
		_spawn_unit(CombatDataScript.FACTION_ELVES, CombatDataScript.ROSTERS[CombatDataScript.FACTION_ELVES][index], elf_cells[index], false)
	faction_state[CombatDataScript.FACTION_GOBLINS]["filament"] = 6
	faction_state[CombatDataScript.FACTION_ELVES]["filament"] = 6
	phase = "initiative"
	selected_unit_id = cell_occupants[Vector2i(14, 18)]
	active_unit_id = selected_unit_id
	_show_unit_in_inspector(selected_unit_id)
	_build_roster_cards()
	_update_ui()


func _capture_validation_frame() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if capture_path == "":
		capture_path = "user://combat-validation.png"
	var image := get_viewport().get_texture().get_image()
	if image == null:
		push_error("Combat capture requires a rendering display; headless dummy rendering has no viewport texture.")
		get_tree().quit(2)
		return
	var result := image.save_png(capture_path)
	print("COMBAT_CAPTURE=%s RESULT=%s" % [capture_path, result])
	get_tree().quit(0 if result == OK else 2)


func _run_smoke_test() -> void:
	assert(terrain.size() == MAP_WIDTH * MAP_HEIGHT, "Combat map cell count mismatch")
	assert(terrain_asset_meshes.size() == 9, "Runtime terrain library must expose all nine recovered assets")
	assert(int(terrain_instance_counts.get("RoadTile", 0)) == 31, "Road runtime mesh coverage mismatch")
	assert(int(terrain_instance_counts.get("StreamTile", 0)) == 22, "Stream runtime mesh coverage mismatch")
	assert(int(terrain_instance_counts.get("BridgeTile", 0)) == 1, "Bridge runtime mesh coverage mismatch")
	assert(prop_root.find_children("*", "StaticBody3D", true, false).size() == obstacles.size(), "Terrain collision coverage mismatch")
	assert(TREE_CELLS.size() + BOULDER_CELLS.size() == obstacles.size(), "Obstacle registry mismatch")
	assert(terrain[Vector2i(4, 15)] == TERRAIN_WATER and terrain[Vector2i(4, 16)] == TERRAIN_WATER, "River must be two cells wide")
	assert(terrain[Vector2i(12, 15)] == TERRAIN_BRIDGE and terrain[Vector2i(12, 16)] == TERRAIN_BRIDGE, "Bridge must span the river")
	assert(CombatDataScript.total_roster_cost(CombatDataScript.FACTION_GOBLINS) == 19, "Goblin roster economy drifted")
	assert(CombatDataScript.total_roster_cost(CombatDataScript.FACTION_ELVES) == 19, "Elf roster economy drifted")
	var targeting_probe: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	_start_target_selection(targeting_probe, "attack", Color("#ff4c4c88"))
	assert(target_cache == targeting_probe, "Target selection was erased while clearing old overlays")
	_clear_overlays()
	var focus_before := camera_focus
	active_touches[0] = Vector2(100.0, 100.0)
	touch_start_positions[0] = Vector2(100.0, 100.0)
	touch_dragged[0] = false
	var pan_probe := InputEventScreenDrag.new()
	pan_probe.index = 0
	pan_probe.position = Vector2(140.0, 100.0)
	pan_probe.relative = Vector2(40.0, 0.0)
	_handle_screen_drag(pan_probe)
	assert(not camera_focus.is_equal_approx(focus_before), "One-finger drag did not pan the combat camera")
	active_touches.clear()
	touch_start_positions.clear()
	touch_dragged.clear()
	pinch_active = false
	pinch_distance = -1.0
	var yaw_before := camera_yaw_degrees
	var pitch_before := camera_pitch_degrees
	active_touches[0] = Vector2(100.0, 100.0)
	active_touches[1] = Vector2(200.0, 100.0)
	touch_start_positions[0] = active_touches[0]
	touch_start_positions[1] = active_touches[1]
	touch_dragged[0] = true
	touch_dragged[1] = true
	pinch_distance = _current_pinch_distance()
	two_finger_angle = _current_two_finger_angle()
	two_finger_centroid = _current_touch_centroid()
	var orbit_probe := InputEventScreenDrag.new()
	orbit_probe.index = 0
	orbit_probe.position = Vector2(100.0, 60.0)
	orbit_probe.relative = Vector2(0.0, -40.0)
	_handle_screen_drag(orbit_probe)
	assert(not is_equal_approx(yaw_before, camera_yaw_degrees), "Two-finger twist did not rotate the combat camera")
	assert(not is_equal_approx(pitch_before, camera_pitch_degrees), "Two-finger vertical slide did not tilt the combat camera")
	active_touches.clear()
	touch_start_positions.clear()
	touch_dragged.clear()
	pinch_active = false
	var zoom_before := camera_distance
	active_touches[0] = Vector2(100.0, 100.0)
	active_touches[1] = Vector2(200.0, 100.0)
	pinch_distance = _current_pinch_distance()
	two_finger_angle = _current_two_finger_angle()
	two_finger_centroid = _current_touch_centroid()
	var zoom_probe := InputEventScreenDrag.new()
	zoom_probe.index = 1
	zoom_probe.position = Vector2(240.0, 100.0)
	zoom_probe.relative = Vector2(40.0, 0.0)
	_handle_screen_drag(zoom_probe)
	assert(camera_distance < zoom_before, "Two-finger pinch-out did not zoom the combat camera in")
	_set_camera_distance(MIN_CAMERA_DISTANCE)
	assert(camera.position.y < 10.0, "Minimum phone zoom did not bring the camera close to the battlefield")
	_set_camera_distance(zoom_before)
	_reset_camera_view()
	assert(camera_focus.is_equal_approx(CAMERA_FOCUS), "Reset view did not restore the tactical focus")
	assert(is_equal_approx(camera_yaw_degrees, 0.0), "Reset view did not restore camera rotation")
	active_touches.clear()
	touch_start_positions.clear()
	touch_dragged.clear()
	pinch_active = false
	pinch_distance = -1.0
	var deadline := Time.get_ticks_msec() + 18000
	while action_counter < 12 and not battle_over and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert(action_counter >= 8 or battle_over, "Initiative loop did not advance")
	if not battle_over:
		faction_state[player_faction]["reserve"].clear()
		for id in units.keys().duplicate():
			if str(units[id]["faction"]) == player_faction:
				_remove_unit(id)
		assert(_check_victory(), "An exhausted faction with no living units must lose immediately")
		assert(battle_over and phase == "complete", "Unit elimination did not complete the battle")
		assert(winner_label.text.begins_with(CombatDataScript.FACTIONS[ai_faction]["name"]), "The surviving faction was not declared the winner")
	print("COMBAT_SMOKE_OK round=%d activations=%d units=%d" % [round_number, action_counter, units.size()])
	get_tree().quit(0)
