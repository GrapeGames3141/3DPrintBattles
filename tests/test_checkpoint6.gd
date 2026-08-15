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
	var fallback := Catalog.creature("galehopper")
	require(str(Catalog.creature("cinderpaw").raw_print).ends_with("cinderpaw_raw_print.png") and str(fallback.get("raw_print", "")).is_empty(), "catalog maps approved raw prints without changing future IDs")
	for id in ["cinderpaw", "aquafin", "voltwig", "mossmunk"]:
		var path := str(Catalog.creature(id).raw_print)
		var texture := ResourceLoader.load(path) as Texture2D
		# Headless Windows may not expose source PNG bytes, so validate the exported-resource seam.
		require(ResourceLoader.exists(path) and texture != null and texture.get_width() > 0, "%s raw art exists and loads" % id)
	if failures.is_empty(): print("PASS: checkpoint6 Arcane Forge sequence and asset mappings")
	call_deferred("finish")

func finish() -> void:
	get_tree().quit(0 if failures.is_empty() else 1)
