extends Node
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _ready() -> void:
	var sequence := ArcaneForgeSequence.create(false)
	require(sequence.phase == ArcaneForgeSequence.IDLE and not sequence.request_commit(), "idle cannot commit")
	require(sequence.begin() and sequence.advance(2100) and sequence.progress_bps == 2100 and sequence.layer_reveal_bps() == 3000, "print phase has monotonic integer layer mapping")
	require(sequence.advance(4900) and sequence.phase == ArcaneForgeSequence.RAW_COMPLETE and sequence.progress_bps == 7000, "raw completion has fixed threshold")
	require(sequence.request_commit() and not sequence.request_commit() and sequence.resolve_commit(true) and sequence.phase == ArcaneForgeSequence.AWAKENING, "commit request is a one-time latch")
	require(sequence.advance(3000) and sequence.phase == ArcaneForgeSequence.AWAKENED and not sequence.skip(), "awakening completes once")
	var reduced := ArcaneForgeSequence.create(true); reduced.begin(); reduced.skip()
	require(reduced.reduced_motion and reduced.phase == ArcaneForgeSequence.RAW_COMPLETE and reduced.request_commit() and reduced.resolve_commit(true) and ArcaneForgeSequence.presentation_interval_seconds(true) > ArcaneForgeSequence.presentation_interval_seconds(false) and ArcaneForgeSequence.presentation_step_bps(true) < ArcaneForgeSequence.PRINT_COMPLETE_BPS / 2, "reduced motion remains calm staged and skippable")
	var fallback := Catalog.creature("future_unmapped_creature")
	require(fallback.is_empty() and BattleSpriteStage.sprite_path_for("future_unmapped_creature").ends_with("mossmunk_sprite_sheet.png"), "unknown future IDs retain the safe mascot visual fallback")
	for definition in Catalog.CREATURES:
		var creature_id: String = str(definition.id)
		var living_path: String = str(definition.get("sprite_sheet", ""))
		var raw_path: String = str(definition.get("raw_print", ""))
		var living_texture := ResourceLoader.load(living_path) as Texture2D
		var raw_texture := ResourceLoader.load(raw_path) as Texture2D
		# Headless Windows may not expose source PNG bytes, so validate the imported/export seam here.
		require(ResourceLoader.exists(living_path) and living_texture != null and living_texture.get_width() == 1536 and living_texture.get_height() == 1024, "%s living 4x2 sheet exists and loads at 1536x1024" % creature_id)
		require(ResourceLoader.exists(raw_path) and raw_texture != null and raw_texture.get_width() > 0 and raw_texture.get_height() > 0, "%s raw print exists and loads" % creature_id)
	if failures.is_empty(): print("PASS: checkpoint6 Arcane Forge sequence and asset mappings")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
