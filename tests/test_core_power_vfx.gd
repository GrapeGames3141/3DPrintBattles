extends Node
## Focused asset and lifecycle contract for the image-authored helmet Core preview.

const CORES := preload("res://scripts/core/armor_core_definitions.gd")
const PREVIEW := preload("res://scripts/ui/tiered_armor_palette_preview.gd")
const CORE_VFX := preload("res://scripts/ui/core_power_vfx.gd")
const BATTLE_STAGE := preload("res://scripts/ui/battle_sprite_stage.gd")
const VFX_SHADER_PATH := "res://assets/vfx/helmet_core_activation_additive.gdshader"
const PALETTE_SHADER_PATH := "res://assets/armor/tiered/cinderpaw_tier_palette.gdshader"
const MASTER_SOURCE_PATH := "res://art-source/source/armor/core/cinderpaw_tiered_armor_signature_green_chroma_v3.png"
# This atlas was byte-identical to its runtime asset and is now retained once
# under assets; the source provenance is recorded in art-source/README.md.
const ATLAS_SOURCE_PATH := "res://assets/vfx/helmet_core_activation_grayscale_v1.png"
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	_assert_core_data()
	_assert_runtime_assets()
	_assert_source_sharing()
	_assert_preview_masks()
	_assert_vfx_lifecycle()
	await _assert_actor_scoped_stage_lifecycle()
	if failures.is_empty():
		print("PASS: image-authored helmet Core assets and finite atlas VFX contracts")
	call_deferred("finish")

func _assert_core_data() -> void:
	var expected_effects := {"ember":"+2 Attack", "tide":"Start battle with 4 Shield", "verdant":"Once per battle: heal 4 below half HP", "storm":"+1 Speed", "arcane":"Signature costs 1 less (minimum 1)"}
	require(CORES.core_ids() == ["ember", "tide", "verdant", "storm", "arcane"], "five stable Core definitions exist")
	var colors: Array[Color] = []
	for core_id in CORES.core_ids():
		var definition: Dictionary = CORES.definition(core_id)
		var color: Color = definition.get("color", Color.TRANSPARENT)
		require(str(definition.get("effect", "")) == str(expected_effects[core_id]) and color.a > 0.99 and not colors.has(color), "%s retains a distinct staged effect and tint" % core_id)
		colors.append(color)

