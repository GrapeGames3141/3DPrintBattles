extends Node3D

const CombatDataScript := preload("res://scripts/combat_data.gd")
const CombatAIScript := preload("res://scripts/combat_ai.gd")
const CombatCameraScript := preload("res://scripts/combat_camera.gd")
const CombatCommandsScript := preload("res://scripts/combat_commands.gd")
const CombatGridScript := preload("res://scripts/combat_grid.gd")
const CombatHudScript := preload("res://scripts/combat_hud.gd")
const CombatNetworkScript := preload("res://scripts/combat_network.gd")
const CombatRulesScript := preload("res://scripts/combat_rules.gd")
const CombatStateScript := preload("res://scripts/combat_state.gd")
const CombatUnitViewScript := preload("res://scripts/combat_unit_view.gd")
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
var unit_nodes := {}
var printer_nodes := {}

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
var session_mode := "solo"
var remote_peer_id := 0
var command_sequence := 0
var last_remote_sequence := 0
var next_unit_serial := 1

var camera_rig: Node3D
var camera: Camera3D
var camera_controller
var grid_navigation
var combat_rules
var combat_ai
var combat_state
var command_validator
var network_session
var unit_view
var hud_builder
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
var session_overlay: Control
var session_status: Label
var address_input: LineEdit
var winner_overlay: Control
var winner_label: Label

var tile_meshes := {}
var tile_materials := {}
var terrain_asset_meshes := {}
var terrain_instance_counts := {}


func _ready() -> void:
	CombatDataScript.validate()
	combat_ai = CombatAIScript.new()
	combat_state = CombatStateScript.new()
	command_validator = CombatCommandsScript.new()
	network_session = CombatNetworkScript.new()
	network_session.name = "CombatNetwork"
	add_child(network_session)
	network_session.peer_joined.connect(_on_network_peer_joined)
	network_session.peer_left.connect(_on_network_peer_left)
	network_session.connected_to_server.connect(_on_network_connected)
	network_session.connection_failed.connect(_on_network_failed)
	network_session.command_received.connect(_on_network_command_received)
	network_session.snapshot_received.connect(_on_network_snapshot_received)
	network_session.command_rejected.connect(_on_network_command_rejected)
	unit_view = CombatUnitViewScript.new()
	hud_builder = CombatHudScript.new()
	combat_rules = CombatRulesScript.new()
	combat_rules.configure(units, CombatDataScript.UNITS)
	grid_navigation = CombatGridScript.new()
	grid_navigation.configure(MAP_WIDTH, MAP_HEIGHT, CELL_SIZE, terrain, obstacles, printer_cells, units, cell_occupants, TERRAIN_WATER)
	rng.seed = 1337
	_parse_command_line()
	_build_world()
	_build_ui()
	if smoke_mode or capture_mode:
		call_deferred("_begin_match", PLAYER_DEFAULT_FACTION)
	else:
		_show_launch_screen()


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
	camera_controller = CombatCameraScript.new()
	camera_controller.configure(
		camera_rig,
		camera,
		world_root,
		MAP_WIDTH,
		MAP_HEIGHT,
		CELL_SIZE,
		CAMERA_FOCUS,
		DEFAULT_CAMERA_DISTANCE,
		MIN_CAMERA_DISTANCE,
		MAX_CAMERA_DISTANCE,
		CAMERA_DEFAULT_OFFSET,
		DEFAULT_CAMERA_PITCH_DEGREES
	)


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

	printers[faction] = combat_state.create_printer_entry(PRINTER_HP, PRINTER_DEFENSE, cells)
	printer_nodes[faction] = root
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
	return grid_navigation.cell_to_world(cell)


func _cells_center(cells: Array) -> Vector3:
	return grid_navigation.cells_center(cells)


