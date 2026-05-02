extends Control

## Clickable 3D workshop landing (Filament Fighters — Makers Guild). Ray picks hotspots → hub flows.

signal go_title
signal open_team
signal open_shop

var _toast_line: Label

const HOTSPOT_DOOR := "door"
const HOTSPOT_MONITOR := "monitor"
const HOTSPOT_PRINTER := "printer"

var _vp_container: SubViewportContainer
var _vp: SubViewport
var _camera: Camera3D


func _ready() -> void:
	name = "WorkshopLandingScreen"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	mouse_filter = Control.MOUSE_FILTER_STOP

	_vp_container = SubViewportContainer.new()
	_vp_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vp_container.mouse_filter = Control.MOUSE_FILTER_STOP
	_vp_container.stretch = true
	add_child(_vp_container)

	_vp = SubViewport.new()
	_vp.size = Vector2i(1920, 1080)
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_vp.handle_input_locally = false
	_vp_container.add_child(_vp)

	var world := _build_workshop_world()
	_vp.add_child(world)

	var overlay := VBoxContainer.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var top_hint := Label.new()
	top_hint.text = "Filament Fighters — Makers Guild"
	top_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_hint.add_theme_font_size_override("font_size", 22)
	top_hint.modulate = Color(0.95, 0.92, 0.85)
	overlay.add_child(top_hint)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(sp)

	var bot := Label.new()
	bot.text = "Click: Door → Menu · Monitor → Team · 3D Printer → Shop"
	bot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bot.add_theme_font_size_override("font_size", 15)
	bot.modulate.a = 0.9
	overlay.add_child(bot)

	_toast_line = Label.new()
	_toast_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast_line.add_theme_font_size_override("font_size", 14)
	_toast_line.modulate = Color(1.0, 0.82, 0.55)
	overlay.add_child(_toast_line)

	if not EventBus.request_toast.is_connected(_on_hub_toast):
		EventBus.request_toast.connect(_on_hub_toast)


func _build_workshop_world() -> Node3D:
	var root := Node3D.new()

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.1, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.85)
	env.ambient_light_energy = 0.35
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58, 32, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.93, 0.78)
	sun.shadow_enabled = true
	root.add_child(sun)

	var warm1 := OmniLight3D.new()
	warm1.position = Vector3(-3.2, 2.6, 2.0)
	warm1.light_energy = 2.8
	warm1.light_color = Color(1.0, 0.82, 0.55)
	warm1.omni_range = 9.0
	root.add_child(warm1)

	var warm2 := OmniLight3D.new()
	warm2.position = Vector3(3.5, 2.6, 1.5)
	warm2.light_energy = 2.6
	warm2.light_color = Color(1.0, 0.78, 0.52)
	warm2.omni_range = 8.5
	root.add_child(warm2)

	_camera = Camera3D.new()
	_camera.position = Vector3(0.15, 3.05, 9.4)
	_camera.rotation_degrees = Vector3(-18.5, 0.0, 0.0)
	_camera.fov = 52.0
	_camera.current = true
	root.add_child(_camera)

	# Floor
	var floor_mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(22, 14)
	floor_mi.mesh = plane
	floor_mi.position = Vector3(0, 0, 0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.35, 0.22, 0.14)
	floor_mat.roughness = 0.88
	floor_mi.material_override = floor_mat
	root.add_child(floor_mi)

	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 2
	floor_body.collision_mask = 0
	var floor_cs := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(22, 0.2, 14)
	floor_cs.shape = floor_box
	floor_body.position = Vector3(0, -0.11, 0)
	floor_body.add_child(floor_cs)
	root.add_child(floor_body)

	# Simple walls (dark wood)
	_add_wall_box(root, Vector3(0, 2.4, -7.0), Vector3(22, 5.0, 0.4))
	_add_wall_box(root, Vector3(-11.0, 2.4, 0), Vector3(0.4, 5.0, 14))
	_add_wall_box(root, Vector3(11.0, 2.4, 0), Vector3(0.4, 5.0, 14))

	# Door opening glow (cold exterior)
	var door_glow := MeshInstance3D.new()
	var dq := PlaneMesh.new()
	dq.size = Vector2(4.2, 4.8)
	door_glow.mesh = dq
	door_glow.position = Vector3(0, 2.4, -6.85)
	door_glow.rotation_degrees = Vector3(0, 180, 0)
	var dg_mat := StandardMaterial3D.new()
	dg_mat.albedo_color = Color(0.45, 0.62, 0.95)
	dg_mat.emission_enabled = true
	dg_mat.emission = Color(0.35, 0.55, 0.95)
	dg_mat.emission_energy_multiplier = 0.55
	door_glow.material_override = dg_mat
	root.add_child(door_glow)

	# Guild sign (Label3D)
	var sign := Label3D.new()
	sign.text = "FILAMENT FIGHTERS — MAKERS GUILD"
	sign.position = Vector3(0, 3.35, -6.55)
	sign.rotation_degrees = Vector3(0, 180, 0)
	sign.font_size = 48
	sign.modulate = Color(0.92, 0.82, 0.62)
	sign.outline_size = 12
	sign.outline_modulate = Color(0, 0, 0, 0.65)
	root.add_child(sign)

	# Left bench + printer + wireframe wolf glow
	_add_bench_cluster(root, Vector3(-4.2, 0, 1.2), true)
	# Right desk + monitor
	_add_bench_cluster(root, Vector3(4.2, 0, 1.0), false)

	# Shelf props (low-poly clutter)
	_add_spool(root, Vector3(-6.5, 1.1, -2.0), Color(0.9, 0.25, 0.2))
	_add_spool(root, Vector3(-6.0, 1.1, -2.4), Color(0.25, 0.85, 0.35))
	_add_spool(root, Vector3(6.2, 1.1, -1.8), Color(0.25, 0.45, 1.0))

	# Hotspots (invisible physics boxes)
	_add_hotspot(root, HOTSPOT_DOOR, Vector3(0, 2.0, -6.5), Vector3(3.8, 4.2, 1.2))
	_add_hotspot(root, HOTSPOT_MONITOR, Vector3(4.1, 1.55, 1.35), Vector3(2.2, 1.8, 1.4))
	_add_hotspot(root, HOTSPOT_PRINTER, Vector3(-4.1, 1.45, 1.35), Vector3(2.6, 2.0, 2.0))

	return root