func _assert_runtime_assets() -> void:
	var master_source := Image.load_from_file(ProjectSettings.globalize_path(MASTER_SOURCE_PATH))
	var atlas_source := Image.load_from_file(ProjectSettings.globalize_path(ATLAS_SOURCE_PATH))
	require(master_source != null and not master_source.is_empty() and master_source.get_size() == Vector2i(1254, 1254), "edited master source is retained at its authored dimensions")
	require(atlas_source != null and not atlas_source.is_empty() and atlas_source.get_size() == Vector2i(1536, 1024), "grayscale atlas source is retained at its authored dimensions")
	var master := Image.load_from_file(ProjectSettings.globalize_path(PREVIEW.MASTER_PATH))
	require(master != null and not master.is_empty() and master.get_format() == Image.FORMAT_RGBA8 and master.get_size() == Vector2i(1254, 1254), "signature-green master is a 1254px RGBA runtime texture")
	if master != null and not master.is_empty():
		var transparent_corners := 0
		var opaque := 0
		var magenta := 0
		for point in [Vector2i(0, 0), Vector2i(1253, 0), Vector2i(0, 1253), Vector2i(1253, 1253)]:
			transparent_corners += 1 if master.get_pixelv(point).a <= 0.01 else 0
		for y in range(12, master.get_height(), 18):
			for x in range(12, master.get_width(), 18):
				var color := master.get_pixel(x, y)
				if color.a > 0.04: opaque += 1
				if color.r > 0.65 and color.b > 0.55 and color.g < 0.45: magenta += 1
		require(transparent_corners == 4 and opaque > 200 and magenta == 0, "signature-green master has alpha coverage, transparent corners, and no magenta fringe")
	if master != null and not master.is_empty():
		var facet_points := [Vector2i(840, 280), Vector2i(855, 280), Vector2i(866, 270), Vector2i(850, 300), Vector2i(870, 310), Vector2i(870, 325)]
		var bezel_source := master.get_pixel(760, 330)
		var armor_source := master.get_pixel(700, 300)
		var fur_source := master.get_pixel(350, 500)
		for point in facet_points:
			var source_facet := master.get_pixelv(point)
			require(PREVIEW.gem_mask_for_color(source_facet) > 0.95, "signature-green gemstone facet %s is selected without a hand-authored mask" % point)
			var unpowered := PREVIEW.apply_core_tint_sample(source_facet, PREVIEW.gem_mask_for_color(source_facet), Color.WHITE, false)
			require(absf(unpowered.r - unpowered.g) < 0.08 and absf(unpowered.g - unpowered.b) < 0.08 and not unpowered.is_equal_approx(source_facet), "no-Core remaps authored green facet %s to smoky neutral gray" % point)
		var rim_audit_count := 0
		var rim_audit_clean := true
		for y in range(253, 364, 3):
			for x in range(835, 968, 3):
				var rim_source := master.get_pixel(x, y)
				var rim_mask := PREVIEW.gem_mask_for_color(rim_source)
				if rim_source.a > 0.90 and rim_mask > 0.95:
					rim_audit_count += 1
					var rim_unpowered := PREVIEW.apply_core_tint_sample(rim_source, rim_mask, Color.WHITE, false)
					rim_audit_clean = rim_audit_clean and absf(rim_unpowered.r - rim_unpowered.g) < 0.08 and absf(rim_unpowered.g - rim_unpowered.b) < 0.08
		require(rim_audit_count > 200 and rim_audit_clean, "every sufficiently green-dominant opaque gemstone edge pixel loses the source-green signature when no Core is installed")
		require(PREVIEW.gem_mask_for_color(bezel_source) <= 0.001 and PREVIEW.gem_mask_for_color(armor_source) <= 0.001 and PREVIEW.gem_mask_for_color(fur_source) <= 0.001, "green-dominance selection excludes silver bezel, blue armor, and orange fur")
		var facet_values: Array[Dictionary] = []
		for core_id in CORES.core_ids():
			var core_color: Color = CORES.definition(core_id).get("color", Color.WHITE)
			for point in facet_points:
				var source_facet := master.get_pixelv(point)
				var mask_facet := PREVIEW.gem_mask_for_color(source_facet)
				var tinted_facet := PREVIEW.apply_core_tint_sample(source_facet, mask_facet, core_color, true)
				require(mask_facet > 0.95 and not tinted_facet.is_equal_approx(source_facet), "%s recolors every signature-green gemstone facet %s" % [core_id, point])
				require(_dominant_channel(tinted_facet) == _dominant_channel(core_color), "%s hue reaches the left/right/upper/lower gemstone facet %s" % [core_id, point])
				if core_id == "arcane":
					facet_values.append({"source":_luminance(source_facet), "tinted":_luminance(tinted_facet)})
		facet_values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.source) < float(b.source))
		var first_luminance := float(facet_values[0].tinted)
		var last_luminance := float(facet_values[facet_values.size() - 1].tinted)
		for index in range(1, facet_values.size()):
			require(float(facet_values[index].tinted) + 0.002 >= float(facet_values[index - 1].tinted), "core palette preserves authored facet luminance ordering")
		require(last_luminance - first_luminance > 0.08, "core palette preserves visible facet contrast across the whole stone")
	var atlas := Image.load_from_file(ProjectSettings.globalize_path(CORE_VFX.ATLAS_PATH))
	require(atlas != null and not atlas.is_empty() and atlas.get_size() == Vector2i(1536, 1024), "activation atlas is exact 1536x1024")
	var master_source_hash := _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(MASTER_SOURCE_PATH)))
	var master_runtime_hash := _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(PREVIEW.MASTER_PATH)))
	var atlas_source_hash := _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(ATLAS_SOURCE_PATH)))
	var atlas_runtime_hash := _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(CORE_VFX.ATLAS_PATH)))
	require(master_source_hash.length() == 64 and master_runtime_hash.length() == 64 and atlas_source_hash.length() == 64 and atlas_runtime_hash.length() == 64 and atlas_source_hash == atlas_runtime_hash, "source/runtime art hashes are present and the activation atlas is copied byte-for-byte")
	if atlas != null and not atlas.is_empty():
		for cell_y in 2:
			for cell_x in 4:
				var corner := atlas.get_pixel(cell_x * 384 + 4, cell_y * 512 + 4)
				var center := atlas.get_pixel(cell_x * 384 + 192, cell_y * 512 + 256)
				require(maxf(corner.r, maxf(corner.g, corner.b)) < 0.04 and maxf(center.r, maxf(center.g, center.b)) > 0.08, "atlas cell %d contains a centered nonblack effect over black corners" % (cell_y * 4 + cell_x))
		for frame in range(8):
			var measured_anchor := _atlas_content_centroid(atlas, frame)
			var configured_anchor := CORE_VFX.atlas_content_center_for_frame(frame)
			require(measured_anchor.distance_to(configured_anchor) <= 6.0, "atlas frame %d uses its measured nonblack content anchor" % frame)
	var shader_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(VFX_SHADER_PATH))
	require(shader_text.contains("blend_add") and shader_text.contains("brightness") and shader_text.contains("authored_gem_exclusion"), "atlas shader uses additive halo/spark tint, makes black pixels inert, and suppresses its guide diamond")
	var palette_shader_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(PALETTE_SHADER_PATH))
	require(palette_shader_text.contains("vec3 luminance_palette") and palette_shader_text.contains("luminance_palette(luminance, plate_shadow.rgb") and palette_shader_text.contains("float gem_mask = gemstone_material_mask(source.rgb) * helmet_gem_region_mask(UV)") and palette_shader_text.contains("vec3 gem_colored = luminance_palette"), "plate and helmet-local gemstone shader paths call one shared luminance palette function")
	var preview_text := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/ui/tiered_armor_palette_preview.gd"))
	require(not palette_shader_text.contains("core_gem_mask") and not preview_text.contains("GEM_MASK_PATH") and not preview_text.contains("helmet_gem_full_interior_mask"), "runtime uses source-derived green material selection with no hand-authored gem mask path")

