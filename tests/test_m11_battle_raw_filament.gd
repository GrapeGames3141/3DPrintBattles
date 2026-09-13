extends Node
## Render-level proof: raw printer silhouettes keep seat-facing alpha while every
## visible source-material pixel becomes warm filament, not blue/purple/black.

const FACING := preload("res://scripts/ui/battle_facing_sprite_cache.gd")
const FILAMENT := preload("res://assets/creatures/2d/battle-facing/battle_raw_filament.gdshader")

var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if value:
		return
	failures.append(message)
	push_error(message)

func _bytes_sha256(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func _rendered_qa_ready() -> bool:
	var evidence_root := ProjectSettings.globalize_path("res://build/evidence/").replace("\\", "/").trim_suffix("/")
	var qa_root := SaveService.profile_path.get_base_dir().replace("\\", "/")
	var isolated := qa_root.begins_with(evidence_root + "/")
	require(isolated, "M11 raw-filament proof requires the pre-autoload isolated E: QA save root.")
	require(DisplayServer.get_name().to_lower() != "headless", "M11 raw-filament proof requires a rendered Forward+ DisplayServer; headless readback is not evidence.")
	return isolated and DisplayServer.get_name().to_lower() != "headless"

func _ready() -> void:
	if not _rendered_qa_ready():
		get_tree().quit(1)
		return
	await get_tree().process_frame
	for fixture in [{"creature_id":"aquafin","seat":0}, {"creature_id":"runestag","seat":0}, {"creature_id":"voltwig","seat":0}, {"creature_id":"voltwig","seat":1}]:
		await _assert_warm_raw_render(str(fixture.creature_id), int(fixture.seat))
	if failures.is_empty():
		print("PASS: M11 raw filament render is warm and preserves facing alpha")
	get_tree().quit(0 if failures.is_empty() else 1)

func _assert_warm_raw_render(creature_id: String, seat: int) -> void:
	var texture := FACING.texture_for_creature(creature_id)
	require(texture != null, "%s raw filament test has a promoted facing texture." % creature_id)
	if texture == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	var source_region := FACING.safe_source_region_for_creature(creature_id, FACING.raw_frame_for_creature(creature_id, seat))
	atlas.region = source_region
	var viewport := SubViewport.new()
	viewport.size = Vector2i(380, 508)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var rect := TextureRect.new()
	rect.texture = atlas
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = Vector2(viewport.size)
	var material := ShaderMaterial.new()
	material.shader = FILAMENT
	rect.material = material
	viewport.add_child(rect)
	# Two process frames let the rendered Forward+ child viewport allocate and
	# submit without waiting indefinitely on a global frame-post-draw signal.
	await get_tree().process_frame
	await get_tree().process_frame
	var source := Image.load_from_file(ProjectSettings.globalize_path(FACING.sprite_path_for(creature_id)))
	var imported := texture.get_image()
	var rendered := viewport.get_texture().get_image()
	require(rendered != null and not rendered.is_empty(), "%s raw filament render target is readable." % creature_id)
	if rendered == null or rendered.is_empty():
		viewport.queue_free()
		return
	var checked := 0
	var warm := 0
	var partial_checked := 0
	var partial_alpha_matches := 0
	var imported_alpha_matches := 0
	for output_y in range(int(source_region.size.y)):
		for output_x in range(int(source_region.size.x)):
			var source_x := int(source_region.position.x) + output_x
			var source_y := int(source_region.position.y) + output_y
			var source_color := source.get_pixel(source_x, source_y)
			if source_color.a <= .20:
				continue
			checked += 1
			var output := rendered.get_pixel(output_x, output_y)
			if output.a > .16 and output.r > output.g and output.g > output.b and output.r > .10:
				warm += 1
			if source_color.a > .20 and source_color.a < .80:
				partial_checked += 1
				if absf(imported.get_pixel(source_x, source_y).a - source_color.a) <= .001:
					imported_alpha_matches += 1
				if absf(output.a - imported.get_pixel(source_x, source_y).a) <= .04:
					partial_alpha_matches += 1
	print("RAW_FILAMENT_ALPHA creature=%s seat=%d source_file_sha=%s source_pixels_sha=%s imported_pixels_sha=%s partial=%d imported_source_exact=%d shader_imported_within_004=%d" % [creature_id, seat, FileAccess.get_sha256(ProjectSettings.globalize_path(FACING.sprite_path_for(creature_id))), _bytes_sha256(source.get_data()), _bytes_sha256(imported.get_data()), partial_checked, imported_alpha_matches, partial_alpha_matches])
	require(checked > 1000, "%s seat %d raw filament test samples visible source geometry." % [creature_id, seat])
	require(warm >= int(checked * .985), "%s seat %d raw filament render is warm for all visible geometry and does not square alpha." % [creature_id, seat])
	require(partial_checked > 0, "%s seat %d source region retains Lanczos partial-alpha edge coverage." % [creature_id, seat])
	require(imported_alpha_matches == partial_checked, "%s seat %d imported facing texture exactly matches source partial alpha; stale imports are not accepted." % [creature_id, seat])
	require(partial_alpha_matches == partial_checked, "%s seat %d raw filament render preserves imported partial alpha within 0.04 and does not square it." % [creature_id, seat])
	viewport.queue_free()
