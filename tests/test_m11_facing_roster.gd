extends Node
## Source-PNG-free roster proof. Mount every catalog creature in the actual stage
## on both seats and validate imported texture, species-aware region, and caption.

const STAGE := preload("res://scripts/ui/physical_battlefield_stage.gd")
const STATE := preload("res://scripts/battle/unified_battle_state.gd")
const RULES := preload("res://scripts/core/unified_rules.gd")
const FACING := preload("res://scripts/ui/battle_facing_sprite_cache.gd")

var failures: Array[String] = []

func require(ok: bool, message: String) -> void:
	if ok:
		return
	failures.append(message)
	push_error(message)

func _ready() -> void:
	FACING.clear_for_test()
	var stage := STAGE.new()
	stage.size = Vector2(576, 1024)
	add_child(stage)
	await get_tree().process_frame
	var directional := 0
	var directional_neutral := 0
	for definition in Catalog.CREATURES:
		var id := str((definition as Dictionary).get("id", ""))
		if FACING.coverage_kind_for(id) == "directional_neutral":
			directional_neutral += 1
		else:
			directional += 1
		for seat in [0, 1]:
			var players := [{"slots":[null, null, null]}, {"slots":[null, null, null]}]
			players[seat]["slots"][0] = STATE._unit(RULES.card(id))
			stage._elapsed = 0.0
			stage.configure({"players":players}, {})
			stage.set_process(false)
			await get_tree().process_frame
			var sprite := stage.find_child("LivingPrintSlot%d" % (seat * 3), true, false) as TextureRect
			var caption := stage.find_child("LivingPrintCaption%d" % (seat * 3), true, false) as Label
			var atlas := sprite.texture as AtlasTexture if sprite != null else null
			var frame := FACING.frame_for_creature(id, seat, 0.0)
			var expected_region := FACING.safe_source_region_for_creature(id, frame)
			require(sprite != null and sprite.visible and atlas != null and atlas.atlas != null and atlas.atlas.resource_path == FACING.sprite_path_for(id), "%s seat %d stage sprite is visible and owns its exact approved resource." % [id, seat])
			require(atlas != null and atlas.atlas.get_size() == Vector2(FACING.atlas_size_for_creature(id)), "%s seat %d imported texture has its species-aware dimensions." % [id, seat])
			require(atlas != null and atlas.region == expected_region, "%s seat %d uses its exact species-aware atlas region (actual=%s expected=%s)." % [id, seat, atlas.region if atlas != null else Rect2(), expected_region])
			require(caption != null and caption.visible and caption.text.to_lower().contains(id), "%s seat %d keeps native visible HP caption ownership." % [id, seat])
	require(directional == 23 and directional_neutral == 1 and FACING.coverage_kind_for("voltwig") == "directional_neutral" and not FACING.uses_legacy_art("voltwig"), "Roster coverage is exactly 23 directional sheets plus Voltwig's genuine two-cell directional-neutral atlas.")
	require(not FACING.has_directional_coverage("not_a_catalog_creature") and FACING.coverage_kind_for("not_a_catalog_creature") == "missing", "Invalid IDs fail closed without generic fallback.")
	if failures.is_empty():
		print("PASS: M11 facing roster stage proof covers all 24 catalog creatures on both seats")
	get_tree().quit(0 if failures.is_empty() else 1)