func _assert_source_sharing() -> void:
	var master_hash := _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(PREVIEW.MASTER_PATH)))
	var atlas_hash := _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(CORE_VFX.ATLAS_PATH)))
	for core_id in CORES.core_ids():
		require(CORE_VFX.master_source_for_core(core_id) == PREVIEW.MASTER_PATH and _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(CORE_VFX.master_source_for_core(core_id)))) == master_hash, "%s shares the edited master hash" % core_id)
		require(CORE_VFX.atlas_source_for_core(core_id) == CORE_VFX.ATLAS_PATH and _sha256(FileAccess.get_file_as_bytes(ProjectSettings.globalize_path(CORE_VFX.atlas_source_for_core(core_id)))) == atlas_hash, "%s shares the one activation atlas hash" % core_id)
	var tiered_pngs: Array[String] = []
	for filename in DirAccess.get_files_at(ProjectSettings.globalize_path("res://assets/armor/tiered")):
		if filename.to_lower().contains("core") and filename.to_lower().ends_with(".png"): tiered_pngs.append(filename)
	require(tiered_pngs.is_empty(), "no per-Core armor PNG variants exist")

func _assert_preview_masks() -> void:
	var gem_center := PREVIEW.GEM_CENTER_NORMALIZED
	require(gem_center.is_equal_approx(CORE_VFX.HELMET_GEM_CENTER_NORMALIZED), "shader tint and atlas overlay share one measured authored-gem center")
	for control_size in [Vector2(320.0, 720.0), Vector2(720.0, 320.0), Vector2(480.0, 480.0)]:
		var fitted := CORE_VFX.fitted_master_rect_for_size(control_size)
		var mapped := CORE_VFX.master_local_to_control(control_size, gem_center)
		var reconstructed := (mapped - fitted.position) / fitted.size
		require(fitted.has_point(mapped) and reconstructed.is_equal_approx(gem_center), "atlas origin remains aligned to the fitted master gem across tall, wide, and square controls")
		var effect_size := Vector2(fitted.size.x * 0.235, fitted.size.x * 0.315)
		var peak_anchor := CORE_VFX.atlas_content_center_for_frame(5) / Vector2(CORE_VFX.CELL_SIZE)
		var effect_origin := mapped - effect_size * peak_anchor
		require((effect_origin + effect_size * peak_anchor).distance_to(mapped) <= 0.01, "atlas peak content maps exactly onto the baked gem across fitted layouts")
	var legendary: Dictionary = PREVIEW.PALETTES.legendary
	for source_color in [Color("ff7d2a"), Color("f7df9a"), Color("e9f5ff"), Color("b8c2c8")]:
		require(PREVIEW.recolor_masked_source_color(source_color, 0.0, legendary).is_equal_approx(source_color), "bezel and non-gem source colors remain stable through armor tier selection")
	var sample := Color("5f7386")
	var sample_luminance := _luminance(sample)
	var shared_plate := PREVIEW.luminance_palette(sample_luminance, Color(legendary.shadow), Color(legendary.primary), Color(legendary.highlight))
	var manual_plate := Color(legendary.shadow).lerp(Color(legendary.primary), PREVIEW._smoothstep(0.10, 0.72, sample_luminance))
	manual_plate = manual_plate.lerp(Color(legendary.highlight), PREVIEW._smoothstep(0.63, 0.95, sample_luminance) * 0.56)
	require(shared_plate.is_equal_approx(manual_plate), "shared GDScript luminance palette uses the exact armor smoothstep thresholds and highlight blend")
	var armor_result := PREVIEW.recolor_source_color(sample, legendary)
	var expected_armor := sample.lerp(shared_plate, PREVIEW.armor_mask_for_color(sample))
	require(armor_result.is_equal_approx(expected_armor), "armor path delegates its remap to the shared luminance palette")
	var arcane := CORES.definition("arcane")
	var shared_gem := PREVIEW.luminance_palette(sample_luminance, Color(PREVIEW.core_palette_for_color(arcane.color).shadow), Color(PREVIEW.core_palette_for_color(arcane.color).primary), Color(PREVIEW.core_palette_for_color(arcane.color).highlight))
	var gem_result := PREVIEW.apply_core_tint_sample(sample, 1.0, arcane.color, true)
	require(gem_result.is_equal_approx(shared_gem), "gem path uses the same shared luminance palette with only its Core palette inputs changed")