func _build_ui() -> void:
	var refs: Dictionary = hud_builder.build(self, {
		"reset_view": _reset_camera_view,
		"attack": _on_attack_pressed,
		"ability": _on_ability_pressed,
		"wait": _on_wait_pressed,
		"skip_spawn": _on_skip_spawn_pressed,
		"solo": _choose_solo_mode,
		"host": _host_network_match,
		"join": _join_network_match,
		"choose_faction": _begin_match,
		"reload": _reload_scene,
	})
	top_status = refs["top_status"] as Label
	round_label = refs["round_label"] as Label
	printer_label = refs["printer_label"] as Label
	filament_label = refs["filament_label"] as Label
	active_label = refs["active_label"] as Label
	roster_panel = refs["roster_panel"] as VBoxContainer
	inspector_title = refs["inspector_title"] as Label
	inspector_portrait = refs["inspector_portrait"] as TextureRect
	inspector_body = refs["inspector_body"] as Label
	action_panel = refs["action_panel"] as HBoxContainer
	attack_button = refs["attack_button"] as Button
	ability_button = refs["ability_button"] as Button
	wait_button = refs["wait_button"] as Button
	skip_spawn_button = refs["skip_spawn_button"] as Button
	session_overlay = refs["session_overlay"] as Control
	session_status = refs["session_status"] as Label
	address_input = refs["address_input"] as LineEdit
	faction_overlay = refs["faction_overlay"] as Control
	winner_overlay = refs["winner_overlay"] as Control
	winner_label = refs["winner_label"] as Label
	_update_ui()


func _label(text_value: String, size: int, color: Color) -> Label:
	return hud_builder.label(text_value, size, color)


func _action_button(text_value: String) -> Button:
	return hud_builder.action_button(text_value)


func _show_launch_screen() -> void:
	phase = "setup"
	session_overlay.visible = true
	faction_overlay.visible = false
	session_status.text = ""


func _choose_solo_mode() -> void:
	session_mode = "solo"
	network_session.close()
	session_overlay.visible = false
	_show_faction_choice()


func _show_faction_choice() -> void:
	phase = "setup"
	faction_overlay.visible = true


func _host_network_match() -> void:
	session_mode = "host"
	var result: Error = network_session.host(CombatNetworkScript.DEFAULT_PORT)
	if result == OK:
		var addresses := _local_ipv4_addresses()
		var address_hint := "Local IP: %s" % ", ".join(addresses) if not addresses.is_empty() else "Use this computer's IPv4 address"
		session_status.text = "Hosting on UDP %d. %s. Waiting for one opponent..." % [CombatNetworkScript.DEFAULT_PORT, address_hint]
		top_status.text = "ENET HOST // WAITING FOR OPPONENT"


func _join_network_match(address_text: String) -> void:
	var endpoint := _parse_endpoint(address_text)
	if endpoint["address"] == "":
		session_status.text = "Enter a host IP address or hostname."
		return
	session_mode = "client"
	var result: Error = network_session.join(endpoint["address"], endpoint["port"])
	if result == OK:
		session_status.text = "Connecting to %s:%d..." % [endpoint["address"], endpoint["port"]]
		top_status.text = "ENET CLIENT // CONNECTING"


func _parse_endpoint(value: String) -> Dictionary:
	var cleaned := value.strip_edges()
	var port := CombatNetworkScript.DEFAULT_PORT
	var address := cleaned
	if cleaned.count(":") == 1:
		var parts := cleaned.split(":", false, 1)
		address = parts[0].strip_edges()
		if parts.size() > 1 and parts[1].is_valid_int():
			port = clampi(int(parts[1]), 1, 65535)
	return {"address": address, "port": port}


func _local_ipv4_addresses() -> Array[String]:
	var result: Array[String] = []
	for address in IP.get_local_addresses():
		if address.contains(":") or address.begins_with("127.") or address == "0.0.0.0":
			continue
		result.append(address)
	return result


func _reload_scene() -> void:
	get_tree().reload_current_scene()


