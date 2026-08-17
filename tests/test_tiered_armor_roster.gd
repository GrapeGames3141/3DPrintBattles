extends Node
## Full-suit art contract: one alpha master and measured helmet socket per creature.

const CATALOG_SCRIPT := preload("res://scripts/core/catalog.gd")
const ROSTER := preload("res://scripts/ui/tiered_armor_roster.gd")
const PREVIEW := preload("res://scripts/ui/tiered_armor_palette_preview.gd")
const BATTLE_STAGE := preload("res://scripts/ui/battle_sprite_stage.gd")
const FORGE_STAGE := preload("res://scripts/ui/arcane_forge_stage.gd")
const WORKBENCH := preload("res://scripts/ui/equipment_workbench_view.gd")

const EXPECTED_CREATURE_IDS := ["cinderpaw", "aquafin", "voltwig", "mossmunk", "frostling", "stoneback", "galehopper", "sparkotter", "glassdrake", "coralisk", "runestag", "brambleowl", "ironmaw", "aurorawing", "thunderelk", "coalgriffin", "tidewhale", "skyforge", "pyraxis", "verdantitan", "miragefox", "voidmanta", "worldcoil", "starloom"]
const IDENTITY_SAMPLES := {
	"aquafin": Vector2(0.570, 0.140), # dorsal fin cyan
	"aurorawing": Vector2(0.480, 0.110), # crown feather ice-blue
	"skyforge": Vector2(0.600, 0.300) # neck feather blue-green
}
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	_assert_manifest_and_masters()
	await _assert_presenters()
	_assert_ui_gate_sources()
	if failures.is_empty():
		print("PASS: 24-creature tiered armor roster, alpha masters, shader materials, and generic UI presenters")
	call_deferred("finish")

func _assert_manifest_and_masters() -> void:
	var catalog_ids: Array[String] = []
	for creature in CATALOG_SCRIPT.CREATURES:
		catalog_ids.append(str(creature.id))
	require(catalog_ids == EXPECTED_CREATURE_IDS and ROSTER.creature_ids() == EXPECTED_CREATURE_IDS, "catalog and armor registry contain the exact 24-creature roster in stable order")
	require(ROSTER.master_path_for("cinderpaw") == PREVIEW.MASTER_PATH and ROSTER.master_path_for("cinderpaw").ends_with("_v3.png"), "approved Cinderpaw v3 master path remains unchanged")
	for creature_id in EXPECTED_CREATURE_IDS:
		var definition := ROSTER.definition(creature_id)
		var path := ROSTER.master_path_for(creature_id)
		var anchor := ROSTER.gem_anchor_for(creature_id)
		require(not path.is_empty() and path.begins_with("res://assets/armor/tiered/") and path.get_file().begins_with(creature_id + "_"), "%s has its expected runtime master path" % creature_id)
		require(anchor.x > 0.0 and anchor.x < 1.0 and anchor.y > 0.0 and anchor.y < 1.0 and definition.has("gem_anchor"), "%s has a measured normalized helmet-gem anchor" % creature_id)
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		var mask_path := ROSTER.plate_mask_path_for(creature_id)
		var mask := Image.load_from_file(ProjectSettings.globalize_path(mask_path))
		require(image != null and not image.is_empty() and image.get_format() == Image.FORMAT_RGBA8, "%s master is an RGBA PNG" % creature_id)
		require(mask != null and not mask.is_empty() and mask.get_width() == image.get_width() and mask.get_height() == image.get_height(), "%s plate mask aligns exactly to its RGBA master" % creature_id)
		if image != null and not image.is_empty() and mask != null and not mask.is_empty():
			_assert_master_material_contract(creature_id, image, mask)