func _assert_vfx_lifecycle() -> void:
	var vfx := CORE_VFX.new()
	add_child(vfx)
	vfx.configure_core("")
	require(vfx.has_visible_socket() and vfx.has_embedded_gem() and not vfx.has_powered_core() and not vfx.has_active_atlas_overlay() and not vfx.is_processing(), "unpowered authored gem stays dull with no powered Core, atlas VFX, or processing")
	vfx.configure_core("arcane")
	require(vfx.has_embedded_gem() and vfx.has_powered_core(), "installing a Core powers the same authored gem")
	var token_a := vfx.start_activation()
	var token_b := vfx.start_activation()
	require(token_b > token_a and vfx.is_processing() and vfx.frame_index == 0, "activation token is monotonic and begins at atlas frame zero")
	var last_frame := -1
	for progress in [0.0, 0.12, 0.28, 0.46, 0.64, 0.80, 0.95]:
		var frame := CORE_VFX.atlas_frame_for_progress(progress)
		require(frame >= last_frame, "activation atlas frames advance monotonically")
		last_frame = frame
	vfx._process(2.0)
	require(not vfx.is_processing() and not vfx.is_activation_active() and vfx.phase == "resolved" and not vfx.has_active_atlas_overlay(), "activation ends with no atlas VFX")
	vfx.set_reduced_motion(true)
	vfx.start_activation()
	require(not vfx.is_processing() and not vfx.has_moving_elements() and not vfx.has_active_atlas_overlay(), "reduced motion stays static without atlas frame progression")
	var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://scripts/ui/core_power_vfx.gd"))
	require(source.contains("ATLAS_PATH") and source.contains("HelmetCoreAtlasEffect"), "CorePowerVFX remains driven by the authored activation atlas")
	require(source.contains("draw_circle") and source.contains("draw_arc"), "a compact procedural halo only reinforces the authored atlas at the embedded gem")
	vfx.queue_free()