func _begin_match(chosen_faction: String) -> void:
	player_faction = chosen_faction
	ai_faction = CombatDataScript.enemy_faction(player_faction)
	faction_overlay.visible = false
	session_overlay.visible = false
	first_faction = CombatDataScript.FACTION_ELVES if rng.randi_range(0, 1) == 0 else CombatDataScript.FACTION_GOBLINS
	next_unit_serial = 1
	command_sequence = 0
	last_remote_sequence = 0
	faction_state.clear()
	faction_state.assign(combat_state.create_faction_state(CombatDataScript.ROSTERS, STARTING_FILAMENT))
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
	elif session_mode == "host":
		if not _has_affordable_reserve(player_faction):
			_complete_spawn(player_faction)
		_broadcast_snapshot({"type": "phase", "phase": "spawn"})
	elif session_mode == "client":
		pass
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
	_submit_player_command(CombatCommandsScript.SPAWN, Vector2i(-1, -1), unit_key)


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
	var id := "%s_%s_%02d" % [faction, unit_key, next_unit_serial]
	next_unit_serial += 1
	var node := _build_unit_figure(id, data, faction)
	node.position = _cell_to_world(cell)
	unit_root.add_child(node)
	var entry: Dictionary = combat_state.create_unit_entry(id, unit_key, faction, cell, int(data["hp"]))
	units[id] = entry
	unit_nodes[id] = node
	cell_occupants[cell] = id
	faction_state[faction]["filament"] = int(faction_state[faction]["filament"]) - int(data["cost"])
	var reserve: Array = faction_state[faction]["reserve"]
	reserve.erase(unit_key)
	if animate:
		_play_print_animation(node, CombatDataScript.FACTIONS[faction]["color"])
	return id


func _build_unit_figure(id: String, data: Dictionary, faction: String) -> Node3D:
	return unit_view.build_unit_figure(id, data, faction, not smoke_mode)

func _play_unit_animation(id: String, preferred: Array[String]) -> void:
	if not unit_nodes.has(id):
		return
	unit_view.play_animation(unit_nodes[id] as Node, preferred)


func _resume_unit_idle(id: String) -> void:
	if not unit_nodes.has(id):
		return
	unit_view.resume_idle(unit_nodes[id] as Node)
func _play_print_animation(node: Node3D, color: Color) -> void:
	unit_view.play_print_animation(node, color)


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
	if session_mode == "host" and str(unit["faction"]) != player_faction:
		input_mode = "busy"
		_update_ui()
		_broadcast_snapshot({"type": "activation", "actor_id": id})
	elif autoplay_both or (session_mode == "solo" and str(unit["faction"]) == ai_faction):
		input_mode = "busy"
		_update_ui()
		call_deferred("_run_ai_activation", id)
	else:
		input_mode = "move"
		reachable_cache = _reachable_cells(id)
		_show_cells(reachable_cache.keys(), Color("#4cb7ff66"), 0.045)
		_update_ui()
		_broadcast_snapshot({"type": "activation", "actor_id": id})


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
	_broadcast_snapshot({"type": "activation_complete"})
	call_deferred("_next_activation")


func _end_round() -> void:
	if _check_victory():
		return
	round_number += 1
	first_faction = CombatDataScript.enemy_faction(first_faction)
	combat_state.refill_filament(faction_state, MAX_FILAMENT, FILAMENT_PER_ROUND)
	_start_spawn_phase()


func _on_skip_spawn_pressed() -> void:
	if phase == "spawn" and faction_state.has(player_faction):
		_submit_player_command(CombatCommandsScript.SKIP_SPAWN)


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
	var ability_id := str(_unit_data(active_unit_id)["ability_id"])
	var cells := _ability_target_cells(active_unit_id)
	if ability_id in ["brace", "bloodlust", "hold_line", "forest_shield"]:
		_submit_player_command(CombatCommandsScript.ABILITY)
	else:
		_start_targeted_ability(cells, Color("#55f0a488") if ability_id in ["stitch", "renew"] else Color("#c96dff88"))


func _on_wait_pressed() -> void:
	if _player_can_act():
		_submit_player_command(CombatCommandsScript.WAIT)


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


