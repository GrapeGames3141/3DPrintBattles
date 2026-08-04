extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("#d9dde2")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color.WHITE
	settings.ambient_light_energy = 0.65
	environment.environment = settings
	world.add_child(environment)

	var base := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.68
	disc.bottom_radius = 0.74
	disc.height = 0.20
	base.mesh = disc
	base.position.y = 0.10
	var base_material := StandardMaterial3D.new()
	base_material.albedo_color = Color("#7d6954")
	base_material.metallic = 0.1
	base_material.roughness = 0.62
	base.material_override = base_material
	world.add_child(base)

	var packed := load("res://assets/models/verdant_alchemist_animated.glb") as PackedScene
	var model := packed.instantiate()
	world.add_child(model)
	for helper in model.find_children("*Icosphere*", "MeshInstance3D", true, false):
		helper.visible = false
	_fit_model(model)
	model.position.y += 0.21
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var player := players[0] as AnimationPlayer
		player.play("mage_soell_cast_4")
		player.seek(0.55, true)

	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.15, 4.1)
	camera.fov = 36.0
	world.add_child(camera)
	camera.look_at(Vector3(0.0, 1.15, 0.0), Vector3.UP)
	camera.current = true

	for setup in [
		[Vector3(-2.5, 3.5, 3.0), Color("#fff2df"), 3.4],
		[Vector3(2.5, 2.0, 2.0), Color("#d6edff"), 2.0],
	]:
		var light := OmniLight3D.new()
		light.position = setup[0]
		light.light_color = setup[1]
		light.light_energy = setup[2]
		light.omni_range = 8.0
		world.add_child(light)

	for _frame in range(8):
		await process_frame
	var output := "res://previews/verdant-alchemist-godot.png"
	var image := root.get_viewport().get_texture().get_image()
	var result := image.save_png(ProjectSettings.globalize_path(output))
	print("VERDANT_CAPTURE=%s RESULT=%s" % [output, result])
	quit(0 if result == OK else 1)


func _fit_model(model: Node3D) -> void:
	var combined := AABB()
	var has_bounds := false
	for candidate in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := candidate as MeshInstance3D
		if mesh == null or not mesh.visible or mesh.mesh == null:
			continue
		var bounds := mesh.get_aabb()
		combined = combined.merge(bounds) if has_bounds else bounds
		has_bounds = true
	var fit_scale := minf(1.72 / combined.size.y, 1.05 / maxf(combined.size.x, combined.size.z))
	model.scale = Vector3.ONE * fit_scale
	model.position = Vector3(
		-(combined.position.x + combined.size.x * 0.5) * fit_scale,
		-combined.position.y * fit_scale,
		-(combined.position.z + combined.size.z * 0.5) * fit_scale
	)