func _assert_master_material_contract(creature_id: String, image: Image, plate_mask: Image) -> void:
	var transparent_corners := 0
	for point in [Vector2i(0, 0), Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), Vector2i(image.get_width() - 1, image.get_height() - 1)]:
		transparent_corners += 1 if image.get_pixelv(point).a <= 0.01 else 0
	var opaque := 0
	var transparent := 0
	var plate_pixels := 0
	var plate_sample := Vector2i(-1, -1)
	var unmasked_sample := Vector2i(-1, -1)
	var gem_pixels := 0
	var gem_pixels_outside_helmet := 0
	var green_outside_samples := 0
	var gem_anchor := ROSTER.gem_anchor_for(creature_id)
	for y in range(8, image.get_height(), 16):
		for x in range(8, image.get_width(), 16):
			var color := image.get_pixel(x, y)
			if color.a <= 0.04:
				transparent += 1
				continue
			opaque += 1
			var plate_alpha := plate_mask.get_pixel(x, y).r
			if plate_alpha > 0.50:
				plate_pixels += 1
				plate_sample = Vector2i(x, y)
			elif unmasked_sample.x < 0 and color.a > 0.95:
				unmasked_sample = Vector2i(x, y)
			var normalized := Vector2(float(x) / float(image.get_width()), float(y) / float(image.get_height()))
			if PREVIEW.gem_mask_for_creature(color, normalized, creature_id) > 0.10:
				gem_pixels += 1
				if PREVIEW.gem_region_mask(normalized, gem_anchor, ROSTER.gem_radius_for(creature_id)) <= 0.10: gem_pixels_outside_helmet += 1
			elif PREVIEW.gem_mask_for_color(color) > 0.10 and PREVIEW.gem_region_mask(normalized, gem_anchor, ROSTER.gem_radius_for(creature_id)) <= 0.001:
				green_outside_samples += 1
				require(PREVIEW.apply_core_tint_sample(color, PREVIEW.gem_mask_for_creature(color, normalized, creature_id), Color("5f8cff"), true).is_equal_approx(color), "%s natural green outside helmet gem bounds remains byte/color stable" % creature_id)
	require(transparent_corners == 4 and opaque > 80 and transparent > 100, "%s master preserves a transparent surround and usable subject coverage" % creature_id)
	require(plate_pixels > 8 and gem_pixels > 2, "%s master supplies plate-mask coverage and a green-dominant helmet gem" % creature_id)
	require(gem_pixels_outside_helmet <= max(25, int(gem_pixels * 0.08)), "%s keeps natural green identity materials outside its measured helmet-gem region unchanged" % creature_id)
	if creature_id in ["aquafin", "voidmanta", "worldcoil"]:
		require(green_outside_samples > 0, "%s green identity fixture exercises the helmet-local restriction" % creature_id)
	require(plate_sample.x >= 0 and unmasked_sample.x >= 0, "%s has usable masked plate and unmasked identity sample pixels" % creature_id)
	if plate_sample.x >= 0 and unmasked_sample.x >= 0:
		var plate_source := image.get_pixelv(plate_sample)
		var plate_alpha := plate_mask.get_pixelv(plate_sample).r
		var unmasked_source := image.get_pixelv(unmasked_sample)
		var tier_outputs: Array[Color] = []
		for tier_id in PREVIEW.tier_ids():
			var palette := Dictionary(PREVIEW.PALETTES[tier_id])
			tier_outputs.append(PREVIEW.recolor_masked_source_color(plate_source, plate_alpha, palette))
			require(PREVIEW.recolor_masked_source_color(unmasked_source, 0.0, palette).is_equal_approx(unmasked_source), "%s %s tier preserves unmasked source pixels exactly" % [creature_id, tier_id])
		for output_index in range(1, tier_outputs.size()):
			require(not tier_outputs[output_index].is_equal_approx(tier_outputs[0]), "%s all five suit tiers produce distinct plate results" % creature_id)
	if IDENTITY_SAMPLES.has(creature_id):
		var identity_position: Vector2 = IDENTITY_SAMPLES[creature_id]
		var identity_pixel := Vector2i(roundi(identity_position.x * float(image.get_width() - 1)), roundi(identity_position.y * float(image.get_height() - 1)))
		require(plate_mask.get_pixelv(identity_pixel).r < 0.04, "%s known natural identity-color sample remains unmasked" % creature_id)

func _assert_presenters() -> void:
	var stage := BATTLE_STAGE.new()
	stage.size = Vector2(960, 420)
	add_child(stage)
	await get_tree().process_frame
	stage.configure({"id":"aquafin", "suit_id":"legendary", "core_id":"arcane"}, {"id":"mossmunk"}, "ability", 0, false, false, 401)
	await get_tree().process_frame
	require(stage.left_armor_preview.visible and stage.left_armor_preview.creature_id == "aquafin" and stage.left_armor_preview.master_path() == ROSTER.master_path_for("aquafin"), "Battle renders Aquafin's suit master instead of a Cinderpaw-only preview")
	require(stage.left_core_vfx.creature_id == "aquafin" and stage.left_core_vfx.gem_anchor().is_equal_approx(ROSTER.gem_anchor_for("aquafin")), "Battle Core activation uses Aquafin's own helmet-gem anchor")
	stage.queue_free()
	var forge := FORGE_STAGE.new()
	forge.size = Vector2(720, 360)
	add_child(forge)
	await get_tree().process_frame
	forge.configure("mossmunk", false, false, "standard")
	forge.queue_redraw()
	await get_tree().process_frame
	require(forge.equipment_preview.creature_id == "mossmunk" and forge.equipment_preview.visible, "Forge preview follows the selected creature's suit master")
	forge.queue_free()
	var profile := {"creatures":[{"instance_id":"aquafin-fixture", "creature_id":"aquafin", "suit_instance_id":"aquafin-suit"}], "suits":[{"suit_instance_id":"aquafin-suit", "tier_id":"legendary", "socketed_core_id":"aquafin-core"}], "cores":[{"core_instance_id":"aquafin-core", "core_id":"arcane"}], "suit_blueprints":[], "core_blueprints":[]}
	var noop := func() -> void: pass
	var actions := {"select_creature":noop, "select_mode":noop, "select_item":noop, "suit_action":noop, "core_action":noop, "fit_suit":noop, "remove_suit":noop, "remove_core":noop, "socket_core":noop}
	var workbench := WORKBENCH.build(profile, "aquafin-fixture", "suits", "legendary", false, actions)
	add_child(workbench)
	await get_tree().process_frame
	var preview := workbench.find_child("TieredArmorMaster", true, false) as TextureRect
	require(preview != null and preview.texture != null and preview.texture.resource_path == ROSTER.master_path_for("aquafin"), "Workbench renders the selected non-Cinderpaw suit master")
	workbench.queue_free()

func _assert_ui_gate_sources() -> void:
	for path in ["res://scripts/ui/main.gd", "res://scripts/ui/equipment_workbench_view.gd", "res://scripts/ui/arcane_forge_stage.gd", "res://scripts/ui/battle_sprite_stage.gd"]:
		var source := FileAccess.get_file_as_string(ProjectSettings.globalize_path(path))
		require(source.contains("TieredArmorRoster") and not source.contains('== "cinderpaw" and not'), "%s has no Cinderpaw-only armor gate" % path.get_file())

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