func _ability_target_cells(id: String) -> Array[Vector2i]:
	var ability_id := str(_unit_data(id)["ability_id"])
	if ability_id in ["stitch", "renew"]:
		return _ally_cells_in_range(id, int(_unit_data(id)["range"]), true)
	if ability_id in ["brace", "bloodlust", "hold_line", "forest_shield"]:
		return []
	return _valid_attack_cells(id)


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
	var result: Dictionary = combat_rules.damage(attacker_id, target_id, ignore_defense)
	var amount := int(result["amount"])
	if amount <= 0:
		return 0
	if unit_nodes.has(target_id):
		_flash_figure(unit_nodes[target_id], Color("#ff4a4a"))
	if bool(result["killed"]):
		_remove_unit(target_id)
	_check_victory()
	return amount


func _deal_printer_damage(attacker_id: String, target_faction: String) -> int:
	if str(units[attacker_id]["faction"]) == target_faction:
		return 0
	var amount: int = combat_rules.printer_damage_amount(attacker_id, PRINTER_DEFENSE)
	printers[target_faction]["hp"] = int(printers[target_faction]["hp"]) - amount
	if printer_nodes.has(target_faction):
		_flash_figure(printer_nodes[target_faction], Color("#ff4a4a"))
	_check_victory()
	return amount


func _apply_raw_damage(target_id: String, amount: int) -> void:
	if not units.has(target_id):
		return
	var killed: bool = combat_rules.raw_damage(target_id, amount)
	if unit_nodes.has(target_id):
		_flash_figure(unit_nodes[target_id], Color("#ff4a4a"))
	if killed:
		_remove_unit(target_id)
	_check_victory()


func _heal_unit(id: String, amount: int) -> void:
	if combat_rules.heal(id, amount):
		if unit_nodes.has(id):
			_flash_figure(unit_nodes[id], Color("#55f0a4"))


func _apply_status(id: String, status_name: String, payload: Dictionary) -> void:
	combat_rules.apply_status(id, status_name, payload)


func _effective_stat(id: String, stat: String) -> int:
	return combat_rules.effective_stat(id, stat)


func _effective_max_hp(id: String) -> int:
	return combat_rules.effective_max_hp(id)


func _unit_data(id: String) -> Dictionary:
	return combat_rules.unit_data(id)


func _remove_unit(id: String) -> void:
	if not units.has(id):
		return
	cell_occupants.erase(units[id]["cell"])
	if unit_nodes.has(id):
		unit_nodes[id].queue_free()
		unit_nodes.erase(id)
	units.erase(id)
	initiative_queue.erase(id)
	if selected_unit_id == id:
		selected_unit_id = ""


func _flash_figure(node: Node3D, color: Color) -> void:
	unit_view.flash(node, color)


func _reachable_cells(id: String) -> Dictionary:
	return grid_navigation.reachable_cells(id, _effective_stat(id, "movement"))


