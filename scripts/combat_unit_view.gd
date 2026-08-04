class_name CombatUnitView
extends RefCounted

const CombatDataScript := preload("res://scripts/combat_data.gd")


func build_unit_figure(id: String, data: Dictionary, faction: String, use_runtime_model: bool) -> Node3D:
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
	if use_runtime_model and data.has("scene") and ResourceLoader.exists(data["scene"]):
		var resource := load(data["scene"]) as PackedScene
		if resource != null:
			var model := resource.instantiate()
			visual_anchor.add_child(model)
			_hide_helper_meshes(model)
			_fit_model_to_base(model)
			_start_model_idle(model)
			return root
	_build_cardboard_placeholder(visual_anchor, data, faction)
	return root


func play_animation(figure: Node, preferred: Array[String]) -> void:
	for candidate in figure.find_children("*", "AnimationPlayer", true, false):
		var player := candidate as AnimationPlayer
		if player == null:
			continue
		for animation_name in preferred:
			if player.has_animation(animation_name):
				player.play(animation_name)
				return


func resume_idle(figure: Node) -> void:
	play_animation(figure, ["Idle_6", "Idle", "idle", "RESET"])


func play_print_animation(node: Node3D, color: Color) -> void:
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
	var tween := node.create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale:y", 1.0, 0.75)
	tween.tween_property(scan, "position:y", 2.25, 0.75)
	tween.chain().tween_callback(scan.queue_free)


func flash(figure: Node3D, color: Color) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 5.0
	light.omni_range = 2.4
	light.position.y = 1.0
	figure.add_child(light)
	var tween := figure.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.32)
	tween.tween_callback(light.queue_free)


func _start_model_idle(model: Node) -> void:
	play_animation(model, ["Idle_6", "Idle", "idle", "Armature|clip0|baselayer"])


func _build_cardboard_placeholder(anchor: Node3D, data: Dictionary, faction: String) -> void:
	var faction_color: Color = CombatDataScript.FACTIONS[faction]["color"]
	var cardboard_core := MeshInstance3D.new()
	cardboard_core.name = "CardboardCore"
	var core_mesh := BoxMesh.new()
	core_mesh.size = Vector3(0.82, 1.30, 0.82)
	cardboard_core.mesh = core_mesh
	cardboard_core.position.y = 0.68
	cardboard_core.material_override = _material(Color("#8f7045"), 0.96, 0.0)
	anchor.add_child(cardboard_core)

	var concept_directory := str(data["concept"]).get_base_dir()
	_add_cardboard_face(anchor, "Front", "%s/front.png" % concept_directory, Vector3(0.0, 0.68, 0.416), 0.0)
	_add_cardboard_face(anchor, "Back", "%s/back.png" % concept_directory, Vector3(0.0, 0.68, -0.416), 180.0)
	_add_cardboard_face(anchor, "Left", "%s/left.png" % concept_directory, Vector3(-0.416, 0.68, 0.0), -90.0)
	_add_cardboard_face(anchor, "Right", "%s/right.png" % concept_directory, Vector3(0.416, 0.68, 0.0), 90.0)

	var team_lid := MeshInstance3D.new()
	team_lid.name = "TeamColorTop"
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.86, 0.065, 0.86)
	team_lid.mesh = lid_mesh
	team_lid.position.y = 1.36
	team_lid.material_override = _emissive_material(faction_color, 0.85)
	anchor.add_child(team_lid)


func _add_cardboard_face(
	anchor: Node3D,
	face_name: String,
	texture_path: String,
	position: Vector3,
	rotation_y_degrees: float
) -> void:
	var panel := MeshInstance3D.new()
	panel.name = "CardFace_%s" % face_name
	var panel_mesh := QuadMesh.new()
	panel_mesh.size = Vector2(0.76, 1.18)
	panel.mesh = panel_mesh
	panel.position = position
	panel.rotation_degrees.y = rotation_y_degrees
	var panel_material := StandardMaterial3D.new()
	panel_material.albedo_color = Color("#f1dfbd")
	panel_material.roughness = 0.94
	panel_material.metallic = 0.0
	panel_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	panel_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if ResourceLoader.exists(texture_path):
		panel_material.albedo_texture = load(texture_path) as Texture2D
	panel.material_override = panel_material
	anchor.add_child(panel)


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


func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
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