func _add_wall_box(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.17, 0.11)
	mat.roughness = 0.92
	mi.material_override = mat
	parent.add_child(mi)


func _add_bench_cluster(parent: Node3D, base: Vector3, is_printer_side: bool) -> void:
	var bench := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(5.0, 0.35, 2.4)
	bench.mesh = bm
	bench.position = base + Vector3(0, 0.5, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.42, 0.28, 0.16)
	bmat.roughness = 0.75
	bench.material_override = bmat
	parent.add_child(bench)

	if is_printer_side:
		var pr := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(1.8, 1.6, 1.8)
		pr.mesh = pm
		pr.position = base + Vector3(0.3, 1.35, 0)
		var pm_mat := StandardMaterial3D.new()
		pm_mat.albedo_color = Color(0.12, 0.12, 0.14)
		pm_mat.metallic = 0.55
		pm_mat.roughness = 0.45
		pr.material_override = pm_mat
		parent.add_child(pr)

		var wolf := MeshInstance3D.new()
		var wm := CapsuleMesh.new()
		wm.radius = 0.35
		wm.height = 0.85
		wolf.mesh = wm
		wolf.position = base + Vector3(0.35, 1.65, 0.15)
		wolf.rotation_degrees = Vector3(0, 25, 0)
		var wire := StandardMaterial3D.new()
		wire.albedo_color = Color(0.25, 0.55, 1.0)
		wire.emission_enabled = true
		wire.emission = Color(0.25, 0.65, 1.0)
		wire.emission_energy_multiplier = 1.65
		wire.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		wire.albedo_color.a = 0.85
		wolf.material_override = wire
		parent.add_child(wolf)
	else:
		var mon := MeshInstance3D.new()
		var mm := BoxMesh.new()
		mm.size = Vector3(1.5, 1.05, 0.08)
		mon.mesh = mm
		mon.position = base + Vector3(-0.2, 1.55, 1.15)
		var scr := StandardMaterial3D.new()
		scr.albedo_color = Color(0.15, 0.18, 0.22)
		scr.emission_enabled = true
		scr.emission = Color(0.35, 0.55, 0.95)
		scr.emission_energy_multiplier = 0.35
		mon.material_override = scr
		parent.add_child(mon)

		var lbl := Label3D.new()
		lbl.text = "Extruder Forge"
		lbl.position = base + Vector3(-0.2, 2.35, 1.15)
		lbl.rotation_degrees = Vector3(-12, -35, 0)
		lbl.font_size = 38
		lbl.modulate = Color(0.85, 0.92, 1.0)
		parent.add_child(lbl)


func _add_spool(parent: Node3D, pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.38
	tm.bottom_radius = 0.38
	tm.height = 0.35
	mi.mesh = tm
	mi.position = pos
	mi.rotation_degrees = Vector3(90, 0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.55
	mi.material_override = mat
	parent.add_child(mi)


func _add_hotspot(parent: Node3D, kind: String, pos: Vector3, box_size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 1
	body.set_meta("hotspot", kind)
	body.position = pos
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = box_size
	cs.shape = bx
	body.add_child(cs)
	parent.add_child(body)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_ray_pick(event.global_position)
	if event is InputEventScreenTouch and event.pressed:
		_try_ray_pick(event.position)


func _exit_tree() -> void:
	if EventBus.request_toast.is_connected(_on_hub_toast):
		EventBus.request_toast.disconnect(_on_hub_toast)


func _on_hub_toast(message: String) -> void:
	if _toast_line != null:
		_toast_line.text = str(message)


func _try_ray_pick(screen_pos: Vector2) -> void:
	if _camera == null or _vp == null or _vp_container == null:
		return
	var gr := _vp_container.get_global_rect()
	if not gr.has_point(screen_pos):
		return
	var local := screen_pos - gr.position
	var vp_px: Vector2 = local / gr.size * Vector2(_vp.size)
	var from := _camera.project_ray_origin(vp_px)
	var dir := _camera.project_ray_normal(vp_px)
	var to := from + dir * 120.0
	var space := _vp.world_3d.direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	q.collide_with_areas = true
	q.collide_with_bodies = true
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		return
	var col: Object = hit.get("collider")
	if col == null:
		return
	var node: Node = col as Node
	var spot: String = ""
	var walk: Node = node
	while walk != null:
		if walk.has_meta("hotspot"):
			spot = str(walk.get_meta("hotspot"))
			break
		walk = walk.get_parent()
	if spot == "":
		return
	match spot:
		HOTSPOT_DOOR:
			go_title.emit()
		HOTSPOT_MONITOR:
			open_team.emit()
		HOTSPOT_PRINTER:
			open_shop.emit()