func _find_path(id: String, destination: Vector2i) -> Array[Vector2i]:
	return grid_navigation.find_path(id, destination, _effective_stat(id, "movement"))


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
		tween.tween_property(unit_nodes[id], "position", _cell_to_world(destination), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(_resume_unit_idle.bind(id))
	else:
		unit_nodes[id].position = _cell_to_world(destination)


func _movement_cost(id: String, cell: Vector2i) -> int:
	return grid_navigation.movement_cost(id, cell)


func _is_walkable(cell: Vector2i, mover_id := "") -> bool:
	return grid_navigation.is_walkable(cell, mover_id)


func _neighbors(cell: Vector2i) -> Array[Vector2i]:
	return grid_navigation.neighbors(cell)


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
	return grid_navigation.grid_distance(a, b)


func _has_line_of_sight(source: Vector2i, target: Vector2i) -> bool:
	return grid_navigation.has_line_of_sight(source, target)


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
	var enemy := CombatDataScript.enemy_faction(str(units[id]["faction"]))
	var destination: Vector2i = combat_ai.best_destination(id, reachable, units, printers, enemy, grid_navigation)
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
		var allies := _allies_in_range(id, maxi(1, int(_unit_data(id)["range"])), true)
		var hurt_id: String = combat_ai.most_hurt_ally(units, allies)
		if hurt_id != "":
			active_unit_id = id
			_resolve_targeted_ability(units[hurt_id]["cell"])
			return true
	elif ability_id in ["brace", "bloodlust", "hold_line", "forest_shield"]:
		if combat_ai.should_use_round_support(ability_id, round_number):
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
	var faction := str(units[id]["faction"])
	var enemy_faction := CombatDataScript.enemy_faction(faction)
	return combat_ai.distance_to_nearest_target(id, from_cell, units, printers, enemy_faction, grid_navigation)


func _submit_player_command(command_type: String, cell := Vector2i(-1, -1), unit_key := "") -> void:
	command_sequence += 1
	var command: Dictionary = command_validator.make(command_type, command_sequence, active_unit_id, cell, unit_key)
	if session_mode == "client":
		network_session.send_command(command)
		input_mode = "busy"
		_clear_overlays()
		_update_ui()
	else:
		_execute_authoritative_command(player_faction, command)


func _execute_authoritative_command(sender_faction: String, command: Dictionary, peer_id := 0) -> bool:
	var command_type := str(command.get("type", ""))
	var valid_cells: Array = []
	var requires_cell := true
	if phase == "initiative" and active_unit_id != "" and units.has(active_unit_id):
		match command_type:
			CombatCommandsScript.MOVE:
				valid_cells = _reachable_cells(active_unit_id).keys()
			CombatCommandsScript.ATTACK:
				valid_cells = _valid_attack_cells(active_unit_id)
			CombatCommandsScript.ABILITY:
				valid_cells = _ability_target_cells(active_unit_id)
				var ability_id := str(_unit_data(active_unit_id)["ability_id"])
				requires_cell = ability_id not in ["brace", "bloodlust", "hold_line", "forest_shield"]
	var error_message: String = command_validator.validate(command, sender_faction, {
		"phase": phase,
		"units": units,
		"factions": faction_state,
		"definitions": CombatDataScript.UNITS,
		"active_unit_id": active_unit_id,
		"valid_cells": valid_cells,
		"requires_cell": requires_cell,
	})
	if error_message != "":
		if peer_id > 1:
			network_session.reject(peer_id, error_message)
		else:
			_set_notice(error_message)
		return false
	match command_type:
		CombatCommandsScript.SPAWN:
			var cell := _first_free_spawn_cell(sender_faction)
			if cell.x < 0:
				return false
			_spawn_unit(sender_faction, str(command["unit_key"]), cell, not smoke_mode)
			_complete_spawn(sender_faction)
		CombatCommandsScript.SKIP_SPAWN:
			_complete_spawn(sender_faction)
		CombatCommandsScript.MOVE:
			_move_unit(active_unit_id, command["cell"], not smoke_mode)
			input_mode = "inspect"
			_clear_overlays()
			_update_ui()
		CombatCommandsScript.ATTACK:
			_resolve_basic_attack(command["cell"])
		CombatCommandsScript.ABILITY:
			if command.has("cell"):
				_resolve_targeted_ability(command["cell"])
			else:
				_begin_ability(active_unit_id)
		CombatCommandsScript.WAIT:
			_end_activation()
	_broadcast_snapshot(command)
	return true


func _snapshot() -> Dictionary:
	return combat_state.build_snapshot(units, printers, faction_state, initiative_queue, {
		"round": round_number,
		"phase": phase,
		"first_faction": first_faction,
		"active_unit_id": active_unit_id,
		"battle_over": battle_over,
		"action_counter": action_counter,
		"next_unit_serial": next_unit_serial,
	})


func _broadcast_snapshot(event := {}) -> void:
	if session_mode == "host" and remote_peer_id > 1:
		network_session.send_snapshot(_snapshot(), event, remote_peer_id)


func _on_network_peer_joined(peer_id: int) -> void:
	if session_mode != "host" or remote_peer_id != 0:
		return
	remote_peer_id = peer_id
	session_status.text = "Opponent connected. Starting match..."
	top_status.text = "ENET HOST // OPPONENT CONNECTED"
	_begin_match(CombatDataScript.FACTION_ELVES)


func _on_network_peer_left(peer_id: int) -> void:
	if peer_id != remote_peer_id:
		return
	remote_peer_id = 0
	if phase == "setup":
		session_overlay.visible = true
		session_status.text = "Opponent disconnected. Still hosting on UDP port %d." % CombatNetworkScript.DEFAULT_PORT
	else:
		battle_over = true
		phase = "complete"
		winner_label.text = "Opponent disconnected.\nThe ENet match has ended."
		winner_overlay.visible = true
		_update_ui()


func _on_network_connected() -> void:
	session_status.text = "Connected. Waiting for the host's match state..."
	top_status.text = "ENET CLIENT // CONNECTED"


func _on_network_failed(message: String) -> void:
	if phase == "setup":
		session_overlay.visible = true
		session_status.text = message
	else:
		_set_notice(message)


func _on_network_command_received(peer_id: int, command: Dictionary) -> void:
	if session_mode != "host" or peer_id != remote_peer_id:
		return
	var sequence := int(command.get("sequence", 0))
	if sequence <= last_remote_sequence:
		network_session.reject(peer_id, "Duplicate or out-of-order command.")
		return
	last_remote_sequence = sequence
	_execute_authoritative_command(CombatDataScript.FACTION_GOBLINS, command, peer_id)


func _on_network_snapshot_received(snapshot: Dictionary, event: Dictionary) -> void:
	if session_mode != "client":
		return
	var previous_units := units.duplicate(true)
	var previous_printers := printers.duplicate(true)
	var flow: Dictionary = combat_state.apply_snapshot(snapshot, units, printers, faction_state, cell_occupants, initiative_queue)
	if flow.is_empty():
		_on_network_command_rejected("The host sent an incompatible match snapshot.")
		return
	round_number = int(flow["round"])
	phase = str(flow["phase"])
	first_faction = str(flow["first_faction"])
	active_unit_id = str(flow["active_unit_id"])
	battle_over = bool(flow["battle_over"])
	action_counter = int(flow["action_counter"])
	next_unit_serial = int(flow["next_unit_serial"])
	player_faction = CombatDataScript.FACTION_GOBLINS
	ai_faction = CombatDataScript.FACTION_ELVES
	session_overlay.visible = false
	faction_overlay.visible = false
	_reconcile_network_views(previous_units, previous_printers, event)
	_refresh_network_input()


func _reconcile_network_views(previous_units: Dictionary, previous_printers: Dictionary, event: Dictionary) -> void:
	for id in unit_nodes.keys().duplicate():
		if not units.has(id):
			unit_nodes[id].queue_free()
			unit_nodes.erase(id)
	for id in units.keys():
		var is_new := not unit_nodes.has(id)
		if is_new:
			var data: Dictionary = CombatDataScript.UNITS[units[id]["key"]]
			var node := _build_unit_figure(id, data, str(units[id]["faction"]))
			node.position = _cell_to_world(units[id]["cell"])
			unit_root.add_child(node)
			unit_nodes[id] = node
			_play_print_animation(node, CombatDataScript.FACTIONS[units[id]["faction"]]["color"])
		else:
			var destination := _cell_to_world(units[id]["cell"])
			if previous_units.has(id) and previous_units[id]["cell"] != units[id]["cell"]:
				_play_unit_animation(id, ["Running", "Run", "Walking_Woman", "Walking", "Walk"])
				var tween := create_tween()
				tween.tween_property(unit_nodes[id], "position", destination, 0.28)
				tween.tween_callback(_resume_unit_idle.bind(id))
			else:
				unit_nodes[id].position = destination
		if previous_units.has(id) and int(previous_units[id]["hp"]) != int(units[id]["hp"]):
			var flash_color := Color("#55f0a4") if int(units[id]["hp"]) > int(previous_units[id]["hp"]) else Color("#ff4a4a")
			_flash_figure(unit_nodes[id], flash_color)
	var event_type := str(event.get("type", ""))
	var actor_id := str(event.get("actor_id", ""))
	if unit_nodes.has(actor_id):
		if event_type == CombatCommandsScript.ATTACK:
			_play_unit_animation(actor_id, ["Thrust_Slash", "SwordSlash", "Double_Blade_Spin"])
		elif event_type == CombatCommandsScript.ABILITY:
			_play_unit_animation(actor_id, ["mage_soell_cast_4", "Spell_Cast", "Cast", "Thrust_Slash"])
	for faction in printers.keys():
		if previous_printers.has(faction) and int(previous_printers[faction]["hp"]) > int(printers[faction]["hp"]) and printer_nodes.has(faction):
			_flash_figure(printer_nodes[faction], Color("#ff4a4a"))


func _refresh_network_input() -> void:
	_clear_overlays()
	_build_roster_cards()
	if _player_can_act():
		selected_unit_id = active_unit_id
		input_mode = "move"
		reachable_cache = _reachable_cells(active_unit_id)
		_show_cells(reachable_cache.keys(), Color("#4cb7ff66"), 0.045)
		_show_unit_in_inspector(active_unit_id)
	else:
		input_mode = "busy"
	if battle_over:
		var loser: String = combat_state.losing_faction(units, printers, faction_state, CombatDataScript.ROSTERS)
		var victor := CombatDataScript.enemy_faction(loser) if loser != "" else CombatDataScript.FACTION_ELVES
		winner_label.text = "%s wins.\nThe authoritative ENet match is complete." % CombatDataScript.FACTIONS[victor]["name"]
		winner_overlay.visible = true
	_update_ui()


func _on_network_command_rejected(message: String) -> void:
	_set_notice("Host rejected command: %s" % message)
	_refresh_network_input()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and _player_can_act():
		input_mode = "move"
		reachable_cache = _reachable_cells(active_unit_id)
		_clear_overlays()
		_show_cells(reachable_cache.keys(), Color("#4cb7ff66"), 0.045)
		_update_ui()
		return
	if camera_controller != null:
		camera_controller.handle_input(event, _on_cell_clicked)


func _reset_camera_view() -> void:
	camera_controller.reset_view()


func _on_cell_clicked(cell: Vector2i) -> void:
	if battle_over:
		return
	if input_mode == "attack" and target_cache.has(cell):
		_submit_player_command(CombatCommandsScript.ATTACK, cell)
		return
	if input_mode == "ability" and target_cache.has(cell):
		_submit_player_command(CombatCommandsScript.ABILITY, cell)
		return
	if _player_can_act() and input_mode == "move" and reachable_cache.has(cell):
		_submit_player_command(CombatCommandsScript.MOVE, cell)
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
	var loser: String = combat_state.losing_faction(units, printers, faction_state, CombatDataScript.ROSTERS)
	if loser == "":
		return false
	battle_over = true
	phase = "complete"
	var victor := CombatDataScript.enemy_faction(loser)
	winner_label.text = "%s wins.\n%s was destroyed or exhausted." % [CombatDataScript.FACTIONS[victor]["name"], CombatDataScript.FACTIONS[loser]["name"]]
	winner_overlay.visible = not smoke_mode
	_update_ui()
	_broadcast_snapshot({"type": "victory", "victor": victor})
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
	var focus_before: Vector3 = camera_controller.focus
	camera_controller.active_touches[0] = Vector2(100.0, 100.0)
	camera_controller.touch_start_positions[0] = Vector2(100.0, 100.0)
	camera_controller.touch_dragged[0] = false
	var pan_probe := InputEventScreenDrag.new()
	pan_probe.index = 0
	pan_probe.position = Vector2(140.0, 100.0)
	pan_probe.relative = Vector2(40.0, 0.0)
	camera_controller.handle_input(pan_probe, Callable())
	assert(not camera_controller.focus.is_equal_approx(focus_before), "One-finger drag did not pan the combat camera")
	camera_controller.active_touches.clear()
	camera_controller.touch_start_positions.clear()
	camera_controller.touch_dragged.clear()
	camera_controller.pinch_active = false
	camera_controller.pinch_distance = -1.0
	var yaw_before: float = camera_controller.yaw_degrees
	var pitch_before: float = camera_controller.pitch_degrees
	camera_controller.active_touches[0] = Vector2(100.0, 100.0)
	camera_controller.active_touches[1] = Vector2(200.0, 100.0)
	camera_controller.touch_start_positions[0] = camera_controller.active_touches[0]
	camera_controller.touch_start_positions[1] = camera_controller.active_touches[1]
	camera_controller.touch_dragged[0] = true
	camera_controller.touch_dragged[1] = true
	camera_controller.pinch_distance = 100.0
	camera_controller.two_finger_angle = 0.0
	camera_controller.two_finger_centroid = Vector2(150.0, 100.0)
	var orbit_probe := InputEventScreenDrag.new()
	orbit_probe.index = 0
	orbit_probe.position = Vector2(100.0, 60.0)
	orbit_probe.relative = Vector2(0.0, -40.0)
	camera_controller.handle_input(orbit_probe, Callable())
	assert(not is_equal_approx(yaw_before, camera_controller.yaw_degrees), "Two-finger twist did not rotate the combat camera")
	assert(not is_equal_approx(pitch_before, camera_controller.pitch_degrees), "Two-finger vertical slide did not tilt the combat camera")
	camera_controller.active_touches.clear()
	camera_controller.touch_start_positions.clear()
	camera_controller.touch_dragged.clear()
	camera_controller.pinch_active = false
	var zoom_before: float = camera_controller.distance
	camera_controller.active_touches[0] = Vector2(100.0, 100.0)
	camera_controller.active_touches[1] = Vector2(200.0, 100.0)
	camera_controller.pinch_distance = 100.0
	camera_controller.two_finger_angle = 0.0
	camera_controller.two_finger_centroid = Vector2(150.0, 100.0)
	var zoom_probe := InputEventScreenDrag.new()
	zoom_probe.index = 1
	zoom_probe.position = Vector2(240.0, 100.0)
	zoom_probe.relative = Vector2(40.0, 0.0)
	camera_controller.handle_input(zoom_probe, Callable())
	assert(camera_controller.distance < zoom_before, "Two-finger pinch-out did not zoom the combat camera in")
	camera_controller.set_distance(MIN_CAMERA_DISTANCE)
	assert(camera.position.y < 10.0, "Minimum phone zoom did not bring the camera close to the battlefield")
	camera_controller.set_distance(zoom_before)
	_reset_camera_view()
	assert(camera_controller.focus.is_equal_approx(CAMERA_FOCUS), "Reset view did not restore the tactical focus")
	assert(is_equal_approx(camera_controller.yaw_degrees, 0.0), "Reset view did not restore camera rotation")
	camera_controller.active_touches.clear()
	camera_controller.touch_start_positions.clear()
	camera_controller.touch_dragged.clear()
	camera_controller.pinch_active = false
	camera_controller.pinch_distance = -1.0
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
	for id in units.keys():
		assert(not units[id].has("node"), "Authoritative unit state must not contain scene nodes")
	for faction in printers.keys():
		assert(not printers[faction].has("node"), "Authoritative printer state must not contain scene nodes")
	var snapshot_probe: Dictionary = _snapshot()
	assert(not var_to_bytes(snapshot_probe).is_empty(), "Combat snapshots must be Variant-serializable")
	var probe_units := {}
	var probe_printers := {}
	var probe_factions := {}
	var probe_occupants := {}
	var probe_initiative: Array[String] = []
	var probe_flow: Dictionary = combat_state.apply_snapshot(snapshot_probe, probe_units, probe_printers, probe_factions, probe_occupants, probe_initiative)
	assert(not probe_flow.is_empty() and probe_units == units, "Snapshot round trip changed authoritative units")
	assert(probe_printers == printers and probe_factions == faction_state, "Snapshot round trip changed match resources")
	var command_probe: Dictionary = command_validator.make(CombatCommandsScript.WAIT, 1, "probe")
	var command_context := {"phase": "initiative", "units": {"probe": {"faction": "elves"}}, "active_unit_id": "probe"}
	assert(command_validator.validate(command_probe, "elves", command_context) == "", "A legal authoritative command was rejected")
	assert(command_validator.validate(command_probe, "goblins", command_context) != "", "A command from the wrong faction was accepted")
	print("COMBAT_SMOKE_OK round=%d activations=%d units=%d" % [round_number, action_counter, units.size()])
	get_tree().quit(0)