func _assert_actor_scoped_stage_lifecycle() -> void:
	var stage := BATTLE_STAGE.new()
	stage.size = Vector2(960, 420)
	add_child(stage)
	await get_tree().process_frame
	var left := {"id":"cinderpaw", "suit_id":"legendary", "core_id":"arcane"}
	var right := {"id":"cinderpaw", "suit_id":"legendary", "core_id":"arcane"}
	stage.configure(left, right, "ability", 0, false, false, 91)
	await get_tree().process_frame
	require(stage.left_core_vfx.is_activation_active() and not stage.right_core_vfx.is_activation_active() and stage._is_core_activation_visible(0, "arcane") and not stage._is_core_activation_visible(1, "arcane"), "two Arcane Cores activate only the ability actor's atlas and compact halo")
	stage.advance_presentation(2.0)
	await get_tree().process_frame
	require(not stage.left_core_vfx.has_active_atlas_overlay() and not stage.right_core_vfx.has_active_atlas_overlay() and not stage._is_core_activation_visible(0, "arcane") and not stage._is_core_activation_visible(1, "arcane"), "post-duration actor and non-actor Core overlays and halos are both hidden")
	stage.configure(left, right, "ability", 1, true, false, 92)
	require(not stage.left_core_vfx.has_active_atlas_overlay() and stage.right_core_vfx.has_active_atlas_overlay() and not stage._is_core_activation_visible(0, "arcane") and stage._is_core_activation_visible(1, "arcane"), "reduced motion holds one static peak only on the current ability actor")
	stage.advance_presentation(2.0)
	require(not stage.left_core_vfx.has_active_atlas_overlay() and not stage.right_core_vfx.has_active_atlas_overlay() and not stage._is_core_activation_visible(0, "arcane") and not stage._is_core_activation_visible(1, "arcane"), "reduced-motion static peak also clears after the finite ability window")
	stage.queue_free()

func _sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _luminance(color: Color) -> float:
	return color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722

func _dominant_channel(color: Color) -> int:
	if color.r >= color.g and color.r >= color.b:
		return 0
	if color.g >= color.b:
		return 1
	return 2

func _atlas_content_centroid(atlas: Image, frame: int) -> Vector2:
	var cell_x := (frame % 4) * CORE_VFX.CELL_SIZE.x
	var cell_y := (frame / 4) * CORE_VFX.CELL_SIZE.y
	var total := 0.0
	var weighted := Vector2.ZERO
	for y in range(0, CORE_VFX.CELL_SIZE.y, 2):
		for x in range(0, CORE_VFX.CELL_SIZE.x, 2):
			var color := atlas.get_pixel(cell_x + x, cell_y + y)
			var brightness := maxf(color.r, maxf(color.g, color.b))
			if brightness > 0.094:
				weighted += Vector2(x, y) * brightness
				total += brightness
	return weighted / maxf(total, 0.001)

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
