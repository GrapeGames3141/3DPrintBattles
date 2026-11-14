class_name Effects
extends RefCounted
## Short bursts of particles for things that happen on the battlefield: a hit,
## a repair, a buff, frost, flame, dust. Each is a one-shot that frees itself.

static var _dot_tex: Texture2D


## A soft round dot, shared by every burst.
static func dot() -> Texture2D:
	if _dot_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 32
		t.height = 32
		_dot_tex = t
	return _dot_tex


## kinds: hit, heal, buff, frost, flame, dust, ring, steam, spark
static func burst(parent: Node, at: Vector2, kind: String, color: Color = Color.WHITE, scale_by := 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.texture = dot()
	p.position = at
	p.z_index = 40
	p.one_shot = true
	p.emitting = true
	p.local_coords = false
	p.explosiveness = 0.9
	p.amount = 16
	p.lifetime = 0.5
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 80.0
	p.initial_velocity_max = 220.0
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.add_point(0.5, color)
	ramp.set_color(2, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	var life := 0.5
	match kind:
		"hit":
			p.amount = 14
			p.lifetime = 0.3
			p.initial_velocity_min = 140.0
			p.initial_velocity_max = 340.0
			p.damping_min = 160.0
			p.damping_max = 260.0
			p.scale_amount_min = 0.12
			p.scale_amount_max = 0.3
			life = 0.3
		"heal":
			p.amount = 14
			p.lifetime = 0.9
			p.explosiveness = 0.3
			p.direction = Vector2(0, -1)
			p.spread = 30.0
			p.gravity = Vector2(0, -60)
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 90.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = Vector2(34, 22)
			p.scale_amount_min = 0.15
			p.scale_amount_max = 0.35
			life = 0.9
		"buff":
			p.amount = 18
			p.lifetime = 0.8
			p.explosiveness = 0.4
			p.spread = 40.0
			p.gravity = Vector2(0, -90)
			p.initial_velocity_min = 30.0
			p.initial_velocity_max = 120.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = Vector2(36, 30)
			p.scale_amount_min = 0.1
			p.scale_amount_max = 0.28
			life = 0.8
		"frost":
			p.amount = 20
			p.lifetime = 0.7
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 170.0
			p.gravity = Vector2(0, 120)
			p.scale_amount_min = 0.12
			p.scale_amount_max = 0.3
			life = 0.7
		"flame":
			p.amount = 22
			p.lifetime = 0.7
			p.explosiveness = 0.5
			p.spread = 45.0
			p.gravity = Vector2(0, -160)
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 130.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = Vector2(26, 20)
			p.scale_amount_min = 0.2
			p.scale_amount_max = 0.45
			ramp.set_color(0, Color("fff0a0"))
			ramp.set_color(1, Color("ff6a1a"))
			life = 0.7
		"dust":
			p.amount = 12
			p.lifetime = 0.6
			p.direction = Vector2(0, -1)
			p.spread = 90.0
			p.gravity = Vector2(0, 20)
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 110.0
			p.scale_amount_min = 0.25
			p.scale_amount_max = 0.55
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
			p.emission_rect_extents = Vector2(46, 4)
			life = 0.6
		"steam":
			p.amount = 10
			p.lifetime = 1.0
			p.explosiveness = 0.2
			p.spread = 25.0
			p.gravity = Vector2(0, -50)
			p.initial_velocity_min = 20.0
			p.initial_velocity_max = 60.0
			p.scale_amount_min = 0.3
			p.scale_amount_max = 0.7
			life = 1.0
		"ring":
			p.amount = 24
			p.lifetime = 0.5
			p.explosiveness = 1.0
			p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
			p.emission_sphere_radius = 14.0
			p.initial_velocity_min = 130.0
			p.initial_velocity_max = 150.0
			p.scale_amount_min = 0.2
			p.scale_amount_max = 0.3
			life = 0.5
		_: # spark
			p.amount = 12
			p.lifetime = 0.35
			p.initial_velocity_min = 120.0
			p.initial_velocity_max = 300.0
			p.scale_amount_min = 0.1
			p.scale_amount_max = 0.22
			life = 0.35
	p.scale_amount_min *= scale_by
	p.scale_amount_max *= scale_by
	p.color_ramp = ramp
	parent.add_child(p)
	var t := p.get_tree().create_timer(life + 0.4)
	t.timeout.connect(p.queue_free)
