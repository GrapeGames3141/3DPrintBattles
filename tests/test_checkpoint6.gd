extends Node
var failures: Array[String] = []

func require(value: bool, message: String) -> void:
	if not value: failures.append(message); push_error(message)

func _ready() -> void:
	var sequence := ArcaneForgeSequence.create(false)
	require(sequence.phase == ArcaneForgeSequence.IDLE and not sequence.request_commit(), "idle cannot commit")
	require(sequence.begin() and sequence.advance(2100) and sequence.progress_bps == 2100 and sequence.layer_reveal_bps() == 3000, "print phase has monotonic integer layer mapping")
	require(sequence.advance(4900) and sequence.phase == ArcaneForgeSequence.RAW_COMPLETE and sequence.progress_bps == 7000, "raw completion has fixed threshold")
	require(ArcaneForgeSequence.presentation_interval_seconds(false) * ceil(float(ArcaneForgeSequence.PRINT_COMPLETE_BPS) / ArcaneForgeSequence.presentation_step_bps(false, ArcaneForgeSequence.PRINTING)) >= 10.0, "normal visible layer printing lasts at least ten seconds")
	require(sequence.request_commit() and not sequence.request_commit() and sequence.resolve_commit(true) and sequence.phase == ArcaneForgeSequence.RAW_HOLD, "commit request is a one-time latch before the raw hold")
	require(sequence.advance(ArcaneForgeSequence.RAW_HOLD_BPS) and sequence.phase == ArcaneForgeSequence.AWAKENING and sequence.advance(ArcaneForgeSequence.AWAKEN_BPS) and sequence.phase == ArcaneForgeSequence.DEPARTING and sequence.advance(ArcaneForgeSequence.DEPART_BPS) and sequence.phase == ArcaneForgeSequence.AWAKENED and not sequence.skip(), "committed raw hold, awakening, departure, and final state complete once")
	var reduced := ArcaneForgeSequence.create(true); reduced.begin(); reduced.skip()
	require(reduced.reduced_motion and reduced.phase == ArcaneForgeSequence.RAW_COMPLETE and reduced.request_commit() and reduced.resolve_commit(true) and reduced.skip() and reduced.phase == ArcaneForgeSequence.AWAKENED and ArcaneForgeSequence.presentation_interval_seconds(true) > ArcaneForgeSequence.presentation_interval_seconds(false), "reduced motion remains calm staged, safe, and skippable")
	var frame_stage := ArcaneForgeStage.new()
	frame_stage.configure("cinderpaw", false, false)
	frame_stage.set_presentation_time(0.0)
	var first_frame := frame_stage.printer_frame_index()
	frame_stage.set_preview_phase(ArcaneForgeSequence.PRINTING, 1200)
	frame_stage.set_presentation_time(1.0)
	require(first_frame == 0 and frame_stage.printer_frame_index() in [1, 2, 3] and ArcaneForgeStage.PRINTER_FRAME_PATHS.size() == 4, "printing maps four printer frames through a deterministic ping-pong")
	for path in ArcaneForgeStage.PRINTER_FRAME_PATHS:
		var source := Image.load_from_file(ProjectSettings.globalize_path(path))
		require(source != null and not source.is_empty() and source.get_pixel(0, 0).a == 0.0 and source.get_pixel(source.get_width() - 1, source.get_height() - 1).a == 0.0, "%s has transparent keyed corners" % path)
	for path in ["res://assets/ui/printforge_launcher_icon.png", "res://assets/ui/workshop_boot_splash.png"]:
		require(ResourceLoader.exists(path) and ResourceLoader.load(path) != null, "%s runtime icon/splash path loads" % path)
	require(int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)) == 6, "sensor orientation is configured")
	require(str(ProjectSettings.get_setting("application/boot_splash/image", "")) == "res://assets/ui/workshop_boot_splash.png", "boot splash setting is runtime PNG")
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
